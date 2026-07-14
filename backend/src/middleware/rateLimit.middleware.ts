// ============================================================
//  src/middleware/rateLimit.middleware.ts
//  Redis-backed rate limiter for Calc-Calories v1 API
// ============================================================

import { Request, Response, NextFunction } from "express";
import redis, { isRedisReady } from "../services/redis.service";

interface RateLimitOptions {
  windowSeconds: number;
  maxRequests: number;
  keyPrefix: string;
}

/**
 * Factory that returns an Express middleware enforcing Redis-backed rate limiting.
 * Falls back gracefully (allows request) when Redis is offline.
 */
export function createRateLimiter(options: RateLimitOptions) {
  const { windowSeconds, maxRequests, keyPrefix } = options;

  return async function rateLimitMiddleware(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    // Graceful degradation: if Redis is offline, allow the request
    if (!isRedisReady()) {
      console.warn("⚠️  [RateLimit] Redis offline — rate limiting skipped.");
      return next();
    }

    const identifier = req.user?.id ?? req.ip ?? "anonymous";
    const key = `ratelimit:${keyPrefix}:${identifier}`;

    try {
      const pipeline = redis.pipeline();
      pipeline.incr(key);
      pipeline.ttl(key);
      const results = await pipeline.exec();

      if (!results) {
        return next();
      }

      const count = results[0]?.[1] as number;
      const ttl = results[1]?.[1] as number;

      // Set expiry only on first request
      if (count === 1) {
        await redis.expire(key, windowSeconds);
      }

      const remaining = Math.max(0, maxRequests - count);
      const resetTime = ttl > 0 ? ttl : windowSeconds;

      // Set rate limit headers
      res.setHeader("X-RateLimit-Limit", maxRequests);
      res.setHeader("X-RateLimit-Remaining", remaining);
      res.setHeader("X-RateLimit-Reset", Math.floor(Date.now() / 1000) + resetTime);

      if (count > maxRequests) {
        res.status(429).json({
          success: false,
          error: `Rate limit exceeded. You can make ${maxRequests} requests per ${windowSeconds} seconds.`,
          code: "RATE_LIMIT_EXCEEDED",
          retryAfter: resetTime,
        });
        return;
      }

      next();
    } catch (err: unknown) {
      // Redis error — allow request through rather than block users
      const msg = err instanceof Error ? err.message : String(err);
      console.error("❌ [RateLimit] Redis error:", msg);
      next();
    }
  };
}

// Pre-configured limiters
export const analyzeMealLimiter = createRateLimiter({
  keyPrefix: "analyze",
  maxRequests: 30,
  windowSeconds: 60,
});

export const authLimiter = createRateLimiter({
  keyPrefix: "auth",
  maxRequests: 10,
  windowSeconds: 60,
});
