# 🥗 Autonomous AI Nutrition Engine

> **A demand-driven, self-populating nutrition database for Egyptian restaurants — powered by Google Gemini AI.**

[![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Prisma](https://img.shields.io/badge/Prisma-ORM-2D3748?logo=prisma&logoColor=white)](https://www.prisma.io/)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-4285F4?logo=google&logoColor=white)](https://ai.google.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📖 Overview

The **Autonomous AI Nutrition Engine** is a REST API backend that reverse-engineers the nutritional macros of any Egyptian restaurant menu item using Google Gemini AI.

The database **starts completely empty**. The first time a menu item is requested, Gemini AI analyses it and calculates tight macro ranges (calories, protein, carbs, fats). The result is cached in PostgreSQL — every subsequent request for that item returns instantly at **zero API cost**.

This project also includes a **Talabat Chrome Extension** that overlays macro information directly on Talabat restaurant pages.

---

## ✨ Features

- 🤖 **AI-Powered** — Gemini reverse-engineers any menu item with tight 10–15% macro margins
- ⚡ **Smart Caching** — Cache hit = zero API cost, sub-100ms response
- 🏪 **13 Pre-seeded Restaurants** — Popular Egyptian fast-food, koshary, and grill spots
- 📦 **Batch Processing** — Process up to 50 items in a single request
- 🛠️ **Admin Cache Tools** — View stats, purge items/restaurants, reset entire cache
- 🔒 **Type-Safe** — Full TypeScript with centralized types and DTOs
- 🌐 **Browser Extension** — Chrome extension that shows macros on Talabat pages

---

## 🏗️ Architecture

### Two-Table Design

| Table | Purpose |
|-------|---------|
| `Restaurant` | Metadata (name, category, rating). Created on-the-fly on first query. |
| `CachedMenuItem` | AI-generated macro ranges. Keyed by `(restaurantId, itemName)`. |

### Demand-Driven Workflow

```
User Request
  │
  ├─→ 1. Find or create Restaurant (upsert)
  │
  ├─→ 2. Check cache for (Restaurant, Item)
  │
  ├─→ 3a. CACHE HIT  → return instantly         [$0, <100ms]
  │
  └─→ 3b. CACHE MISS → call Gemini AI
           ├─→ Reverse-engineer item macros
           ├─→ Validate response (min ≤ max)
           ├─→ Persist to database
           └─→ Return result                     [~0.01¢, 1-2s]
```

### Project Structure

```
Calc-calories/
├── prisma/
│   ├── schema.prisma          # Database schema (Restaurant, CachedMenuItem)
│   └── seed.ts                # 13 Egyptian restaurants seed data
├── src/
│   ├── app.ts                 # Express entry point & middleware
│   ├── config/
│   │   └── index.ts           # Centralized config & category mappings
│   ├── types/
│   │   └── index.ts           # Shared TypeScript types & DTOs
│   ├── services/
│   │   ├── gemini.service.ts  # Gemini AI integration
│   │   └── prisma.service.ts  # Database singleton
│   ├── controllers/
│   │   ├── nutrition.controller.ts   # Single-item endpoint
│   │   ├── batch.controller.ts       # Batch processing endpoint
│   │   └── cache.controller.ts       # Cache management endpoints
│   ├── middleware/
│   │   └── validation.ts      # Request validation & error handling
│   └── routes/
│       └── nutrition.routes.ts # API route definitions
├── talabat-nutrition-extension/  # Chrome browser extension
│   ├── manifest.json
│   ├── background.js
│   ├── content.js
│   ├── popup.html / popup.js
│   └── styles.css
├── api-examples.sh            # cURL test scenarios
├── .env.example               # Environment variables template
├── package.json
└── tsconfig.json
```

---

## ⚡ Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL database
- Redis (for BullMQ queue)
- Gemini API key — get one free at [ai.google.dev](https://ai.google.dev)

### 1. Clone & Install

```bash
git clone https://github.com/your-username/Calc-calories.git
cd Calc-calories
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and fill in your credentials:

```env
DATABASE_URL="postgresql://user:password@localhost:5432/nutrition_engine?schema=public"
GEMINI_API_KEY="your-api-key-here"
REDIS_URL="redis://localhost:6379"
PORT=3000
NODE_ENV=development
```

### 3. Set Up Database

```bash
# Push schema to your database
npm run db:push

# (Optional) Seed with 13 Egyptian restaurants
npm run db:seed
```

### 4. Start Dev Server

```bash
npm run dev
```

Server runs on `http://localhost:3000` ✅

---

## 📡 API Reference

Base URL: `http://localhost:3000/api/nutrition`

### Endpoints Summary

| Endpoint | Method | Purpose | Cache Hit | Cache Miss |
|----------|--------|---------|-----------|-----------|
| `/calculate` | POST | Single item | <100ms | 1–2s |
| `/batch` | POST | Up to 50 items | <200ms | 30–60s |
| `/cache/stats` | GET | Cache breakdown | <50ms | — |
| `/cache/:restaurant` | DELETE | Purge restaurant | — | — |
| `/cache/:restaurant/:item` | DELETE | Purge single item | — | — |
| `/cache/reset` | POST | Clear all cache | — | — |

---

### POST `/calculate` — Single Item

```bash
curl -X POST http://localhost:3000/api/nutrition/calculate \
  -H "Content-Type: application/json" \
  -d '{
    "restaurantName": "Buffalo Burger",
    "restaurantCategory": "fast-food",
    "itemName": "Old School 200g"
  }'
```

**Response (Cache Hit):**
```json
{
  "success": true,
  "source": "cache",
  "restaurant": {
    "id": "uuid",
    "name": "Buffalo Burger",
    "category": "fast-food"
  },
  "item": {
    "name": "Old School 200g",
    "calories": { "min": 850, "max": 950 },
    "protein":  { "min": 48,  "max": 55 },
    "carbs":    { "min": 65,  "max": 75 },
    "fats":     { "min": 38,  "max": 45 },
    "cachedAt": "2025-06-01T10:30:00Z"
  }
}
```

**Response (Cache Miss — AI called):**
```json
{
  "success": true,
  "source": "ai_generated",
  "restaurant": { "..." : "..." },
  "item": { "..." : "..." }
}
```

---

### POST `/batch` — Batch Processing

Process up to **50 items** in one request:

```bash
curl -X POST http://localhost:3000/api/nutrition/batch \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      { "restaurantName": "Buffalo Burger", "itemName": "Old School 200g" },
      { "restaurantName": "McDonald'\''s",    "itemName": "Big Mac" },
      { "restaurantName": "KFC",             "itemName": "Fried Chicken Bucket" }
    ]
  }'
```

**Response:**
```json
{
  "success": true,
  "totalRequested": 3,
  "totalProcessed": 3,
  "results": [ { "..." : "..." } ],
  "summary": {
    "cacheHits": 2,
    "aiGenerated": 1,
    "failed": 0
  }
}
```

---

### GET `/cache/stats` — Cache Statistics

```bash
curl http://localhost:3000/api/nutrition/cache/stats
```

```json
{
  "success": true,
  "totalRestaurants": 5,
  "totalCachedItems": 47,
  "restaurants": [
    {
      "name": "Buffalo Burger",
      "category": "fast-food",
      "itemCount": 12,
      "createdAt": "2025-06-01T10:00:00Z"
    }
  ]
}
```

---

### DELETE `/cache/:restaurant` — Purge Restaurant Cache

```bash
curl -X DELETE http://localhost:3000/api/nutrition/cache/Buffalo%20Burger
```

### DELETE `/cache/:restaurant/:item` — Purge Single Item

```bash
curl -X DELETE "http://localhost:3000/api/nutrition/cache/Buffalo%20Burger/Old%20School%20200g"
```

### POST `/cache/reset` — Reset Entire Cache ⚠️

```bash
curl -X POST http://localhost:3000/api/nutrition/cache/reset \
  -H "X-Confirm-Reset: true"
```

---

## 🗄️ Database Schema

```sql
-- Restaurants (auto-created on first query)
CREATE TABLE "Restaurant" (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT NOT NULL UNIQUE,
  category  TEXT NOT NULL,
  rating    FLOAT DEFAULT 4.6,
  createdAt TIMESTAMP DEFAULT NOW()
);

-- Cached macro ranges (populated by Gemini AI on cache miss)
CREATE TABLE "CachedMenuItem" (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurantId UUID NOT NULL REFERENCES "Restaurant"(id) ON DELETE CASCADE,
  itemName     TEXT NOT NULL,

  -- Macro ranges with tight 10–15% margin
  caloriesMin  INT NOT NULL,
  caloriesMax  INT NOT NULL,
  proteinMin   INT NOT NULL,
  proteinMax   INT NOT NULL,
  carbsMin     INT NOT NULL,
  carbsMax     INT NOT NULL,
  fatsMin      INT NOT NULL,
  fatsMax      INT NOT NULL,

  createdAt    TIMESTAMP DEFAULT NOW(),
  UNIQUE(restaurantId, itemName)  -- prevents duplicate cache entries
);
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `GEMINI_API_KEY` | ✅ | Google Gemini API key |
| `REDIS_URL` | ✅ | Redis connection URL |
| `PORT` | ❌ | Server port (default: 3000) |
| `NODE_ENV` | ❌ | `development` or `production` |
| `GEMINI_MODEL` | ❌ | AI model override (default: `gemini-2.0-flash-lite`) |
| `GEMINI_MOCK` | ❌ | Set `true` to skip real AI calls during testing |

### Change Gemini Model

In `src/services/gemini.service.ts`:

```typescript
const model = genAI.getGenerativeModel({
  model: "gemini-2.0-flash-lite",  // or gemini-2.5-flash, gemini-1.5-pro, etc.
});
```

### Add Restaurant Categories

In `src/config/index.ts`:

```typescript
export const CATEGORY_DEFAULTS: Record<string, string> = {
  "buffalo burger": "fast-food",
  "abou tarek":     "koshary",
  "arab":           "grills",
  // Add your restaurant here ↓
  "my restaurant":  "your-category",
};
```

---

## 🧪 Development

### Available Scripts

```bash
npm run dev          # Start dev server with hot-reload
npm run build        # Compile TypeScript → dist/
npm start            # Start production server

npm run db:push      # Sync Prisma schema with database
npm run db:seed      # Seed 13 Egyptian restaurants
npm run db:reset     # Force reset + re-seed
npm run db:studio    # Open Prisma Studio (GUI)
npm run db:generate  # Regenerate Prisma client
```

### Run API Tests

```bash
# Make the script executable (Linux/macOS)
chmod +x api-examples.sh
./api-examples.sh

# On Windows (Git Bash or WSL)
bash api-examples.sh
```

---

## 🌐 Talabat Chrome Extension

A companion browser extension that shows nutritional macros directly on [Talabat](https://www.talabat.com) restaurant pages.

### Installation (Developer Mode)

1. Open Chrome and go to `chrome://extensions/`
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked**
4. Select the `talabat-nutrition-extension/` folder

### How It Works

- The extension reads menu item names from Talabat pages
- Calls the local nutrition engine API (`http://localhost:3000`)
- Overlays macro badges (calories, protein, carbs, fats) on each menu item card

> **Note:** The backend API must be running locally for the extension to work.

See [`talabat-nutrition-extension/EXTENSION_README.md`](talabat-nutrition-extension/EXTENSION_README.md) for full details.

---

## 🔐 Error Handling

All errors return a consistent structure:

```json
{
  "success": false,
  "error": "restaurantName and itemName are required",
  "code": "VALIDATION_ERROR",
  "timestamp": "2025-06-01T10:30:00Z"
}
```

| Error Code | Cause |
|------------|-------|
| `VALIDATION_ERROR` | Missing or invalid request fields |
| `RESTAURANT_NOT_FOUND` | Restaurant lookup failed |
| `ITEM_NOT_FOUND` | Item lookup failed |
| `GEMINI_ERROR` | Gemini AI API failure |
| `DATABASE_ERROR` | Database query failure |
| `RATE_LIMIT_EXCEEDED` | Too many requests |

---

## 💰 Cost Analysis

| Scenario | Cost | Latency |
|----------|------|---------|
| Cache hit | **$0** | <100ms |
| Cache miss (Gemini Flash) | ~$0.0001 | 1–2s |
| Batch (30 hits + 20 misses) | ~$0.002 | ~40s |

After the first request for any item, **all subsequent requests are free**. Cache hit ratios typically reach 80%+ by Week 2.

---

## 📈 Performance

| Metric | Target | Typical |
|--------|--------|---------|
| Cache hit latency | <100ms | ~50–80ms |
| Cache miss latency | <2s | ~1–1.5s |
| Batch (50 items) | <60s | ~30–50s |
| Database query | <50ms | ~10–30ms |

---

## 🔮 Roadmap

- [ ] Parallel batch processing (`Promise.all`)
- [ ] Rate limiting middleware
- [ ] Redis layer for ultra-low latency
- [ ] AI confidence scores
- [ ] Arabic menu item support
- [ ] Admin dashboard UI
- [ ] More restaurant coverage

---

## 📄 License

MIT © 2026

---

## 🙋 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request
