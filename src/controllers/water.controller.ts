// ============================================================
//  src/controllers/water.controller.ts
//  The Teneen — Water Tracking endpoints
//  POST /api/v1/water        — log water intake
//  GET  /api/v1/water/today  — get today's total + goal progress
//  DELETE /api/v1/water/:id  — delete a water log entry
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";

// ── Validation ───────────────────────────────────────────────

const LogWaterSchema = z.object({
  amountMl: z
    .number()
    .int()
    .min(10,   "Minimum amount is 10ml")
    .max(5000, "Maximum single log is 5000ml (5L)"),
  loggedAt: z.string().datetime().optional(),
});

// ── Helper: day bounds ────────────────────────────────────────

function getDayBounds(dateStr?: string): { start: Date; end: Date } {
  const base = dateStr ? new Date(dateStr) : new Date();
  const start = new Date(base);
  start.setUTCHours(0, 0, 0, 0);
  const end = new Date(base);
  end.setUTCHours(23, 59, 59, 999);
  return { start, end };
}

// ── POST /api/v1/water ───────────────────────────────────────

export async function logWater(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const parsed = LogWaterSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error:   "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
      return;
    }

    const { amountMl, loggedAt } = parsed.data;

    const log = await prisma.waterLog.create({
      data: {
        userId,
        amountMl,
        loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
      },
    });

    // Return updated today total alongside the new log
    const { start, end } = getDayBounds();
    const [todayLogs, user] = await Promise.all([
      prisma.waterLog.findMany({
        where: { userId, loggedAt: { gte: start, lte: end } },
        orderBy: { loggedAt: "asc" },
      }),
      prisma.user.findUnique({
        where:  { id: userId },
        select: { dailyWaterGoalMl: true },
      }),
    ]);

    const totalMl     = todayLogs.reduce((sum, l) => sum + l.amountMl, 0);
    const goalMl      = user?.dailyWaterGoalMl ?? 2500;
    const remainingMl = Math.max(0, goalMl - totalMl);
    const progressPct = Math.min(100, Math.round((totalMl / goalMl) * 100));

    res.status(201).json({
      message:  "Water logged successfully",
      log: {
        id:       log.id,
        amountMl: log.amountMl,
        loggedAt: log.loggedAt,
      },
      today: {
        totalMl,
        goalMl,
        remainingMl,
        progressPct,
        logs: todayLogs.map((l) => ({
          id:       l.id,
          amountMl: l.amountMl,
          loggedAt: l.loggedAt,
        })),
      },
    });
  } catch (error) {
    console.error("[water] logWater error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── GET /api/v1/water/today ──────────────────────────────────

export async function getTodayWater(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const date = req.query.date as string | undefined;
    const { start, end } = getDayBounds(date);

    const [logs, user] = await Promise.all([
      prisma.waterLog.findMany({
        where:   { userId, loggedAt: { gte: start, lte: end } },
        orderBy: { loggedAt: "asc" },
      }),
      prisma.user.findUnique({
        where:  { id: userId },
        select: { dailyWaterGoalMl: true },
      }),
    ]);

    const totalMl     = logs.reduce((sum, l) => sum + l.amountMl, 0);
    const goalMl      = user?.dailyWaterGoalMl ?? 2500;
    const remainingMl = Math.max(0, goalMl - totalMl);
    const progressPct = Math.min(100, Math.round((totalMl / goalMl) * 100));

    // Build hourly breakdown for charting (0–23)
    const hourlyBreakdown: Record<number, number> = {};
    for (const log of logs) {
      const hour = new Date(log.loggedAt).getUTCHours();
      hourlyBreakdown[hour] = (hourlyBreakdown[hour] ?? 0) + log.amountMl;
    }

    res.status(200).json({
      date:         start.toISOString().split("T")[0],
      totalMl,
      goalMl,
      remainingMl,
      progressPct,
      // Quick-add suggestions (standard Egyptian cup sizes)
      quickAddOptions: [150, 200, 250, 330, 500, 750, 1000],
      hourlyBreakdown,
      logs: logs.map((l) => ({
        id:       l.id,
        amountMl: l.amountMl,
        loggedAt: l.loggedAt,
      })),
    });
  } catch (error) {
    console.error("[water] getTodayWater error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── DELETE /api/v1/water/:id ─────────────────────────────────

export async function deleteWaterLog(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const { id } = req.params;

    const log = await prisma.waterLog.findUnique({ where: { id } });
    if (!log) {
      res.status(404).json({ error: "Water log entry not found" });
      return;
    }

    if (log.userId !== userId) {
      res.status(403).json({ error: "Forbidden: you do not own this log entry" });
      return;
    }

    await prisma.waterLog.delete({ where: { id } });

    res.status(200).json({ message: "Water log entry deleted successfully" });
  } catch (error) {
    console.error("[water] deleteWaterLog error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}
