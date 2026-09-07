# 🌿 Aura — AI Nutrition & Fitness Ecosystem

<p align="center">
  <img src="mobile/assets/images/aura_logo.png" width="220" alt="Aura Logo" />
</p>

<p align="center">
  <strong>The Intelligent Nutrition, Calorie & Workout Ecosystem Powered by Dual-Engine AI</strong>
</p>

<p align="center">
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://nodejs.org/"><img src="https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white" alt="Node.js" /></a>
  <a href="https://www.typescriptlang.org/"><img src="https://img.shields.io/badge/TypeScript-5.7-3178C6?logo=typescript&logoColor=white" alt="TypeScript" /></a>
  <a href="https://www.prisma.io/"><img src="https://img.shields.io/badge/Prisma-7.x-2D3748?logo=prisma&logoColor=white" alt="Prisma" /></a>
  <a href="https://deepmind.google/technologies/gemini/"><img src="https://img.shields.io/badge/AI-Gemini_2.0_Flash-4285F4?logo=google&logoColor=white" alt="Gemini" /></a>
  <a href="https://ollama.com/"><img src="https://img.shields.io/badge/Local_AI-Ollama-FF6F61" alt="Ollama" /></a>
  <a href="https://www.revenuecat.com/"><img src="https://img.shields.io/badge/IAP-RevenueCat-E53935" alt="RevenueCat" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT" /></a>
</p>

---

## 📖 Executive Summary

**Aura** is an elite, full-stack nutrition and fitness platform designed to make daily calorie, macro, and workout tracking effortless. Combining the analytical accuracy of **Google Gemini 2.0 Flash** with the privacy and offline freedom of **on-device Ollama Vision**, Aura recognizes complex meals (including deep knowledge of Middle Eastern & Egyptian cuisine), reads product barcodes, transcribes voice meal logs, and builds periodized workout splits tailored to any phone display.

---

## 🏛️ System Architecture

```
                             ┌──────────────────────────────────────┐
                             │       Flutter Mobile Client          │
                             │       (Android / iOS / Tablets)      │
                             └──────┬────────────┬────────────▲─────┘
                                    │            │            │
                         (HTTPS / REST)          │            │
                    All routes authenticated     │            │
                    via Bearer JWT token         │            │
                                    │     (Local Multipart)   │
                                    │     POST /scan-local    │
                                    ▼            ▼            │
              ┌───────────────────────────────────────────────┴─────┐
              │           Express API Gateway v2 (/api/v1)          │
              │   (JWT Auth · Social OAuth · Rate Limiting · Log)   │
              └──────┬───────────────────┬────────────────────┬─────┘
                     │                   │                    │
               (Prisma ORM)       (Cloud API Call)    (Local API Call)
                     │                   │                    │
                     ▼                   ▼                    ▼
            ┌──────────────────┐┌──────────────────┐┌──────────────────┐
            │    PostgreSQL    ││  Google Gemini / ││   Local Ollama   │
            │  (Users, Meals,  ││ Open Food Facts  ││ (llava / llama3) │
            │  Water, Weight,  │└──────────────────┘└──────────────────┘
            │  Workouts, Plans)│
            └──────────────────┘
```

---

## ✨ Key Features & Capabilities

### 🥗 1. Dual-Engine Nutrition Intelligence
- **Cloud Gemini 2.0 Flash**: Snap or type any meal. Delivers rapid itemized ingredient breakdowns, gram estimation, and macro decomposition. Includes strict non-food detection (guards against selfies, objects, and animals).
- **Egyptian & Regional Food Database**: Specially tuned for regional recipes (Koshary, Hawawshi, Molokhia, Shawarma, Ful, Taameya) alongside standard international items.
- **Local On-Device Ollama Inference**: Private offline photo scanning via Ollama (`llava`, `llama3.2-vision`) with automated fallbacks.
- **Smart Barcode Scanner**: High-speed real-time camera scanning with torch toggle and camera flip, querying **Open Food Facts** with persistent caching and offline AI estimate fallbacks.
- **Microphone Voice Meal Logging**: Instant Arabic and English voice transcription (`speech_to_text`) that feeds directly into the AI nutrition analyzer.

