// ============================================================
//  src/services/redis.service.ts
//  Redis Client Singleton — gracefully optional (no-op when offline)
// ============================================================

import Redis from "ioredis";

const rawRedisUrl = process.env.REDIS_URL;
const isRedisConfigured = !!rawRedisUrl && rawRedisUrl !== "none" && rawRedisUrl !== "disabled";
const redisUrl = isRedisConfigured ? rawRedisUrl : "redis://localhost:6379";
const isTls = isRedisConfigured && redisUrl.startsWith("rediss://");

let isReady = false;

let redis: Redis;

if (isRedisConfigured) {
  console.log(`🔌 Initializing Redis Client (TLS: ${isTls})`);

  redis = new Redis(redisUrl, {
    lazyConnect: true,
    maxRetriesPerRequest: 1,
    connectTimeout: 5000,
    tls: isTls ? { rejectUnauthorized: false } : undefined,
    retryStrategy(times) {
      if (times > 2) {
        console.warn("⚠️  [Redis] Max retries reached — Redis offline. API continues normally without caching.");
        return null; // stop reconnect loop
      }
      return 1000;
    },
  });

  redis.on("connect", () => console.log("🟢 Redis: Connecting to server..."));
  redis.on("ready", () => {
    isReady = true;
    console.log("🟢 Redis: Connection ready.");
  });
  redis.on("error", (err: unknown) => {
    isReady = false;
    const msg = err instanceof Error ? err.message : String(err);
    if (!msg.includes("ECONNREFUSED") && !msg.includes("ETIMEDOUT")) {
      console.error("🔴 Redis Error:", msg);
    }
  });
  redis.on("close", () => {
    isReady = false;
  });
  redis.on("end", () => {
    isReady = false;
  });

  redis.connect().catch(() => {
    isReady = false;
    console.warn("⚠️  [Redis] Could not connect. Redis caching disabled; core API continues normally.");
  });
} else {
  console.log("ℹ️  [Redis] No REDIS_URL configured — caching disabled; core API running normally.");
  // Dummy instance with no-op lazy connection
  redis = new Redis({ lazyConnect: true, enableOfflineQueue: false });
}

/**
 * Checks if Redis is currently connected and ready to process commands.
 */
export function isRedisReady(): boolean {
  return isReady;
}

export default redis;
