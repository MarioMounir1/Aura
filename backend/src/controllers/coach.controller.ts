import { Request, Response } from "express";
import prisma from "../services/prisma.service";
import {
  generateDailyEcosystemBriefing,
  generateWeeklyInsightsReport,
} from "../services/coach.service";

// ── In-Memory Cache (15 min TTL) for Instant Responses ─────
interface CacheItem<T> {
  data: T;
  expiresAt: number;
}

const CACHE_TTL_MS = 15 * 60 * 1000; // 15 minutes
const briefingCache = new Map<string, CacheItem<any>>();
const weeklyCache = new Map<string, CacheItem<any>>();

/**
 * GET /api/v1/coach/daily-briefing
 * Returns a holistic, personalized daily briefing connecting nutrition targets,
 * today's workout split, active streak, and progress goals.
 */
export async function getDailyBriefingHandler(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const userId = req.user!.id;

    // Check fast cache
    const cached = briefingCache.get(userId);
    if (cached && cached.expiresAt > Date.now()) {
      res.status(200).json({ success: true, data: cached.data });
      return;
    }

    // 1. Fetch User Profile
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        name: true,
        dailyCalorieGoal: true,
        goal: true,
        weightKg: true,
        targetWeightKg: true,
      },
    });

    const calorieTarget = user?.dailyCalorieGoal ?? 2000;
    // Default protein target ~2g per kg or ~25% of calories
    const proteinTarget = user?.weightKg ? Math.round(user.weightKg * 1.8) : 130;

    // 2. Fetch today's nutrition logs
    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setUTCHours(23, 59, 59, 999);

    const [mealLogs, foodLogs] = await Promise.all([
      prisma.mealLog.findMany({
        where: {
          userId,
          createdAt: { gte: todayStart, lte: todayEnd },
        },
        select: { calories: true, protein: true },
      }),
      prisma.foodLog.findMany({
        where: {
          userId,
          loggedAt: { gte: todayStart, lte: todayEnd },
        },
        include: {
          foodItem: { select: { calories: true, protein: true } },
        },
      }),
    ]);

    let caloriesConsumedToday = 0;
    let proteinConsumedToday = 0;

    mealLogs.forEach((m) => {
      caloriesConsumedToday += m.calories ?? 0;
      proteinConsumedToday += m.protein ?? 0;
    });

    foodLogs.forEach((f) => {
      const servings = f.servings ?? 1;
      caloriesConsumedToday += Math.round((f.foodItem?.calories ?? 0) * servings);
      proteinConsumedToday += Math.round((f.foodItem?.protein ?? 0) * servings);
    });

    // 3. Fetch active routine and today's day
    const activeRoutine = await prisma.userRoutine.findFirst({
      where: { userId, isActive: true },
      include: {
        days: {
          include: { exercises: { select: { id: true } } },
        },
      },
    });

    let todaysWorkoutSplit: string | undefined;
    if (activeRoutine && activeRoutine.days.length > 0) {
      const daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      const currentDayName = daysOfWeek[new Date().getDay()];
      const matchingDay = activeRoutine.days.find(
        (d) => d.dayName.toLowerCase() === currentDayName.toLowerCase()
      );
      if (matchingDay && matchingDay.exercises.length > 0) {
        todaysWorkoutSplit = matchingDay.name || matchingDay.dayName;
      }
    }

    // 4. Calculate workout streak (consecutive active days)
    const recentSessions = await prisma.workoutSession.findMany({
      where: {
        userId,
        status: "COMPLETED",
        endedAt: { gte: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000) },
      },
      orderBy: { endedAt: "desc" },
      select: { endedAt: true },
    });

    const uniqueDates = new Set(
      recentSessions.map((s) => (s.endedAt ? s.endedAt.toISOString().slice(0, 10) : ""))
    );
    const streakDays = uniqueDates.size;

    // 5. Generate AI Briefing
    const briefing = await generateDailyEcosystemBriefing({
      userName: user?.name?.split(" ")[0],
      calorieTarget,
      caloriesConsumedToday: Math.round(caloriesConsumedToday),
      proteinTarget,
      proteinConsumedToday: Math.round(proteinConsumedToday),
      todaysWorkoutSplit,
      streakDays,
      weightTrend: user?.goal ? `${user.goal} Phase` : "Healthy Lifestyle",
    });

    const resultData = {
      ...briefing,
      metrics: {
        calorieTarget,
        caloriesConsumedToday: Math.round(caloriesConsumedToday),
        proteinTarget,
        proteinConsumedToday: Math.round(proteinConsumedToday),
        streakDays,
        todaysWorkoutSplit: todaysWorkoutSplit ?? "Rest Day",
      },
    };

    briefingCache.set(userId, { data: resultData, expiresAt: Date.now() + CACHE_TTL_MS });

    res.status(200).json({
      success: true,
      data: resultData,
    });
  } catch (error: unknown) {
    console.error("❌ [Coach] Daily briefing error:", error);
    res.status(500).json({
      success: false,
      error: "Unable to generate daily briefing",
    });
  }
}

