// ============================================================
//  src/services/queue.ts
//  BullMQ Queue — gracefully optional (no-op when Redis is offline)
// ============================================================

import { Queue, QueueEvents, ConnectionOptions } from "bullmq";
import { URL } from "url";
import { generateCacheKey } from "../middleware/redis-cache";

const redisUrl = process.env.REDIS_URL ?? "redis://localhost:6379";

console.log(`🔌 Configuring BullMQ Redis Connection options targeting: ${redisUrl}`);

const parsedUrl = new URL(redisUrl);

export const queueConnectionOptions: ConnectionOptions = {
  host: parsedUrl.hostname || "localhost",
  port: parsedUrl.port ? parseInt(parsedUrl.port, 10) : 6379,
  username: parsedUrl.username || undefined,
  password: parsedUrl.password || undefined,
  db:
    parsedUrl.pathname && parsedUrl.pathname !== "/"
      ? parseInt(parsedUrl.pathname.substring(1), 10) || 0
      : 0,
  maxRetriesPerRequest: null,
  connectTimeout: 5000,
  // Don't retry forever when Redis is offline — fail fast
  enableOfflineQueue: false,
};

const QUEUE_NAME = "food-processing";

// Queue and QueueEvents are lazy — they don't connect until first use.
export let foodQueue: Queue | null = null;
export let queueEvents: QueueEvents | null = null;

try {
  foodQueue = new Queue(QUEUE_NAME, {
    connection: queueConnectionOptions,
    defaultJobOptions: {
      removeOnComplete: { age: 3600, count: 1000 },
      removeOnFail: { age: 24 * 3600, count: 5000 },
    },
  });

  queueEvents = new QueueEvents(QUEUE_NAME, {
    connection: queueConnectionOptions,
  });

  console.log(`✅ [Queue] BullMQ Queue "${QUEUE_NAME}" initialized.`);
} catch (err: any) {
  console.warn(`⚠️  [Queue] BullMQ Queue failed to initialize (Redis likely offline): ${err?.message ?? err}`);
  console.warn(`⚠️  [Queue] Background queue processing is disabled. Core API is still fully operational.`);
}

/**
 * Pushes a food processing task to the BullMQ queue.
 * Returns null gracefully if Redis/queue is unavailable.
 */
export async function addFoodToQueue(
  companyId: string,
  restaurantName: string,
  restaurantCategory: string | undefined,
  itemName: string,
  itemDescription: string,
  addOns: string[]
) {
  if (!foodQueue) {
    console.warn("⚠️  [Queue] Cannot enqueue job — Redis is offline.");
    return null;
  }

  const cacheKey = generateCacheKey(companyId, restaurantName, itemName, addOns);
  // BullMQ prohibits using colons (:) in job IDs.
  const jobId = cacheKey.replace(/:/g, "__");

  console.log(`📥 Adding job to "${QUEUE_NAME}" queue. Job ID: ${jobId}`);

  // Clean up stale completed/failed jobs to allow retries
  const existingJob = await foodQueue.getJob(jobId);
  if (existingJob) {
    const state = await existingJob.getState();
    if (state === "failed" || state === "completed") {
      try { await existingJob.remove(); } catch (_) {}
    }
  }

  const job = await foodQueue.add(
    "process-food",
    {
      companyId,
      restaurantName,
      restaurantCategory,
      itemName,
      itemDescription,
      addOns,
    },
    { jobId }
  );

  return job;
}
