// ============================================================
//  src/controllers/suggestion.controller.ts
//  Calc-Calories — Smart Product Recommendation Engine
// ============================================================

import { Request, Response } from "express";
import prisma from "../services/prisma.service";

/**
 * GET /api/v1/meals/suggestions
 * Calculates remaining daily macros and suggests sponsored protein products.
 */
export async function getSuggestions(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;

  try {
    // 1. Get today's start and end timestamps (Server local time matching User Profile)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // 2. Fetch User goals and today's meal logs
    const [user, todayLogs] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: {
          proteinGoal: true,
          carbsGoal: true,
          fatsGoal: true,
          dailyCalorieGoal: true,
        },
      }),
      prisma.mealLog.findMany({
        where: {
          userId,
          createdAt: { gte: today, lt: tomorrow },
        },
        select: {
          calories: true,
          protein: true,
          carbs: true,
          fats: true,
        },
      }),
    ]);

    if (!user) {
      res.status(404).json({
        success: false,
        error: "User not found.",
        code: "USER_NOT_FOUND",
      });
      return;
    }

    // 3. Compute today's totals
    const todayTotals = todayLogs.reduce(
      (acc, log) => ({
        calories: acc.calories + log.calories,
        protein: acc.protein + log.protein,
        carbs: acc.carbs + log.carbs,
        fats: acc.fats + log.fats,
      }),
      { calories: 0, protein: 0, carbs: 0, fats: 0 }
    );

    // 4. Calculate deficit (Goal - Eaten)
    const proteinDeficit = user.proteinGoal - todayTotals.protein;
    const carbsDeficit = user.carbsGoal - todayTotals.carbs;
    const fatsDeficit = user.fatsGoal - todayTotals.fats;
    const caloriesDeficit = user.dailyCalorieGoal - todayTotals.calories;

    // 5. Query Sponsor Products if Protein deficit > 25g
    let recommendations: any[] = [];
    if (proteinDeficit > 25) {
      recommendations = await prisma.sponsorProduct.findMany({
        where: {
          proteinContent: { gte: 20 },
        },
        select: {
          id: true,
          name: true,
          imageUrl: true,
          proteinContent: true,
          calorieContent: true,
          purchaseUrl: true,
          promoCode: true,
        },
      });
    }

    // 6. Return response
    res.json({
      success: true,
      data: {
        deficit: {
          calories: Math.max(0, Math.round(caloriesDeficit)),
          protein: Math.max(0, Math.round(proteinDeficit)),
          carbs: Math.max(0, Math.round(carbsDeficit)),
          fats: Math.max(0, Math.round(fatsDeficit)),
        },
        recommendations,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [Suggestions] Failed to calculate suggestions:", msg);
    res.status(500).json({
      success: false,
      error: "Suggestions engine temporarily unavailable.",
      code: "SUGGESTIONS_ERROR",
    });
  }
}