/**
 * GET /api/v1/coach/weekly-insights
 * Aggregates the last 7 days of workouts, nutrition adherence, and weight changes.
 */
export async function getWeeklyInsightsHandler(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const userId = req.user!.id;

    // Check fast cache
    const cached = weeklyCache.get(userId);
    if (cached && cached.expiresAt > Date.now()) {
      res.status(200).json({ success: true, data: cached.data });
      return;
    }

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    sevenDaysAgo.setUTCHours(0, 0, 0, 0);

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { dailyCalorieGoal: true },
    });
    const calorieTarget = user?.dailyCalorieGoal ?? 2000;

    // 1. Fetch 7-day nutrition logs
    const [mealLogs, foodLogs, completedWorkouts, weightLogs] = await Promise.all([
      prisma.mealLog.findMany({
        where: { userId, createdAt: { gte: sevenDaysAgo } },
        select: { calories: true, createdAt: true },
      }),
      prisma.foodLog.findMany({
        where: { userId, loggedAt: { gte: sevenDaysAgo } },
        include: { foodItem: { select: { calories: true } } },
      }),
      prisma.workoutSession.findMany({
        where: { userId, status: "COMPLETED", endedAt: { gte: sevenDaysAgo } },
        select: { id: true, endedAt: true },
      }),
      prisma.weightLog.findMany({
        where: { userId, loggedAt: { gte: sevenDaysAgo } },
        orderBy: { loggedAt: "asc" },
        select: { weightKg: true },
      }),
    ]);

    const activeDaysSet = new Set<string>();
    let totalCaloriesLogged = 0;

    mealLogs.forEach((m) => {
      totalCaloriesLogged += m.calories ?? 0;
      activeDaysSet.add(m.createdAt.toISOString().slice(0, 10));
    });

    foodLogs.forEach((f) => {
      const cals = (f.foodItem?.calories ?? 0) * (f.servings ?? 1);
      totalCaloriesLogged += cals;
      activeDaysSet.add(f.loggedAt.toISOString().slice(0, 10));
    });

    const daysLoggedCount = Math.max(1, activeDaysSet.size);
    const avgDailyCalories = Math.round(totalCaloriesLogged / daysLoggedCount);

    let weightDeltaKg: number | undefined;
    if (weightLogs.length >= 2) {
      weightDeltaKg = weightLogs[weightLogs.length - 1].weightKg - weightLogs[0].weightKg;
    }

    const report = await generateWeeklyInsightsReport({
      totalCaloriesLogged: Math.round(totalCaloriesLogged),
      avgDailyCalories,
      calorieTarget,
      totalWorkouts: completedWorkouts.length,
      weightDeltaKg,
      daysLoggedCount: activeDaysSet.size,
    });

    const resultData = {
      ...report,
      stats: {
        totalCaloriesLogged: Math.round(totalCaloriesLogged),
        avgDailyCalories,
        calorieTarget,
        totalWorkouts: completedWorkouts.length,
        daysLoggedCount: activeDaysSet.size,
        weightDeltaKg,
      },
    };

    weeklyCache.set(userId, { data: resultData, expiresAt: Date.now() + CACHE_TTL_MS });

    res.status(200).json({
      success: true,
      data: resultData,
    });
  } catch (error: unknown) {
    console.error("❌ [Coach] Weekly insights error:", error);
    res.status(500).json({
      success: false,
      error: "Unable to generate weekly insights",
    });
  }
}
