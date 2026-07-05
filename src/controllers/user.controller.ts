// ============================================================
//  src/controllers/user.controller.ts
//  Calc-Calories — User Auth & Profile endpoints
//  POST /api/v1/auth/register
//  POST /api/v1/auth/login
//  GET  /api/v1/users/me
//  PUT  /api/v1/users/me/goals
// ============================================================

import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import prisma from "../services/prisma.service";
import { generateToken } from "../middleware/auth.middleware";

// ── Zod Validation Schemas ─────────────────────────────────

const RegisterSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters").max(100),
  email: z.string().email("Invalid email address").toLowerCase(),
  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .max(128),
  dailyCalorieGoal: z.number().int().min(500).max(10000).optional(),
});

const LoginSchema = z.object({
  email: z.string().email("Invalid email address").toLowerCase(),
  password: z.string().min(1, "Password is required"),
});

const UpdateGoalsSchema = z.object({
  dailyCalorieGoal: z.number().int().min(500).max(10000).optional(),
  proteinGoal: z.number().int().min(0).max(1000).optional(),
  carbsGoal: z.number().int().min(0).max(2000).optional(),
  fatsGoal: z.number().int().min(0).max(500).optional(),
});

// ── Helper ─────────────────────────────────────────────────

function userPublicProfile(user: {
  id: string;
  name: string;
  email: string;
  dailyCalorieGoal: number;
  proteinGoal: number;
  carbsGoal: number;
  fatsGoal: number;
  createdAt: Date;
}) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    goals: {
      dailyCalories: user.dailyCalorieGoal,
      protein: user.proteinGoal,
      carbs: user.carbsGoal,
      fats: user.fatsGoal,
    },
    createdAt: user.createdAt,
  };
}

// ── Controllers ────────────────────────────────────────────

export async function register(req: Request, res: Response): Promise<void> {
  const parsed = RegisterSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  const { name, email, password, dailyCalorieGoal } = parsed.data;

  try {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      res.status(409).json({
        success: false,
        error: "An account with this email already exists.",
        code: "EMAIL_TAKEN",
      });
      return;
    }

    const SALT_ROUNDS = 12;
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        name,
        email,
        passwordHash,
        dailyCalorieGoal: dailyCalorieGoal ?? 2000,
      },
      select: {
        id: true,
        name: true,
        email: true,
        dailyCalorieGoal: true,
        proteinGoal: true,
        carbsGoal: true,
        fatsGoal: true,
        createdAt: true,
      },
    });

    const token = generateToken(user.id, user.email);

    console.log(`✅ [Auth] New user registered: ${email}`);
    res.status(201).json({
      success: true,
      data: {
        user: userPublicProfile(user),
        token,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [Auth] Register error:", msg);
    res.status(500).json({
      success: false,
      error: "Failed to create account. Please try again.",
      code: "REGISTER_ERROR",
    });
  }
}

export async function login(req: Request, res: Response): Promise<void> {
  const parsed = LoginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  const { email, password } = parsed.data;

  try {
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        name: true,
        email: true,
        passwordHash: true,
        isActive: true,
        dailyCalorieGoal: true,
        proteinGoal: true,
        carbsGoal: true,
        fatsGoal: true,
        createdAt: true,
      },
    });

    if (!user || !user.isActive) {
      res.status(401).json({
        success: false,
        error: "Invalid email or password.",
        code: "INVALID_CREDENTIALS",
      });
      return;
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      res.status(401).json({
        success: false,
        error: "Invalid email or password.",
        code: "INVALID_CREDENTIALS",
      });
      return;
    }

    const token = generateToken(user.id, user.email);

    console.log(`✅ [Auth] User logged in: ${email}`);
    res.json({
      success: true,
      data: {
        user: userPublicProfile(user),
        token,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [Auth] Login error:", msg);
    res.status(500).json({
      success: false,
      error: "Login service temporarily unavailable.",
      code: "LOGIN_ERROR",
    });
  }
}

export async function getMe(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;

  try {
    // Get user + today's meal logs for daily summary
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const [user, todayLogs] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          name: true,
          email: true,
          dailyCalorieGoal: true,
          proteinGoal: true,
          carbsGoal: true,
          fatsGoal: true,
          createdAt: true,
        },
      }),
      prisma.mealLog.findMany({
        where: {
          userId,
          createdAt: { gte: today, lt: tomorrow },
        },
        select: { calories: true, protein: true, carbs: true, fats: true },
      }),
    ]);

    if (!user) {
      res.status(404).json({ success: false, error: "User not found." });
      return;
    }

    const todayTotals = todayLogs.reduce(
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
        user: userPublicProfile(user),
        todaySummary: {
          consumed: todayTotals,
          remaining: {
            calories: Math.max(0, user.dailyCalorieGoal - todayTotals.calories),
            protein: Math.max(0, user.proteinGoal - todayTotals.protein),
            carbs: Math.max(0, user.carbsGoal - todayTotals.carbs),
            fats: Math.max(0, user.fatsGoal - todayTotals.fats),
          },
          mealsLogged: todayLogs.length,
        },
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [User] getMe error:", msg);
    res.status(500).json({ success: false, error: "Failed to load profile." });
  }
}

export async function updateGoals(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;

  const parsed = UpdateGoalsSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      success: false,
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  if (Object.keys(parsed.data).length === 0) {
    res.status(400).json({
      success: false,
      error: "No goals provided to update.",
    });
    return;
  }

  try {
    const updated = await prisma.user.update({
      where: { id: userId },
      data: parsed.data,
      select: {
        id: true,
        name: true,
        email: true,
        dailyCalorieGoal: true,
        proteinGoal: true,
        carbsGoal: true,
        fatsGoal: true,
        createdAt: true,
      },
    });

    res.json({
      success: true,
      data: { user: userPublicProfile(updated) },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [User] updateGoals error:", msg);
    res.status(500).json({ success: false, error: "Failed to update goals." });
  }
}
