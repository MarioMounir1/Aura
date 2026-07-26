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

    // ── 1. Local Database Query ───────────────────────────────
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

    const localQueryPromise = Promise.all([
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
        },
      }),
      prisma.foodItem.count({ where: whereClause }),
    ]);

    // ── 2. Open Food Facts Text Search Query ──────────────────
    const offUrl = `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(
      q
    )}&json=1&page=${page}&page_size=${limit}`;

    const offQueryPromise = (async () => {
      try {
        const response = await fetch(offUrl, {
          headers: {
            "User-Agent": "Aura-FitnessApp/1.0 (contact@aura.app)",
          },
          signal: AbortSignal.timeout(8000), // 8 sec timeout
        });
        if (!response.ok) return [];
        const offData = await response.json();
        const products = Array.isArray(offData.products) ? offData.products : [];

        return products.map((product: any, idx: number) => {
          const nutriments = product.nutriments ?? {};
          const code = product.code || product._id || `${Date.now()}_${idx}`;
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
            rawProduct: {
              code,
              brands: product.brands,
              nutriments,
            },
          };
        });
      } catch (err) {
        console.error("❌ [FoodSearch] Open Food Facts search failed:", err);
        return [];
      }
    })();

    const [[localItems, localTotal], offItems] = await Promise.all([
      localQueryPromise,
      offQueryPromise,
    ]);

    const formattedLocalItems = localItems.map((item) => ({
      ...item,
      source: "local" as const,
    }));

    // Merge: Open Food Facts primary + local DB items
    const mergedItems = [...offItems, ...formattedLocalItems];
    const total = localTotal + offItems.length;

    const responsePayload = {
      items: mergedItems,
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
