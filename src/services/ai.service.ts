// ============================================================
//  src/services/ai.service.ts
//  Calc-Calories — Multimodal AI Service (text + image → macros)
//  Uses Gemini 1.5 Pro with strict JSON Schema output mode
// ============================================================

import {
  GoogleGenerativeAI,
  SchemaType,
  Part,
  InlineDataPart,
} from "@google/generative-ai";

const apiKey = process.env.GEMINI_API_KEY ?? "";
if (!apiKey) {
  console.warn("⚠️  [AI Service] GEMINI_API_KEY is not set. AI analysis will fail.");
}

const genAI = new GoogleGenerativeAI(apiKey);

// ── Response Types ─────────────────────────────────────────

export interface IngredientBreakdown {
  ingredient: string;
  estimatedWeightGrams: number;
}

export interface MealAnalysisResult {
  mealName: string;
  restaurantName: string;
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
  ingredientsBreakdown: IngredientBreakdown[];
}

export interface AnalyzeTextInput {
  type: "text";
  restaurantName: string;
  mealDescription: string;
}

export interface AnalyzeImageInput {
  type: "image";
  imageBuffer: Buffer;
  mimeType: "image/jpeg" | "image/png" | "image/webp";
  restaurantName?: string;
}

export type AnalyzeInput = AnalyzeTextInput | AnalyzeImageInput;

// ── Gemini JSON Response Schema ────────────────────────────

const RESPONSE_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    mealName: { type: SchemaType.STRING },
    restaurantName: { type: SchemaType.STRING },
    calories: { type: SchemaType.NUMBER },
    protein: { type: SchemaType.NUMBER },
    carbs: { type: SchemaType.NUMBER },
    fats: { type: SchemaType.NUMBER },
    ingredientsBreakdown: {
      type: SchemaType.ARRAY,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          ingredient: { type: SchemaType.STRING },
          estimatedWeightGrams: { type: SchemaType.NUMBER },
        },
        required: ["ingredient", "estimatedWeightGrams"],
      },
    },
  },
  required: [
    "mealName",
    "restaurantName",
    "calories",
    "protein",
    "carbs",
    "fats",
    "ingredientsBreakdown",
  ],
};

// ── System Instruction ─────────────────────────────────────

const SYSTEM_INSTRUCTION = `You are an expert Egyptian sports nutritionist and food analyst specializing in Egyptian and international restaurant cuisine.

Your task: Analyze the provided meal (either a text description or a screenshot/photo of food) and return precise nutritional macros.

CRITICAL RULES:
1. Be realistic about Egyptian restaurant portion sizes. Egyptian restaurants like Buffalo Burger, Bazooka, KFC Egypt, Pizza Hut Egypt, Koshary El Tahrir, etc., serve standard portions.
2. For burgers/sandwiches: Account for the full meal (bun + patty + toppings + any included sides).
3. For combos/meals: Deconstruct ALL components and SUM their macros.
4. For images: Carefully examine every visible food item. Identify the restaurant from logos, packaging, or menu style if possible.
5. Return calories as kcal (a single realistic integer, not a range).
6. All macro values (protein, carbs, fats) must be in grams as realistic integers.
7. The ingredientsBreakdown must list every major component with a realistic estimated weight.
8. If the restaurant cannot be identified from an image, use "Unknown Restaurant".
9. Egyptian-specific dishes: Koshary (500-700 kcal), Falafel sandwich (350-450 kcal), Shawarma (450-600 kcal), Ful medames (300-400 kcal).

Always return a valid JSON object matching the exact schema. Never include markdown, explanations, or extra text.`;

// ── Core AI Analysis Function ──────────────────────────────

export async function analyzeMeal(input: AnalyzeInput): Promise<MealAnalysisResult> {
  const modelName = process.env.GEMINI_MODEL ?? "gemini-1.5-pro";

  const model = genAI.getGenerativeModel({
    model: modelName,
    systemInstruction: SYSTEM_INSTRUCTION,
  });

  const generationConfig = {
    responseMimeType: "application/json",
    responseSchema: RESPONSE_SCHEMA as any,
    temperature: 0.1, // Low temperature for factual nutritional data
    topP: 0.8,
    topK: 40,
    maxOutputTokens: 4096,
  };

  let parts: Part[];

  if (input.type === "text") {
    const prompt = `Restaurant: ${input.restaurantName}
Meal Description: ${input.mealDescription}

Analyze the nutritional content of this specific meal from this Egyptian restaurant and return the macros.`;

    parts = [{ text: prompt }];
  } else {
    // Image input — convert buffer to base64 inline data
    const base64Image = input.imageBuffer.toString("base64");

    const imagePart: InlineDataPart = {
      inlineData: {
        data: base64Image,
        mimeType: input.mimeType,
      },
    };

    const textPrompt = input.restaurantName
      ? `This is a food image from the restaurant: ${input.restaurantName}. Analyze the meal in this image and return its complete nutritional breakdown.`
      : `Analyze the food/meal shown in this image. Identify the restaurant if possible from logos or packaging. Return the complete nutritional breakdown.`;

    parts = [imagePart, { text: textPrompt }];
  }

  let responseText: string;
  try {
    const result = await model.generateContent({
      contents: [{ role: "user", parts }],
      generationConfig,
    });

    responseText = result.response.text();
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new Error(`Gemini API call failed: ${msg}`);
  }

  if (!responseText || responseText.trim() === "") {
    throw new Error("Gemini returned an empty response.");
  }

  let parsed: any;
  try {
    parsed = JSON.parse(responseText);
  } catch {
    throw new Error(`Gemini returned invalid JSON: ${responseText.slice(0, 200)}`);
  }

  // Validate required fields
  const required = ["mealName", "restaurantName", "calories", "protein", "carbs", "fats"];
  for (const field of required) {
    if (parsed[field] === undefined || parsed[field] === null) {
      throw new Error(`Gemini response missing required field: "${field}"`);
    }
  }

  return {
    mealName: String(parsed.mealName),
    restaurantName: String(parsed.restaurantName),
    calories: Number(parsed.calories),
    protein: Number(parsed.protein),
    carbs: Number(parsed.carbs),
    fats: Number(parsed.fats),
    ingredientsBreakdown: Array.isArray(parsed.ingredientsBreakdown)
      ? parsed.ingredientsBreakdown.map((item: any) => ({
          ingredient: String(item.ingredient ?? ""),
          estimatedWeightGrams: Number(item.estimatedWeightGrams ?? 0),
        }))
      : [],
  };
}
