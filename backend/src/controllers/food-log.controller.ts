// ============================================================
//  src/controllers/food-log.controller.ts
//  The Teneen — Daily Food Logging endpoints
//  POST   /api/v1/food-logs          — log a food item from DB
//  GET    /api/v1/food-logs/today    — today's logs + totals
//  GET    /api/v1/food-logs/summary  — combined summary (DB + AI logs)
//  DELETE /api/v1/food-logs/:id      — delete a log entry
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";

// ── Validation ───────────────────────────────────────────────

const LogFoodSchema = z.object({
  foodItemId: z.string().uuid("Invalid food item ID"),
  servings:   z.number().min(0.1).max(50).default(1),
  mealType:   z
    .enum(["breakfast", "lunch", "dinner", "snack", "other"])
    .default("other"),
  loggedAt:   z.string().datetime().optional(), // ISO string, defaults to now
});

// ── Helper: get start/end of a day in UTC ────────────────────

function getDayBounds(dateStr?: string): { start: Date; end: Date } {
  const base = dateStr ? new Date(dateStr) : new Date();
  const start = new Date(base);
  start.setUTCHours(0, 0, 0, 0);
  const end = new Date(base);
  end.setUTCHours(23, 59, 59, 999);
  return { start, end };
}

// ── Helper: calculate nutrition for a log entry ───────────────

function calcNutrition(
  food: { calories: number; protein: number; carbs: number; fats: number; fiber: number; servingSize: number },
  servings: number,
) {
  // servings is a multiplier on food.servingSize
  return {
    calories: Math.round(food.calories * servings * 10) / 10,
    protein:  Math.round(food.protein  * servings * 10) / 10,
    carbs:    Math.round(food.carbs    * servings * 10) / 10,
    fats:     Math.round(food.fats     * servings * 10) / 10,
    fiber:    Math.round(food.fiber    * servings * 10) / 10,
  };
}

// ── POST /api/v1/food-logs ───────────────────────────────────

