// ============================================================
//  src/services/gemini.mock.ts
//  Local mock for dev without Gemini API quota (GEMINI_MOCK=true)
// ============================================================

import { AddOnMacros, BaseItemMacroFields } from "../types";
import { ReverseEngineerResponse } from "./ollama.service";

export class GeminiNutritionService {
  async reverseEngineerItem(
    restaurantName: string,
    itemName: string,
    addOns: string[] = [],
    _options?: { baseItemAlreadyCached?: boolean; itemDescription?: string }
  ): Promise<ReverseEngineerResponse> {
    console.log(`🎭 MOCK: ${restaurantName} — ${itemName} (+${addOns.length} add-ons)`);
    await new Promise((r) => setTimeout(r, 300));

    const lower = itemName.toLowerCase();
    let baseItem: BaseItemMacroFields;

    if (lower.includes("philly") || (lower.includes("steak") && lower.includes("baguette")) || (lower.includes("steak") && lower.includes("fries"))) {
      baseItem = {
        caloriesMin: 800, caloriesMax: 1100,
        proteinMin: 45, proteinMax: 65,
        carbsMin: 120, carbsMax: 160,
        fatsMin: 25, fatsMax: 35,
      };
    } else if (lower.includes("double") || lower.includes("large") || lower.includes("200g")) {
      baseItem = {
        caloriesMin: 750, caloriesMax: 900,
        proteinMin: 45, proteinMax: 55,
        carbsMin: 60, carbsMax: 75,
        fatsMin: 35, fatsMax: 45,
      };
    } else if (lower.includes("burger") || lower.includes("sandwich")) {
      baseItem = {
        caloriesMin: 450, caloriesMax: 550,
        proteinMin: 25, proteinMax: 30,
        carbsMin: 40, carbsMax: 50,
        fatsMin: 20, fatsMax: 28,
      };
    } else {
      // Generic fallback — return zeros so no stale numbers are displayed.
      // A successful AI response will always override this.
      baseItem = {
        caloriesMin: 0, caloriesMax: 0,
        proteinMin:  0, proteinMax:  0,
        carbsMin:    0, carbsMax:    0,
        fatsMin:     0, fatsMax:     0,
      };
    }

    const addOnMacros: AddOnMacros[] = addOns.map((name) => {
      const n = name.toLowerCase();
      if (n.includes("cheese")) {
        return { name, calories: 60, protein: 4, carbs: 1, fats: 5 };
      }
      if (n.includes("sauce") || n.includes("tasty")) {
        return { name, calories: 90, protein: 0, carbs: 4, fats: 9 };
      }
      if (n.includes("bacon")) {
        return { name, calories: 45, protein: 3, carbs: 0, fats: 4 };
      }
      return { name, calories: 50, protein: 2, carbs: 3, fats: 3 };
    });

    return { baseItem, addOns: addOnMacros };
  }
}
