// ============================================================
//  src/services/notification-scheduler.service.ts
//  Aura — Automated Push Notification Scheduler & Dispatcher
// ============================================================

import prisma from "./prisma.service";
import {
  sendWorkoutBriefingNotification,
  sendRestDayNotification,
  sendLunchPromptNotification,
  sendHydrationTouchNotification,
  sendDinnerPromptNotification,
  sendStreakGuardianNotification,
  sendSundayRecapNotification,
  sendOvertrainingAlertNotification,
} from "./notification.service";

// In-memory daily deduplication cache: "userId:type:YYYY-MM-DD"
const dispatchedAlertsToday = new Set<string>();

// Purge cache at midnight
let lastPurgeDate = new Date().toISOString().split("T")[0];

function checkDailyPurge(): void {
  const today = new Date().toISOString().split("T")[0];
  if (today !== lastPurgeDate) {
    dispatchedAlertsToday.clear();
    lastPurgeDate = today;
  }
}

/**
 * Helper to get local date and time in a given IANA timezone
 */
function getLocalTimeInfo(timezone: string = "Africa/Cairo"): {
  localDateStr: string;
  hour: number;
  minute: number;
  dayOfWeek: number; // 0 = Sunday, 1 = Monday, ... 6 = Saturday
} {
  const now = new Date();
  try {
    const dtf = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      hour12: false,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      weekday: "narrow",
    });

    const parts = dtf.formatToParts(now);
    const getPart = (type: string) => parts.find((p) => p.type === type)?.value ?? "";

    const year = getPart("year");
    const month = getPart("month");
    const day = getPart("day");
    const hour = parseInt(getPart("hour"), 10) || 0;
    const minute = parseInt(getPart("minute"), 10) || 0;

    // Day of week in target timezone
    const dayFormatter = new Intl.DateTimeFormat("en-US", { timeZone: timezone, weekday: "short" });
    const dayStr = dayFormatter.format(now);
    const dayMap: Record<string, number> = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
    const dayOfWeek = dayMap[dayStr] ?? now.getDay();

    return {
      localDateStr: `${year}-${month}-${day}`,
      hour,
      minute,
      dayOfWeek,
    };
  } catch {
    // Fallback if timezone string is invalid
    return {
      localDateStr: now.toISOString().split("T")[0],
      hour: now.getUTCHours(),
      minute: now.getUTCMinutes(),
      dayOfWeek: now.getUTCDay(),
    };
  }
}

/**
 * Main evaluation tick: examines all users with registered devices
 * and evaluates whether any notification condition is met.
 */
