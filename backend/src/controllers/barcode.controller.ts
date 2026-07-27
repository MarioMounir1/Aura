// ============================================================
//  src/controllers/barcode.controller.ts
//  Aura — Barcode Meal Lookup + Log
//
//  Endpoints:
//    POST /api/v1/meals/scan-barcode  — look up a product on Open Food Facts
//    POST /api/v1/meals/log-barcode   — persist confirmed barcode meal to MealLog
//
//  Design decisions:
//   • Open Food Facts is free & keyless — no env var needed
//   • HTTP 200 with status:0 means "barcode not found" — we NEVER log it
//   • In-process Map cache (6 h TTL) prevents hammering the external API
//   • Barcode scans never touch aiUsageLog — separate quota from AI scans
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";
import { estimateNutritionFromName } from "../services/ai.service";

// ── In-Memory Barcode Cache ────────────────────────────────────

const CACHE_TTL_MS = 6 * 60 * 60 * 1000; // 6 hours

interface CacheEntry {
  data: BarcodeNutrition;
  expiresAt: number;
}

const barcodeCache = new Map<string, CacheEntry>();

function getCached(barcode: string): BarcodeNutrition | null {
  const entry = barcodeCache.get(barcode);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    barcodeCache.delete(barcode);
    return null;
  }
  return entry.data;
}

function setCache(barcode: string, data: BarcodeNutrition): void {
  barcodeCache.set(barcode, { data, expiresAt: Date.now() + CACHE_TTL_MS });
}

// ── Data Shape ─────────────────────────────────────────────────

interface BarcodeNutrition {
  barcode: string;
  productName: string;
  dataSource?: string;
  /** All values are per 100 g of product */
  per100g: {
    calories: number;
    protein: number;
    carbs: number;
    fats: number;
  };
}

// ── Zod Schemas ────────────────────────────────────────────────

const ScanBarcodeSchema = z.object({
  barcode: z
    .string()
    .transform((val) => val.trim().replace(/[^\d]/g, "")) // Strip non-digit characters (spaces, dashes)
    .pipe(
      z
        .string()
        .min(4, "Barcode must be at least 4 digits")
        .max(20, "Barcode must be at most 20 digits")
    ),
});

const EstimateBarcodeSchema = z.object({
  barcode: z
    .string()
    .transform((val) => val.trim().replace(/[^\d]/g, ""))
    .pipe(
      z
        .string()
        .min(4, "Barcode must be at least 4 digits")
        .max(20, "Barcode must be at most 20 digits")
    ),
  productName: z.string().min(1, "Product name is required").max(300).trim(),
});

const LogBarcodeSchema = z.object({
  barcode: z.string().min(4).max(20),
  productName: z.string().min(1).max(300).trim(),
  /** Pre-calculated macros for the chosen serving size (not per-100g) */
  calories: z.number().min(0).max(10000),
  protein: z.number().min(0).max(1000),
  carbs: z.number().min(0).max(1000),
  fats: z.number().min(0).max(1000),
  /** The serving size the user chose in grams */
  servingGrams: z.number().min(1).max(10000),
});

// ── Helper: safe number extraction ────────────────────────────

function safeNum(value: unknown): number {
  const n = Number(value);
  return isFinite(n) && n >= 0 ? Math.round(n * 10) / 10 : 0;
}

// ── Handler 1: Scan Barcode ────────────────────────────────────

/**
 * POST /api/v1/meals/scan-barcode
 * Body: { barcode: string }
 *
 * Returns per-100g nutrition from local DB or Open Food Facts.
 * Responds 404 if barcode is not found.
 */
