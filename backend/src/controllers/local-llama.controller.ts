// ============================================================
//  src/controllers/local-llama.controller.ts
//  Aura — Local Llama Image Scan Endpoint
//  POST /api/v1/meals/scan-local
//
//  Flow:
//    1. Accept multipart/form-data image upload
//    2. Convert image buffer → base64
//    3. Send to local Ollama vision model (llava / llama3.2-vision)
//    4. Parse structured macro response
//    5. Generate a contextual recommendation banner
//    6. Return LlamaMealResponse payload
// ============================================================

import { Request, Response } from "express";
import { processUpload } from "../middleware/upload.middleware";
import { OLLAMA_CONFIG, getAiScanLimit } from "../config";
import prisma from "../services/prisma.service";
import { analyzeMeal } from "../services/ai.service";

// ── Response Shape (matches Flutter LlamaMealResponse model) ─

export interface LlamaMealAnalysis {
  detectedFood: string;
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
}

export interface LlamaRecommendation {
  triggerWarning: boolean;
  message: string;
}

export interface LlamaMealResponse {
  success: boolean;
  source: "local_llama_inference";
  mealAnalysis: LlamaMealAnalysis;
  llamaRecommendation: LlamaRecommendation;
}

// ── Vision Prompt ────────────────────────────────────────────

const VISION_SYSTEM_PROMPT = `You are an expert nutritionist AI running locally.
Analyze the food or drink image provided and return ONLY a raw JSON object with NO markdown, NO explanation.

CRITICAL RULES:
1. DIET / ZERO SUGAR DRINKS: If you detect Diet Coke, Coke Zero, Pepsi Max, Diet Pepsi, Zero Sugar, Sprite Zero, or any Light/Diet beverage, calories MUST be 0 (or 1) and carbs MUST be 0. NEVER return 150 calories for a diet/zero drink!
2. REGULAR PACKAGED FOOD/DRINKS: Read brand label. Regular 330ml soda = 150 kcal. Diet soda = 0 kcal.
3. HOME/RESTAURANT MEALS: Estimate realistic portion sizes.

Required JSON format:
{
  "detectedFood": "exact food or drink name (e.g. Diet Coke 330ml Can)",
  "calories": integer,
  "protein": integer,
  "carbs": integer,
  "fats": integer
}

Never return prose or markdown wrapper — output only the JSON object.`;

// ── Recommendation Engine ────────────────────────────────────

function generateRecommendation(
  analysis: LlamaMealAnalysis,
  userProteinGoal = 150
): LlamaRecommendation {
  const { calories, protein, carbs, fats } = analysis;

  if (carbs > 70 && protein < 30) {
    const deficit = Math.round(userProteinGoal * 0.2);
    return {
      triggerWarning: true,
      message: `Llama Notice: This meal lacks sufficient protein for your daily goal. The carb load is high (${carbs}g). We recommend adding ${deficit}g of lean protein to your next meal.`,
    };
  }

  if (calories > 800) {
    return {
      triggerWarning: true,
      message: `Llama Notice: This is a high-calorie meal (${calories} kcal). Consider balancing your remaining meals today with lighter, protein-dense options to stay within your daily target.`,
    };
  }

  if (fats > 30) {
    return {
      triggerWarning: true,
      message: `Llama Notice: This meal has elevated fat content (${fats}g). Pair your next meal with complex carbs and lean protein to balance your macro distribution.`,
    };
  }

  if (protein >= 30 && calories < 600) {
    return {
      triggerWarning: false,
      message: `Llama says: Excellent macro balance! This meal supports muscle synthesis with ${protein}g of protein and a controlled caloric load. Keep it up.`,
    };
  }

  return {
    triggerWarning: false,
    message: `Llama says: This looks like a balanced meal. Your macros are within healthy ranges — Calories: ${calories} kcal, Protein: ${protein}g, Carbs: ${carbs}g, Fats: ${fats}g.`,
  };
}

