// ============================================================
//  Shared base-item + add-on cache / Gemini orchestration
// ============================================================

import type { CachedAddOn, CachedMenuItem, Restaurant } from "@prisma/client";
import prisma from "./prisma.service";
import { OllamaNutritionService } from "./ollama.service";
import { GeminiNutritionService } from "./gemini.service";
import { GeminiNutritionService as MockOllamaService } from "./gemini.mock";
import {
  AddOnMacros,
  BaseItemMacroFields,
  CalculateNutritionResponse,
  MacroRange,
} from "../types";

const aiService =
  process.env.GEMINI_MOCK === "true"
    ? new MockOllamaService()
    : process.env.AI_PROVIDER === "google"
    ? new GeminiNutritionService()
    : new OllamaNutritionService();

export function normalizeAddOns(addOns?: string[]): string[] {
  if (!addOns || !Array.isArray(addOns)) return [];
  
  const splitParts = addOns
    .flatMap((c) => (typeof c === "string" ? c.split(",") : []))
    .map((c) => c.trim())
    .filter(Boolean)
    .sort(); // Alphabetical sort ensures order-independence

  const seen = new Set<string>();
  const out: string[] = [];
  for (const part of splitParts) {
    const key = part.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(part);
  }
  return out;
}

function parseSizeMultiplierFromString(sizeText: string, contextName: string): number {
  const lower = sizeText.toLowerCase().replace(/_/g, " ");
  const contextLower = contextName.toLowerCase().replace(/_/g, " ");

  // 1. Explicit weight/volume
  const weightMatches = [...lower.matchAll(/(\d+(?:\.\d+)?)\s*(kg|gm|g|ml|l|oz|lb)(?:\b|$)/g)];
  if (weightMatches.length > 0) {
    const weightMatch = weightMatches[weightMatches.length - 1];
    const value = parseFloat(weightMatch[1]);
    const unit  = weightMatch[2];

    let grams = value;
    if (unit === "kg") grams = value * 1000;
    if (unit === "oz") grams = value * 28.35;
    if (unit === "lb") grams = value * 453.6;
    if (unit === "l")  grams = value * 1000;

    const isLiquid  = unit === "ml" || unit === "l";
    const isDrink   = contextLower.includes("juice") || contextLower.includes("drink") ||
                      contextLower.includes("water") || contextLower.includes("coffee") ||
                      contextLower.includes("tea") || contextLower.includes("soda");
    const basePortion = (isLiquid || isDrink) ? 330 : 250;

    return Math.max(0.3, Math.min(grams / basePortion, 6.0));
  }

  // 2. Named sizes
  const SIZE_MULTIPLIERS: Record<string, number> = {
    "mini":         0.5,
    "xs":           0.6,
    "extra small":  0.6,
    "small":        0.75,
    "s":            0.75,
    "regular":      1.0,
    "normal":       1.0,
    "standard":     1.0,
    "medium":       1.0,
    "m":            1.0,
    "large":        1.35,
    "l":            1.35,
    "big":          1.35,
    "extra large":  1.7,
    "xl":           1.7,
    "xxl":          2.0,
    "double":       2.0,
    "triple":       3.0,
    "family":       4.0,
    "sharing":      3.5,
    "صغير":         0.75,
    "وسط":          1.0,
    "متوسط":        1.0,
    "كبير":         1.35,
    "اكسترا":       1.7,
  };

  for (const [keyword, multiplier] of Object.entries(SIZE_MULTIPLIERS)) {
    const escapedKw = keyword.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`\\b${escapedKw}\\b`, "i");
    if (regex.test(lower)) {
      return multiplier;
    }
  }

  return 1.0;
}

function cleanItemNameAndExtractSize(itemName: string): { cleanName: string, multiplier: number, sizeStr: string } {
  const sizeRegex = /\s*\(([^)]+)\)\s*$/;
  const match = itemName.match(sizeRegex);
  
  let cleanName = itemName;
  let sizeStr = "";
  let multiplier = 1.0;
  
  if (match) {
    sizeStr = match[1];
    cleanName = itemName.replace(sizeRegex, "").trim();
    multiplier = parseSizeMultiplierFromString(sizeStr, cleanName);
  } else {
    multiplier = parseSizeMultiplierFromString(itemName, itemName);
  }
  
  return { cleanName, multiplier, sizeStr };
}

