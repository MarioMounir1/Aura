// ============================================================
//  src/services/redis.service.ts
//  Redis Client Singleton — gracefully optional (no-op when offline)
// ============================================================

import Redis from "ioredis";

const redisUrl = process.env.REDIS_URL ?? "redis://localhost:6379";

console.log(`🔌 Initializing Redis Client targeting: ${redisUrl}`);

const redis = new Redis(redisUrl, {
  // Connect lazily — don't attempt connection at module load time
  lazyConnect: true,
  // Limit retries so Redis being offline doesn't flood the console
  maxRetriesPerRequest: 1,
  connectTimeout: 3000,
  // Return null (no retry) so the process keeps running when Redis is down
  retryStrategy(times) {
    if (times > 3) {
      console.warn("⚠️  [Redis] Max retries reached — Redis is offline. API continues without caching.");
      return null; // stop retrying
    }
    return Math.min(times * 500, 2000);
  },
});

// Event listeners for connection monitoring
redis.on("connect",     () => console.log("🟢 Redis: Connecting to server..."));
redis.on("ready",       () => console.log("🟢 Redis: Connection ready."));
redis.on("error",       (err: unknown) => {
  // Suppress repeated ECONNREFUSED noise — log once at warn level
  const msg = err instanceof Error ? err.message : String(err);
  if (!msg.includes("ECONNREFUSED")) {
    console.error("🔴 Redis Error:", msg);
  }
});
redis.on("close",       () => console.warn("🟡 Redis: Connection closed."));
redis.on("reconnecting",() => console.warn("🟡 Redis: Reconnecting..."));
redis.on("end",         () => console.warn("⚠️  Redis: Connection ended permanently. Caching disabled."));

// Attempt connection in background — server starts regardless
redis.connect().catch(() => {
  console.warn("⚠️  [Redis] Could not connect. Redis caching is disabled; core API still works.");
});

/**
 * Checks if Redis is currently connected and ready to process commands.
 */
export function isRedisReady(): boolean {
  return redis.status === "ready";
}

export default redis;
