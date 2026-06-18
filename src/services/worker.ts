import { Worker } from "bullmq";
import { queueConnectionOptions } from "./queue";
import { calculateMealWithAddOns } from "./nutrition-calculation.service";
import prisma from "./prisma.service";
import { inferRestaurantCategory } from "../config";
import redis from "./redis.service";
import { generateCacheKey } from "../middleware/redis-cache";

// Grab configurable concurrency limit from env, default to 2
const concurrency = parseInt(process.env.QUEUE_CONCURRENCY || "2", 10);

console.log(`🤖 Initializing BullMQ Worker with concurrency limit: ${concurrency}`);

export const foodWorker = new Worker(
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

      // 3. Save the final JSON result to Redis Cache so future requests HIT the cache
      const cacheKey = generateCacheKey(companyId, restaurantName, normalizedItem, addOns || []);
      const ttlSeconds = 7 * 24 * 60 * 60; // 7 days (matching middleware ttl)

      await redis.set(cacheKey, JSON.stringify(result), "EX", ttlSeconds);
      
      console.log(`💾 [Worker] Cached result for key: "${cacheKey}"`);

      // 4. Return results so job completes successfully
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