function itemToNutritionData(cached: CachedMenuItem, rawItemName: string, multiplier: number) {
  return {
    id:       cached.id,
    name:     rawItemName,
    calories: { min: Math.round(cached.caloriesMin * multiplier), max: Math.round(cached.caloriesMax * multiplier) },
    protein:  { min: Math.round(cached.proteinMin * multiplier),  max: Math.round(cached.proteinMax * multiplier)  },
    carbs:    { min: Math.round(cached.carbsMin * multiplier),    max: Math.round(cached.carbsMax * multiplier)    },
    fats:     { min: Math.round(cached.fatsMin * multiplier),     max: Math.round(cached.fatsMax * multiplier)     },
    cachedAt: cached.createdAt,
  };
}

function cachedAddOnToMacros(cached: CachedAddOn): AddOnMacros {
  return {
    name:     cached.addOnName,
    calories: cached.calories,
    protein:  cached.protein,
    carbs:    cached.carbs,
    fats:     cached.fats,
  };
}

function calculateFinalMacros(
  itemName: string,
  baseItem: {
    caloriesMin: number;
    caloriesMax: number;
    proteinMin: number;
    proteinMax: number;
    carbsMin: number;
    carbsMax: number;
    fatsMin: number;
    fatsMax: number;
  },
  addOns: AddOnMacros[] = []
) {
  // Calculate base values (averaging out the min/max ranges from backend)
  const baseCal = (baseItem.caloriesMin + baseItem.caloriesMax) / 2;
  const baseProt = (baseItem.proteinMin + baseItem.proteinMax) / 2;
  const baseCarbs = (baseItem.carbsMin + baseItem.carbsMax) / 2;
  const baseFat = (baseItem.fatsMin + baseItem.fatsMax) / 2;

  // Determine margin based on categorization of the itemName (baseName)
  const nameToCheck = itemName.toLowerCase();
  let margin = 0.03; // Default 3% margin for general items to keep ranges tight
  if (
    nameToCheck.includes("burger") ||
    nameToCheck.includes("sandwich") ||
    nameToCheck.includes("fried") ||
    nameToCheck.includes("pizza")
  ) {
    margin = 0.05; // 5% margin for fast food
  } else if (
    nameToCheck.includes("grilled") ||
    nameToCheck.includes("steak") ||
    nameToCheck.includes("kebab") ||
    nameToCheck.includes("shiitake")
  ) {
    margin = 0.02; // 2% margin for clean whole foods
  }

  // Sum values with all selected extras/addOns (static: 0% margin)
  let addOnCalories = 0;
  let addOnProtein = 0;
  let addOnCarbs = 0;
  let addOnFats = 0;

  for (const addOn of addOns) {
    addOnCalories += addOn.calories || 0;
    addOnProtein += addOn.protein || 0;
    addOnCarbs += addOn.carbs || 0;
    addOnFats += addOn.fats || 0;
  }

  // Detect combo/meal in the raw item name and add typical combo macros (Fries + Drink)
  const lowerItemName = itemName.toLowerCase();
  const isCombo = lowerItemName.includes("combo") || 
                  lowerItemName.includes("meal") || 
                  lowerItemName.includes("وجب");
  if (isCombo) {
    addOnCalories += 500;
    addOnProtein  += 4;
    addOnCarbs    += 85;
    addOnFats     += 16;
  }

  return {
    calories: {
      min: Math.floor(baseCal * (1 - margin)) + addOnCalories,
      max: Math.ceil(baseCal * (1 + margin)) + addOnCalories
    },
    protein: {
      min: Math.floor(baseProt * (1 - margin)) + addOnProtein,
      max: Math.ceil(baseProt * (1 + margin)) + addOnProtein
    },
    carbs: {
      min: Math.floor(baseCarbs * (1 - margin)) + addOnCarbs,
      max: Math.ceil(baseCarbs * (1 + margin)) + addOnCarbs
    },
    fats: {
      min: Math.floor(baseFat * (1 - margin)) + addOnFats,
      max: Math.ceil(baseFat * (1 + margin)) + addOnFats
    }
  };
}

