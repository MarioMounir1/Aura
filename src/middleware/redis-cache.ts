// ============================================================
//  src/middleware/redis-cache.ts
//  Deterministic Redis Caching Middleware (Interceptor)
// ============================================================

import { Request, Response, NextFunction } from "express";
import Redis from "ioredis";
import { isRedisReady } from "../services/redis.service";

/**
 * Creates a unique, deterministic cache key from the item name and customizations.
 * Sanitizes strings to lowercase, trims, replaces non-alphanumeric characters with
 * underscores, and sorts customizations alphabetically before joining.
 */
export function generateCacheKey(
  companyId: string,
  restaurantName: string,
  itemName: string,
  customizations: string[]
): string {
  const sanitize = (str: string): string => {
    return str
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "");
  };

  const sanitizedRestaurant = restaurantName.toLowerCase().replace(/\s+/g, "_");
  const sanitizedItem = itemName.toLowerCase().replace(/\s+/g, "_");
  
  const splitCustoms = customizations
    .flatMap((c) => c.split(","))
    .map((c) => c.trim())
    .filter(Boolean)
    .sort(); // Alphabetical sort ensures order-independence

  const sanitizedCustoms = splitCustoms
    .map((c) => sanitize(c))
    .filter(Boolean);

  return [
    `food_cache:${companyId}:${sanitizedRestaurant}:${sanitizedItem}`,
    ...sanitizedCustoms
  ].join(":");
}

/**
 * Reusable Express Middleware to cache POST requests based on request payload.
 *
 * @param redisClient Instantiated ioredis client
 * @param ttlSeconds Expiration time in seconds (default: 7 days = 604800s)
 */
export function redisCacheMiddleware(redisClient: Redis, ttlSeconds: number = 7 * 24 * 60 * 60) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    // Only intercept POST requests with json payloads containing menu item calculations
    if (req.method !== "POST") {
      return next();
    }

    // Extract fields, supporting both user-requested names and existing API schema names
    const itemName = req.body.item_name ?? req.body.itemName;
    const customizations = req.body.customizations ?? req.body.addOns;

    // Fail-safe: If no valid item name, bypass caching and call next middleware/controller
    if (!itemName || typeof itemName !== "string") {
      return next();
    }

    const companyId = (req as any).company?.id;
    if (!companyId) {
      return next();
    }

    const restaurantName = req.body.restaurantName ?? req.body.restaurant_name ?? "B2B_Client";
    const customsArray = Array.isArray(customizations) ? customizations : [];
    const cacheKey = generateCacheKey(companyId, restaurantName, itemName, customsArray);

    // Track if Redis is functional to safely intercept the response later
    let redisBypassed = false;

    if (isRedisReady()) {
      try {
        const startTime = Date.now();
        const cachedPayload = await redisClient.get(cacheKey);

        if (cachedPayload) {
          const latency = Date.now() - startTime;
          console.log(`⚡  [Redis] Cache HIT for key: "${cacheKey}" (${latency}ms)`);
          
          res.setHeader("X-Cache", "HIT");
          res.setHeader("Content-Type", "application/json");
          res.status(200).send(cachedPayload);
          return;
        }
      } catch (error) {
        console.error("⚠️  [Redis] Cache read failed (failing safe):", error);
        redisBypassed = true;
      }
    } else {
      console.warn("⚠️  [Redis] Server not ready. Bypassing Redis cache check.");
      redisBypassed = true;
    }

    // Cache Miss Logic: Set standard cache miss header
    res.setHeader("X-Cache", "MISS");

    // Intercept res.json to capture and cache response on success
    const originalJson = res.json;

    res.json = function (body: any): Response {
      // Restore the original res.json immediately to prevent recursion loops
      res.json = originalJson;

      // Only cache successful 2xx responses containing valid payloads
      const isSuccess = res.statusCode >= 200 && res.statusCode < 300;
      
      if (!redisBypassed && isSuccess && body && body.success !== false) {
        // Run Redis write operations asynchronously in the background (non-blocking)
        redisClient
          .set(cacheKey, JSON.stringify(body), "EX", ttlSeconds)
          .then(() => {
            console.log(`💾  [Redis] Successfully cached response under key: "${cacheKey}"`);
          })
          .catch((err) => {
            console.error("⚠️  [Redis] Cache write failed:", err);
          });
      }

      return originalJson.call(this, body);
    };

    next();
  };
}
