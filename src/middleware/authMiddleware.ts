// ============================================================
//  src/middleware/authMiddleware.ts
//  API Key Authentication middleware
// ============================================================

import { Request, Response, NextFunction } from "express";
import prisma from "../services/prisma.service";

export async function validateApiKey(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const apiKey = req.headers["x-api-key"];

    if (!apiKey || typeof apiKey !== "string") {
      res.status(401).json({
        success: false,
        message: "Access Denied: Missing API Key.",
      });
      return;
    }

    const company = await prisma.company.findUnique({
      where: { apiKey },
    });

    if (!company || !company.isActive) {
      res.status(403).json({
        success: false,
        message: "Forbidden: Invalid or Inactive API Key.",
      });
      return;
    }

    req.company = {
      id: company.id,
      name: company.name,
    };

    next();
  } catch (error) {
    console.error("API Key validation error:", error);
    res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
}
