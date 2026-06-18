// ============================================================
//  src/routes/nutrition.routes.ts
//  Main nutrition API routes (layered layout)
// ============================================================

import { Router }                 from "express";
import { calculateNutrition }      from "../controllers/nutrition.controller";
import { batchCalculateNutrition } from "../controllers/batch.controller";
import { calculateB2B }            from "../controllers/b2b.controller";
import {
  getCacheStats,
  purgeRestaurantCache,
  purgeItem,
  resetCache,
} from "../controllers/cache.controller";
import {
  validateCalculateRequest,
  validateBatchRequest,
  validateB2BRequest,
} from "../middleware/validation";
import { redisCacheMiddleware }    from "../middleware/redis-cache";
import redis                       from "../services/redis.service";
import { validateApiKey }          from "../middleware/authMiddleware";
import { checkUsageLimit }         from "../middleware/usageLimitMiddleware";

const router = Router();

// Apply Redis caching middleware as an interceptor on calculations
router.post(
  "/calculate",
  validateApiKey,
  checkUsageLimit,
  validateCalculateRequest,
  redisCacheMiddleware(redis),
  calculateNutrition
);

router.post(
  "/b2b/calculate",
  validateApiKey,
  checkUsageLimit,
  validateB2BRequest,
  redisCacheMiddleware(redis),
  calculateB2B
);

router.post("/batch", validateBatchRequest, batchCalculateNutrition);
router.get("/cache/stats", validateApiKey, getCacheStats);
router.delete("/cache/:restaurantName", validateApiKey, checkUsageLimit, purgeRestaurantCache);
router.delete("/cache/:restaurantName/:itemName", purgeItem);
router.post("/cache/reset", resetCache);

export default router;