export async function scanBarcodeHandler(
  req: Request,
  res: Response
): Promise<void> {
  const parsed = ScanBarcodeSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Invalid barcode",
      details: parsed.error.flatten().fieldErrors,
      code: "VALIDATION_ERROR",
    });
    return;
  }

  const { barcode } = parsed.data;

  // ── Step 0: Check Local Database for mapped barcode ──────────
  try {
    const dbItem = await prisma.foodItem.findUnique({
      where: { barcode },
    });
    if (dbItem) {
      const dbNutrition: BarcodeNutrition = {
        barcode,
        productName: dbItem.nameEn,
        dataSource: dbItem.dataSource,
        per100g: {
          calories: dbItem.calories,
          protein: dbItem.protein,
          carbs: dbItem.carbs,
          fats: dbItem.fats,
        },
      };
      setCache(barcode, dbNutrition);
      console.log(`✅ [Barcode] Database HIT: ${barcode} — ${dbItem.nameEn} (${dbItem.dataSource})`);
      res.status(200).json({
        success: true,
        source: "local_db",
        data: dbNutrition,
      });
      return;
    }
  } catch (dbErr) {
    console.warn(`⚠️ [Barcode] Local DB check error for ${barcode}:`, dbErr);
  }

  // ── Cache check ─────────────────────────────────────────────
  const cached = getCached(barcode);
  if (cached) {
    console.log(`✅ [Barcode] Cache HIT: ${barcode} — ${cached.productName}`);
    res.status(200).json({
      success: true,
      source: "cache",
      data: cached,
    });
    return;
  }

  // ── Fetch from Open Food Facts (v2 with v0 fallback) ────────
  const offV2Url = `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(barcode)}.json`;
  const offV0Url = `https://world.openfoodfacts.org/api/v0/product/${encodeURIComponent(barcode)}.json`;

  let offData: any = null;
  try {
    let response = await fetch(offV2Url, {
      headers: { "User-Agent": "Aura-FitnessApp/1.0 (contact@aura.app)" },
      signal: AbortSignal.timeout(8_000),
    });

    if (response.status === 404) {
      // Try v0 endpoint fallback before declaring 404
      response = await fetch(offV0Url, {
        headers: { "User-Agent": "Aura-FitnessApp/1.0 (contact@aura.app)" },
        signal: AbortSignal.timeout(8_000),
      });
    }

    if (response.status === 404) {
      console.log(`🔍 [Barcode] Product not found in Open Food Facts: ${barcode}`);
      res.status(404).json({
        success: false,
        error: "Product not found in Open Food Facts database.",
        code: "BARCODE_NOT_FOUND",
        hint: "Try scanning the product label with the AI photo scanner instead.",
      });
      return;
    }

    if (!response.ok) {
      throw new Error(`Open Food Facts responded with HTTP ${response.status}`);
    }

    offData = await response.json();
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Network error";
    const isTimeout = msg.toLowerCase().includes("timeout") || msg.toLowerCase().includes("abort");
    console.error(`❌ [Barcode] OFF fetch failed for ${barcode}:`, msg);
    res.status(isTimeout ? 504 : 502).json({
      success: false,
      error: isTimeout
        ? "Open Food Facts lookup timed out. Please try again."
        : `Barcode lookup failed: ${msg}`,
      code: isTimeout ? "LOOKUP_TIMEOUT" : "LOOKUP_ERROR",
    });
    return;
  }

  // ── CRITICAL: explicit status:0 check ──────────────────────
  // OFF returns HTTP 200 with status:0 for unrecognized barcodes.
  if (!offData || offData.status !== 1) {
    console.log(`🔍 [Barcode] Not found in OFF database: ${barcode}`);
    res.status(404).json({
      success: false,
      error: "Product not found in Open Food Facts database.",
      code: "BARCODE_NOT_FOUND",
      hint: "Try scanning the product label with the AI photo scanner instead.",
    });
    return;
  }

  // ── Extract nutrition ────────────────────────────────────────
  const product = offData.product ?? {};
  const nutriments = product.nutriments ?? {};

  const productName: string =
    (product.product_name_en as string | undefined)?.trim() ||
    (product.product_name as string | undefined)?.trim() ||
    "Unknown Product";

  const nutrition: BarcodeNutrition = {
    barcode,
    productName,
    per100g: {
      // OFF field: "energy-kcal_100g" or fall back to kJ → kcal conversion
      calories: safeNum(
        nutriments["energy-kcal_100g"] ??
        (nutriments["energy-kj_100g"] != null
          ? (nutriments["energy-kj_100g"] as number) / 4.184
          : nutriments["energy_100g"])
      ),
      protein: safeNum(nutriments["proteins_100g"]),
      carbs: safeNum(nutriments["carbohydrates_100g"]),
      fats: safeNum(nutriments["fat_100g"]),
    },
  };

  // ── Cache and respond ────────────────────────────────────────
  setCache(barcode, nutrition);

  console.log(
    `✅ [Barcode] Found: "${productName}" (${barcode}) — ` +
    `${nutrition.per100g.calories} kcal / P:${nutrition.per100g.protein}g ` +
    `C:${nutrition.per100g.carbs}g F:${nutrition.per100g.fats}g per 100g`
  );

  res.status(200).json({
    success: true,
    source: "open_food_facts",
    data: nutrition,
  });
}

// ── Handler 2: Log Barcode Meal ────────────────────────────────

/**
 * POST /api/v1/meals/log-barcode
 * Body: { barcode, productName, calories, protein, carbs, fats, servingGrams }
 *
 * Persists the confirmed barcode meal to MealLog with source:"barcode".
 * Does NOT count against aiUsageLog (barcode scans are free/unlimited).
 */
