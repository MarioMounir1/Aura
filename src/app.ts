// ============================================================
//  src/app.ts
//  Express entry point (moved to `src/`)
// ============================================================

import dotenv from 'dotenv';
dotenv.config();

import express, { Request, Response, NextFunction }  from "express";
import cors from "cors";
import nutritionRouter from './routes/nutrition.routes';
import { errorHandler } from "./middleware/validation";
import "./services/worker";
import prisma from "./services/prisma.service";


const app  = express();
const PORT = process.env.PORT ?? 3000;

app.use(cors({ origin: '*' }));
app.use(express.json());

app.use((req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - startTime;
    console.log(
      `📊  ${req.method.padEnd(6)} ${req.originalUrl.padEnd(30)} ${res.statusCode} (${duration}ms)`
    );
  });
  next();
});


app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "ok", engine: "Autonomous AI Nutrition Engine" });
});

app.use("/api/nutrition", nutritionRouter);

app.use((_req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: "Endpoint not found",
    timestamp: new Date(),
  });
});

app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`🚀  Nutrition Engine running on http://localhost:${PORT}`);
  console.log(`📚  API Documentation:`);
  console.log(`   Single:  POST /api/nutrition/calculate`);
  console.log(`   Batch:   POST /api/nutrition/batch`);
  console.log(`   Stats:   GET  /api/nutrition/cache/stats`);
  console.log(`   Purge:   DELETE /api/nutrition/cache/:restaurantName`);
});
async function bootstrapApiKey() {
  try {
    await prisma.company.upsert({
      where: { apiKey: 'talabat_test_key_123' },
      update: {},
      create: {
        id: '1', // هيديك ID صريح عشان الـ DB ترضى بيه
        name: 'Talabat',
        apiKey: 'talabat_test_key_123',
      },
    });
    console.log('🚀 [Database] Production API Key Synchronized.');
  } catch (err) {
    console.error('❌ [Database] Failed to sync API key:', err);
  }
}
bootstrapApiKey();

export default app;