export async function evaluateScheduledNotifications(): Promise<void> {
  checkDailyPurge();

  try {
    // Find all users who have at least one registered device token
    const users = await prisma.user.findMany({
      where: {
        isActive: true,
        deviceTokens: { some: {} },
      },
      select: {
        id: true,
        name: true,
        workoutSplitName: true,
        workoutDays: true,
        workoutConfiguredAt: true,
        proteinGoal: true,
        timezone: true,
        notifyWorkoutReminders: true,
        notifyMealReminders: true,
        notifyHydrationReminders: true,
        notifyStreakProtection: true,
        notifyWeeklyRecap: true,
        notifyAiCoachInsights: true,
        preferredWorkoutTime: true,
      },
    });

    for (const user of users) {
      const tz = user.timezone || "Africa/Cairo";
      const { localDateStr, hour, minute, dayOfWeek } = getLocalTimeInfo(tz);

      // Parse preferred workout time (default 09:00)
      const [prefHour, prefMin] = (user.preferredWorkoutTime || "09:00")
        .split(":")
        .map((v) => parseInt(v, 10));

      const todayStart = new Date(localDateStr + "T00:00:00Z");
      const todayEnd = new Date(localDateStr + "T23:59:59Z");

      // ── 1. Morning Workout Briefing ─────────────────────────
      if (
        user.notifyWorkoutReminders &&
        hour === (prefHour ?? 9) &&
        minute >= (prefMin ?? 0) &&
        minute < (prefMin ?? 0) + 30
      ) {
        const key = `${user.id}:workout_briefing:${localDateStr}`;
        if (!dispatchedAlertsToday.has(key)) {
          // Check if already completed today
          const completedToday = await prisma.workoutSession.findFirst({
            where: {
              userId: user.id,
              startedAt: { gte: todayStart, lte: todayEnd },
              endedAt: { not: null },
            },
          });

          if (!completedToday) {
            dispatchedAlertsToday.add(key);
            await sendWorkoutBriefingNotification(
              user.id,
              user.workoutSplitName || "Workout",
              5
            );
          }
        }
      }

      // ── 2. Lunch Fuel Check (1:30 PM - 2:00 PM) ─────────────
      if (user.notifyMealReminders && hour === 13 && minute >= 30) {
        const key = `${user.id}:lunch_prompt:${localDateStr}`;
        if (!dispatchedAlertsToday.has(key)) {
          // Check if lunch is already logged
          const lunchLogged = await prisma.mealLog.findFirst({
            where: {
              userId: user.id,
              mealType: "lunch",
              loggedAt: { gte: todayStart, lte: todayEnd },
            },
          });

          if (!lunchLogged) {
            dispatchedAlertsToday.add(key);
            await sendLunchPromptNotification(user.id);
          }
        }
      }

      // ── 3. Afternoon Hydration Touch (2:30 PM) ──────────────
      if (user.notifyHydrationReminders && hour === 14 && minute >= 30) {
        const key = `${user.id}:hydration_touch:${localDateStr}`;
        if (!dispatchedAlertsToday.has(key)) {
          dispatchedAlertsToday.add(key);
          await sendHydrationTouchNotification(user.id);
        }
      }

      // ── 4. Dinner & Macro Closing (8:00 PM) ─────────────────
      if (user.notifyMealReminders && hour === 20 && minute <= 30) {
        const key = `${user.id}:dinner_prompt:${localDateStr}`;
        if (!dispatchedAlertsToday.has(key)) {
          const meals = await prisma.mealLog.findMany({
            where: {
              userId: user.id,
              loggedAt: { gte: todayStart, lte: todayEnd },
            },
            select: { protein: true },
          });

          const totalProteinLogged = meals.reduce((acc, m) => acc + (m.protein || 0), 0);
          const remainingProtein = Math.max(0, user.proteinGoal - totalProteinLogged);

          dispatchedAlertsToday.add(key);
          await sendDinnerPromptNotification(user.id, remainingProtein);
        }
      }

      // ── 5. The Streak Guardian (9:30 PM) ────────────────────
      if (user.notifyStreakProtection && hour === 21 && minute >= 30) {
        const key = `${user.id}:streak_guardian:${localDateStr}`;
        if (!dispatchedAlertsToday.has(key)) {
          const mealsToday = await prisma.mealLog.count({
            where: {
              userId: user.id,
              loggedAt: { gte: todayStart, lte: todayEnd },
            },
          });

          // Only fire if user hasn't logged adequately today
          if (mealsToday < 2) {
            dispatchedAlertsToday.add(key);
            await sendStreakGuardianNotification(user.id, 3);
          }
        }
      }

      // ── 6. Sunday Transformation Recap (Sunday 8:00 PM) ─────
      if (dayOfWeek === 0 && user.notifyWeeklyRecap && hour === 20 && minute <= 30) {
        const key = `${user.id}:sunday_recap:${localDateStr}`;
        if (!dispatchedAlertsToday.has(key)) {
          const sevenDaysAgo = new Date(Date.now() - 7 * 86400000);
          const finishedWorkouts = await prisma.workoutSession.count({
            where: {
              userId: user.id,
              startedAt: { gte: sevenDaysAgo },
              endedAt: { not: null },
            },
          });

          dispatchedAlertsToday.add(key);
          await sendSundayRecapNotification(user.id, finishedWorkouts);
        }
      }

      // ── 7. AI Overtraining Alert (Morning 8:30 AM) ──────────
      if (user.notifyAiCoachInsights && hour === 8 && minute >= 30) {
        const key = `${user.id}:overtrain_alert:${localDateStr}`;
        if (!dispatchedAlertsToday.has(key)) {
          // Check consecutive training sessions
          const fiveDaysAgo = new Date(Date.now() - 5 * 86400000);
          const recentSessions = await prisma.workoutSession.findMany({
            where: {
              userId: user.id,
              startedAt: { gte: fiveDaysAgo },
              endedAt: { not: null },
            },
            select: { startedAt: true },
            orderBy: { startedAt: "desc" },
          });

          if (recentSessions.length >= 4) {
            dispatchedAlertsToday.add(key);
            await sendOvertrainingAlertNotification(user.id, recentSessions.length);
          }
        }
      }
    }
  } catch (err) {
    console.error("❌ [Scheduler] Error during scheduled notification evaluation:", err);
  }
}

let schedulerTimer: NodeJS.Timeout | null = null;

/**
 * Start the background notification ticker (runs every 15 minutes)
 */
export function startNotificationScheduler(): void {
  if (schedulerTimer) return;

  console.log("⏰ [Notifications] Automated notification scheduler started (15-min tick).");

  // Initial check after 10 seconds
  setTimeout(() => {
    evaluateScheduledNotifications().catch((err) => {
      console.warn("⚠️ [Notifications] Initial scheduler evaluation caught error:", err);
    });
  }, 10000);

  // Periodic 15-minute interval
  schedulerTimer = setInterval(() => {
    evaluateScheduledNotifications().catch((err) => {
      console.warn("⚠️ [Notifications] Periodic scheduler evaluation caught error:", err);
    });
  }, 15 * 60 * 1000);
}

/**
 * Stop scheduler on shutdown
 */
export function stopNotificationScheduler(): void {
  if (schedulerTimer) {
    clearInterval(schedulerTimer);
    schedulerTimer = null;
    console.log("🛑 [Notifications] Automated notification scheduler stopped.");
  }
}
