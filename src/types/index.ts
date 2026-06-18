// ============================================================
//  src/types/index.ts
//  Shared types, request/response DTOs, and domain models
// ============================================================

export interface CalculateNutritionRequest {
  restaurantName: string;
  restaurantCategory?: string;
  itemName: string;
  itemDescription?: string;
  addOns?: string[];
}

export interface BatchCalculateRequest {
  items: Array<{
    restaurantName: string;
    restaurantCategory?: string;
    itemName: string;
    itemDescription?: string;
    addOns?: string[];
  }>;
}

export interface MacroRange {
  min: number;
  max: number;
}

export interface AddOnMacros {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
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
  addOns?: AddOnMacros[];
  calories?: MacroRange;
  protein?: MacroRange;
  carbs?: MacroRange;
  fats?: MacroRange;
}

export interface BatchCalculateResponse {
  success: boolean;
  totalRequested: number;
  totalProcessed: number;
  results: Array<{
    requested: {
      restaurantName: string;
      itemName: string;
      addOns?: string[];
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
  totalCachedAddOns: number;
  restaurants: Array<{
    id: string;
    name: string;
    category: string;
    itemCount: number;
    addOnCount: number;
    createdAt: Date;
  }>;
  companyUsage?: {
    companyId: string;
    companyName: string;
    currentMonth: string;
    limit: number;
    used: number;
    remaining: number;
  };
}

export interface PurgeResponse {
  success: boolean;
  restaurantName: string;
  itemsPurged: number;
  addOnsPurged: number;
}

export interface ErrorResponse {
  success: false;
  error: string;
  code?: string;
  timestamp: Date;
}

export enum ErrorCode {
  VALIDATION_ERROR = "VALIDATION_ERROR",
  RESTAURANT_NOT_FOUND = "RESTAURANT_NOT_FOUND",
  ITEM_NOT_FOUND = "ITEM_NOT_FOUND",
  GEMINI_ERROR = "GEMINI_ERROR",
  DATABASE_ERROR = "DATABASE_ERROR",
  RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED",
}

/** Flat macro range fields used by Prisma / Gemini base item */
export interface BaseItemMacroFields {
  caloriesMin: number;
  caloriesMax: number;
  proteinMin: number;
  proteinMax: number;
  carbsMin: number;
  carbsMax: number;
  fatsMin: number;
  fatsMax: number;
}

declare global {
  namespace Express {
    interface Request {
      company?: {
        id: string;
        name: string;
      };
      companyUsage?: number;
    }
  }
}