// ── Parse Ollama Text Response (handles dirty JSON & sanitizes diet drinks) ──

function parseOllamaResponse(raw: string): LlamaMealAnalysis {
  let text = raw.trim();

  // Strip markdown fences if present
  text = text.replace(/```json/gi, "").replace(/```/g, "").trim();

  // Extract first JSON object block
  const jsonMatch = text.match(/\{[\s\S]*?\}/);
  if (!jsonMatch) {
    throw new Error(`No JSON object found in Ollama response: ${text.slice(0, 200)}`);
  }

  let parsed: any;
  try {
    parsed = JSON.parse(jsonMatch[0]);
  } catch {
    throw new Error(`Failed to parse Ollama JSON: ${jsonMatch[0].slice(0, 200)}`);
  }

  let detectedFood = String(parsed.detectedFood ?? parsed.dish_name ?? parsed.food ?? "Unknown Meal");
  let calories     = Math.round(Number(parsed.calories ?? 0));
  let protein      = Math.round(Number(parsed.protein ?? 0));
  let carbs        = Math.round(Number(parsed.carbs ?? parsed.carbohydrates ?? 0));
  let fats         = Math.round(Number(parsed.fats ?? parsed.fat ?? 0));

  // ── Smart Diet / Zero Sugar Calorie Sanitizer ─────────────
  const lowerName = (detectedFood + " " + text).toLowerCase();
  const isDietDrink = /(diet|zero|max|light|no sugar|sugar free|zero sugar)/i.test(lowerName) && 
                      /(coke|coca|pepsi|soda|cola|sprite|7up|seven up|dr pepper|fanta|drink|can|beverage)/i.test(lowerName);

  if (isDietDrink) {
    console.log(`🥤 [LocalLlama] Detected Diet/Zero beverage: "${detectedFood}". Overriding calories from ${calories} -> 1 kcal`);
    calories = 1;
    carbs = 0;
    fats = 0;
    protein = 0;
  }

  if (calories === 0 && protein === 0 && carbs === 0 && fats === 0 && !isDietDrink) {
    throw new Error("Ollama returned all-zero macros — likely failed to identify the food.");
  }

  return { detectedFood, calories, protein, carbs, fats };
}

// ── Main Handler ─────────────────────────────────────────────

/**
 * POST /api/v1/meals/scan-local
 *
 * Accepts: multipart/form-data with field "image"
 * Returns: LlamaMealResponse
 */
