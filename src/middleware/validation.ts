// ============================================================
//  src/middleware/validation.ts
//  Input validation and error handling
// ============================================================

import { Request, Response, NextFunction } from "express";
import { ErrorResponse, ErrorCode } from "../types";

export class AppError extends Error {
  constructor(
    public message: string,
    public code: ErrorCode,
    public statusCode: number = 400
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export function validateCalculateRequest(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const { restaurantName, itemName } = req.body;

  if (!restaurantName || typeof restaurantName !== "string") {
    res.status(400).json({
      success: false,
      error: "restaurantName is required and must be a non-empty string",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  if (!itemName || typeof itemName !== "string") {
    res.status(400).json({
      success: false,
      error: "itemName is required and must be a non-empty string",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  if (restaurantName.trim().length === 0 || itemName.trim().length === 0) {
    res.status(400).json({
      success: false,
      error: "restaurantName and itemName cannot be empty or whitespace-only",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  const { addOns } = req.body;
  if (addOns !== undefined) {
    if (!Array.isArray(addOns)) {
      res.status(400).json({
        success: false,
        error: "addOns must be an array of strings when provided",
        code: ErrorCode.VALIDATION_ERROR,
        timestamp: new Date(),
      } as ErrorResponse);
      return;
    }
    for (let i = 0; i < addOns.length; i++) {
      if (typeof addOns[i] !== "string" || addOns[i].trim().length === 0) {
        res.status(400).json({
          success: false,
          error: `addOns[${i}] must be a non-empty string`,
          code: ErrorCode.VALIDATION_ERROR,
          timestamp: new Date(),
        } as ErrorResponse);
        return;
      }
    }
  }

  next();
}

export function validateB2BRequest(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const { item_name } = req.body;

  if (!item_name || typeof item_name !== "string") {
    res.status(400).json({
      success: false,
      error: "item_name is required and must be a non-empty string",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  if (item_name.trim().length === 0) {
    res.status(400).json({
      success: false,
      error: "item_name cannot be empty or whitespace-only",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  const { customizations } = req.body;
  if (customizations !== undefined) {
    if (!Array.isArray(customizations)) {
      res.status(400).json({
        success: false,
        error: "customizations must be an array of strings when provided",
        code: ErrorCode.VALIDATION_ERROR,
        timestamp: new Date(),
      } as ErrorResponse);
      return;
    }
    for (let i = 0; i < customizations.length; i++) {
      if (typeof customizations[i] !== "string" || customizations[i].trim().length === 0) {
        res.status(400).json({
          success: false,
          error: `customizations[${i}] must be a non-empty string`,
          code: ErrorCode.VALIDATION_ERROR,
          timestamp: new Date(),
        } as ErrorResponse);
        return;
      }
    }
  }

  next();
}

export function validateBatchRequest(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const { items } = req.body;

  if (!Array.isArray(items)) {
    res.status(400).json({
      success: false,
      error: "items must be an array",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  if (items.length === 0) {
    res.status(400).json({
      success: false,
      error: "items array cannot be empty",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  if (items.length > 50) {
    res.status(400).json({
      success: false,
      error: "items array cannot exceed 50 items per batch",
      code: ErrorCode.VALIDATION_ERROR,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    if (!item.restaurantName || !item.itemName) {
      res.status(400).json({
        success: false,
        error: `Item at index ${i} is missing restaurantName or itemName`,
        code: ErrorCode.VALIDATION_ERROR,
        timestamp: new Date(),
      } as ErrorResponse);
      return;
    }
    if (item.addOns !== undefined) {
      if (!Array.isArray(item.addOns)) {
        res.status(400).json({
          success: false,
          error: `Item at index ${i}: addOns must be an array of strings`,
          code: ErrorCode.VALIDATION_ERROR,
          timestamp: new Date(),
        } as ErrorResponse);
        return;
      }
      for (let j = 0; j < item.addOns.length; j++) {
        if (typeof item.addOns[j] !== "string" || item.addOns[j].trim().length === 0) {
          res.status(400).json({
            success: false,
            error: `Item at index ${i}, addOns[${j}] must be a non-empty string`,
            code: ErrorCode.VALIDATION_ERROR,
            timestamp: new Date(),
          } as ErrorResponse);
          return;
        }
      }
    }
  }

  next();
}

export function errorHandler(
  err: Error | AppError,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  console.error("🔴  Error:", err.message);

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      error: err.message,
      code: err.code,
      timestamp: new Date(),
    } as ErrorResponse);
    return;
  }

  res.status(500).json({
    success: false,
    error: "Internal server error",
    code: ErrorCode.DATABASE_ERROR,
    timestamp: new Date(),
  } as ErrorResponse);
}
