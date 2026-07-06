// ============================================================
//  src/controllers/weight.controller.ts
//  The Teneen — Weight Progress Tracking endpoints
//  POST /api/v1/weight          — log today's weight
//  GET  /api/v1/weight/history  — get weight history (last N days)
//  DELETE /api/v1/weight/:id    — delete a weight entry
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";

// ── Validation ───────────────────────────────────────────────

const LogWeightSchema = z.object({
  weightKg: z
    .number()
    .min(20,  "Weight must be at least 20kg")
    .max(400, "Weight must be under 400kg"),
  loggedAt: z.string().datetime().optional(),
});

const HistoryQuerySchema = z.object({
  days:  z.coerce.number().int().min(7).max(365).default(30),
  limit: z.coerce.number().int().min(7).max(365).default(30),
});

// ── POST /api/v1/weight ──────────────────────────────────────

export async function logWeight(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const parsed = LogWeightSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error:   "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
      return;
    }

    const { weightKg, loggedAt } = parsed.data;

    // Also update user's current weight for TDEE calculations
    const [log] = await prisma.$transaction([
      prisma.weightLog.create({
        data: {
          userId,
          weightKg,
          loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
        },
      }),
      prisma.user.update({
        where: { id: userId },
        data:  { weightKg },
      }),
    ]);

    // Fetch previous log to show delta
    const previous = await prisma.weightLog.findFirst({
      where:   { userId, id: { not: log.id } },
      orderBy: { loggedAt: "desc" },
    });

    const delta = previous ? Math.round((weightKg - previous.weightKg) * 10) / 10 : null;

    res.status(201).json({
      message: "Weight logged successfully",
      log: {
        id:       log.id,
        weightKg: log.weightKg,
        loggedAt: log.loggedAt,
      },
      delta,            // e.g. -0.3 means lost 300g since last log
      previousWeightKg: previous?.weightKg ?? null,
    });
  } catch (error) {
    console.error("[weight] logWeight error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── GET /api/v1/weight/history ───────────────────────────────

export async function getWeightHistory(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const parsed = HistoryQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({
        error:   "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
      return;
    }

    const { days } = parsed.data;
    const since = new Date();
    since.setDate(since.getDate() - days);
    since.setUTCHours(0, 0, 0, 0);

    const [logs, user] = await Promise.all([
      prisma.weightLog.findMany({
        where:   { userId, loggedAt: { gte: since } },
        orderBy: { loggedAt: "asc" },
        select: {
          id:       true,
          weightKg: true,
          loggedAt: true,
        },
      }),
      prisma.user.findUnique({
        where:  { id: userId },
        select: { weightKg: true, goal: true },
      }),
    ]);

    if (logs.length === 0) {
      res.status(200).json({
        days,
        logs:         [],
        stats:        null,
        currentWeight: user?.weightKg ?? null,
        goal:          user?.goal     ?? "maintain",
      });
      return;
    }

    // Calculate stats
    const weights    = logs.map((l) => l.weightKg);
    const first      = weights[0];
    const last       = weights[weights.length - 1];
    const totalDelta = Math.round((last - first) * 10) / 10;
    const minWeight  = Math.min(...weights);
    const maxWeight  = Math.max(...weights);
    const avgWeight  = Math.round((weights.reduce((s, w) => s + w, 0) / weights.length) * 10) / 10;

    // Simple 7-day trend: compare last 7 days avg vs previous 7 days avg
    let trend: "losing" | "gaining" | "stable" = "stable";
    if (logs.length >= 4) {
      const half  = Math.floor(logs.length / 2);
      const firstHalfAvg = weights.slice(0, half).reduce((s, w) => s + w, 0) / half;
      const lastHalfAvg  = weights.slice(-half).reduce((s, w) => s + w, 0)   / half;
      const diff = lastHalfAvg - firstHalfAvg;
      if (diff < -0.2)      trend = "losing";
      else if (diff > 0.2)  trend = "gaining";
    }

    res.status(200).json({
      days,
      logs,
      currentWeight: user?.weightKg ?? last,
      goal:          user?.goal     ?? "maintain",
      stats: {
        firstWeight:  first,
        currentWeight: last,
        totalDelta,            // negative = lost weight, positive = gained
        minWeight,
        maxWeight,
        avgWeight,
        trend,                 // losing | gaining | stable
        logsCount: logs.length,
      },
    });
  } catch (error) {
    console.error("[weight] getWeightHistory error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

// ── DELETE /api/v1/weight/:id ────────────────────────────────

export async function deleteWeightLog(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) { res.status(401).json({ error: "Unauthorized" }); return; }

    const { id } = req.params;

    const log = await prisma.weightLog.findUnique({ where: { id } });
    if (!log) {
      res.status(404).json({ error: "Weight log entry not found" });
      return;
    }

    if (log.userId !== userId) {
      res.status(403).json({ error: "Forbidden: you do not own this log entry" });
      return;
    }

    await prisma.weightLog.delete({ where: { id } });

    res.status(200).json({ message: "Weight log entry deleted successfully" });
  } catch (error) {
    console.error("[weight] deleteWeightLog error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}
