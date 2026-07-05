// ============================================================
//  src/controllers/history.controller.ts
//  Calc-Calories — Meal History endpoints
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
