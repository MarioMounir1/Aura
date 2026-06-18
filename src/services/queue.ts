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
  db: parsedUrl.pathname && parsedUrl.pathname !== "/"
    ? parseInt(parsedUrl.pathname.substring(1), 10) || 0
    : 0,
  maxRetriesPerRequest: null,
  connectTimeout: 5000,
};

const QUEUE_NAME = "food-processing";

// Create the Queue instance
export const foodQueue = new Queue(QUEUE_NAME, {
  connection: queueConnectionOptions,
  defaultJobOptions: {
    removeOnComplete: {
      age: 3600, // keep for 1 hour
      count: 1000,
    },
    removeOnFail: {
      age: 24 * 3600, // keep for 24 hours
      count: 5000,
    },
  },
});

// Create QueueEvents instance to track job progress and listen to completion
export const queueEvents = new QueueEvents(QUEUE_NAME, {
  connection: queueConnectionOptions,
});

/**
 * Pushes a food processing task to the BullMQ queue.
 * Leverages the deterministic cache key as the jobId to perform automatic
 * de-duplication of concurrent, identical requests.
 */
export async function addFoodToQueue(
  companyId: string,
  restaurantName: string,
  restaurantCategory: string | undefined,
  itemName: string,
  itemDescription: string,
  addOns: string[]
) {
  const cacheKey = generateCacheKey(companyId, restaurantName, itemName, addOns);
  // BullMQ prohibits using colons (:) in job IDs. Replace all colons with double underscores.
  const jobId = cacheKey.replace(/:/g, "__");

  console.log(`📥 Adding job to "${QUEUE_NAME}" queue. Job ID: ${jobId}`);

  // Clean up stale completed/failed jobs with the same ID to allow retries
  const existingJob = await foodQueue.getJob(jobId);
  if (existingJob) {
    const state = await existingJob.getState();
    if (state === "failed" || state === "completed") {
      try {
        await existingJob.remove();
      } catch (_) {}
    }
  }

  // Adding the job. If the jobId already exists and is active/delayed/waiting,
  // BullMQ will reuse the existing job and NOT add a duplicate.
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
    {
      jobId,
    }
  );

  return job;
}
