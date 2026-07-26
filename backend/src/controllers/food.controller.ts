// ============================================================
//  src/controllers/food.controller.ts
//  The Teneen — Food Database Search endpoints
//  GET /api/v1/foods/search?q=&lang=&category=&limit=
//  GET /api/v1/foods/:id
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";

// ── Validation ───────────────────────────────────────────────

const SearchQuerySchema = z.object({
  q:        z.string().min(1).max(200),
  lang:     z.enum(["en", "ar"]).default("en"),
  category: z.string().optional(),
  limit:    z.coerce.number().int().min(1).max(50).default(20),
  page:     z.coerce.number().int().min(1).default(1),
});

// ── In-Memory Search Cache ─────────────────────────────────────

const SEARCH_CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes cache

interface SearchCacheEntry {
  data: any;
  expiresAt: number;
}

const searchCache = new Map<string, SearchCacheEntry>();

function getCachedSearch(key: string): any | null {
  const entry = searchCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    searchCache.delete(key);
    return null;
  }
  return entry.data;
}

function setCachedSearch(key: string, data: any): void {
  searchCache.set(key, { data, expiresAt: Date.now() + SEARCH_CACHE_TTL_MS });
}

function safeNum(value: unknown): number {
  const n = Number(value);
  return isFinite(n) && n >= 0 ? Math.round(n * 10) / 10 : 0;
}

import { estimateNutritionFromName } from "../services/ai.service";

// ── Rate Limiter for AI Text Estimation ─────────────────────────

const aiEstTracker = new Map<string, number[]>();
const AI_EST_WINDOW_MS = 60 * 1000; // 1 minute
const AI_EST_MAX_REQUESTS = 10; // max 10 AI text estimations per minute per user/IP

function isAiEstRateLimited(key: string): boolean {
  const now = Date.now();
  const timestamps = (aiEstTracker.get(key) || []).filter(t => now - t < AI_EST_WINDOW_MS);
  if (timestamps.length >= AI_EST_MAX_REQUESTS) {
    return true;
  }
  timestamps.push(now);
  aiEstTracker.set(key, timestamps);
  return false;
}

// ── Auto-Persist Helper ────────────────────────────────────────

async function autoPersistFoodItems(items: Array<any>): Promise<void> {
  for (const item of items) {
    if (item.source === "local" || item.dataSource === "verified") continue;
    try {
      const existing = await prisma.foodItem.findFirst({
        where: {
          OR: [
            { nameEn: { equals: item.nameEn, mode: "insensitive" } },
            { nameAr: { equals: item.nameAr, mode: "insensitive" } },
          ],
        },
      });

      if (!existing) {
        const created = await prisma.foodItem.create({
          data: {
            nameEn:      item.nameEn,
            nameAr:      item.nameAr,
            calories:    item.calories,
            protein:     item.protein,
            carbs:       item.carbs,
            fats:        item.fats,
            fiber:       item.fiber || 0,
            servingSize: item.servingSize || 100,
            servingUnit: item.servingUnit || "g",
            category:    item.category || "General",
            isVerified:  false,
            dataSource:  item.dataSource || item.source || "external",
          },
        });
        item.id = created.id;
        console.log(`🌱 [FoodSearch] Auto-persisted ${item.dataSource || item.source} food item: "${item.nameEn}" (${created.id})`);
      } else {
        item.id = existing.id;
        item.dataSource = (existing as any).dataSource || "verified";
      }
    } catch (err) {
      console.error("❌ [FoodSearch] Auto-persist error:", err);
    }
  }
}

// ── GET /api/v1/foods/search ─────────────────────────────────