export async function logBarcodeHandler(
  req: Request,
  res: Response
): Promise<void> {
  const userId = req.user!.id;

  const parsed = LogBarcodeSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Invalid input",
      details: parsed.error.flatten().fieldErrors,
      code: "VALIDATION_ERROR",
    });
    return;
  }

  const { barcode, productName, calories, protein, carbs, fats, servingGrams } = parsed.data;

  let mealLog;
  try {
    mealLog = await prisma.mealLog.create({
      data: {
        userId,
        mealName: productName,
        restaurantName: "Barcode Scan",
        calories,
        protein,
        carbs,
        fats,
        ingredientsBreakdown: [],
        rawAiResponse: {
          barcode,
          productName,
          servingGrams,
          source: "open_food_facts",
        } as any,
        source: "barcode",
      },
      select: { id: true },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "DB error";
    console.error("❌ [Barcode] DB save error:", msg);
    res.status(500).json({
      success: false,
      error: "Failed to save meal log.",
      code: "DB_ERROR",
    });
    return;
  }

  console.log(
    `✅ [Barcode] Logged: "${productName}" (${barcode}) — ` +
    `${calories} kcal | P:${protein}g C:${carbs}g F:${fats}g | serving:${servingGrams}g`
  );

  res.status(201).json({
    success: true,
    source: "barcode",
    data: {
      logId: mealLog.id,
      mealName: productName,
      calories,
      protein,
      carbs,
      fats,
      servingGrams,
      barcode,
      loggedAt: new Date().toISOString(),
    },
  });
}

// ── Handler 3: Estimate Nutrition for Missing Barcode Product ──

/**
 * POST /api/v1/meals/estimate-barcode
 * Body: { barcode: string, productName: string }
 *
 * Runs user-provided product name through text-only AI nutrition estimation
 * (estimateNutritionFromName), saves to FoodItem database with barcode mapping,
 * and caches for instant future lookups.
 */
export async function estimateBarcodeHandler(
  req: Request,
  res: Response
): Promise<void> {
  const parsed = EstimateBarcodeSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Invalid input",
      details: parsed.error.flatten().fieldErrors,
      code: "VALIDATION_ERROR",
    });
    return;
  }

  const { barcode, productName } = parsed.data;

  // 1. Check if already mapped in DB
  try {
    const existing = await prisma.foodItem.findUnique({
      where: { barcode },
    });
    if (existing) {
      const existingNutrition: BarcodeNutrition = {
        barcode,
        productName: existing.nameEn,
        dataSource: existing.dataSource,
        per100g: {
          calories: existing.calories,
          protein: existing.protein,
          carbs: existing.carbs,
          fats: existing.fats,
        },
      };
      setCache(barcode, existingNutrition);
      res.status(200).json({
        success: true,
        source: "local_db",
        data: existingNutrition,
      });
      return;
    }
  } catch (err) {
    console.warn(`⚠️ [Barcode] DB check error before estimation for ${barcode}:`, err);
  }

  // 2. Run text-only AI nutrition estimation
  console.log(`🤖 [Barcode] Estimating nutrition via text AI for: "${productName}" (${barcode})`);
  let estimate;
  try {
    estimate = await estimateNutritionFromName(productName);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "AI estimation failed";
    console.error(`❌ [Barcode] AI estimation failed for "${productName}":`, msg);
    res.status(500).json({
      success: false,
      error: `Nutrition estimation failed: ${msg}`,
      code: "ESTIMATION_ERROR",
    });
    return;
  }

  // 3. Save to FoodItem table with barcode mapping
  try {
    const createdItem = await prisma.foodItem.create({
      data: {
        nameEn: productName,
        nameAr: productName,
        calories: estimate.calories,
        protein: estimate.protein,
        carbs: estimate.carbs,
        fats: estimate.fats,
        fiber: 0,
        servingSize: 100,
        servingUnit: "g",
        category: "General",
        isVerified: false,
        dataSource: "ai-estimated",
        barcode: barcode,
      },
    });
    console.log(`🌱 [Barcode] Auto-persisted barcode mapping: "${productName}" -> barcode:${barcode} (${createdItem.id})`);
  } catch (err: unknown) {
    console.error("❌ [Barcode] Failed to persist food item mapping:", err);
  }

  const nutrition: BarcodeNutrition = {
    barcode,
    productName: estimate.dishName || productName,
    dataSource: "ai-estimated",
    per100g: {
      calories: estimate.calories,
      protein: estimate.protein,
      carbs: estimate.carbs,
      fats: estimate.fats,
    },
  };

  setCache(barcode, nutrition);

  res.status(200).json({
    success: true,
    source: "ai-estimated",
    data: nutrition,
  });
}
