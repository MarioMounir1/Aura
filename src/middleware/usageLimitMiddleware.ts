// ============================================================
//  src/middleware/usageLimitMiddleware.ts
//  Redis Usage Counter & Rate Limiting Middleware
// ============================================================

import { Request, Response, NextFunction } from "express";
import redis, { isRedisReady } from "../services/redis.service";

export const USAGE_LIMIT = 50000;

export async function checkUsageLimit(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const company = req.company;
    if (!company || !company.id) {
      res.status(401).json({
        success: false,
        message: "Access Denied: Missing company information.",
      });
      return;
    }

    if (!isRedisReady()) {
      console.warn("⚠️  [Redis] Server not ready. Bypassing usage limit checks.");
      return next();
    }

    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const currentMonth = `${year}-${month}`;

    const redisKey = `usage:company:${company.id}:${currentMonth}`;

    // Increment request count in Redis
    const currentCount = await redis.incr(redisKey);

    // If it's the first request of the month, set an expiration (31 days = 2,678,400 seconds)
    if (currentCount === 1) {
      await redis.expire(redisKey, 2678400);
    }

    if (currentCount > USAGE_LIMIT) {
      res.status(429).json({
        success: false,
        message: "Usage limit exceeded for this month. Please upgrade your plan.",
      });
      return;
    }

    // Attach current count to request object
    req.companyUsage = currentCount;
    next();
  } catch (error) {
    console.error("❌  Usage limit middleware error:", error);
    res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
}
