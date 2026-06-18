// ============================================================
//  src/controllers/cache.controller.ts
//  Admin cache management endpoints
// ============================================================

import { Request, Response } from "express";
import prisma from "../services/prisma.service";
import { CacheStatsResponse, PurgeResponse } from "../types";
import redis, { isRedisReady } from "../services/redis.service";
import { USAGE_LIMIT } from "../middleware/usageLimitMiddleware";

export async function getCacheStats(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const restaurants = await prisma.restaurant.findMany({
      include: { items: true, addOns: true },
      orderBy: { createdAt: "desc" },
    });

    const totalRestaurants = restaurants.length;
    const totalCachedItems = restaurants.reduce(
      (sum, r) => sum + r.items.length,
      0
    );
    const totalCachedAddOns = restaurants.reduce(
      (sum, r) => sum + r.addOns.length,
      0
    );

    let companyUsageData = undefined;

    if (req.company) {
      const company = req.company;
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, "0");
      const currentMonth = `${year}-${month}`;
      const redisKey = `usage:company:${company.id}:${currentMonth}`;

      let used = 0;
      if (isRedisReady()) {
        const cachedCount = await redis.get(redisKey);
        used = cachedCount ? parseInt(cachedCount, 10) : 0;
      }

      companyUsageData = {
        companyId: company.id,
        companyName: company.name,
        currentMonth,
        limit: USAGE_LIMIT,
        used,
        remaining: Math.max(0, USAGE_LIMIT - used),
      };
    }

    const response: CacheStatsResponse = {
      success: true,
      totalRestaurants,
      totalCachedItems,
      totalCachedAddOns,
      restaurants: restaurants.map((r) => ({
        id:          r.id,
        name:        r.name,
        category:    r.category,
        itemCount:   r.items.length,
        addOnCount:  r.addOns.length,
        createdAt:   r.createdAt,
      })),
      companyUsage: companyUsageData,
    };

    res.json(response);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("❌  getCacheStats error:", message);
    res.status(500).json({ success: false, error: message });
  }
}

export async function purgeRestaurantCache(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { restaurantName } = req.params;

    if (!restaurantName) {
      res.status(400).json({
        success: false,
        error: "restaurantName is required",
      });
      return;
    }

    const companyId = req.company?.id;
    if (!companyId) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: Company information is missing",
      });
      return;
    }

    const redisKey = `food_cache:${companyId}:${restaurantName.toLowerCase().replace(/\s+/g, '_')}`;

    if (!isRedisReady()) {
      res.status(503).json({
        success: false,
        error: "Redis service is unavailable",
      });
      return;
    }

    const pattern = `food_cache:${companyId}:${restaurantName.toLowerCase().replace(/\s+/g, '_')}:*`;
    let cursor = "0";
    const keysToDelete: string[] = [];

    do {
      const [newCursor, keys] = await redis.scan(cursor, "MATCH", pattern, "COUNT", 100);
      cursor = newCursor;
      if (keys && keys.length > 0) {
        keysToDelete.push(...keys);
      }
    } while (cursor !== "0");

    if (keysToDelete.length === 0) {
      res.status(404).json({
        success: false,
        error: "No cached data found for this restaurant under your company account.",
      });
      return;
    }

    await redis.del(...keysToDelete);

    console.log(`🗑️   Purged ${keysToDelete.length} cache keys matching pattern "${pattern}" for restaurant "${restaurantName}"`);
    res.status(200).json({
      success: true,
      message: `Cache successfully purged for restaurant "${restaurantName}".`,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("❌  purgeRestaurantCache error:", message);
    res.status(500).json({ success: false, error: message });
  }
}

export async function purgeItem(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const { restaurantName, itemName } = req.params;

    if (!restaurantName || !itemName) {
      res.status(400).json({
        success: false,
        error: "Both restaurantName and itemName are required",
      });
      return;
    }

    const restaurant = await prisma.restaurant.findUnique({
      where: { name: restaurantName },
    });

    if (!restaurant) {
      res.status(404).json({
        success: false,
        error: `Restaurant "${restaurantName}" not found`,
      });
      return;
    }

    const deleted = await prisma.cachedMenuItem.delete({
      where: {
        restaurantId_itemName: {
          restaurantId: restaurant.id,
          itemName,
        },
      },
    }).catch(() => null);

    if (!deleted) {
      res.status(404).json({
        success: false,
        error: `Item "${itemName}" not found in "${restaurantName}"`,
      });
      return;
    }

    console.log(`🗑️   Purged item "${itemName}" from "${restaurantName}"`);
    res.json({
      success: true,
      message: `Item "${itemName}" purged from "${restaurantName}"`,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("❌  purgeItem error:", message);
    res.status(500).json({ success: false, error: message });
  }
}

export async function resetCache(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const confirmed = req.get("X-Confirm-Reset") === "true";
    if (!confirmed) {
      res.status(400).json({
        success: false,
        error: 'Add header "X-Confirm-Reset: true" to confirm reset',
      });
      return;
    }

    const deletedAddOns      = await prisma.cachedAddOn.deleteMany({});
    const deletedItems       = await prisma.cachedMenuItem.deleteMany({});
    const deletedRestaurants = await prisma.restaurant.deleteMany({});

    console.log(
      `🗑️   RESET: ${deletedItems.count} items, ${deletedAddOns.count} add-ons, ${deletedRestaurants.count} restaurants`
    );

    res.json({
      success: true,
      message: `Cache reset: ${deletedItems.count} items, ${deletedAddOns.count} add-ons, ${deletedRestaurants.count} restaurants deleted`,
      data: {
        itemsDeleted:       deletedItems.count,
        addOnsDeleted:      deletedAddOns.count,
        restaurantsDeleted: deletedRestaurants.count,
      },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("❌  resetCache error:", message);
    res.status(500).json({ success: false, error: message });
  }
}
