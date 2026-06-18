// ============================================================
//  src/controllers/nutrition.controller.ts
//  Base meal + dynamic add-on calculation with per-restaurant cache
// ============================================================

import { Request, Response } from "express";
import {
  CalculateNutritionRequest,
  ErrorResponse,
} from "../types";
import { addFoodToQueue, queueEvents } from "../services/queue";

function aiErrorStatus(raw: string): { status: number; error: string } {
  const lower = raw.toLowerCase();
  if (
    lower.includes("fetch failed") ||
    lower.includes("econnrefused") ||
    lower.includes("ollama is offline") ||
    lower.includes("ollama api error") ||
    lower.includes("unreachable")
  ) {
    return {
      status: 503,
      error:
        "Local Ollama service is offline or unreachable. Please make sure Ollama is running on localhost:11434.",
    };
  }
  if (lower.includes("404") && lower.includes("model")) {
    return {
      status: 404,
      error:
        "Ollama model not found. Please pull the model using 'ollama pull <model-name>' or check OLLAMA_MODEL in .env.",
    };
  }
  if (lower.includes("429")) {
    return {
      status: 429,
      error: "AI API quota exceeded.",
    };
  }
  return { status: 500, error: raw };
}

export async function calculateNutrition(
  req: Request,
  res: Response
): Promise<void> {
  const { restaurantName, restaurantCategory, itemName, itemDescription, addOns } =
    req.body as CalculateNutritionRequest;

  const normalizedRestaurant = restaurantName.trim();
  const normalizedItem       = itemName.trim();

  const companyId = req.company?.id;
  if (!companyId) {
    res.status(401).json({
      success: false,
      error: "Unauthorized: Company information is missing",
    });
    return;
  }

  try {
    const job = await addFoodToQueue(
      companyId,
      normalizedRestaurant,
      restaurantCategory,
      normalizedItem,
      itemDescription || "",
      addOns || []
    );

    const result = await job.waitUntilFinished(queueEvents);

    if (result.source === "cache") {
      console.log(
        `✅  Cache HIT (via Queue): ${normalizedRestaurant} — ${normalizedItem}` +
          (result.addOns?.length ? ` (+${result.addOns.length} add-ons)` : "")
      );
      res.json(result);
      return;
    }

    console.log(`💾  AI cached (via Queue): ${normalizedRestaurant} — ${normalizedItem}`);
    res.status(201).json(result);
  } catch (err: unknown) {
    const raw = err instanceof Error ? err.message : "Unknown error";
    const isAiError =
      raw.includes("GoogleGenerativeAI") ||
      raw.includes("Gemini") ||
      raw.includes("Ollama") ||
      raw.includes("fetch failed") ||
      raw.includes("ECONNREFUSED");

    const { status, error } = isAiError
      ? aiErrorStatus(raw)
      : { status: 500, error: raw };

    console.error("❌  calculateNutrition error:", raw);
    res.status(status).json({
      success: false,
      error,
      code:    isAiError ? "GEMINI_ERROR" : "DATABASE_ERROR",
      timestamp: new Date(),
    } as ErrorResponse);
  }
}
