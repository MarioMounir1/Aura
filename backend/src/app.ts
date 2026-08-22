// ============================================================
//  src/app.ts
//  Aura — Express entry point
//  Registers both existing /api/nutrition AND new /api/v1 routes
// ============================================================

import dotenv from 'dotenv';
dotenv.config();

import path from 'path';
import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import v1Router from './routes/v1.routes';
import { errorHandler } from "./middleware/validation";
import prisma from "./services/prisma.service";
import { execSync } from "child_process";

const app = express();
const PORT = process.env.PORT ?? 3000;

// ── Global Middleware ──────────────────────────────────────

app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Request Logger ─────────────────────────────────────────

app.use((req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - startTime;
    console.log(
      `📊  ${req.method.padEnd(6)} ${req.originalUrl.padEnd(40)} ${res.statusCode} (${duration}ms)`
    );
  });
  next();
});

// ── Health Check ───────────────────────────────────────────

app.get("/health", (_req: Request, res: Response) => {
  res.json({
    status: "ok",
    version: "2.0.0",
    engine: "Aura AI Nutrition Engine",
    timestamp: new Date().toISOString(),
  });
});

// ── Routes ─────────────────────────────────────────────────

// New: Mobile App API (v1)
app.use("/api/v1", v1Router);

// ── 404 Handler ────────────────────────────────────────────

app.use((_req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: "Endpoint not found",
    timestamp: new Date().toISOString(),
  });
});

// ── Global Error Handler ───────────────────────────────────

app.use(errorHandler);

if (process.env.NODE_ENV !== "test") {
  try {
    console.log("🔄 Synchronizing Prisma database tables...");
    const rootDir = process.cwd();
    execSync(`npx prisma db push --accept-data-loss`, {
      cwd: rootDir,
      env: { ...process.env },
      stdio: "inherit",
    });
    console.log("✅ Database tables synchronized successfully!");
  } catch (dbErr: any) {
    console.error("⚠️ Prisma db push failed:", dbErr?.message || dbErr);
  }

  app.listen(Number(PORT), "0.0.0.0", () => {
    console.log(`🚀  Aura API running on http://0.0.0.0:${PORT}`);
    console.log(`📱  Mobile API (v1):`);
    console.log(`   Auth:     POST /api/v1/auth/register`);
    console.log(`   Auth:     POST /api/v1/auth/login`);
    console.log(`   Profile:  GET  /api/v1/users/me`);
    console.log(`   Analyze:  POST /api/v1/meals/analyze`);
    console.log(`   History:  GET  /api/v1/meals/history`);
    console.log(`🔧  Legacy API: none`);
  });
}

export default app;
