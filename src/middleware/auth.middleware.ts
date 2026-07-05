// ============================================================
//  src/middleware/auth.middleware.ts
//  JWT-based user authentication for the Calc-Calories mobile API
// ============================================================

import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import prisma from "../services/prisma.service";

export interface JwtPayload {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

// Extend Express Request to include authenticated user
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        name: string;
      };
      // existing field from company auth middleware
      company?: {
        id: string;
        name: string;
      };
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET ?? "change-me-in-production-secret-key";

/**
 * Middleware: Requires a valid JWT Bearer token.
 * Attaches the decoded user to `req.user`.
 */
export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({
      success: false,
      error: "Authentication required. Please provide a Bearer token.",
      code: "MISSING_TOKEN",
    });
    return;
  }

  const token = authHeader.slice(7); // Remove "Bearer " prefix

  let payload: JwtPayload;
  try {
    payload = jwt.verify(token, JWT_SECRET) as JwtPayload;
  } catch (err: unknown) {
    const isExpired = err instanceof jwt.TokenExpiredError;
    res.status(401).json({
      success: false,
      error: isExpired ? "Token has expired. Please log in again." : "Invalid authentication token.",
      code: isExpired ? "TOKEN_EXPIRED" : "INVALID_TOKEN",
    });
    return;
  }

  try {
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: { id: true, email: true, name: true, isActive: true },
    });

    if (!user || !user.isActive) {
      res.status(401).json({
        success: false,
        error: "User account not found or is deactivated.",
        code: "USER_NOT_FOUND",
      });
      return;
    }

    req.user = { id: user.id, email: user.email, name: user.name };
    next();
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("❌ [Auth] Database error during token verification:", msg);
    res.status(500).json({
      success: false,
      error: "Authentication service temporarily unavailable.",
      code: "AUTH_DB_ERROR",
    });
  }
}

/**
 * Utility: Generate a signed JWT for a user.
 */
export function generateToken(userId: string, email: string): string {
  const expiresIn = process.env.JWT_EXPIRES_IN ?? "7d";
  return jwt.sign({ userId, email }, JWT_SECRET, { expiresIn } as jwt.SignOptions);
}

/**
 * Utility: Optional auth — attaches user if token present but doesn't fail.
 */
export async function optionalAuth(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next();
  }

  try {
    const token = authHeader.slice(7);
    const payload = jwt.verify(token, JWT_SECRET) as JwtPayload;
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: { id: true, email: true, name: true, isActive: true },
    });
    if (user && user.isActive) {
      req.user = { id: user.id, email: user.email, name: user.name };
    }
  } catch {
    // Silently ignore invalid tokens in optional auth
  }
  next();
}
