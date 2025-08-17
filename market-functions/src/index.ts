import { XMLParser } from 'fast-xml-parser';
import { defineSecret } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import _ from 'lodash';
import { z } from 'zod';

// --- Firestore admin ---
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
initializeApp();

setGlobalOptions({
  region: 'europe-west3',
  maxInstances: 5,
  timeoutSeconds: 60,
  memory: '512MiB',
});

const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');

// ---------- Config: which feeds to refresh ----------
/**
 * You can move this list to Firestore (e.g. document settings/targets)
 * if you want to edit it without redeploys.
 */
type Target = {
  key: string; // doc id in Firestore
  tickers?: string[]; // e.g., ["AAPL","NVDA"]
  topic?: string; // e.g., "stock market"
  riskLevel?: 'low' | 'medium' | 'high';
  pageSize?: number; // headlines cap
};
const TARGETS: Target[] = [
  { key: 'us_market', topic: 'stock market', riskLevel: 'medium', pageSize: 8 },
  {
    key: 'tech_megacaps',
    tickers: ['AAPL', 'MSFT', 'NVDA', 'GOOGL', 'AMZN'],
    riskLevel: 'medium',
  },
  // Add more groups as needed…
];

// ---------- Shared helpers ----------
const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '',
});

type RssItem = {
  title?: string;
  link?: string | { href?: string };
  pubDate?: string;
  description?: string;
};

function rssUrlFor(t: Target): string {
  if (t.tickers?.length) {
    return `https://feeds.finance.yahoo.com/rss/2.0/headline?s=${encodeURIComponent(
      t.tickers.join(',')
    )}&region=US&lang=en-US`;
  }
  return 'https://feeds.finance.yahoo.com/rss/2.0/headline?s=^GSPC,^NDX,^DJI,^IXIC&region=US&lang=en-US';
}

function summarizeLine(title: string, desc?: string): string {
  const clean = (desc ?? '')
    .replace(/<[^>]*>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  const short = clean.slice(0, 180) + (clean.length > 180 ? '…' : '');
  return short ? `${title} — ${short}` : title;
}

async function fetchCompactNews(t: Target) {
  const url = rssUrlFor(t);
  const res = await fetch(url);
  if (!res.ok) throw new Error(`RSS fetch failed: ${res.status}`);
  const xml = await res.text();
  const rss = parser.parse(xml);
  const raw: RssItem[] = rss?.rss?.channel?.item || rss?.feed?.entry || [];

  const normalized = raw
    .map((it) => ({
      title: (it.title || '').toString().trim(),
      link:
        typeof it.link === 'string' ? it.link : (it.link as any)?.href ?? '',
      description: (it.description || '').toString(),
      pubDate: it.pubDate ? new Date(it.pubDate) : new Date(0),
    }))
    .filter((x) => x.title);

  const dedup = _.uniqBy(normalized, (x) =>
    x.title.toLowerCase().replace(/\s+/g, ' ').slice(0, 140)
  );

  const sorted = dedup
    .sort((a, b) => b.pubDate.getTime() - a.pubDate.getTime())
    .slice(0, Math.max(3, t.pageSize ?? 8));

  const lines = sorted.map((x) => `• ${summarizeLine(x.title, x.description)}`);
  return {
    url,
    items: sorted.map((x) => ({
      title: x.title,
      link: x.link,
      publishedAt: x.pubDate.toISOString(),
    })),
    compactText: lines.join('\n'),
  };
}

async function analyzeWithAI({
  target,
  compactNews,
}: {
  target: Target;
  compactNews: string;
}) {
  const system = `You are a pragmatic, risk-aware investment analyst. Be concise.`;
  const topic = target.tickers?.length
    ? target.tickers.join(', ')
    : target.topic ?? 'market';
  const userPrompt = [
    `Topic: ${topic}`,
    `Risk tolerance: ${target.riskLevel ?? 'medium'}`,
    `Recent market headlines (Yahoo Finance):`,
    compactNews,
    ``,
    `Task:`,
    `1) Market read in 3 concise bullets.`,
    `2) One action (BUY/SELL/HOLD/WATCHLIST) + rationale.`,
    `3) Two key risks to monitor.`,
    `Limit to 120 words.`,
  ].join('\n');

  const resp = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
    },
    body: JSON.stringify({
      model: 'gpt-4.1-mini',
      input: [
        { role: 'system', content: system },
        { role: 'user', content: userPrompt },
      ],
      max_output_tokens: 250,
    }),
  });

  if (!resp.ok)
    throw new Error(`AI error ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  return data.output_text ?? '';
}

async function refreshOne(
  target: Target,
  reason: 'preopen' | 'intraday' | 'postclose'
) {
  const db = getFirestore();
  const feed = await fetchCompactNews(target);
  const recommendation = await analyzeWithAI({
    target,
    compactNews: feed.compactText,
  });

  const payload = {
    target,
    feed: { source: 'Yahoo Finance RSS', url: feed.url, items: feed.items },
    brief: feed.compactText,
    recommendation,
    reason,
    updatedAt: FieldValue.serverTimestamp(),
  };

  // latest snapshot
  await db
    .collection('marketBriefs')
    .doc(target.key)
    .set(payload, { merge: true });

  // history snapshot
  const ts = Date.now();
  await db
    .collection('marketBriefs')
    .doc(target.key)
    .collection('history')
    .doc(String(ts))
    .set(payload);

  return { key: target.key, items: feed.items.length };
}

// ---------- Schedules ----------
// Weekdays, Europe/Berlin timezone.
export const refreshMarketBriefsPreOpen = onSchedule(
  { schedule: '0 15 * * 1-5', timeZone: 'Europe/Berlin' }, // 15:00 = 30m before 15:30 open
  async () => {
    for (const t of TARGETS) await refreshOne(t, 'preopen');
  }
);

export const refreshMarketBriefsIntraday = onSchedule(
  { schedule: '0 16-22/3 * * 1-5', timeZone: 'Europe/Berlin' }, // 16:00,19:00,22:00
  async () => {
    for (const t of TARGETS) await refreshOne(t, 'intraday');
  }
);

export const refreshMarketBriefsPostClose = onSchedule(
  { schedule: '30 22 * * 1-5', timeZone: 'Europe/Berlin' }, // 22:30 = 30m after 22:00 close
  async () => {
    for (const t of TARGETS) await refreshOne(t, 'postclose');
  }
);

// (optional) Keep your existing callable for on-demand refresh:
const ReqSchema = z.object({
  tickers: z.array(z.string().toUpperCase()).max(10).optional(),
  topic: z.string().min(2).max(64).optional(),
  riskLevel: z.enum(['low', 'medium', 'high']).optional(),
  pageSize: z.number().int().min(3).max(15).optional(),
});
export const analyzeMarket = onCall(
  { secrets: [OPENAI_API_KEY], enforceAppCheck: true },
  async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
    const parsed = ReqSchema.safeParse(req.data ?? {});
    if (!parsed.success)
      throw new HttpsError('invalid-argument', 'Invalid payload');

    const override: Target = { key: 'adhoc', ...parsed.data };
    const feed = await fetchCompactNews(override);
    const recommendation = await analyzeWithAI({
      target: override,
      compactNews: feed.compactText,
    });

    return {
      ok: true,
      feed: { source: 'Yahoo Finance RSS', url: feed.url, items: feed.items },
      brief: feed.compactText,
      recommendation,
    };
  }
);