### 🏋️ 2. Adaptive Workout Hub & Plan Builder
- **Material 3 Guided Wizard**: A sleek 4-step wizard (Fitness Goal, Equipment, Days per Week, and AI Routine Review) adapted cleanly to any phone aspect ratio without vertical overflow.
- **Direct 1-Tap Split Switcher**: Change training plans instantly at any time without needing to chat with the AI coach. Choose from proven splits:
  - **3-Day**: Full Body A/B/C, Classic PPL (1×)
  - **4-Day**: Upper / Lower Split, Bro Split (4-Day)
  - **5-Day**: Upper / Lower / PPL Hybrid, Bro Split (5-Day)
  - **6-Day**: PPL 2× (Classic), Arnold Split
- **Live In-Session Tracker**: Inline logger for sets, reps, weight, and RPE with tags for *Warm-up, Working, Top, and Back-off* sets.
- **Instant Coach Notes**: Dynamic contextual workout tips generated instantaneously without slow gateway stalls.
- **Calendar & Streak Tracking**: Weekly completion heatmaps, streak counters, rest day scheduling, and missed session recovery.

### 💧 3. Hydration & Weight Analytics
- **Water Tracker**: Quick-log buttons (+250ml, +500ml) with custom bottle sizes, daily target progress, and hourly hydration breakdown.
- **Body Weight Tracker**: Weight history graphs, delta calculations, target timeline projection, and 7/30/90/365-day moving averages.

### 🔐 4. Enterprise Security & Offline Durability
- **Triple-Method Authentication**: Secure Email/Password, **Sign in with Google**, and **Sign in with Apple** (iOS).
- **Encrypted Keystore Persistence**: Tokens are securely preserved via Android Keystore and iOS Keychain with ProGuard `-keep` rules to prevent sudden logout on release builds.
- **Robust 401 Interceptors**: Selective authentication handling that prevents erroneous session wipes.

### 💎 5. Premium Monetization & AdMob
- **RevenueCat Paywall**: Native in-app subscriptions with custom dark glassmorphic UI (`CustomPaywallSheet`). Verifies entitlements server-side.
- **Google AdMob Banners**: Non-intrusive banner ads for free-tier users, automatically dismissed for Premium subscribers.

### 🌍 6. Internationalization & Design
- **Arabic & English Support**: Dynamic RTL layout adaptation with cultural context and custom localized typography.
- **Aura Green Design System**: Bespoke aesthetic featuring `#235A42` (Aura Deep Forest), `#EAF5EE` (Sage Surface), and `#1E3A2B` (Dark Emerald).

---

## 📂 Repository Structure

```
Aura/
├── backend/                              # 🛠️ Node.js / Express REST API (v2.0.0)
│   ├── prisma/
│   │   ├── schema.prisma                 # PostgreSQL database models
│   │   └── seed.ts                       # Egyptian & international food database
│   ├── src/
│   │   ├── app.ts                        # Express entry point & middleware
│   │   ├── routes/
│   │   │   └── v1.routes.ts              # API v1 endpoint registry
│   │   ├── controllers/                  # Domain business logic
│   │   │   ├── user.controller.ts        # Auth, Google/Apple OAuth, Profile
│   │   │   ├── meal.controller.ts        # Gemini 2.0 Flash nutrition parsing
│   │   │   ├── local-llama.controller.ts # Local Ollama vision endpoints
│   │   │   ├── barcode.controller.ts     # Open Food Facts integration
│   │   │   ├── workout.controller.ts     # Routine, session & workout engine
│   │   │   ├── coach.service.ts          # AI coaching with 6s fail-safe race
│   │   │   ├── water.controller.ts       # Hydration tracking
│   │   │   └── weight.controller.ts      # Weight logs & trends
│   │   └── middleware/                   # JWT auth, rate limits, validators
│   ├── Dockerfile                        # Multi-stage production container
│   ├── docker-compose.yml                # API + PostgreSQL + Redis stack
│   └── package.json
│
└── mobile/                               # 📱 Flutter Application
    ├── android/                          # Android Native Config & ProGuard
    ├── ios/                              # iOS Xcode Project & Capabilities
    ├── assets/                           # Brand emblems, audio, icons
    ├── lib/
    │   ├── main.dart                     # App initialization & MultiBlocProvider
    │   ├── core/
    │   │   ├── network/                  # Dio client, interceptors & Keystore storage
    │   │   ├── theme/                    # Color tokens & typography
    │   │   └── widgets/                  # Ad banners, buttons, cards
    │   └── features/
    │       ├── auth/                     # Login, Register, Social Auth BLoCs
    │       ├── premium/                  # RevenueCat paywalls & subscription state
    │       ├── profile/                  # Onboarding, TDEE calculator
    │       └── calorie_tracker/          # Core domain features
    │           ├── data/                 # Repositories & workout catalogues
    │           └── presentation/
    │               ├── meals_dashboard_screen.dart   # High-density dashboard
    │               ├── workout_screen.dart           # Workout Hub & Split Switcher
    │               ├── workout_plan_wizard.dart      # 4-Step Material 3 Wizard
    │               ├── voice_meal_logging_sheet.dart # Speech-to-Text logger
    │               └── barcode_confirmation_sheet.dart
    └── pubspec.yaml                      # Dependencies & asset declarations
```

