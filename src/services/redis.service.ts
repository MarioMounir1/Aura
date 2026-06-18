// ============================================================
//  src/services/redis.service.ts
//  Redis Client Singleton with Connection Event Logging & Fail-Safe Checks
// ============================================================

import Redis from "ioredis";

const redisUrl = process.env.REDIS_URL ?? "redis://localhost:6379";

console.log(`🔌 Initializing Redis Client targeting: ${redisUrl}`);

const redis = new Redis(redisUrl, {
  // Set connection attempt limits to prevent endless hanging under downtime
  maxRetriesPerRequest: 3,
  connectTimeout: 5000, // 5s connection timeout
  // Fallback retry strategy for reconnection
  retryStrategy(times) {
    const delay = Math.min(times * 100, 3000);
    return delay;
  },
});

// Event listeners for robust logging and connection monitoring
redis.on("connect", () => {
  console.log("🟢 Redis: Connecting to server...");
});

redis.on("ready", () => {
  console.log("🟢 Redis: Connection ready and client initialized.");
});

redis.on("error", (err: unknown) => {
  const errMsg = err instanceof Error ? err.message : String(err);
  console.error("🔴 Redis Error:", errMsg);
});

redis.on("close", () => {
  console.warn("🟡 Redis: Connection closed.");
});

redis.on("reconnecting", () => {
  console.warn("🟡 Redis: Reconnecting to server...");
});

redis.on("end", () => {
  console.error("🔴 Redis: Reconnection attempts exhausted, connection closed permanently.");
});

/**
 * Checks if Redis is currently connected and ready to process commands.
 * This is used for instantaneous fail-safe bypass without command queuing overhead.
 */
export function isRedisReady(): boolean {
  return redis.status === "ready";
}

export default redis;
