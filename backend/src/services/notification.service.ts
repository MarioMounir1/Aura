// ============================================================
//  src/services/notification.service.ts
//  Aura — Firebase Cloud Messaging Push Notification Service
// ============================================================

import { initializeApp, cert, applicationDefault, getApps } from "firebase-admin/app";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import prisma from "./prisma.service";

let isFirebaseAdminInitialized = false;

/**
 * Initialize Firebase Admin SDK safely
 */
function initFirebaseAdmin(): boolean {
  if (isFirebaseAdminInitialized) return true;
  if (getApps().length > 0) {
    isFirebaseAdminInitialized = true;
    return true;
  }

  try {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (serviceAccountJson) {
      const parsed = JSON.parse(serviceAccountJson);
      initializeApp({
        credential: cert(parsed),
      });
      isFirebaseAdminInitialized = true;
      console.log("✅ [FCM] Firebase Admin initialized from FIREBASE_SERVICE_ACCOUNT_JSON");
      return true;
    }

    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      initializeApp({
        credential: applicationDefault(),
      });
      isFirebaseAdminInitialized = true;
      console.log("✅ [FCM] Firebase Admin initialized from GOOGLE_APPLICATION_CREDENTIALS");
      return true;
    }

    // Fallback default initialization
    initializeApp();
    isFirebaseAdminInitialized = true;
    console.log("✅ [FCM] Firebase Admin initialized with default credentials");
    return true;
  } catch (err) {
    console.warn("⚠️ [FCM] Firebase Admin not configured or credentials missing. Push notifications will run in mock mode in dev:", err);
    return false;
  }
}

export interface PushNotificationPayload {
  userId: string;
  title: string;
  body: string;
  route?: string; // Deep link route (e.g. '/workout', '/meals')
  data?: Record<string, string>;
}

/**
 * Send push notification to all active devices of a specific user
 */
export async function sendPushToUser(payload: PushNotificationPayload): Promise<boolean> {
  const { userId, title, body, route = "/home", data = {} } = payload;

  try {
    // 1. Fetch user's registered device tokens
    const tokens = await prisma.deviceToken.findMany({
      where: { userId },
      select: { id: true, token: true },
    });

    if (tokens.length === 0) {
      console.log(`ℹ️ [FCM] No registered devices for user ${userId}. Skipping push.`);
      return false;
    }

    const registrationTokens = tokens.map((t) => t.token);

    // 2. Check if Firebase Admin is configured
    const isReady = initFirebaseAdmin();
    if (!isReady) {
      console.log(`[FCM Mock] Delivered to user ${userId} (${registrationTokens.length} tokens): "${title}" - "${body}" [Route: ${route}]`);
      return true;
    }

    // 3. Dispatch multicast payload via FCM
    const message: MulticastMessage = {
      tokens: registrationTokens,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        route,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "aura_high_importance_channel",
          sound: "default",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await getMessaging().sendEachForMulticast(message);
    console.log(`🔔 [FCM] Multicast sent to user ${userId}: ${response.successCount} succeeded, ${response.failureCount} failed.`);

    // 4. Clean up invalid/stale tokens
    if (response.failureCount > 0) {
      const invalidTokens: string[] = [];
      response.responses.forEach((resp: any, idx: number) => {
        if (!resp.success && resp.error) {
          const code = resp.error.code;
          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(registrationTokens[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await prisma.deviceToken.deleteMany({
          where: { token: { in: invalidTokens } },
        });
        console.log(`🧹 [FCM] Pruned ${invalidTokens.length} stale device tokens.`);
      }
    }

    return response.successCount > 0;
  } catch (err) {
    console.error(`❌ [FCM] Error sending push notification to user ${userId}:`, err);
    return false;
  }
}

// ── Notification Helpers Matching the Master Plan ────────────

/**
 * 1. Morning Workout Briefing (9:00 AM)
 */
export async function sendWorkoutBriefingNotification(userId: string, splitName: string, exerciseCount: number): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: `Today: ${splitName} Session 🏋️`,
    body: `${exerciseCount} exercises queued up. Let's get to work!`,
    route: "/workout",
  });
}

/**
 * 2. Rest Day Protocol (9:30 AM)
 */
export async function sendRestDayNotification(userId: string): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "Scheduled Rest & Recovery 🌿",
    body: "No lifting today. Focus on high protein intake and 8 hours of sleep.",
    route: "/workout",
  });
}

