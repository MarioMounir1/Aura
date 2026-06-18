/**
 * Ollama-powered nutrition service (Local LLM)
 * No API limits, completely free, runs locally
 *
 * Size-aware: parses weight/volume from item name and applies
 * proportional scaling so "Large" vs "Small" return different macros.
 */

import { OLLAMA_CONFIG } from "../config";

export interface AddOnData {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
}

export interface BaseMacroRange {
  caloriesMin: number;
  caloriesMax: number;
  proteinMin: number;
  proteinMax: number;
  carbsMin: number;
  carbsMax: number;
  fatsMin: number;
  fatsMax: number;
}

export interface ReverseEngineerResponse {
  baseItem: BaseMacroRange;
  addOns: AddOnData[];
}

const STANDARD_ADDONS: Record<string, Omit<AddOnData, "name">> = {
  "extra cheddar cheese": { calories: 80, protein: 7, carbs: 1, fats: 6 },
  "bacon": { calories: 45, protein: 3, carbs: 0, fats: 3 },
  "big tasty sauce": { calories: 100, protein: 0, carbs: 2, fats: 10 },
  "mayo": { calories: 90, protein: 0, carbs: 1, fats: 10 },
};

/**
 * Named size multipliers relative to a "Regular" / medium serving (1.0).
 * Applied on top of the base macro range returned by getBaseItemMacros().
 */
const SIZE_MULTIPLIERS: Record<string, number> = {
  // English size names
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

  // Arabic size words (common on Egyptian food apps)
  "صغير":         0.75,
  "وسط":          1.0,
  "متوسط":        1.0,
  "كبير":         1.35,
  "اكسترا":       1.7,
};

/**
 * Extracts a numeric multiplier from the item name by:
 * 1. Parsing explicit weight/volume (e.g. "500g", "250ml", "1kg")
 *    and scaling relative to a standard portion.
 * 2. Matching named size keywords (e.g. "Large", "Small").
 *
 * @param itemName  The full item name, including size suffix (e.g. "Koshary (Large)")
 * @returns A multiplier to apply to the base macro values (1.0 = no change)
 */
function parseSizeMultiplier(itemName: string): number {
  const lower = itemName.toLowerCase().replace(/_/g, " ");

  // ── 1. Explicit weight/volume ──────────────────────────────────────────────
  // Matches patterns like: 500g, 250 ml, 1kg, 1.5 kg, 300G, etc. (supporting gm unit)
  // We use matchAll and take the LAST match so that size suffixes like "(400gm)" override base item weights like "Burger 150 gm"
  const weightMatches = [...lower.matchAll(/(\d+(?:\.\d+)?)\s*(kg|gm|g|ml|l|oz|lb)(?:\b|$)/g)];
  if (weightMatches.length > 0) {
    const weightMatch = weightMatches[weightMatches.length - 1];
    const value = parseFloat(weightMatch[1]);
    const unit  = weightMatch[2];

    // Normalize everything to grams/ml
    let grams = value;
    if (unit === "kg") grams = value * 1000;
    if (unit === "oz") grams = value * 28.35;
    if (unit === "lb") grams = value * 453.6;
    if (unit === "l")  grams = value * 1000; // treat 1L ≈ 1000ml

    // Reference serving sizes per category
    const isLiquid  = unit === "ml" || unit === "l";
    const isDrink   = lower.includes("juice") || lower.includes("drink") ||
                      lower.includes("water") || lower.includes("coffee") ||
                      lower.includes("tea") || lower.includes("soda");
    const basePortion = (isLiquid || isDrink) ? 330 : 250; // grams/ml

    return Math.max(0.3, Math.min(grams / basePortion, 6.0));
  }

  // ── 2. Named size keywords ─────────────────────────────────────────────────
  for (const [keyword, multiplier] of Object.entries(SIZE_MULTIPLIERS)) {
    // Match whole-word boundaries to avoid false positives (e.g. "large" vs "enlarge")
    const escapedKw = keyword.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`\\b${escapedKw}\\b`, "i");
    if (regex.test(lower)) {
      return multiplier;
    }
  }

  // ── 3. Count/portion qualifiers ───────────────────────────────────────────
  // e.g. "3 pieces", "6 wings", "2 patties"
  const countMatch = lower.match(/\b(\d+)\s*(?:piece|pc|pcs|wing|patty|patties|slice|fillet|item)\b/);
  if (countMatch) {
    const count = parseInt(countMatch[1]);
    return Math.max(0.5, Math.min(count * 0.5, 4.0)); // 1 piece ≈ 0.5x, 2 ≈ 1x, 4 ≈ 2x
  }

  return 1.0; // No size indicator found — use base
}

