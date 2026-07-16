# Aura

<p align="center">
  <img src="mobile/assets/images/logo.png" width="180" alt="Aura Logo" />
</p>

> **A premium, full-stack AI-powered nutrition & fitness ecosystem. Track calories, analyze meals with Google Gemini or a local Llama vision model, log water & weight, plan workouts, and get AI-powered macro suggestions — all from one beautiful dark-mode mobile app.**

[![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Prisma](https://img.shields.io/badge/Prisma-7.x-2D3748?logo=prisma&logoColor=white)](https://www.prisma.io/)
[![Ollama](https://img.shields.io/badge/Ollama-Local_AI-FF6F61)](https://ollama.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📖 Overview

**Aura** is an elite, hybrid-AI fitness suite designed to solve the challenge of tracking calories and macros in the Egyptian and international food markets. The ecosystem is composed of two primary pillars:

1. **AI-First Mobile App (`mobile/`)** — A gorgeous dark-mode, multi-lingual app (AR/EN) with full RTL layout support. Features include an active workout tracker, water & weight logging, a food search database, weekly meal plans, AI meal analysis, and a dedicated Local AI Meal Scan interface.
2. **Multimodal REST Backend (`backend/`)** — A production-grade Express API (v2.0.0) built with TypeScript and Prisma. Orchestrates queries to Google Gemini and local Ollama inference models, manages user authentication (JWT), tracks all user data in PostgreSQL, and enforces rate limiting via Redis.

---

## ✨ System Architecture

```
                 ┌──────────────────────────────────────┐
                 │        Flutter Mobile Client         │
                 │              (mobile/)               │
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
  │     (JWT Auth · Rate Limiting · Request Logger)     │
  └──────┬───────────────────┬────────────────────┬─────┘
         │                   │                    │
   (Prisma ORM)       (Cloud API Call)    (Local API Call)
         │                   │                    │
         ▼                   ▼                    ▼
┌──────────────────┐┌──────────────────┐┌──────────────────┐
│    PostgreSQL    ││  Google Gemini   ││   Local Ollama   │
│  (Users, Meals, ││   (Flash/Pro)    ││ (llava / llama3) │
│  Water, Weight, │└──────────────────┘└──────────────────┘
│  Workouts, Plans)│
└──────────────────┘
```

---

## 🚀 Key Features

### 📱 Mobile App
- 🔐 **JWT Authentication** — Register / Login with secure token storage via `flutter_secure_storage`
- 🧭 **Onboarding & Profile Setup** — Height, weight, age, gender, activity level, and fitness goal. Auto-calculates TDEE and macro targets
- 📊 **Dashboard** — Live macro rings, calorie progress, today's food log summary vs daily goals
- 🥗 **AI Meal Analysis** — Analyze meals by text description, restaurant name, or photo (uses Google Gemini)
- 🦙 **Offline Local AI Scan** — Snap or upload a plate photo — inference runs entirely on-device via Ollama (`llava` / `llama3.2-vision`). Your images never leave your machine
- 🔍 **Egyptian Food Database Search** — Bilingual (AR/EN) searchable database with categories, serving sizes, and full macro details
- 💧 **Water Tracking** — Log intake in ml, see daily progress vs goal with an hourly breakdown
- ⚖️ **Weight Logging** — Track weight history with trend analysis (delta, min/max/avg over 7–365 days)
- 🍽️ **Weekly Meal Plans** — Auto-generate a personalized 7-day meal plan based on your calorie goal. Mark entries as eaten
- 🏋️ **Workout Hub** — Configure a training split (3–6 days/week: Full Body, PPL, Upper/Lower, Bro Split, Arnold Split). View today's session, log sets with warm-up / working / top / back-off labels, and track progression vs last week
- 💡 **AI Macro Suggestions** — Get personalized supplement and food suggestions to hit daily macro targets
- 🌍 **AR/EN Localization + RTL** — Full bilingual support with dynamic RTL layout switching
- ⚙️ **Settings** — Language toggle, profile editing, goal updates

### 🛠️ Backend API
- ✅ **Full JWT Authentication** with bcrypt password hashing
- 📦 **Food Database** — Search by name (AR/EN), filter by category, paginated results
- 📋 **Food Logs** — Log items from the database; combined daily summary with totals vs goals
- 🤖 **Dual AI Engine** — Gemini for cloud meal analysis; Ollama for private offline vision inference
- 📅 **Meal Plan Engine** — Generate and manage weekly meal plans from the food database
- 🏋️ **Workout Routine API** — Save training split config; serve today's session with historical context
- 📈 **Weight & Water History** — Full log history with statistics
- 🔒 **Rate Limiting** — Redis-backed rate limiter on AI endpoints (30 req/min per user)
- 🐳 **Docker Support** — `Dockerfile` + `docker-compose.yml` for containerized deployment
- 🧪 **Test Suite** — Jest + Supertest integration tests

---

## 📂 Project Structure

```
Calc-calories/
├── backend/                        # 🛠️ Node.js REST API (v2.0.0)
│   ├── src/
│   │   ├── app.ts                  # Express entry point & global middleware
│   │   ├── routes/
│   │   │   └── v1.routes.ts        # All /api/v1 endpoints
│   │   ├── controllers/            # Business logic per domain
│   │   │   ├── user.controller.ts
│   │   │   ├── meal.controller.ts
│   │   │   ├── local-llama.controller.ts
│   │   │   ├── history.controller.ts
│   │   │   ├── suggestion.controller.ts
│   │   │   ├── profile.controller.ts
│   │   │   ├── food.controller.ts
│   │   │   ├── food-log.controller.ts
│   │   │   ├── water.controller.ts
│   │   │   ├── weight.controller.ts
│   │   │   ├── meal-plan.controller.ts
│   │   │   └── workout.controller.ts
│   │   ├── middleware/             # Auth, rate limiting, validation, error handling
│   │   ├── services/               # Prisma client, AI service wrappers
│   │   └── types/                  # Shared TypeScript types
│   ├── prisma/                     # PostgreSQL schema & seed data
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── package.json
│
└── mobile/                         # 📱 Flutter Mobile App
    ├── lib/
    │   ├── main.dart               # App entry, BLoC providers, router, LanguageCubit
    │   ├── core/
    │   │   ├── theme/              # AppTheme, AppColors design tokens
    │   │   ├── network/            # Dio API client with secure token injection
    │   │   ├── utils/              # Constants (box names, endpoints)
    │   │   └── widgets/            # Shared reusable widgets
    │   ├── features/
    │   │   ├── auth/               # Login · Register · AuthBloc
    │   │   ├── profile/            # Onboarding · ProfileBloc · TDEE setup
    │   │   └── calorie_tracker/    # All tracker features + BLoCs
    │   │       ├── presentation/
    │   │       │   ├── dashboard_screen.dart
    │   │       │   ├── meals_dashboard_screen.dart
    │   │       │   ├── analyze_meal_screen.dart
    │   │       │   ├── food_search_screen.dart
    │   │       │   ├── water_tracking_screen.dart
    │   │       │   ├── weight_progress_screen.dart
    │   │       │   ├── meal_plans_screen.dart
    │   │       │   ├── workout_screen.dart
    │   │       │   ├── ai_suggestion_screen.dart
    │   │       │   ├── history_screen.dart
    │   │       │   ├── settings_screen.dart
    │   │       │   ├── splash_screen.dart
    │   │       │   ├── home_shell_screen.dart
    │   │       │   ├── gyms_screen.dart
    │   │       │   └── market_screen.dart
    │   │       └── bloc/           # CalorieTrackerBloc, DashboardBloc, FoodSearchBloc,
    │   │                           # WaterBloc, WeightBloc, MealPlanBloc
    │   └── l10n/                   # AR/EN ARB localization files
    └── pubspec.yaml
```

---

## ⚡ Setup & Quick Start

### 1. Prerequisites
- [Node.js](https://nodejs.org/) (v18+)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.3.0+, Dart ≥3.3.0)
- [PostgreSQL](https://www.postgresql.org/)
- [Redis](https://redis.io/)
- [Ollama](https://ollama.com/) _(optional — required only for local AI scan)_

---

### 2. Configure Backend

```bash
cd backend
npm install
cp .env.example .env
```

Edit `.env` with your values:

```env
DATABASE_URL="postgresql://user:password@localhost:5432/nutrition_db?schema=public"
REDIS_URL="redis://localhost:6379"
GEMINI_API_KEY="your_google_gemini_api_key"
AI_PROVIDER="ollama"           # "ollama" or "google"
OLLAMA_BASE_URL="http://127.0.0.1:11434"
OLLAMA_VISION_MODEL="llava"
OLLAMA_MODEL="llama3"
JWT_SECRET="generate-a-secure-random-key"
PORT=3000
```

Push DB schema & seed Egyptian restaurant data:

```bash
npm run db:push
npm run db:seed
```

Start the development server:

```bash
npm run dev
# → API running on http://localhost:3000
```

---

### 3. Run Ollama Locally _(optional)_

```bash
# Pull the required models
ollama pull llama3
ollama pull llava

# Verify connection
curl http://localhost:11434
```

---

### 4. Run Flutter Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

---

### 5. Docker (Alternative)

```bash
cd backend
docker-compose up --build
```

---

## 📡 Full API Reference (`/api/v1`)

All endpoints below (except Auth) require:
```
Authorization: Bearer <jwt_token>
```

### 🔐 Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/register` | Create a new account |
| `POST` | `/auth/login` | Authenticate and receive a JWT |

### 👤 User & Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/users/me` | Get current user + today's macro summary |
| `PUT` | `/users/me/goals` | Update daily calorie & macro goals |
| `PUT` | `/users/profile` | Update physical profile (recalculates TDEE) |
| `GET` | `/users/tdee` | Get TDEE breakdown (Mifflin-St Jeor formula) |

### 🥗 AI Meal Analysis
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/meals/analyze` | Analyze meal via text or image (Gemini) |
| `POST` | `/meals/scan-local` | Analyze meal image using local Ollama vision |
| `POST` | `/meals/manual` | Manually log a meal with known macros |
| `GET` | `/meals/history` | Paginated meal log history |
| `GET` | `/meals/suggestions` | AI macro suggestions & supplement recommendations |
| `DELETE` | `/meals/:id` | Delete a meal log entry |

### 🔍 Food Database
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/foods/search` | Search by name (AR/EN), filter by category |
| `GET` | `/foods/categories` | List all categories with bilingual labels |
| `GET` | `/foods/:id` | Get a food item with full nutritional details |

### 📋 Food Logs
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/food-logs` | Log a database food item for today |
| `GET` | `/food-logs/today` | Today's combined food log summary vs goals |
| `DELETE` | `/food-logs/:id` | Delete a food log entry |

### 💧 Water Tracking
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/water` | Log water intake (ml) |
| `GET` | `/water/today` | Today's intake total, progress, hourly breakdown |
| `DELETE` | `/water/:id` | Delete a water log entry |

### ⚖️ Weight Tracking
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/weight` | Log today's weight (also updates TDEE profile) |
| `GET` | `/weight/history` | Weight history with trend stats (7–365 days) |
| `DELETE` | `/weight/:id` | Delete a weight log entry |

### 🍽️ Meal Plans
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/meal-plans/today` | Get today's meal plan with totals |
| `GET` | `/meal-plans/week` | Full week plan grouped by day |
| `POST` | `/meal-plans/generate` | Auto-generate weekly plan from calorie goal |
| `PUT` | `/meal-plans/:id/eaten` | Toggle meal plan entry as eaten |

### 🏋️ Workouts
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/workouts/setup` | Save training split config (days/week, split type) |
| `GET` | `/workouts/routine` | Get active workout routine + today's session |

---

## 🏋️ Workout Splits Available

| Days/Week | Splits Available |
|-----------|-----------------|
| **3 days** | Full Body A/B/C · Classic PPL (1×) |
| **4 days** | Upper / Lower Split · Bro Split |
| **5 days** | UL/PPL Hybrid · Bro Split (5-day) |
| **6 days** | PPL 2× (Classic) · Arnold Split |

Each session generates dynamic set labels: **Warm-up → Working Sets → Top Set → Back-off Set**, with weight & rep targets based on last week's performance.

---

## 🤖 Local AI Scan — Response Example

```json
{
  "success": true,
  "source": "local_llama_inference",
  "mealAnalysis": {
    "detectedFood": "Homemade Rice and Chicken Plate",
    "calories": 620,
    "protein": 42,
    "carbs": 80,
    "fats": 12
  },
  "llamaRecommendation": {
    "triggerWarning": true,
    "message": "This meal lacks sufficient protein for your daily goal. We recommend adding 30g of protein."
  }
}
```

---

## 🧪 Running Tests

```bash
cd backend
npm test                 # Run all integration tests
npm run test:coverage    # Run with coverage report
```

---

## 🌍 Localization

The app ships with full **Arabic & English** localization via Flutter's `flutter_localizations` and generated `AppLocalizations`. To switch language at runtime, the `LanguageCubit` persists the preference via `SharedPreferences` and rebuilds the entire widget tree with the correct locale and text direction (RTL for Arabic).

---

## 📦 Key Dependencies

### Backend
| Package | Purpose |
|---------|---------|
| `express` | HTTP server |
| `@prisma/client` | PostgreSQL ORM |
| `@google/generative-ai` | Gemini AI integration |
| `jsonwebtoken` + `bcryptjs` | JWT auth & password hashing |
| `express-rate-limit` + `ioredis` | Redis-backed rate limiting |
| `multer` | Multipart image upload |
| `zod` | Request schema validation |
| `bullmq` | Background job queue |

### Mobile
| Package | Purpose |
|---------|---------|
| `flutter_bloc` | BLoC state management |
| `dio` | HTTP client with interceptors |
| `hive_flutter` | Offline meal log cache |
| `flutter_secure_storage` | Secure JWT token storage |
| `go_router` | Declarative navigation |
| `fl_chart` | Macro & progress charts |
| `google_fonts` | Premium typography |
| `image_picker` | Camera / gallery meal photos |
| `shared_preferences` | Language preference persistence |
| `dartz` | Functional Either types for error handling |

---

## 📄 License
Licensed under the [MIT License](LICENSE).
