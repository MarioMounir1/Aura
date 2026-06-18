// ============================================================
//  src/controllers/b2b.controller.ts
//  B2B controller for high-traffic food macro calculations
// ============================================================

import { Request, Response } from "express";
import { addFoodToQueue, queueEvents } from "../services/queue";
import { CalculateNutritionResponse } from "../types";

/**
 * Controller to handle B2B API calculations.
 * Accepts item_name and customizations, calculates nutritional macros, and
 * returns the results. This represents the "Slow Path" (Core Controller)
 * which calls the underlying database and LLM.
 */
export async function calculateB2B(req: Request, res: Response): Promise<void> {
  const { item_name, customizations } = req.body;

  // Since restaurantName is not specified in the B2B API payload, we route it
  // to a general B2B tenant identifier.
  const restaurantName = "B2B_Client";

  const companyId = req.company?.id;
  if (!companyId) {
    res.status(401).json({
      success: false,
      error: "Unauthorized: Company information is missing",
    });
    return;
  }

  try {
    // 1. Call addFoodToQueue to push calculation job to the queue
    const job = await addFoodToQueue(
      companyId,
      restaurantName,
      undefined,
      item_name,
      customizations || []
    );

    // 2. Wait for the job to complete
    const result = (await job.waitUntilFinished(queueEvents)) as CalculateNutritionResponse;

    // 3. Return a clean, formatted macro/calories JSON object
    res.json({
      success: true,
      item_name: result.item.name,
      customizations: result.addOns?.map((a) => a.name) ?? [],
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fats: result.fats,
      source: result.source, // 'cache' (Postgres) or 'ai_generated'
    });
  } catch (err: unknown) {
    const rawError = err instanceof Error ? err.message : "Unknown error";
    console.error("❌  B2B calculation error:", rawError);
    
    res.status(500).json({
      success: false,
      error: rawError,
      timestamp: new Date(),
    });
  }
}