export async function scanLocalHandler(req: Request, res: Response): Promise<void> {
  // ── Step 1: Process multipart upload ────────────────────
  try {
    await processUpload(req, res);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Upload failed";
    res.status(400).json({
      success: false,
      source: "local_llama_inference",
      error: msg,
      code: "UPLOAD_ERROR",
    });
    return;
  }

  const file = req.file;
  if (!file) {
    res.status(400).json({
      success: false,
      source: "local_llama_inference",
      error: "No image provided. Please upload an image file in the 'image' field.",
      code: "MISSING_IMAGE",
    });
    return;
  }

  // ── Step 2: Validate AI Usage Limits ──────────────────────
  const scanType: "camera" | "gallery" = req.body.scanType === "camera" ? "camera" : "gallery";
  const userId = req.user!.id;
  const isPremium = req.user!.isPremium;

  try {
    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setUTCHours(23, 59, 59, 999);

    const usageCount = await prisma.aiUsageLog.count({
      where: {
        userId,
        scanType,
        date: { gte: todayStart, lte: todayEnd },
      },
    });

    const limit = getAiScanLimit(isPremium);
    if (usageCount >= limit) {
      res.status(isPremium ? 429 : 402).json({
        success: false,
        error: isPremium 
          ? `Premium limit reached. You can only use ${scanType} ${limit} times per day.`
          : `Free limit reached. Upgrade to Premium for more ${scanType} uses!`,
        code: "QUOTA_EXCEEDED",
      });
      return;
    }
  } catch (err: unknown) {
    console.error("❌ [LocalLlama] Quota check failed:", err);
    // Best-effort: allow if check fails to avoid blocking legitimate users due to DB errors
  }

  // ── Step 3: Analyze Image using AI Engine (Gemini / Ollama) ──────
  let mealAnalysis: LlamaMealAnalysis;
  const mimeType = file.mimetype; // e.g. "image/jpeg"

  try {
    console.log(`🔮 [ImageScan] Analyzing meal image (${(file.size / 1024).toFixed(1)} KB)...`);
    const aiResult = await analyzeMeal({
      type: "image",
      imageBuffer: file.buffer,
      mimeType: (file.mimetype as any) || "image/jpeg",
    });

    mealAnalysis = {
      detectedFood: aiResult.mealName,
      calories: aiResult.calories,
      protein: aiResult.protein,
      carbs: aiResult.carbs,
      fats: aiResult.fats,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Image scan failed";
    console.error("❌ [ImageScan] AI analysis error:", msg);
    res.status(500).json({
      success: false,
      source: "local_llama_inference",
      error: `Meal image scan failed: ${msg}`,
      code: "SCAN_ERROR",
    });
    return;
  }

  // ── Step 5: Generate contextual recommendation ───────────
  const llamaRecommendation = generateRecommendation(mealAnalysis);

  // ── Step 6: Persist to MealLog (best-effort, non-blocking) ──
  try {
    await prisma.mealLog.create({
      data: {
        userId,
        mealName:      mealAnalysis.detectedFood,
        restaurantName: "Local Llama Scan",
        calories:      mealAnalysis.calories,
        protein:       mealAnalysis.protein,
        carbs:         mealAnalysis.carbs,
        fats:          mealAnalysis.fats,
        ingredientsBreakdown: [],
        rawAiResponse: { ...mealAnalysis, recommendation: llamaRecommendation } as any,
        source:        "image",
      },
      select: { id: true },
    });
    await prisma.aiUsageLog.create({ data: { userId, scanType, date: new Date() } });
  } catch (dbErr: unknown) {
    console.warn("⚠️  [LocalLlama] DB log failed (non-critical):", dbErr instanceof Error ? dbErr.message : dbErr);
  }

  console.log(
    `✅ [LocalLlama] ${mealAnalysis.detectedFood} — ${mealAnalysis.calories} kcal | P:${mealAnalysis.protein}g C:${mealAnalysis.carbs}g F:${mealAnalysis.fats}g`
  );

  // ── Step 7: Return structured response ──────────────────
  const response: LlamaMealResponse = {
    success: true,
    source:  "local_llama_inference",
    mealAnalysis,
    llamaRecommendation,
  };

  res.status(200).json(response);
}

// ── AI Usage Quota Endpoint ──────────────────────────────────

/**
 * GET /api/v1/meals/usage
 * Returns the current day's usage counts for camera and gallery scans.
 */
export async function getAiUsageHandler(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.id;
    
    // Get start and end of today in UTC
    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setUTCHours(23, 59, 59, 999);

    const logs = await prisma.aiUsageLog.groupBy({
      by: ['scanType'],
      where: {
        userId,
        date: {
          gte: todayStart,
          lte: todayEnd,
        }
      },
      _count: {
        id: true,
      }
    });

    const usage = {
      camera: 0,
      gallery: 0,
    };

    logs.forEach(log => {
      if (log.scanType === 'camera') usage.camera = log._count.id;
      if (log.scanType === 'gallery') usage.gallery = log._count.id;
    });

    const isPremium = req.user?.isPremium ?? false;
    const limit = getAiScanLimit(isPremium);

    res.status(200).json({
      success: true,
      data: {
        usage,
        limits: {
          camera: limit,
          gallery: limit,
        },
        isPremium
      }
    });
  } catch (error: unknown) {
    console.error("❌ [AiUsage] Failed to fetch usage:", error);
    res.status(500).json({ success: false, error: "Failed to fetch usage limits" });
  }
}