export async function searchFoods(req: Request, res: Response): Promise<void> {
  try {
    const parsed = SearchQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({
        error:   "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
      return;
    }

    const { q, lang, category, limit, page } = parsed.data;
    const cacheKey = `${q.toLowerCase().trim()}_${lang}_${category ?? ''}_${page}_${limit}`;

    // ── Cache check ───────────────────────────────────────────
    const cached = getCachedSearch(cacheKey);
    if (cached) {
      console.log(`✅ [FoodSearch] Cache HIT for key: ${cacheKey}`);
      res.status(200).json(cached);
      return;
    }

    const skip = (page - 1) * limit;

    // ── Step 1: Query Local Database ─────────────────────────
    const whereClause = {
      AND: [
        {
          OR: [
            { nameEn: { contains: q, mode: "insensitive" as const } },
            { nameAr: { contains: q, mode: "insensitive" as const } },
          ],
        },
        ...(category ? [{ category }] : []),
      ],
    };

    const [localItems, localTotal] = await Promise.all([
      prisma.foodItem.findMany({
        where:   whereClause,
        orderBy: [
          { isVerified: "desc" },
          { nameEn:     "asc"  },
        ],
        take: limit,
        skip,
        select: {
          id:          true,
          nameEn:      true,
          nameAr:      true,
          calories:    true,
          protein:     true,
          carbs:       true,
          fats:        true,
          fiber:       true,
          servingSize: true,
          servingUnit: true,
          category:    true,
          isVerified:  true,
          dataSource:  true,
        },
      }),
      prisma.foodItem.count({ where: whereClause }),
    ]);

    let finalItems: any[] = localItems.map((item) => ({
      ...item,
      source: "local" as const,
      dataSource: (item as any).dataSource || (item.isVerified ? "verified" : "external"),
    }));

    // ── Step 2: Query Open Food Facts (search-a-licious API) ─
    if (finalItems.length < limit) {
      const searchUrl = `https://search.openfoodfacts.org/search?q=${encodeURIComponent(
        q
      )}&page_size=${limit}&page=${page}`;

      try {
        const response = await fetch(searchUrl, {
          headers: {
            "User-Agent": "Aura-FitnessApp/1.0 (contact@aura.app)",
          },
          signal: AbortSignal.timeout(8000),
        });

        if (!response.ok) {
          console.warn(`⚠️ [FoodSearch] search-a-licious API returned HTTP ${response.status}`);
        } else {
          const searchData = (await response.json().catch(() => null)) as any;

          if (!searchData || !Array.isArray(searchData.hits)) {
            console.warn(`⚠️ [FoodSearch] search-a-licious returned unexpected response format (hits array missing)`);
          } else {
            const hits = searchData.hits;
            console.log(`🌐 [FoodSearch] search-a-licious returned ${hits.length} hit(s) for "${q}"`);

            const offItems = hits.map((product: any, idx: number) => {
              const nutriments = product.nutriments ?? {};
              const code = product.code || product._id || product.id || `${Date.now()}_${idx}`;
              const rawNameEn =
                (product.product_name_en as string | undefined)?.trim() ||
                (product.product_name as string | undefined)?.trim() ||
                "Unknown Product";
              const rawNameAr =
                (product.product_name_ar as string | undefined)?.trim() || rawNameEn;

              const calories = safeNum(
                nutriments["energy-kcal_100g"] ??
                  (nutriments["energy-kj_100g"] != null
                    ? Number(nutriments["energy-kj_100g"]) / 4.184
                    : nutriments["energy_100g"])
              );

              const servingQuantity = safeNum(product.serving_quantity);

              return {
                id:          `off_${code}`,
                nameEn:      rawNameEn,
                nameAr:      rawNameAr,
                calories,
                protein:     safeNum(nutriments["proteins_100g"]),
                carbs:       safeNum(nutriments["carbohydrates_100g"]),
                fats:        safeNum(nutriments["fat_100g"]),
                fiber:       safeNum(nutriments["fiber_100g"]),
                servingSize: servingQuantity > 0 ? servingQuantity : 100,
                servingUnit: (product.serving_quantity_unit as string | undefined)?.trim() || "g",
                category:    category || "General",
                isVerified:  false,
                source:      "external",
                dataSource:  "external",
              };
            });

            for (const offItem of offItems) {
              const isDuplicate = finalItems.some(
                (existing) => existing.nameEn.toLowerCase() === offItem.nameEn.toLowerCase()
              );
              if (!isDuplicate) {
                finalItems.push(offItem);
              }
            }
          }
        }
      } catch (err) {
        console.error("❌ [FoodSearch] search-a-licious API call failed:", err);
      }
    }

    // ── Step 3: AI Text Estimation Fallback if zero items ───────
    if (finalItems.length === 0) {
      const clientIp = req.ip || "anonymous";
      if (!isAiEstRateLimited(clientIp)) {
        console.log(`🤖 [FoodSearch] Triggering AI text estimation for obscure food: "${q}"`);
        try {
          const estimate = await estimateNutritionFromName(q);
          const aiItem = {
            id:          `ai_${Date.now()}`,
            nameEn:      estimate.dishName,
            nameAr:      estimate.dishName,
            calories:    estimate.calories,
            protein:     estimate.protein,
            carbs:       estimate.carbs,
            fats:        estimate.fats,
            fiber:       0,
            servingSize: 100,
            servingUnit: "g",
            category:    category || "General",
            isVerified:  false,
            source:      "external",
            dataSource:  "ai-estimated",
            confidenceScore: estimate.confidenceScore,
          };
          finalItems.push(aiItem);
        } catch (err) {
          console.error("❌ [FoodSearch] AI estimation fallback error:", err);
        }
      } else {
        console.warn(`⚠️ [FoodSearch] AI estimation rate limit reached for IP: ${clientIp}`);
      }
    }

    // ── Auto-persist external & AI items to local FoodItem DB ─
    await autoPersistFoodItems(finalItems);

    const total = localTotal + finalItems.length;

    const responsePayload = {
      items: finalItems,
      meta: {
        query: q,
        lang,
        total,
        page,
        limit,
        pages: Math.ceil(total / limit),
      },
    };

    setCachedSearch(cacheKey, responsePayload);

    res.status(200).json(responsePayload);
  } catch (error) {
    console.error("[food] searchFoods error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── GET /api/v1/foods/:id ────────────────────────────────────

export async function getFoodById(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    if (!id) {
      res.status(400).json({ error: "Food ID is required" });
      return;
    }

    const item = await prisma.foodItem.findUnique({
      where: { id },
    });

    if (!item) {
      res.status(404).json({ error: "Food item not found" });
      return;
    }

    res.status(200).json({ item });
  } catch (error) {
    console.error("[food] getFoodById error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── GET /api/v1/foods/categories ─────────────────────────────

export async function getFoodCategories(_req: Request, res: Response): Promise<void> {
  try {
    const categories = await prisma.foodItem.groupBy({
      by:      ["category"],
      _count:  { category: true },
      orderBy: { category: "asc" },
    });

    const CATEGORY_LABELS: Record<string, { en: string; ar: string }> = {
      breakfast:  { en: "Breakfast",   ar: "فطور"       },
      lunch:      { en: "Lunch",       ar: "غداء"       },
      dinner:     { en: "Dinner",      ar: "عشاء"       },
      snack:      { en: "Snacks",      ar: "وجبات خفيفة" },
      drink:      { en: "Drinks",      ar: "مشروبات"    },
      grain:      { en: "Grains",      ar: "حبوب ونشويات" },
      protein:    { en: "Proteins",    ar: "بروتينات"   },
      vegetable:  { en: "Vegetables",  ar: "خضروات"     },
      fruit:      { en: "Fruits",      ar: "فواكه"      },
      condiment:  { en: "Condiments",  ar: "توابل وزيوت" },
    };

    const result = categories.map((c) => ({
      category: c.category,
      count:    c._count.category,
      label:    CATEGORY_LABELS[c.category] ?? { en: c.category, ar: c.category },
    }));

    res.status(200).json({ categories: result });
  } catch (error) {
    console.error("[food] getFoodCategories error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}
