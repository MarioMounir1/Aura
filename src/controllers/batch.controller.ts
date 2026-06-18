// ============================================================
//  src/controllers/batch.controller.ts
//  Batch processing with optional add-ons per item
// ============================================================

import { Request, Response } from "express";
import prisma from "../services/prisma.service";
import { calculateMealWithAddOns } from "../services/nutrition-calculation.service";
import {
  BatchCalculateRequest,
  BatchCalculateResponse,
} from "../types";
import { inferRestaurantCategory } from "../config";
import { error } from "console";

export async function batchCalculateNutrition(
  req: Request,
  res: Response
): Promise<void> {
  const { items } = req.body as BatchCalculateRequest;

  const results: BatchCalculateResponse["results"] = [];
  let cacheHits = 0;
  let aiGenerated = 0;
  let failed = 0;

  console.log(`🔄  Processing batch of ${items.length} items...`);

  for (const item of items) {
    const { restaurantName, restaurantCategory, itemName} = item;

    try {
      const normalizedRestaurant = restaurantName.trim();
      const normalizedItem       = itemName.trim();

      const restaurant = await prisma.restaurant.upsert({
        where:  { name: normalizedRestaurant },
        update: {},
        create: {
          name:     normalizedRestaurant,
          category: inferRestaurantCategory(normalizedRestaurant, restaurantCategory),
        },
      });

      const result = await calculateMealWithAddOns({
        restaurant,
        itemName: normalizedItem,
     
      });

      if (result.source === "cache") {
        cacheHits++;
      } else {
        aiGenerated++;
      }

      results.push({
        requested: {
          restaurantName: normalizedRestaurant,
          itemName:       normalizedItem,
        },
        result,
      });
    } catch (err: unknown) {
      failed++;
      const message = err instanceof Error ? err.message : "Unknown error";
      results.push({
        requested: { restaurantName, itemName },
        result: null,
        error: message,
      });
      console.error(`❌  Batch item failed: ${restaurantName} — ${itemName}: ${message}`);
    }
  }

  console.log(
    `✅  Batch complete: ${cacheHits} cache hits, ${aiGenerated} AI generated, ${failed} failed`
  );

  res.json({
    success: failed === 0,
    totalRequested: items.length,
    totalProcessed: items.length,
    results,
    summary: { cacheHits, aiGenerated, failed },
  } as BatchCalculateResponse);
}