/**
 * 3. Lunch Fuel Prompt (1:30 PM)
 */
export async function sendLunchPromptNotification(userId: string): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "Time to Refuel 🥗",
    body: "Snap a quick photo or speak your lunch to keep your macros on target.",
    route: "/meals",
  });
}

/**
 * 4. Afternoon Hydration Touch (2:30 PM)
 */
export async function sendHydrationTouchNotification(userId: string): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "Coach Tip: Hydration Check 💧",
    body: "Grab a fresh glass of water to keep your energy and metabolism sharp.",
    route: "/home",
  });
}

/**
 * 6. Dinner & Macro Closing (8:00 PM)
 */
export async function sendDinnerPromptNotification(userId: string, remainingProteinGrams: number): Promise<boolean> {
  const proteinText = remainingProteinGrams > 0
    ? `You're only ${Math.round(remainingProteinGrams)}g protein away from your goal. Close the gap with dinner!`
    : "Time for dinner! Log your meal to finish today's nutrition targets strong.";

  return sendPushToUser({
    userId,
    title: "Evening Macro Check 🎯",
    body: proteinText,
    route: "/meals",
  });
}

/**
 * 7. Streak Guardian (9:30 PM)
 */
export async function sendStreakGuardianNotification(userId: string, streakDays: number): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "Keep Your Streak Alive! 🔥",
    body: `Don't break your ${streakDays}-day streak! Take 10 seconds to log today before midnight.`,
    route: "/meals",
  });
}

/**
 * 8. Sunday Transformation Recap (Sunday 8:00 PM)
 */
export async function sendSundayRecapNotification(userId: string, completedWorkoutsCount: number): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "Your Weekly Transformation Report 📊",
    body: `You completed ${completedWorkoutsCount} workouts this week! Tap to see your full consistency score.`,
    route: "/workout",
  });
}

/**
 * 9. AI Plateau Buster Alert
 */
export async function sendPlateauAlertNotification(userId: string, exerciseName: string, weightKg: number): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "AI Coach: Plateau Detected 💡",
    body: `Your ${exerciseName} has stalled at ${weightKg}kg for 3 sessions. Tap to view your AI Coach's progression tip!`,
    route: "/workout",
  });
}

/**
 * 10. AI Overtraining & Fatigue Warning
 */
export async function sendOvertrainingAlertNotification(userId: string, consecutiveDays: number): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "AI Coach: Recovery Warning ⚠️",
    body: `You've trained ${consecutiveDays} consecutive days without rest. Muscles grow during recovery—take an active rest day!`,
    route: "/workout",
  });
}

/**
 * 11. Post-Workout Replenishment Prompt (15 mins after session)
 */
export async function sendPostWorkoutReplenishNotification(userId: string, totalVolumeKg: number, setsCount: number): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "Session Crushed! ⚡",
    body: `Total volume: ${Math.round(totalVolumeKg)} kg lifted across ${setsCount} sets. Replenish with 25-30g protein within the hour!`,
    route: "/meals",
  });
}

/**
 * 12. AI Macro Rebalance Tip
 */
export async function sendMacroRebalanceNotification(userId: string, proteinDeficit: number): Promise<boolean> {
  return sendPushToUser({
    userId,
    title: "Coach Tip: Protein Priority 🍗",
    body: `Calories are accumulating but protein is ${Math.round(proteinDeficit)}g behind. Make lean protein the centerpiece of tonight's dinner!`,
    route: "/meals",
  });
}
