// ============================================================
//  src/services/worker.ts
//  BullMQ Worker — gracefully optional (no-op when Redis is offline)
// ============================================================

import { Worker } from "bullmq";
import { queueConnectionOptions } from "./queue";
import { calculateMealWithAddOns } from "./nutrition-calculation.service";
import prisma from "./prisma.service";
import { inferRestaurantCategory } from "../config";
import redis from "./redis.service";
import { generateCacheKey } from "../middleware/redis-cache";

// Grab configurable concurrency limit from env, default to 2
const concurrency = parseInt(process.env.QUEUE_CONCURRENCY || "2", 10);

/**
 * BullMQ Worker — optional, only starts when Redis is available.
 * If Redis is offline the core API still runs; only background queue
 * processing is disabled.
 */
let foodWorker: Worker | null = null;

try {
  console.log(`🤖 Initializing BullMQ Worker with concurrency limit: ${concurrency}`);

  foodWorker = new Worker(
    "food-processing",
    async (job) => {
      const { companyId, restaurantName, restaurantCategory, itemName, itemDescription, addOns } = job.data;

      console.log(`⚙️  [Worker] Processing Job ID: ${job.id} (${restaurantName} — ${itemName})`);

      const normalizedRestaurant = restaurantName.trim();
      const normalizedItem       = itemName.trim();

      try {
        // 1. Ensure restaurant exists in Postgres database
        const restaurant = await prisma.restaurant.upsert({
          where:  { name: normalizedRestaurant },
          update: {},
          create: {
            name:     normalizedRestaurant,
            category: inferRestaurantCategory(normalizedRestaurant, restaurantCategory),
          },
        });

        // 2. Call existing AI handler function
        const result = await calculateMealWithAddOns({
          restaurant,
          itemName: normalizedItem,
          itemDescription,
          addOns,
        });

        // 3. Save result to Redis so future requests HIT the cache
        const cacheKey   = generateCacheKey(companyId, restaurantName, normalizedItem, addOns || []);
        const ttlSeconds = 7 * 24 * 60 * 60; // 7 days

        await redis.set(cacheKey, JSON.stringify(result), "EX", ttlSeconds);
        console.log(`💾 [Worker] Cached result for key: "${cacheKey}"`);

        return result;
      } catch (error: any) {
        console.error(`❌ [Worker] Job ${job.id} failed:`, error.message || error);
        throw error; // Let BullMQ handle failure state
      }
    },
    {
      connection: queueConnectionOptions,
      concurrency,
    }
  );

  foodWorker.on("completed", (job) => {
    console.log(`✨ [Worker] Job ${job.id} completed successfully.`);
  });

  foodWorker.on("failed", (job, err) => {
    console.error(`💥 [Worker] Job ${job?.id} failed with error:`, err);
  });

  console.log("✅ [Worker] BullMQ Worker started successfully.");

} catch (err: any) {
  console.warn(`⚠️  [Worker] BullMQ Worker failed to start (Redis likely offline): ${err?.message ?? err}`);
  console.warn(`⚠️  [Worker] Background queue processing is disabled. Core API is still fully operational.`);
}

export { foodWorker };