/**
 * Scales a macro range by the given multiplier, rounding to integers.
 */
function scaleMacros(base: BaseMacroRange, multiplier: number): BaseMacroRange {
  return {
    caloriesMin: Math.round(base.caloriesMin * multiplier),
    caloriesMax: Math.round(base.caloriesMax * multiplier),
    proteinMin:  Math.round(base.proteinMin  * multiplier),
    proteinMax:  Math.round(base.proteinMax  * multiplier),
    carbsMin:    Math.round(base.carbsMin    * multiplier),
    carbsMax:    Math.round(base.carbsMax    * multiplier),
    fatsMin:     Math.round(base.fatsMin     * multiplier),
    fatsMax:     Math.round(base.fatsMax     * multiplier),
  };
}

export class OllamaNutritionService {
  async reverseEngineerItem(
    restaurantName: string,
    itemName: string,
    addOns: string[] = [],
    options?: { baseItemAlreadyCached?: boolean; itemDescription?: string }
  ): Promise<ReverseEngineerResponse> {
    console.log(`🔮 Calling Ollama API: ${restaurantName} — ${itemName} (${addOns.length} add-ons)`);

    const systemInstruction = `You are an expert Egyptian Nutritionist AI. You must recognize Egyptian marketing food names. For example, if the restaurant is 'B-Laban' or similar, items like 'Koshary B-Laban', 'Eshtouta', or 'Mesakhsakha' are heavy desserts consisting of milk, cream (Qeshta), sugar, cake, and nuts. Deconstruct them into their dense sugar/fat components and estimate high-range macros accordingly. Never mistake 'Koshary B-Laban' for traditional savory Koshary.
Your task is to analyze menu items and calculate their nutritional values (calories, protein, carbs, fats).

PORTION ESTIMATION INSTRUCTION:
If specific weights are missing in the item description (like French fries, baguette, or steak), you must use Standard Restaurant Portion Estimates based on the item type.
For example: A 'Philly Cheese Steak Sandwich' on a white baguette with French fries automatically implies a high-density meal: Baguette (~80g carbs), Steak (~150g protein/fat), Emmental cheese (~30g fat), and Side Fries (~80g dense carbs/fats).
Total calories for such meals must realistically scale between 800 - 1100 Calories, not a generic low range.

EXPLICIT NUTRITIONAL VALUE MATCHING:
If an item description or context is provided, check if it contains explicit nutritional values (e.g. '340 calories, 42 protein, 38 carb' or '340 kcal, 42g protein, 38g carbs').
If explicit nutritional values (calories, protein, and/or carbs) are stated:
1. You MUST respect and use these exact values as the basis for your 'baseItem' calculations. If calories are 340, set baseItem.calories.min = 340 and baseItem.calories.max = 340 (or a very tight margin around it like 330-350).
2. If fat is not explicitly stated but calories, protein, and carbs are given, you must calculate the fats using the formula: Fat = (Calories - (Protein * 4 + Carbs * 4)) / 9. If the result is less than 0 or negative, set fats to a realistic minimum estimate (e.g. 1g to 5g).
3. If no explicit numbers are given but there is a description, use the ingredients (like 'light mozzarella', 'oat dough') to refine your macro estimates (e.g. using lower fat or carbs than standard items).

CRITICAL INSTRUCTION FOR COMPOSITE ITEMS (COMBOS, MEALS, BOXES, FAMILY OFFERS):
If the item is a combo, meal, box, or family offer, you MUST deconstruct the item into its components, estimate the nutritional MIN and MAX ranges for each component, and AGGREGATE (sum all mins together, and sum all maxs together) into the final 'baseItem' object. The 'addOns' array should strictly contain the explicit modifications passed in the customizations parameter.

CRITICAL INSTRUCTION FOR ADDONS (CUSTOMIZATIONS):
Calculate the nutritional MIN and MAX ranges for each customization/add-on listed in the request. Make sure each customization is evaluated individually.

You MUST return a raw, clean JSON object with NO markdown formatting, NO \`\`\`json blocks, and NO conversational text. The JSON structure must strictly be: { baseItem: { calories: { min: number, max: number }, protein: { min: number, max: number }, carbs: { min: number, max: number }, fats: { min: number, max: number } }, addOns: Array<{ name: string, calories: { min: number, max: number }, protein: { min: number, max: number }, carbs: { min: number, max: number }, fats: { min: number, max: number } }> }`;

    const userPrompt = `Restaurant: ${restaurantName}
Item: ${itemName}
Description/Context: ${options?.itemDescription || "No description provided"}
Customizations to calculate: ${JSON.stringify(addOns)}`;

    const response = await fetch(`${OLLAMA_CONFIG.baseUrl}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: OLLAMA_CONFIG.model,
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: userPrompt },
        ],
        stream: false,
        options: {
          temperature: OLLAMA_CONFIG.temperature,
        },
        format: "json",
      }),
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => "");
      throw new Error(`Ollama API error: ${response.status} ${response.statusText} - ${errorText}`);
    }

    const responseData = await response.json() as any;
    const responseText = responseData.message?.content?.trim();

    if (!responseText) {
      throw new Error("Empty response from Ollama API");
    }

    let cleanedText = responseText;
    if (cleanedText.includes("```")) {
      cleanedText = cleanedText.replace(/```json/g, "").replace(/```/g, "").trim();
    }

    let parsed: any;
    try {
      parsed = JSON.parse(cleanedText);
    } catch (err) {
      console.error("Failed to parse Ollama response:", responseText);
      throw new Error("Ollama returned invalid JSON response");
    }

    if (!parsed.baseItem || !parsed.baseItem.calories || typeof parsed.baseItem.calories.min !== "number") {
      throw new Error("Ollama returned invalid JSON response structure");
    }

    const baseItem: BaseMacroRange = {
      caloriesMin: parsed.baseItem.calories.min,
      caloriesMax: parsed.baseItem.calories.max,
      proteinMin: parsed.baseItem.protein.min,
      proteinMax: parsed.baseItem.protein.max,
      carbsMin: parsed.baseItem.carbs.min,
      carbsMax: parsed.baseItem.carbs.max,
      fatsMin: parsed.baseItem.fats.min,
      fatsMax: parsed.baseItem.fats.max,
    };

    const addOnsData: AddOnData[] = (parsed.addOns || []).map((addon: any) => ({
      name: addon.name,
      calories: Math.round((addon.calories.min + addon.calories.max) / 2),
      protein: Math.round((addon.protein.min + addon.protein.max) / 2),
      carbs: Math.round((addon.carbs.min + addon.carbs.max) / 2),
      fats: Math.round((addon.fats.min + addon.fats.max) / 2),
    }));

    return { baseItem, addOns: addOnsData };
  }

