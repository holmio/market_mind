# Investment Assistant App 📈📱

A mobile application built with **Flutter** and powered by **Firebase** to help users monitor and act on investment opportunities using AI recommendations. The system analyzes market data, detects buy/sell signals, and sends real-time notifications to the user.

## 🚀 Features

- 🧠 AI-based investment opportunity analysis
- 🔔 Real-time push notifications for buy/sell signals
- 📊 Market tracking and data visualization
- 🔐 Secure user authentication
- 🗃️ Cloud-synced data and settings
- 📱 Mobile-first experience using Flutter

---

## 🧩 Business Logic

### Core Flow

1. **User sets up portfolio** with an initial balance (e.g., €500).
2. The **AI system scans the market** and identifies potential investments using historical performance, technical indicators, or custom heuristics.
3. When a buy signal is found:
   - AI sends a **notification**: _“Opportunity detected: consider buying XYZ at €X.XX”_.
4. After acquisition, the system **monitors price evolution**.
5. Once gain/loss thresholds are met:
   - AI sends a **sell alert**: _“You've reached a gain of 15% – consider selling XYZ.”_

---

## 🧰 Technologies Used

| Component           | Tech Stack                       |
| ------------------- | -------------------------------- |
| Frontend (mobile)   | Flutter (Dart)                   |
| Backend             | Firebase Functions (TypeScript)  |
| Authentication      | Firebase Auth                    |
| Database            | Firebase Firestore               |
| Notifications       | Firebase Cloud Messaging (FCM)   |
| Hosting/Infra       | Firebase Hosting (optional)      |
| AI/ML Analysis      | OpenAI API or custom AI pipeline |
| Scheduling/Triggers | Cloud Scheduler + Pub/Sub        |

---

## 🛠 Project Structure

```plaintext
market_mind/
├── lib/
│   ├── main.dart                # Entry point of the Flutter app
│   ├── screens/                 # UI screens
│   ├── models/                  # Data models
│   ├── services/                # Business logic and API calls
│   └── widgets/                 # Reusable UI components
├── functions/                 # Firebase Functions
│   ├── index.ts                 # Main entry point for Firebase Functions
│   ├── aiAnalysis.ts            # AI analysis logic
│   ├── notifications.ts          # Notification handling
│   └── utils.ts                 # Utility functions
├── pubspec.yaml                # Flutter dependencies
├── firebase.json              # Firebase configuration
└── README.md                  # Project documentation
```

---

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/holmio/market_mind

# Navigate into the project directory
cd market_mind

# Install Flutter dependencies
flutter pub get

# Set up Firebase
firebase init

# Follow the prompts to configure Firebase for your project

# Run the app
flutter run
```

---
