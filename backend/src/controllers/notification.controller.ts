// ============================================================
//  src/controllers/notification.controller.ts
//  Aura — Push Notification Device & Preferences Controller
// ============================================================

import { Request, Response } from "express";
import { z } from "zod";
import prisma from "../services/prisma.service";

// ── Validation Schemas ───────────────────────────────────────

const RegisterTokenSchema = z.object({
  token: z.string().min(10, "Valid device token required"),
  platform: z.enum(["android", "ios", "web"]).default("android"),
  timezone: z.string().optional(),
  appVersion: z.string().optional(),
});

const UpdatePreferencesSchema = z.object({
  notifyWorkoutReminders: z.boolean().optional(),
  notifyMealReminders: z.boolean().optional(),
  notifyHydrationReminders: z.boolean().optional(),
  notifyStreakProtection: z.boolean().optional(),
  notifyWeeklyRecap: z.boolean().optional(),
  notifyAiCoachInsights: z.boolean().optional(),
  preferredWorkoutTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, "Format must be HH:mm").optional(),
  timezone: z.string().optional(),
});

// ── Endpoints ────────────────────────────────────────────────

/**
 * POST /api/v1/notifications/register-token
 * Registers or updates an FCM device token for the authenticated user.
 */
export async function registerDeviceToken(req: Request, res: Response): Promise<void> {
  const parsed = RegisterTokenSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  const userId = req.user!.id;
  const { token, platform, timezone, appVersion } = parsed.data;

  try {
    // 1. Upsert DeviceToken record
    await prisma.deviceToken.upsert({
      where: { token },
      update: {
        userId,
        platform,
        timezone: timezone ?? null,
        appVersion: appVersion ?? null,
        lastUsedAt: new Date(),
      },
      create: {
        userId,
        token,
        platform,
        timezone: timezone ?? null,
        appVersion: appVersion ?? null,
      },
    });

    // 2. Update user's timezone if provided
    if (timezone) {
      await prisma.user.update({
        where: { id: userId },
        data: { timezone },
      });
    }

    console.log(`📱 [Notifications] Device token registered for user ${userId} (${platform})`);

    res.status(200).json({
      success: true,
      message: "Device token registered successfully",
    });
  } catch (error) {
    console.error("❌ [Notifications] Failed to register token:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error registering notification token",
    });
  }
}

/**
 * POST /api/v1/notifications/unregister-token
 * Removes a device token upon logout.
 */
export async function unregisterDeviceToken(req: Request, res: Response): Promise<void> {
  const { token } = req.body;
  if (!token || typeof token !== "string") {
    res.status(400).json({ success: false, error: "Token string required" });
    return;
  }

  try {
    await prisma.deviceToken.deleteMany({
      where: { token },
    });

    res.status(200).json({
      success: true,
      message: "Device token unregistered successfully",
    });
  } catch (error) {
    console.error("❌ [Notifications] Failed to unregister token:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error unregistering device token",
    });
  }
}

/**
 * GET /api/v1/notifications/preferences
 * Returns the current notification preferences for the authenticated user.
 */
export async function getNotificationPreferences(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        notifyWorkoutReminders: true,
        notifyMealReminders: true,
        notifyHydrationReminders: true,
        notifyStreakProtection: true,
        notifyWeeklyRecap: true,
        notifyAiCoachInsights: true,
        preferredWorkoutTime: true,
        timezone: true,
      },
    });

    if (!user) {
      res.status(404).json({ success: false, error: "User not found" });
      return;
    }

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("❌ [Notifications] Failed to get preferences:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error retrieving notification preferences",
    });
  }
}

/**
 * PATCH /api/v1/notifications/preferences
 * Updates notification preferences for the authenticated user.
 */
export async function updateNotificationPreferences(req: Request, res: Response): Promise<void> {
  const parsed = UpdatePreferencesSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  const userId = req.user!.id;

  try {
    const updated = await prisma.user.update({
      where: { id: userId },
      data: parsed.data,
      select: {
        notifyWorkoutReminders: true,
        notifyMealReminders: true,
        notifyHydrationReminders: true,
        notifyStreakProtection: true,
        notifyWeeklyRecap: true,
        notifyAiCoachInsights: true,
        preferredWorkoutTime: true,
        timezone: true,
      },
    });

    res.status(200).json({
      success: true,
      data: updated,
      message: "Notification preferences updated",
    });
  } catch (error) {
    console.error("❌ [Notifications] Failed to update preferences:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error updating notification preferences",
    });
  }
}
