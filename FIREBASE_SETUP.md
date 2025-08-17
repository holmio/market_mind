# Firebase Setup for Market Mind

This document outlines the Firebase configuration and security rules for the Market Mind application.

## 🔥 Firebase Services Configuration

The Market Mind app uses the following Firebase services:
- **Firestore** - Database for market briefs, user data, portfolios, and transactions
- **Firebase Storage** - File storage for user uploads, market charts, and media
- **Firebase Functions** - Server-side logic for market analysis and scheduled updates
- **Firebase Authentication** - User authentication and authorization

## 📁 Project Structure

```
market_mind/
├── firebase.json          # Firebase project configuration
├── firestore.rules        # Firestore security rules
├── storage.rules          # Storage security rules
├── firestore.indexes.json # Database indexes
├── market-functions/      # Firebase Functions for market analysis
│   ├── src/index.ts      # Main functions code
│   └── package.json      # Functions dependencies
└── lib/services/
    └── firebase_services.dart # Flutter Firebase services
```

## 🚀 Getting Started

### 1. Install Dependencies

```bash
# Install Firebase CLI globally (if not already installed)
npm install -g firebase-tools

# Install functions dependencies
cd market-functions
npm install
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Deploy Firebase Configuration

```bash
# Deploy security rules and indexes
firebase deploy --only firestore,storage

# Deploy functions
firebase deploy --only functions

# Deploy everything
firebase deploy
```

## 🔐 Security Rules Overview

### Firestore Rules

Our Firestore security rules are designed around the Market Mind app architecture:

#### Key Collections:

- **`marketBriefs`** - AI-analyzed market data (public read, functions write only)
- **`users`** - User profiles (private to each user)
- **`portfolios`** - User portfolios (private to each user)  
- **`transactions`** - User transactions (private to each user)
- **`watchlists`** - User watchlists (private to each user)
- **`userAnalysis`** - Custom market analysis (private to each user)
- **`notifications`** - User notifications (private to each user)

#### Helper Functions:

- `isAuthenticated()` - Checks if user is signed in
- `isValidUser()` - Checks if user is authenticated with verified email
- `isOwner(userId)` - Checks if current user owns the resource
- `isSystemFunction()` - Allows Firebase Functions service account access

### Storage Rules

Storage rules protect user files and media:

- **User Profile Images** - Private to each user
- **Portfolio Documents** - Private to each user
- **Market Data Assets** - Public read, functions write
- **System Assets** - Public read, admin write

### Key Security Features:

1. **User Data Isolation** - Users can only access their own data
2. **Function-Only Write Access** - Market data can only be written by Firebase Functions
3. **Email Verification** - Most operations require verified email
4. **File Type Validation** - Only specific file types allowed for uploads
5. **Size Limits** - Images (10MB), Documents (20MB)

## 📊 Firebase Functions

### Market Analysis Functions

The `market-functions` codebase provides:

1. **Scheduled Market Updates** - Automatic market brief updates
   - Pre-market (15:00 Berlin time)
   - Intraday (16:00, 19:00, 22:00 Berlin time)  
   - Post-market (22:30 Berlin time)

2. **On-Demand Analysis** - `analyzeMarket` callable function
   - Custom ticker analysis
   - Risk-level based recommendations
   - AI-powered market insights

### Environment Variables

Set up required secrets:

```bash
# Set OpenAI API key for AI analysis
firebase functions:secrets:set OPENAI_API_KEY
```

## 🛠️ Development Commands

### Firebase Functions

```bash
# Serve functions locally
cd market-functions
npm run serve

# Build TypeScript
npm run build

# Deploy functions only
firebase deploy --only functions:market-functions

# View function logs
firebase functions:log
```

### Firestore

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes

# Start Firestore emulator
firebase emulators:start --only firestore
```

### Storage

```bash
# Deploy storage rules
firebase deploy --only storage

# Start storage emulator
firebase emulators:start --only storage
```

## 📱 Flutter Integration

The Flutter app connects to Firebase using the configuration in:
- `lib/firebase_options.dart` - Auto-generated Firebase config
- `lib/services/firebase_services.dart` - Custom Firebase service wrapper

### Key Flutter Firebase Packages:
- `firebase_core` - Core Firebase functionality
- `firebase_auth` - Authentication
- `cloud_firestore` - Firestore database
- `firebase_storage` - File storage
- `cloud_functions` - Callable functions
- `firebase_messaging` - Push notifications

## 🔧 Customization

### Adding New Collections

1. Add security rules in `firestore.rules`
2. Add indexes in `firestore.indexes.json` if needed
3. Update Flutter services in `firebase_services.dart`
4. Deploy: `firebase deploy --only firestore`

### Modifying Functions

1. Edit `market-functions/src/index.ts`
2. Build: `npm run build`
3. Deploy: `firebase deploy --only functions`

### Updating Storage Rules

1. Edit `storage.rules`
2. Deploy: `firebase deploy --only storage`

## 🚨 Security Best Practices

1. **Never store sensitive data in client-side code**
2. **Always validate data on the server side (in Functions)**
3. **Use Firebase App Check for additional security**
4. **Regularly audit security rules**
5. **Monitor usage and set up billing alerts**
6. **Use environment-specific projects (dev, staging, prod)**

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Functions](https://firebase.google.com/docs/functions)
- [Flutter Firebase](https://firebase.flutter.dev/)

## 🐛 Troubleshooting

### Common Issues:

1. **Permission Denied** - Check security rules and user authentication
2. **Function Timeout** - Increase timeout in `setGlobalOptions`
3. **Index Missing** - Deploy firestore indexes
4. **Storage Upload Fails** - Check file size and type validation

### Debug Commands:

```bash
# Check Firebase project status
firebase projects:list

# Test security rules locally
firebase emulators:start

# View detailed error logs
firebase functions:log --limit 50
```
