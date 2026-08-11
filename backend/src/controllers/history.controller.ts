// ============================================================
//  src/controllers/history.controller.ts
//  Aura — Meal History endpoints
//  GET    /api/v1/meals/history
//  DELETE /api/v1/meals/:id
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";

// ── Pagination Schema ──────────────────────────────────────

const HistoryQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  date: z.string().optional(), // ISO date string filter e.g. "2025-07-05"
});

// ── Get Meal History ───────────────────────────────────────

export async function getMealHistory(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;

  const parsed = HistoryQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Invalid query parameters",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  const { page, limit, date } = parsed.data;
  const skip = (page - 1) * limit;

  // Build date filter
  let dateFilter: { gte: Date; lt: Date } | undefined;
  if (date) {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    if (isNaN(startOfDay.getTime())) {
      res.status(400).json({
        success: false,
        error: "Invalid date format. Use ISO format: YYYY-MM-DD",
      });
      return;
    }

    dateFilter = { gte: startOfDay, lt: endOfDay };
  }

  try {
    const [logs, total] = await Promise.all([
      prisma.mealLog.findMany({
        where: {
          userId,
          ...(dateFilter && { createdAt: dateFilter }),
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
        select: {
          id: true,
          restaurantName: true,
          mealName: true,
          imageUrl: true,
          calories: true,
          protein: true,
          carbs: true,
          fats: true,
          ingredientsBreakdown: true,
          source: true,
          createdAt: true,
        },
      }),
      prisma.mealLog.count({
        where: {
          userId,
          ...(dateFilter && { createdAt: dateFilter }),
        },
      }),
    ]);

    // Compute macro totals for the result set
    const totals = logs.reduce(
      (acc, log) => ({
        calories: acc.calories + log.calories,
        protein: acc.protein + log.protein,
        carbs: acc.carbs + log.carbs,
        fats: acc.fats + log.fats,
      }),
      { calories: 0, protein: 0, carbs: 0, fats: 0 }
    );

    res.json({
      success: true,
      data: {
        logs,
        totals: {
          calories: Math.round(totals.calories),
          protein: Math.round(totals.protein),
          carbs: Math.round(totals.carbs),
          fats: Math.round(totals.fats),
        },
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
          hasNext: skip + limit < total,
          hasPrev: page > 1,
        },
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [History] getMealHistory error:", msg);
    res.status(500).json({
      success: false,
      error: "Failed to load meal history.",
      code: "HISTORY_ERROR",
    });
  }
}

// ── Delete Meal Log ────────────────────────────────────────

export async function deleteMealLog(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;
  const { id } = req.params;

  if (!id || typeof id !== "string") {
    res.status(400).json({ success: false, error: "Meal log ID is required." });
    return;
  }

  try {
    const existing = await prisma.mealLog.findUnique({
      where: { id },
      select: { userId: true },
    });

    if (!existing) {
      res.status(404).json({
        success: false,
        error: "Meal log not found.",
        code: "NOT_FOUND",
      });
      return;
    }

    // Ownership check — users can only delete their own logs
    if (existing.userId !== userId) {
      res.status(403).json({
        success: false,
        error: "You do not have permission to delete this meal log.",
        code: "FORBIDDEN",
      });
      return;
    }

    await prisma.mealLog.delete({ where: { id } });

    res.json({
      success: true,
      message: "Meal log deleted successfully.",
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [History] deleteMealLog error:", msg);
    res.status(500).json({
      success: false,
      error: "Failed to delete meal log.",
      code: "DELETE_ERROR",
    });
  }
}

// ── Nutrition History ──────────────────────────────────────

const NutritionHistoryQuerySchema = z.object({
  days: z.coerce.number().int().min(7).max(30).default(7),
});

function calcNutrition(
  food: { calories: number; protein: number; carbs: number; fats: number; fiber: number; servingSize: number },
  servings: number,
) {
  return {
    calories: Math.round(food.calories * servings * 10) / 10,
    protein:  Math.round(food.protein  * servings * 10) / 10,
    carbs:    Math.round(food.carbs    * servings * 10) / 10,
    fats:     Math.round(food.fats     * servings * 10) / 10,
  };
}

export async function getNutritionHistory(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;
  
  const parsed = NutritionHistoryQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Invalid query parameters",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }
  
  const { days } = parsed.data;
  
  const since = new Date();
  since.setDate(since.getDate() - days + 1);
  since.setUTCHours(0, 0, 0, 0);

  try {
    const [user, foodLogs, mealLogs] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: { dailyCalorieGoal: true, proteinGoal: true, carbsGoal: true, fatsGoal: true }
      }),
      prisma.foodLog.findMany({
        where: { userId, loggedAt: { gte: since } },
        include: { foodItem: true },
      }),
      prisma.mealLog.findMany({
        where: { userId, loggedAt: { gte: since } },
        select: { calories: true, protein: true, carbs: true, fats: true, loggedAt: true },
      }),
    ]);
    
    const goalCalories = user?.dailyCalorieGoal ?? 2000;
    const goalProtein = user?.proteinGoal ?? 150;
    
    const dailyTotals: Record<string, { calories: number; protein: number; carbs: number; fats: number; date: string }> = {};
    
    for (let i = 0; i < days; i++) {
      const d = new Date(since);
      d.setDate(d.getDate() + i);
      const key = d.toISOString().split("T")[0];
      dailyTotals[key] = { date: key, calories: 0, protein: 0, carbs: 0, fats: 0 };
    }
    
    for (const log of foodLogs) {
      const key = log.loggedAt.toISOString().split("T")[0];
      if (dailyTotals[key]) {
        const n = calcNutrition(log.foodItem, log.servings);
        dailyTotals[key].calories += n.calories;
        dailyTotals[key].protein += n.protein;
        dailyTotals[key].carbs += n.carbs;
        dailyTotals[key].fats += n.fats;
      }
    }
    
    for (const log of mealLogs) {
      const key = log.loggedAt.toISOString().split("T")[0];
      if (dailyTotals[key]) {
        dailyTotals[key].calories += log.calories;
        dailyTotals[key].protein += log.protein;
        dailyTotals[key].carbs += log.carbs;
        dailyTotals[key].fats += log.fats;
      }
    }
    
    const sortedDays = Object.values(dailyTotals).sort((a, b) => a.date.localeCompare(b.date));
    
    let sumCalories = 0;
    let sumProtein = 0;
    let daysGoalMet = 0;
    
    for (const day of sortedDays) {
      sumCalories += day.calories;
      sumProtein += day.protein;
      if (day.calories > 0 && day.calories <= goalCalories) {
        daysGoalMet++;
      }
    }
    
    const daysWithData = sortedDays.filter(d => d.calories > 0).length;
    const divisor = daysWithData > 0 ? daysWithData : 1;
    
    res.json({
      success: true,
      data: {
        days: sortedDays.map(d => ({
          date: d.date,
          calories: Math.round(d.calories),
          protein: Math.round(d.protein),
          carbs: Math.round(d.carbs),
          fats: Math.round(d.fats),
        })),
        stats: {
          averageCalories: Math.round(sumCalories / divisor),
          averageProtein: Math.round(sumProtein / divisor),
          daysGoalMet,
        },
        goals: {
          calories: goalCalories,
          protein: goalProtein,
        }
      }
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [History] getNutritionHistory error:", msg);
    res.status(500).json({
      success: false,
      error: "Failed to load nutrition history.",
    });
  }
}
