# ⚡ QUICK REFERENCE — Autonomous AI Nutrition Engine

## 🚀 START IN 30 SECONDS

```bash
npm install
cp .env.example .env          # Edit with your credentials
npm run db:push
npm run dev
```

---

## 📡 API CALLS

### Single Item
```bash
curl -X POST http://localhost:3000/api/nutrition/calculate \
  -H "Content-Type: application/json" \
  -d '{
    "restaurantName": "Buffalo Burger",
    "itemName": "Old School 200g"
  }'
```

**Response:** `{ "success": true, "source": "cache"|"ai_generated", "restaurant": {...}, "item": {...} }`

---

### Batch (50 items)
```bash
curl -X POST http://localhost:3000/api/nutrition/batch \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"restaurantName": "Buffalo Burger", "itemName": "Old School 200g"},
      {"restaurantName": "McDonald'\''s", "itemName": "Big Mac"}
    ]
  }'
```

---

### Cache Stats
```bash
curl http://localhost:3000/api/nutrition/cache/stats
```

---

### Purge Item
```bash
curl -X DELETE http://localhost:3000/api/nutrition/cache/Buffalo%20Burger/Old%20School%20200g
```

---

## 📦 NPM SCRIPTS

| Script | Purpose |
|--------|---------|
| `npm run dev` | Start dev server (hot-reload) |
| `npm start` | Run production build |
| `npm run build` | Compile TypeScript |
| `npm run db:push` | Sync database schema |
| `npm run db:seed` | Load 13 Egyptian restaurants |
| `npm run db:studio` | Open Prisma GUI |
| `npm run db:reset` | Force reset + re-seed |

---

## 🏗️ KEY FILES

| File | Purpose |
|------|---------|
| `schema.prisma` | Database schema (Restaurant, CachedMenuItem) |
| `src/services/gemini.service.ts` | AI reverse-engineering with tight macro ranges |
| `src/controllers/nutrition.controller.ts` | Single-item calculation + cache logic |
| `src/controllers/batch.controller.ts` | Batch processing (50 items) |
| `src/controllers/cache.controller.ts` | Admin: view stats, purge cache |
| `src/config/index.ts` | Centralized restaurant categories & settings |
| `src/types/index.ts` | Shared TypeScript types & DTOs |

---

## 🔧 ENVIRONMENT VARIABLES

```env
DATABASE_URL="postgresql://user:password@host:5432/db"
GEMINI_API_KEY="your-api-key"
PORT=3000
NODE_ENV=development
```

Get Gemini API key free at [ai.google.dev](https://ai.google.dev)

---

## 💡 HOW IT WORKS

```
Request → Find/Create Restaurant → Check Cache
         ↓ (found)                    ↓
    Return cached macros    ┌─ Gemini API
    (zero cost)             │  ├─ Reverse-engineer
                            │  ├─ Validate
                            │  └─ Cache & return
                            └─ Cached data (next time: free)
```

---

## 📊 RESPONSE FORMAT

### Item Response
```json
{
  "id": "uuid",
  "name": "Old School 200g",
  "calories": { "min": 850, "max": 950 },
  "protein": { "min": 48, "max": 55 },
  "carbs": { "min": 65, "max": 75 },
  "fats": { "min": 38, "max": 45 },
  "cachedAt": "2025-06-01T10:30:00Z"
}
```

---

## ⚠️ LIMITS

- Batch max: **50 items per request**
- Restaurant category: Inferred from name or provided
- Macro margin: **10-15%** (tight ranges)
- Database: PostgreSQL 12+

---

## 🛠️ EXTEND RESTAURANTS

In `src/config/index.ts`:

```typescript
export const RESTAURANT_CATEGORIES: Record<string, string> = {
  "buffalo burger": "fast-food",
  "your-new-restaurant": "category",  // Add here
};
```

---

## 📊 MONITORING

Track these metrics:
- **Cache hit ratio** (target: >80%)
- **Response time** (target: <100ms hits, <2s misses)
- **API cost** (per request, should decrease over time)
- **Database size** (grows as cache fills)

---

## 🔐 SAFETY

- ✅ Validation on all inputs
- ✅ Batch size limits (50 max)
- ✅ Typed responses (TypeScript)
- ✅ Error codes without sensitive info
- ✅ Confirmation headers for reset

---

## 🚀 DEPLOY

**Quick options:**
1. **Vercel** — `vercel deploy` (recommended)
2. **Railway** — Connect GitHub, auto-deploy
3. **Docker** — `docker build && docker run`
4. **AWS EC2 + RDS** — Full control

See `DEPLOYMENT.md` for detailed guides.

---

## 📞 RESOURCES

- `README.md` — Full documentation
- `DEPLOYMENT.md` — Production guide
- `tests/api-examples.sh` — 10 test scenarios
- Inline code comments — TypeScript JSDoc

---

## ✅ VERIFY SETUP

```bash
# Check server is running
curl http://localhost:3000/health
# {"status":"ok","engine":"Autonomous AI Nutrition Engine"}

# Test single calculation
./tests/api-examples.sh

# Open database GUI
npm run db:studio
```

---

**Version:** 1.0.0 | **Status:** ✅ Production-Ready
