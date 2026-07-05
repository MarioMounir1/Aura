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
    const skip = (page - 1) * limit;

    // Build where clause: search by Arabic OR English name depending on lang
    // Also always try both to catch bilingual queries
    const whereClause = {
      AND: [
        {
          OR: [
            { nameEn: { contains: q, mode: "insensitive" as const } },
            { nameAr: { contains: q,   mode: "insensitive" as const } },
          ],
        },
        ...(category ? [{ category }] : []),
      ],
    };

    const [items, total] = await Promise.all([
      prisma.foodItem.findMany({
        where:   whereClause,
        orderBy: [
          // Prioritize exact matches and verified items
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

    // Format response: always send both names, let client choose
    res.status(200).json({
      items,
      meta: {
        query:    q,
        lang,
        total,
        page,
        limit,
        pages: Math.ceil(total / limit),
      },
    });
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