---

## 🚀 Quick Start Guide

### Prerequisites
- **Node.js**: v18+ & npm v9+
- **Flutter SDK**: v3.22+
- **PostgreSQL**: v14+ (or Docker)
- **Redis**: v7+ (for rate limiting)
- **Gemini API Key**: from [Google AI Studio](https://aistudio.google.com/)

---

### 1. Backend Setup

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Edit .env with your DATABASE_URL, GEMINI_API_KEY, and JWT_SECRET

# Run Prisma migrations & seed database
npx prisma migrate dev
npx prisma db seed

# Start development server
npm run dev
```

*The API will be available at `http://localhost:5000/api/v1`.*

#### Running with Docker:
```bash
cd backend
docker-compose up -d --build
```

---

### 2. Mobile App Setup

```bash
# Navigate to mobile directory
cd mobile

# Fetch Flutter dependencies
flutter pub get

# Run on connected device or emulator (Debug)
flutter run

# Build release Android App Bundle (AAB) for Google Play
flutter build appbundle --release

# Build standalone release APK
flutter build apk --release
```

---

## 📡 Core API Reference (`/api/v1`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/users/register` | Register with email & password |
| `POST` | `/users/login` | Log in and receive JWT token |
| `POST` | `/users/google` | Verify Google ID token & sign in |
| `POST` | `/users/apple` | Verify Apple identity token & sign in |
| `GET` | `/users/profile` | Retrieve user profile & TDEE macro targets |
| `POST` | `/meals/analyze` | Multimodal meal analysis (Gemini 2.0 Flash) |
| `POST` | `/meals/scan-barcode` | Open Food Facts lookup with cached response |
| `POST` | `/meals/log-barcode` | Log scanned product directly into diary |
| `GET` | `/foods/search` | Search Egyptian & international food database |
| `GET` | `/workouts/routine` | Get active workout routine & today's session |
| `POST` | `/workouts/setup` | Set/switch routine split (days, splitType, name) |
| `POST` | `/workouts/session/log` | Record completed workout session & sets |
| `POST` | `/workouts/session/override`| Override today's session (e.g. skip/rest) |
| `GET` | `/water/today` | Fetch today's hydration total & logs |
| `POST` | `/water/log` | Log water intake in milliliters |
| `GET` | `/weight/history` | Get historical weigh-ins & analytics |
| `POST` | `/weight/log` | Record a new body weight measurement |

---

## 🔐 Environment Variables (`backend/.env`)

```env
PORT=5000
NODE_ENV=development
DATABASE_URL="postgresql://user:password@localhost:5432/aura_db?schema=public"
REDIS_URL="redis://localhost:6379"

JWT_SECRET="your_secure_jwt_secret"
JWT_EXPIRES_IN="30d"

GEMINI_API_KEY="AIzaSy..."
OLLAMA_BASE_URL="http://127.0.0.1:11434"

REVENUECAT_WEBHOOK_SECRET="your_webhook_secret"
GOOGLE_CLIENT_ID="your_google_client_id"
APPLE_CLIENT_ID="your_apple_client_id"
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
