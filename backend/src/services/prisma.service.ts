// ============================================================
//  src/services/prisma.service.ts
//  Singleton Prisma client with pg.Pool adapter (Prisma 7 compatible)
// ============================================================

import "dotenv/config";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";

const connectionString = process.env.DATABASE_URL;

const isProduction =
  process.env.NODE_ENV === "production" ||
  connectionString?.includes("sslmode=") ||
  connectionString?.includes("render.com");

const pool = new Pool({
  connectionString,
  ssl: isProduction ? { rejectUnauthorized: false } : false,
});
const adapter = new PrismaPg(pool);

declare global {
  var __prisma: PrismaClient | undefined;
}

const prisma: PrismaClient =
  global.__prisma ??
  new PrismaClient({
    adapter,
    log:
      process.env.NODE_ENV === "development"
        ? ["query", "warn", "error"]
        : ["error"],
  });

if (process.env.NODE_ENV !== "production") {
  global.__prisma = prisma;
}

export default prisma;