  private getBaseItemMacros(itemName: string): BaseMacroRange {
    const lower = itemName.toLowerCase();

    // ── Determine the SIZE multiplier first ───────────────────────────────
    const sizeMultiplier = parseSizeMultiplier(lower);

    // ── Determine the FOOD CATEGORY for base macros ───────────────────────
    let baseMacros: BaseMacroRange;

    if (
      (lower.includes("koshary") || lower.includes("koshari") || lower.includes("كشري")) &&
      !lower.includes("b-laban") &&
      !lower.includes("b laban") &&
      !lower.includes("بلبن")
    ) {
      baseMacros = {
        caloriesMin: 550, caloriesMax: 700,
        proteinMin: 18,   proteinMax: 24,
        carbsMin: 90,     carbsMax: 110,
        fatsMin: 12,      fatsMax: 20,
      };
    } else if (
      lower.includes("b-laban") ||
      lower.includes("b laban") ||
      lower.includes("بلبن") ||
      lower.includes("eshtouta") ||
      lower.includes("قشطوطة") ||
      lower.includes("mesakhsakha") ||
      lower.includes("مسخسخة")
    ) {
      baseMacros = {
        caloriesMin: 700, caloriesMax: 1100,
        proteinMin: 8,    proteinMax: 15,
        carbsMin: 110,    carbsMax: 160,
        fatsMin: 25,      fatsMax: 45,
      };
    } else if (lower.includes("shawarma") || lower.includes("شاورما")) {
      baseMacros = {
        caloriesMin: 450, caloriesMax: 600,
        proteinMin: 30,   proteinMax: 40,
        carbsMin: 40,     carbsMax: 55,
        fatsMin: 18,      fatsMax: 28,
      };
    } else if (lower.includes("falafel") || lower.includes("فلافل")) {
      baseMacros = {
        caloriesMin: 350, caloriesMax: 450,
        proteinMin: 15,   proteinMax: 20,
        carbsMin: 40,     carbsMax: 52,
        fatsMin: 14,      fatsMax: 22,
      };
    } else if (lower.includes("philly") || (lower.includes("steak") && lower.includes("baguette")) || (lower.includes("steak") && lower.includes("fries"))) {
      baseMacros = {
        caloriesMin: 800, caloriesMax: 1100,
        proteinMin: 45,   proteinMax: 65,
        carbsMin: 120,    carbsMax: 160,
        fatsMin: 25,      fatsMax: 35,
      };
    } else if (lower.includes("burger") || lower.includes("sandwich") || lower.includes("ساندويتش")) {
      baseMacros = {
        caloriesMin: 450, caloriesMax: 580,
        proteinMin: 25,   proteinMax: 35,
        carbsMin: 40,     carbsMax: 55,
        fatsMin: 20,      fatsMax: 30,
      };
    } else if (lower.includes("pizza")) {
      baseMacros = {
        caloriesMin: 250, caloriesMax: 320,  // per slice / per 100g
        proteinMin: 12,   proteinMax: 18,
        carbsMin: 28,     carbsMax: 38,
        fatsMin: 9,       fatsMax: 14,
      };
    } else if (lower.includes("pasta") || lower.includes("spaghetti") || lower.includes("penne")) {
      baseMacros = {
        caloriesMin: 400, caloriesMax: 520,
        proteinMin: 18,   proteinMax: 25,
        carbsMin: 60,     carbsMax: 75,
        fatsMin: 10,      fatsMax: 18,
      };
    } else if (lower.includes("rice") || lower.includes("roz") || lower.includes("أرز") || lower.includes("رز")) {
      baseMacros = {
        caloriesMin: 350, caloriesMax: 450,
        proteinMin: 8,    proteinMax: 15,
        carbsMin: 65,     carbsMax: 80,
        fatsMin: 5,       fatsMax: 12,
      };
    } else if (lower.includes("chicken") || lower.includes("دجاج")) {
      baseMacros = {
        caloriesMin: 280, caloriesMax: 380,
        proteinMin: 30,   proteinMax: 40,
        carbsMin: 8,      carbsMax: 18,
        fatsMin: 12,      fatsMax: 20,
      };
    } else if (lower.includes("fried") || lower.includes("nugget") || lower.includes("crispy")) {
      baseMacros = {
        caloriesMin: 380, caloriesMax: 500,
        proteinMin: 22,   proteinMax: 32,
        carbsMin: 30,     carbsMax: 42,
        fatsMin: 18,      fatsMax: 28,
      };
    } else if (lower.includes("salad") || lower.includes("سلطة")) {
      baseMacros = {
        caloriesMin: 120, caloriesMax: 280,
        proteinMin: 5,    proteinMax: 15,
        carbsMin: 10,     carbsMax: 25,
        fatsMin: 6,       fatsMax: 18,
      };
    } else if (lower.includes("soup") || lower.includes("شوربة")) {
      baseMacros = {
        caloriesMin: 120, caloriesMax: 250,
        proteinMin: 8,    proteinMax: 18,
        carbsMin: 15,     carbsMax: 28,
        fatsMin: 4,       fatsMax: 12,
      };
    } else if (
      lower.includes("juice") || lower.includes("drink") ||
      lower.includes("coffee") || lower.includes("tea") ||
      lower.includes("water") || lower.includes("soda") ||
      lower.includes("smoothie") || lower.includes("عصير")
    ) {
      baseMacros = {
        caloriesMin: 80,  caloriesMax: 180,
        proteinMin: 0,    proteinMax: 4,
        carbsMin: 18,     carbsMax: 40,
        fatsMin: 0,       fatsMax: 3,
      };
    } else if (lower.includes("dessert") || lower.includes("cake") || lower.includes("ice cream") ||
               lower.includes("waffle") || lower.includes("brownie") || lower.includes("chocolate")) {
      baseMacros = {
        caloriesMin: 300, caloriesMax: 500,
        proteinMin: 4,    proteinMax: 10,
        carbsMin: 45,     carbsMax: 65,
        fatsMin: 12,      fatsMax: 25,
      };
    } else {
      // Generic fallback — return zeros so no stale numbers are displayed.
      // A successful AI response will always override this.
      baseMacros = {
        caloriesMin: 0, caloriesMax: 0,
        proteinMin:  0, proteinMax:  0,
        carbsMin:    0, carbsMax:    0,
        fatsMin:     0, fatsMax:     0,
      };
    }

    // Apply size scaling
    return scaleMacros(baseMacros, sizeMultiplier);
  }
}
