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

// ── Google Play Legal Compliance Pages ─────────────────────

app.get("/privacy-policy", (_req: Request, res: Response) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Privacy Policy — Aura</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #1C2B1E; background: #F6F8F5; margin: 0; padding: 24px; }
    .container { max-width: 800px; margin: 0 auto; background: #FFFFFF; padding: 36px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); }
    h1 { color: #16382B; font-size: 28px; margin-top: 0; }
    h2 { color: #235A42; font-size: 20px; margin-top: 24px; border-bottom: 1px solid #E2EBE4; padding-bottom: 6px; }
    p, li { color: #374151; font-size: 15px; }
    ul { padding-left: 20px; }
    .footer { margin-top: 32px; font-size: 13px; color: #6B7280; border-top: 1px solid #E2EBE4; padding-top: 16px; }
    .badge { display: inline-block; background: #EAF5EE; color: #235A42; padding: 4px 10px; border-radius: 20px; font-size: 13px; font-weight: 600; margin-bottom: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <span class="badge">Aura — Nutrition & Fitness</span>
    <h1>Privacy Policy</h1>
    <p><strong>Effective Date:</strong> September 18, 2026</p>
    <p>Aura ("we", "our", or "us") is dedicated to protecting your privacy. This Privacy Policy describes how the Aura mobile application collects, uses, and safeguards your information.</p>
    
    <h2>1. Information We Collect</h2>
    <ul>
      <li><strong>Account Information:</strong> Email address, name, and profile credentials when you register or sign in via Google or Apple OAuth.</li>
      <li><strong>Health & Fitness Data:</strong> Calories, macronutrients, body weight, water intake, and workout logs you provide.</li>
      <li><strong>Camera & Meal Photos:</strong> When you use our AI meal scanner, food photos are transmitted securely to estimate nutrition. Photos are processed in real-time and are never sold or used for public training.</li>
    </ul>

    <h2>2. How We Use Your Information</h2>
    <ul>
      <li>Calculate personalized metabolic goals (TDEE, daily calorie and macro targets).</li>
      <li>Provide workout routines, tracking, and nutritional analytics.</li>
      <li>Maintain account authentication and cross-device sync.</li>
      <li>We <strong>DO NOT</strong> sell, rent, or trade your personal or health data to advertisers or third parties.</li>
    </ul>

    <h2>3. Third-Party Services</h2>
    <ul>
      <li><strong>Google Firebase:</strong> Used for secure user authentication and crash reporting.</li>
      <li><strong>RevenueCat:</strong> Manages in-app subscriptions and purchase receipts.</li>
      <li><strong>Google AI (Gemini):</strong> Powers real-time nutritional estimation for meal photos.</li>
    </ul>

    <h2>4. Data Retention & Deletion</h2>
    <p>We store your data only as long as your account remains active. You can request full account and data deletion at any time via the app or through our <a href="/delete-account" style="color: #235A42; font-weight: 600;">Account Deletion Page</a>.</p>

    <h2>5. Contact Us</h2>
    <p>If you have questions about this policy, contact our developer support team at: <a href="mailto:maryomoner58@gmail.com" style="color: #235A42;">maryomoner58@gmail.com</a>.</p>
    
    <div class="footer">
      &copy; 2026 Aura. Developed by Mario Mounir. All rights reserved.
    </div>
  </div>
</body>
</html>`);
});

app.get("/delete-account", (_req: Request, res: Response) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Delete Account & Data — Aura</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #1C2B1E; background: #F6F8F5; margin: 0; padding: 24px; }
    .container { max-width: 800px; margin: 0 auto; background: #FFFFFF; padding: 36px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); }
    h1 { color: #991B1B; font-size: 26px; margin-top: 0; }
    h2 { color: #16382B; font-size: 19px; margin-top: 24px; border-bottom: 1px solid #E2EBE4; padding-bottom: 6px; }
    p, li { color: #374151; font-size: 15px; }
    ol, ul { padding-left: 20px; }
    .card { background: #FEF2F2; border-left: 4px solid #EF4444; padding: 16px; border-radius: 6px; margin: 20px 0; }
    .footer { margin-top: 32px; font-size: 13px; color: #6B7280; border-top: 1px solid #E2EBE4; padding-top: 16px; }
    .btn { display: inline-block; background: #991B1B; color: #FFFFFF; text-decoration: none; padding: 10px 20px; border-radius: 8px; font-weight: 600; margin-top: 8px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Aura — Account & Data Deletion Request</h1>
    <p>In accordance with Google Play and Apple App Store data safety requirements, Aura provides users with full control over their account and personal data.</p>
    
    <div class="card">
      <p style="margin: 0; color: #991B1B; font-weight: 600;">⚠️ Notice: Account deletion is permanent and cannot be undone.</p>
    </div>

    <h2>How to Request Account & Data Deletion</h2>
    
    <h3>Method 1: In-App Deletion (Instant)</h3>
    <ol>
      <li>Open the <strong>Aura</strong> app on your device.</li>
      <li>Go to your <strong>Profile</strong> screen (bottom navigation bar).</li>
      <li>Tap <strong>Account Settings</strong>.</li>
      <li>Tap <strong>Delete Account</strong> and confirm. Your account will be closed immediately.</li>
    </ol>

    <h3>Method 2: Email Request (Web)</h3>
    <p>If you have uninstalled the app or cannot access your device, you can submit a manual deletion request by sending an email from your registered email address:</p>
    <p>
      <strong>Email:</strong> <a href="mailto:maryomoner58@gmail.com?subject=Aura%20Account%20Deletion%20Request">maryomoner58@gmail.com</a><br />
      <strong>Subject:</strong> <code>Aura Account Deletion Request</code><br />
      <strong>Message details:</strong> Please specify your registered email address and name.
    </p>

    <h2>What Data Is Deleted?</h2>
    <ul>
      <li>Your user profile (Name, email address, password hash, demographic profile).</li>
      <li>All logged nutrition data, meal history, food photos, and calorie records.</li>
      <li>All logged workouts, exercises, weight records, and water tracking history.</li>
      <li>All authentication tokens and device identifiers.</li>
    </ul>

    <h2>Data Retention Period</h2>
    <p>Upon submitting an account deletion request, your data is immediately deactivated and rendered inaccessible. Complete removal from database backups occurs within <strong>30 days</strong>.</p>

    <div class="footer">
      App: <strong>Aura</strong> &bull; Developer: <strong>Mario Mounir</strong> &bull; Contact: <a href="mailto:maryomoner58@gmail.com">maryomoner58@gmail.com</a>
    </div>
  </div>
</body>
</html>`);
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
  // Synchronize Prisma schema in development only.
  // In production, migrations should be applied via `prisma migrate deploy` in your deploy pipeline.
  if (process.env.NODE_ENV === "development") {
    try {
      console.log("🔄 Synchronizing Prisma database tables (development)...");
      const rootDir = process.cwd();
      execSync(`npx prisma db push`, {
        cwd: rootDir,
        env: { ...process.env },
        stdio: "inherit",
      });
      console.log("✅ Database tables synchronized successfully!");
    } catch (dbErr: any) {
      console.error("⚠️ Prisma db push failed:", dbErr?.message || dbErr);
    }
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
