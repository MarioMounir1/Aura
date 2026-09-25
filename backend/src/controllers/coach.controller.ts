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
 * daily calorie/protein progress, active streak, and progress goals.
 */
export async function getDailyBriefingHandler(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const userId = req.user!.id;
    const qCalTarget = Number(req.query.calorieTarget);
    const qCalConsumed = Number(req.query.caloriesConsumed);
    const qProteinTarget = Number(req.query.proteinTarget);
    const qProteinConsumed = Number(req.query.proteinConsumed);

    // Check fast cache (keyed by userId, calorie target, and protein target)
    const cacheKey = `${userId}:${!isNaN(qCalTarget) && qCalTarget > 0 ? qCalTarget : "default"}:${!isNaN(qProteinTarget) && qProteinTarget > 0 ? qProteinTarget : "default"}`;
    const cached = briefingCache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) {
      res.status(200).json({ success: true, data: cached.data });
      return;
    }

    // 1. Fetch User Profile & Goal Info
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        name: true,
        dailyCalorieGoal: true,
        proteinGoal: true,
        goal: true,
        weightKg: true,
        heightCm: true,
        age: true,
        gender: true,
        activityLevel: true,
        targetWeightKg: true,
      },
    });

    let calorieTarget = !isNaN(qCalTarget) && qCalTarget > 0 ? qCalTarget : (user?.dailyCalorieGoal ?? 2000);
    // If calorieTarget is default 2000 and user has bio stats, calculate accurate TDEE:
    if (calorieTarget === 2000 && user?.weightKg && user?.heightCm && user?.age) {
      const g = (user.gender ?? "male").toLowerCase();
      const bmr = 10 * user.weightKg + 6.25 * user.heightCm - 5 * user.age + (g === "male" ? 5 : -161);
      const act = user.activityLevel ?? "moderate";
      const mult = act === "sedentary" ? 1.2 : act === "lightly_active" ? 1.375 : act === "very_active" ? 1.725 : 1.55;
      const adj = user.goal === "lose" ? -500 : user.goal === "gain" ? 500 : 0;
      calorieTarget = Math.round(Math.min(5000, Math.max(1200, bmr * mult + adj)));
    }

    let proteinTarget = !isNaN(qProteinTarget) && qProteinTarget > 0
      ? qProteinTarget
      : (user?.proteinGoal && !(user.proteinGoal === 150 && (calorieTarget > 2500 || (user.weightKg && user.weightKg * 2 > 160)))
          ? user.proteinGoal
          : (user?.weightKg
              ? Math.max(80, Math.min(250, Math.max(Math.round(user.weightKg * 2.0), Math.round((calorieTarget * 0.25) / 4))))
              : (user?.proteinGoal ?? 150)));

    // 2. Fetch today's & yesterday's nutrition logs
    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setUTCHours(23, 59, 59, 999);

    const yesterdayStart = new Date(todayStart);
    yesterdayStart.setUTCDate(yesterdayStart.getUTCDate() - 1);
    const yesterdayEnd = new Date(todayEnd);
    yesterdayEnd.setUTCDate(yesterdayEnd.getUTCDate() - 1);

    const [mealLogs, foodLogs, yesterdayMealLogs, yesterdayFoodLogs] = await Promise.all([
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
      prisma.mealLog.findMany({
        where: {
          userId,
          createdAt: { gte: yesterdayStart, lte: yesterdayEnd },
        },
        select: { calories: true, protein: true, carbs: true, fats: true },
      }),
      prisma.foodLog.findMany({
        where: {
          userId,
          loggedAt: { gte: yesterdayStart, lte: yesterdayEnd },
        },
        include: {
          foodItem: { select: { calories: true, protein: true, carbs: true, fats: true } },
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

    if (!isNaN(qCalConsumed) && qCalConsumed > caloriesConsumedToday) {
      caloriesConsumedToday = qCalConsumed;
    }
    if (!isNaN(qProteinConsumed) && qProteinConsumed > proteinConsumedToday) {
      proteinConsumedToday = qProteinConsumed;
    }

    // Aggregate yesterday's totals
    let yCalories = 0;
    let yProtein = 0;
    let yCarbs = 0;
    let yFats = 0;

    yesterdayMealLogs.forEach((m) => {
      yCalories += m.calories ?? 0;
      yProtein += m.protein ?? 0;
      yCarbs += m.carbs ?? 0;
      yFats += m.fats ?? 0;
    });

    yesterdayFoodLogs.forEach((f) => {
      const servings = f.servings ?? 1;
      yCalories += Math.round((f.foodItem?.calories ?? 0) * servings);
      yProtein += Math.round((f.foodItem?.protein ?? 0) * servings);
      yCarbs += Math.round((f.foodItem?.carbs ?? 0) * servings);
      yFats += Math.round((f.foodItem?.fats ?? 0) * servings);
    });

    const yesterdayMealCount = yesterdayMealLogs.length + yesterdayFoodLogs.length;
    const yesterdayStats = {
      calories: Math.round(yCalories),
      protein: Math.round(yProtein),
      carbs: Math.round(yCarbs),
      fats: Math.round(yFats),
      mealCount: yesterdayMealCount,
      calorieTarget,
      proteinTarget,
    };

    // 3. Calculate active logging streak (consecutive active days)
    const recentSessions = await prisma.workoutSession.findMany({
      where: {
        userId,
        endedAt: { not: null, gte: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000) },
      },
      orderBy: { endedAt: "desc" },
      select: { endedAt: true },
    });

    const uniqueDates = new Set<string>();
    recentSessions.forEach((s) => {
      if (s.endedAt) {
        uniqueDates.add(s.endedAt.toISOString().slice(0, 10));
      }
    });

    const streakDays = uniqueDates.size;

    // 4. Generate AI Progress Briefing
    const briefing = await generateDailyEcosystemBriefing({
      userName: user?.name?.split(" ")[0],
      calorieTarget,
      caloriesConsumedToday: Math.round(caloriesConsumedToday),
      proteinTarget,
      proteinConsumedToday: Math.round(proteinConsumedToday),
      streakDays,
      weightTrend: user?.goal ? `${user.goal} Phase` : "Healthy Lifestyle",
      yesterday: yesterdayStats,
    });

    const resultData = {
      ...briefing,
      yesterday: yesterdayStats,
      metrics: {
        calorieTarget,
        caloriesConsumedToday: Math.round(caloriesConsumedToday),
        proteinTarget,
        proteinConsumedToday: Math.round(proteinConsumedToday),
        streakDays,
      },
    };

    briefingCache.set(cacheKey, { data: resultData, expiresAt: Date.now() + CACHE_TTL_MS });

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
    const qCalTarget = Number(req.query.calorieTarget);

    // Check fast cache (can force-refresh when logging in real-time)
    const forceRefresh = req.query.refresh === "true" || req.query.refresh === "1";
    const weeklyCacheKey = `${userId}:${!isNaN(qCalTarget) && qCalTarget > 0 ? qCalTarget : "default"}`;
    if (!forceRefresh) {
      const cached = weeklyCache.get(weeklyCacheKey);
      if (cached && cached.expiresAt > Date.now()) {
        res.status(200).json({ success: true, data: cached.data });
        return;
      }
    }

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    sevenDaysAgo.setUTCHours(0, 0, 0, 0);

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        dailyCalorieGoal: true,
        weightKg: true,
        heightCm: true,
        age: true,
        gender: true,
        activityLevel: true,
        goal: true,
        workoutDays: true,
        workoutSplitType: true,
      },
    });

    let calorieTarget = !isNaN(qCalTarget) && qCalTarget > 0 ? qCalTarget : (user?.dailyCalorieGoal ?? 2000);
    if (calorieTarget === 2000 && user?.weightKg && user?.heightCm && user?.age) {
      const g = (user.gender ?? "male").toLowerCase();
      const bmr = 10 * user.weightKg + 6.25 * user.heightCm - 5 * user.age + (g === "male" ? 5 : -161);
      const act = user.activityLevel ?? "moderate";
      const mult = act === "sedentary" ? 1.2 : act === "lightly_active" ? 1.375 : act === "very_active" ? 1.725 : 1.55;
      const adj = user.goal === "lose" ? -500 : user.goal === "gain" ? 500 : 0;
      calorieTarget = Math.round(Math.min(5000, Math.max(1200, bmr * mult + adj)));
    }

    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    const yesterdayStart = new Date(todayStart);
    yesterdayStart.setUTCDate(yesterdayStart.getUTCDate() - 1);
    const yesterdayEnd = new Date(todayStart);
    yesterdayEnd.setUTCMilliseconds(-1);

    // 1. Fetch 7-day nutrition logs & activity
    const [mealLogs, foodLogs, completedWorkouts, weightLogs] = await Promise.all([
      prisma.mealLog.findMany({
        where: { userId, createdAt: { gte: sevenDaysAgo } },
        select: { calories: true, protein: true, carbs: true, fats: true, createdAt: true },
      }),
      prisma.foodLog.findMany({
        where: { userId, loggedAt: { gte: sevenDaysAgo } },
        include: { foodItem: { select: { calories: true, protein: true, carbs: true, fats: true } } },
      }),
      prisma.workoutSession.findMany({
        where: { userId, endedAt: { not: null, gte: sevenDaysAgo } },
        select: { id: true, endedAt: true, startedAt: true },
      }),
      prisma.weightLog.findMany({
        where: { userId, loggedAt: { gte: sevenDaysAgo } },
        orderBy: { loggedAt: "asc" },
        select: { weightKg: true, loggedAt: true },
      }),
    ]);

    const foodDaysSet = new Set<string>();
    let totalCaloriesLogged = 0;

    let yCals = 0;
    let yProt = 0;
    let yCarb = 0;
    let yFat = 0;
    let yCount = 0;

    mealLogs.forEach((m) => {
      totalCaloriesLogged += m.calories ?? 0;
      foodDaysSet.add(m.createdAt.toISOString().slice(0, 10));

      if (m.createdAt >= yesterdayStart && m.createdAt <= yesterdayEnd) {
        yCals += m.calories ?? 0;
        yProt += m.protein ?? 0;
        yCarb += m.carbs ?? 0;
        yFat += m.fats ?? 0;
        yCount++;
      }
    });

    foodLogs.forEach((f) => {
      const servings = f.servings ?? 1;
      const c = Math.round((f.foodItem?.calories ?? 0) * servings);
      totalCaloriesLogged += c;
      foodDaysSet.add(f.loggedAt.toISOString().slice(0, 10));

      if (f.loggedAt >= yesterdayStart && f.loggedAt <= yesterdayEnd) {
        yCals += c;
        yProt += Math.round((f.foodItem?.protein ?? 0) * servings);
        yCarb += Math.round((f.foodItem?.carbs ?? 0) * servings);
        yFat += Math.round((f.foodItem?.fats ?? 0) * servings);
        yCount++;
      }
    });

    const proteinTarget = user?.proteinGoal ?? 150;
    const yesterdayStats = {
      calories: Math.round(yCals),
      protein: Math.round(yProt),
      carbs: Math.round(yCarb),
      fats: Math.round(yFat),
      mealCount: yCount,
      calorieTarget,
      proteinTarget,
    };

    // Active days include days where user logged food, finished a workout, or logged weight
    const activeDaysSet = new Set<string>(foodDaysSet);
    completedWorkouts.forEach((w) => {
      const d = w.endedAt || w.startedAt;
      if (d) {
        activeDaysSet.add(new Date(d).toISOString().slice(0, 10));
      }
    });
    weightLogs.forEach((wl) => {
      activeDaysSet.add(new Date(wl.loggedAt).toISOString().slice(0, 10));
    });

    const avgDailyCalories = foodDaysSet.size > 0
      ? Math.round(totalCaloriesLogged / foodDaysSet.size)
      : 0;

    // 2. Weight delta calculation
    let weightDeltaKg: number | undefined;
    if (weightLogs.length >= 2) {
      const firstWeight = weightLogs[0].weightKg;
      const lastWeight = weightLogs[weightLogs.length - 1].weightKg;
      weightDeltaKg = Math.round((lastWeight - firstWeight) * 10) / 10;
    }

    // 3. Generate Weekly AI Report
    const targetWorkouts = user?.workoutDays ?? 5;
    const report = await generateWeeklyInsightsReport({
      totalCaloriesLogged: Math.round(totalCaloriesLogged),
      avgDailyCalories,
      calorieTarget,
      totalWorkouts: completedWorkouts.length,
      targetWorkouts,
      weightDeltaKg,
      daysLoggedCount: activeDaysSet.size,
      yesterday: yesterdayStats,
    });

    const resultData = {
      ...report,
      yesterday: yesterdayStats,
      stats: {
        totalCaloriesLogged: Math.round(totalCaloriesLogged),
        avgDailyCalories,
        calorieTarget,
        totalWorkouts: completedWorkouts.length,
        targetWorkouts,
        daysLoggedCount: activeDaysSet.size,
        weightDeltaKg,
      },
    };

    // Fast 30s TTL cache so real-time food logging reflects promptly
    weeklyCache.set(weeklyCacheKey, { data: resultData, expiresAt: Date.now() + 30000 });

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