export async function logFood(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const parsed = LogFoodSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error:   "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
      return;
    }

    const { foodItemId, servings, mealType, loggedAt } = parsed.data;

    // Verify food item exists
    const foodItem = await prisma.foodItem.findUnique({ where: { id: foodItemId } });
    if (!foodItem) {
      res.status(404).json({ error: "Food item not found" });
      return;
    }

    const log = await prisma.foodLog.create({
      data: {
        userId,
        foodItemId,
        servings,
        mealType,
        loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
      },
      include: { foodItem: true },
    });

    const nutrition = calcNutrition(log.foodItem, log.servings);

    res.status(201).json({
      message: "Food logged successfully",
      log: {
        id:       log.id,
        mealType: log.mealType,
        servings: log.servings,
        loggedAt: log.loggedAt,
        foodItem: {
          id:          log.foodItem.id,
          nameEn:      log.foodItem.nameEn,
          nameAr:      log.foodItem.nameAr,
          servingSize: log.foodItem.servingSize,
          servingUnit: log.foodItem.servingUnit,
          category:    log.foodItem.category,
        },
        nutrition,
      },
    });
  } catch (error) {
    console.error("[food-log] logFood error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── GET /api/v1/food-logs/today ──────────────────────────────

export async function getTodayFoodLogs(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const date = req.query.date as string | undefined;
    const { start, end } = getDayBounds(date);

    const [user, foodLogs, mealLogs] = await Promise.all([
      prisma.user.findUnique({
        where:  { id: userId },
        select: {
          dailyCalorieGoal: true,
          proteinGoal:      true,
          carbsGoal:        true,
          fatsGoal:         true,
          dailyWaterGoalMl: true,
        },
      }),
      prisma.foodLog.findMany({
        where: {
          userId,
          loggedAt: { gte: start, lte: end },
        },
        include: { foodItem: true },
        orderBy: { loggedAt: "asc" },
      }),
      prisma.mealLog.findMany({
        where: {
          userId,
          loggedAt: { gte: start, lte: end },
        },
        orderBy: { loggedAt: "asc" },
        select: {
          id:            true,
          mealName:      true,
          restaurantName: true,
          calories:      true,
          protein:       true,
          carbs:         true,
          fats:          true,
          mealType:      true,
          loggedAt:      true,
          source:        true,
        },
      }),
    ]);

    if (user && user.proteinGoal > 160) {
      const cal = user.dailyCalorieGoal || 2000;
      const prot = Math.min(145, Math.round((cal * 0.20) / 4));
      const fat = Math.round((cal * 0.25) / 9);
      const carb = Math.round((cal - (prot * 4 + fat * 9)) / 4);

      await prisma.user.update({
        where: { id: userId },
        data: { proteinGoal: prot, carbsGoal: carb, fatsGoal: fat },
      });
      user.proteinGoal = prot;
      user.carbsGoal = carb;
      user.fatsGoal = fat;
    }

    // Calculate totals from food logs
    const foodLogTotals = foodLogs.reduce(
      (acc, log) => {
        const n = calcNutrition(log.foodItem, log.servings);
        return {
          calories: acc.calories + n.calories,
          protein:  acc.protein  + n.protein,
          carbs:    acc.carbs    + n.carbs,
          fats:     acc.fats     + n.fats,
          fiber:    acc.fiber    + n.fiber,
        };
      },
      { calories: 0, protein: 0, carbs: 0, fats: 0, fiber: 0 },
    );

    // Calculate totals from AI meal logs
    const mealLogTotals = mealLogs.reduce(
      (acc, log) => ({
        calories: acc.calories + log.calories,
        protein:  acc.protein  + log.protein,
        carbs:    acc.carbs    + log.carbs,
        fats:     acc.fats     + log.fats,
        fiber:    acc.fiber,
      }),
      { calories: 0, protein: 0, carbs: 0, fats: 0, fiber: 0 },
    );

    // Combined totals
    const totals = {
      calories: Math.round((foodLogTotals.calories + mealLogTotals.calories) * 10) / 10,
      protein:  Math.round((foodLogTotals.protein  + mealLogTotals.protein)  * 10) / 10,
      carbs:    Math.round((foodLogTotals.carbs    + mealLogTotals.carbs)    * 10) / 10,
      fats:     Math.round((foodLogTotals.fats     + mealLogTotals.fats)     * 10) / 10,
      fiber:    Math.round(foodLogTotals.fiber * 10) / 10,
    };

    // Remaining vs goal
    const goals = user ?? { dailyCalorieGoal: 2000, proteinGoal: 150, carbsGoal: 200, fatsGoal: 65, dailyWaterGoalMl: 2500 };
    const remaining = {
      calories: Math.max(0, goals.dailyCalorieGoal - totals.calories),
      protein:  Math.max(0, goals.proteinGoal      - totals.protein),
      carbs:    Math.max(0, goals.carbsGoal         - totals.carbs),
      fats:     Math.max(0, goals.fatsGoal          - totals.fats),
    };

    // Format food logs for response
    const formattedFoodLogs = foodLogs.map((log) => {
      const n = calcNutrition(log.foodItem, log.servings);
      return {
        id:       log.id,
        type:     "food_db" as const,
        mealType: log.mealType,
        servings: log.servings,
        loggedAt: log.loggedAt,
        foodItem: {
          id:          log.foodItem.id,
          nameEn:      log.foodItem.nameEn,
          nameAr:      log.foodItem.nameAr,
          servingSize: log.foodItem.servingSize,
          servingUnit: log.foodItem.servingUnit,
          category:    log.foodItem.category,
        },
        nutrition: n,
      };
    });

    const formattedMealLogs = mealLogs.map((log) => ({
      id:             log.id,
      type:           "ai_scan" as const,
      mealType:       log.mealType,
      mealName:       log.mealName,
      restaurantName: log.restaurantName,
      loggedAt:       log.loggedAt,
      source:         log.source,
      nutrition: {
        calories: log.calories,
        protein:  log.protein,
        carbs:    log.carbs,
        fats:     log.fats,
        fiber:    0,
      },
    }));

    // Group by meal type
    const allEntries = [...formattedFoodLogs, ...formattedMealLogs].sort(
      (a, b) => new Date(a.loggedAt).getTime() - new Date(b.loggedAt).getTime(),
    );

    res.status(200).json({
      date:     start.toISOString().split("T")[0],
      totals,
      remaining,
      goals: {
        calories: goals.dailyCalorieGoal,
        protein:  goals.proteinGoal,
        carbs:    goals.carbsGoal,
        fats:     goals.fatsGoal,
      },
      entries: allEntries,
      counts: {
        foodDbEntries: foodLogs.length,
        aiScanEntries: mealLogs.length,
        total:         foodLogs.length + mealLogs.length,
      },
    });
  } catch (error) {
    console.error("[food-log] getTodayFoodLogs error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── PUT /api/v1/food-logs/:id ─────────────────────────────

const UpdateFoodLogSchema = z.object({
  servings: z.number().min(0.1).max(50).optional(),
  mealType: z.enum(["breakfast", "lunch", "dinner", "snack", "other"]).optional(),
});

/**
 * PUT /api/v1/food-logs/:id
 * Update a food log entry's servings and/or meal type.
 * Macros are derived from the FoodItem, so only servings & mealType are editable.
 */
export async function updateFoodLog(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const { id } = req.params;

    const parsed = UpdateFoodLogSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error:   "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
      return;
    }

    if (!parsed.data.servings && !parsed.data.mealType) {
      res.status(400).json({ error: "At least one of servings or mealType must be provided." });
      return;
    }

    const log = await prisma.foodLog.findUnique({
      where:   { id },
      include: { foodItem: true },
    });

    if (!log) {
      res.status(404).json({ error: "Food log entry not found" });
      return;
    }

    if (log.userId !== userId) {
      res.status(403).json({ error: "Forbidden: you do not own this log entry" });
      return;
    }

    const updated = await prisma.foodLog.update({
      where:   { id },
      data:    parsed.data,
      include: { foodItem: true },
    });

    const nutrition = calcNutrition(updated.foodItem, updated.servings);

    res.status(200).json({
      message: "Food log entry updated successfully",
      log: {
        id:       updated.id,
        mealType: updated.mealType,
        servings: updated.servings,
        loggedAt: updated.loggedAt,
        foodItem: {
          id:          updated.foodItem.id,
          nameEn:      updated.foodItem.nameEn,
          nameAr:      updated.foodItem.nameAr,
          servingSize: updated.foodItem.servingSize,
          servingUnit: updated.foodItem.servingUnit,
          category:    updated.foodItem.category,
        },
        nutrition,
      },
    });
  } catch (error) {
    console.error("[food-log] updateFoodLog error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}


export async function deleteFoodLog(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const { id } = req.params;

    const log = await prisma.foodLog.findUnique({ where: { id } });
    if (!log) {
      res.status(404).json({ error: "Food log entry not found" });
      return;
    }

    if (log.userId !== userId) {
      res.status(403).json({ error: "Forbidden: you do not own this log entry" });
      return;
    }

    await prisma.foodLog.delete({ where: { id } });

    res.status(200).json({ message: "Food log entry deleted successfully" });
  } catch (error) {
    console.error("[food-log] deleteFoodLog error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}
