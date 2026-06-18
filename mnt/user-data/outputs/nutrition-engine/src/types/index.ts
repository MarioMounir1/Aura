// ============================================================
//  src/types/index.ts
//  Shared types, request/response DTOs, and domain models
// ============================================================

// ── Request DTOs ───────────────────────────────────────────────────
export interface CalculateNutritionRequest {
  restaurantName: string;
  restaurantCategory?: string;
  itemName: string;
}

export interface BatchCalculateRequest {
  items: Array<{
    restaurantName: string;
    restaurantCategory?: string;
    itemName: string;
  }>;
}

// ── Response DTOs ──────────────────────────────────────────────────
export interface MacroRange {
  min: number;
  max: number;
}

export interface NutritionData {
  id: string;
  name: string;
  calories: MacroRange;
  protein: MacroRange;
  carbs: MacroRange;
  fats: MacroRange;
  cachedAt: Date;
}

export interface RestaurantInfo {
  id: string;
  name: string;
  category: string;
}

export interface CalculateNutritionResponse {
  success: boolean;
  source: "cache" | "ai_generated";
  restaurant: RestaurantInfo;
  item: NutritionData;
}

export interface BatchCalculateResponse {
  success: boolean;
  totalRequested: number;
  totalProcessed: number;
  results: Array<{
    requested: {
      restaurantName: string;
      itemName: string;
    };
    result: CalculateNutritionResponse | null;
    error?: string;
  }>;
  summary: {
    cacheHits: number;
    aiGenerated: number;
    failed: number;
  };
}

export interface CacheStatsResponse {
  success: boolean;
  totalRestaurants: number;
  totalCachedItems: number;
  restaurants: Array<{
    id: string;
    name: string;
    category: string;
    itemCount: number;
    createdAt: Date;
  }>;
}

export interface PurgeResponse {
  success: boolean;
  restaurantName: string;
  itemsPurged: number;
}

export interface ErrorResponse {
  success: false;
  error: string;
  code?: string;
  timestamp: Date;
}

// ── Domain Models ──────────────────────────────────────────────────
export interface CacheEntry {
  restaurantId: string;
  itemName: string;
  macros: MacroRange & {
    protein: MacroRange;
    carbs: MacroRange;
    fats: MacroRange;
  };
  createdAt: Date;
}

export enum ErrorCode {
  VALIDATION_ERROR = "VALIDATION_ERROR",
  RESTAURANT_NOT_FOUND = "RESTAURANT_NOT_FOUND",
  ITEM_NOT_FOUND = "ITEM_NOT_FOUND",
  GEMINI_ERROR = "GEMINI_ERROR",
  DATABASE_ERROR = "DATABASE_ERROR",
  RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED",
}
