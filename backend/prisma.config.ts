import "dotenv/config";
import { defineConfig, env } from "prisma/config";

const databaseUrl =
  process.env.DATABASE_URL ||
  process.env.POSTGRES_URL ||
  process.env.DATABASE_PRIVATE_URL ||
  process.env.RENDER_DATABASE_URL ||
  env("DATABASE_URL");

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: "ts-node prisma/seed.ts",
  },
  datasource: {
    url: databaseUrl,
  },
});