export async function calculateMealWithAddOns(params: {
  restaurant: Restaurant;
  itemName: string;
  itemDescription?: string;
  addOns?: string[];
}): Promise<CalculateNutritionResponse> {
  const { restaurant } = params;
  const rawItemName = params.itemName.trim();
  const { cleanName, multiplier } = cleanItemNameAndExtractSize(rawItemName);
  const normalizedAddOns = normalizeAddOns(params.addOns);

  let cachedItem = await prisma.cachedMenuItem.findUnique({
    where: {
      restaurantId_itemName: {
        restaurantId: restaurant.id,
        itemName:     cleanName,
      },
    },
  });

  const cachedAddOnMap = new Map<string, CachedAddOn>();
  const missingAddOns: string[] = [];

  for (const addOnName of normalizedAddOns) {
    const cached = await prisma.cachedAddOn.findUnique({
      where: {
        restaurantId_addOnName: {
          restaurantId: restaurant.id,
          addOnName,
        },
      },
    });

    if (cached) {
      cachedAddOnMap.set(addOnName, cached);
    } else {
      missingAddOns.push(addOnName);
    }
  }

  const fullCacheHit = cachedItem !== null && missingAddOns.length === 0;

  if (fullCacheHit && cachedItem) {
    const mappedAddOns = normalizedAddOns.length > 0
      ? normalizedAddOns.map((name) => cachedAddOnToMacros(cachedAddOnMap.get(name)!))
      : [];

    const response: CalculateNutritionResponse = {
      success:    true,
      source:     "cache",
      restaurant: {
        id:       restaurant.id,
        name:     restaurant.name,
        category: restaurant.category,
      },
      item: itemToNutritionData(cachedItem, rawItemName, multiplier),
    };
    if (normalizedAddOns.length > 0) {
      response.addOns = mappedAddOns;
    }

    const scaledBaseItem = {
      caloriesMin: Math.round(cachedItem.caloriesMin * multiplier),
      caloriesMax: Math.round(cachedItem.caloriesMax * multiplier),
      proteinMin:  Math.round(cachedItem.proteinMin * multiplier),
      proteinMax:  Math.round(cachedItem.proteinMax * multiplier),
      carbsMin:    Math.round(cachedItem.carbsMin * multiplier),
      carbsMax:    Math.round(cachedItem.carbsMax * multiplier),
      fatsMin:     Math.round(cachedItem.fatsMin * multiplier),
      fatsMax:     Math.round(cachedItem.fatsMax * multiplier),
    };

    const finalMacros = calculateFinalMacros(rawItemName, scaledBaseItem, mappedAddOns);
    Object.assign(response, finalMacros);

    return response;
  }

  const needsBase = cachedItem === null;

  const aiResponse = await aiService.reverseEngineerItem(
    restaurant.name,
    cleanName,
    missingAddOns,
    { baseItemAlreadyCached: !needsBase, itemDescription: params.itemDescription }
  );

  if (needsBase) {
    cachedItem = await prisma.cachedMenuItem.upsert({
      where: {
        restaurantId_itemName: {
          restaurantId: restaurant.id,
          itemName:     cleanName,
        },
      },
      update: {},
      create: {
        restaurantId: restaurant.id,
        itemName:     cleanName,
        ...(aiResponse.baseItem as BaseItemMacroFields),
      },
    });
  }

  for (const addOn of aiResponse.addOns) {
    if (!missingAddOns.includes(addOn.name)) continue;

    const saved = await prisma.cachedAddOn.upsert({
      where: {
        restaurantId_addOnName: {
          restaurantId: restaurant.id,
          addOnName:    addOn.name,
        },
      },
      update: {},
      create: {
        restaurantId: restaurant.id,
        addOnName:    addOn.name,
        calories:     addOn.calories,
        protein:      addOn.protein,
        carbs:        addOn.carbs,
        fats:         addOn.fats,
      },
    });
    cachedAddOnMap.set(addOn.name, saved);
  }

  const mappedAddOns = normalizedAddOns.length > 0
    ? normalizedAddOns.map((name) => cachedAddOnToMacros(cachedAddOnMap.get(name)!))
    : [];

  const response: CalculateNutritionResponse = {
    success:    true,
    source:     "ai_generated",
    restaurant: {
      id:       restaurant.id,
      name:     restaurant.name,
      category: restaurant.category,
    },
    item: itemToNutritionData(cachedItem!, rawItemName, multiplier),
  };

  if (normalizedAddOns.length > 0) {
    response.addOns = mappedAddOns;
  }

  const scaledBaseItem = {
    caloriesMin: Math.round(cachedItem!.caloriesMin * multiplier),
    caloriesMax: Math.round(cachedItem!.caloriesMax * multiplier),
    proteinMin:  Math.round(cachedItem!.proteinMin * multiplier),
    proteinMax:  Math.round(cachedItem!.proteinMax * multiplier),
    carbsMin:    Math.round(cachedItem!.carbsMin * multiplier),
    carbsMax:    Math.round(cachedItem!.carbsMax * multiplier),
    fatsMin:     Math.round(cachedItem!.fatsMin * multiplier),
    fatsMax:     Math.round(cachedItem!.fatsMax * multiplier),
  };

  const finalMacros = calculateFinalMacros(rawItemName, scaledBaseItem, mappedAddOns);
  Object.assign(response, finalMacros);

  return response;
}
