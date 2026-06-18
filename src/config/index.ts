// ============================================================
//  src/config/index.ts
//  Centralized app configuration and constants
// ============================================================

export const RESTAURANT_CATEGORIES: Record<string, string> = {
  "buffalo burger":     "fast-food",
  "buffalo burgers":    "fast-food",
  "mcdonald's":         "fast-food",
  "mcdonalds":          "fast-food",
  "kfc":                "fast-food",
  "hardee's":           "fast-food",
  "hardees":            "fast-food",
  "popeyes":            "fast-food",
  "cook door":          "fast-food",
  "mo'men":             "fast-food",
  "gad":                "fast-food",
  "burger king":        "fast-food",
  "subway":             "fast-food",
  "abou tarek":         "koshary",
  "koshary el tahrir":  "koshary",
  "kazouza":            "koshary",
  "koshary":            "koshary",
  "arab":               "grills",
  "kababgy":            "grills",
};

export const DEFAULT_RESTAURANT_CATEGORY = "restaurant";

export const BATCH_LIMITS = {
  maxItemsPerBatch: 50,
  timeoutMs:        300000,
};

export const OLLAMA_CONFIG = {
  baseUrl:              process.env.OLLAMA_BASE_URL ?? "http://127.0.0.1:11434",
  model:                process.env.OLLAMA_MODEL ?? "llama3",
  temperature:          0.1,
};

export const GEMINI_CONFIG = {
  model:                process.env.GEMINI_MODEL ?? "gemini-2.5-flash",
  temperature:          0.1,
  topP:                 0.95,
  topK:                 40,
};

export const MACRO_BOUNDS = {
  calories: { min: 10, max: 5000 },
  protein:  { min: 0, max: 500 },
  carbs:    { min: 0, max: 500 },
  fats:     { min: 0, max: 500 },
};

export const CACHE_TTL_DAYS = null;

export const LOG_LEVELS = {
  development: ["query", "warn", "error"],
  production:  ["error"],
};

export const ERROR_MESSAGES = {
  MISSING_RESTAURANT_NAME: "restaurantName is required and must be a non-empty string",
  MISSING_ITEM_NAME:       "itemName is required and must be a non-empty string",
  EMPTY_BATCH:             "items array cannot be empty",
  BATCH_TOO_LARGE:         `items array cannot exceed ${BATCH_LIMITS.maxItemsPerBatch} items per batch`,
  GEMINI_PARSE_ERROR:      "Gemini returned invalid JSON response",
  INVALID_MACRO_RANGE:     "Invalid macro range returned (min > max)",
  DATABASE_ERROR:          "Database operation failed",
};

export const SUCCESS_MESSAGES = {
  CALCULATION_COMPLETE: "Nutrition calculation complete",
  CACHE_PURGED:         "Cache purged successfully",
  CACHE_RESET:          "Cache reset successfully",
};

export function inferRestaurantCategory(
  restaurantName: string,
  overrideCategory?: string
): string {
  if (overrideCategory) {
    return overrideCategory.toLowerCase();
  }

  const normalized = restaurantName.toLowerCase().trim();
  return RESTAURANT_CATEGORIES[normalized] ?? DEFAULT_RESTAURANT_CATEGORY;
}
