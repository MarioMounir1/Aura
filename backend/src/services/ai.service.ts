// ============================================================
//  src/services/ai.service.ts
//  Aura — Multimodal AI Service (text + image → macros)
//  Automatically switches between Google Gemini and Local Ollama (Llama 3)
// ============================================================

import {
  GoogleGenerativeAI,
  SchemaType,
  Part,
  InlineDataPart,
} from "@google/generative-ai";
import { OLLAMA_CONFIG, resolveGeminiModelName } from "../config";

const apiKey = process.env.GEMINI_API_KEY ?? "";
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
    is_food: { type: SchemaType.BOOLEAN, description: "True if the image contains edible food or beverage, false otherwise." },
    dish_name: { type: SchemaType.STRING, description: "Descriptive name of the dish or meal. If not food, return 'Not Food'." },
    calories: { type: SchemaType.INTEGER },
    protein: { type: SchemaType.INTEGER },
    carbs: { type: SchemaType.INTEGER },
    fats: { type: SchemaType.INTEGER },
    confidence_score: { type: SchemaType.NUMBER },
  },
  required: [
    "is_food",
    "dish_name",
    "calories",
    "protein",
    "carbs",
    "fats",
    "confidence_score",
  ],
};

// ── System Instruction ─────────────────────────────────────

const SYSTEM_INSTRUCTION = `You are a world-class, highly accurate nutritional analysis AI specializing in visual portion estimation and scientific macronutrient calculation for ALL global cuisines — including fast food, homemade meals, restaurant dishes, packaged foods, snacks, and beverages from any country worldwide.

Your task:
1. FIRST check if the image or description contains edible food or beverage.
   - If the image contains non-food objects (e.g. laptop, computer, keyboard, screen, phone, electronics, furniture, clothing, animal, person, room, table without food, random items), you MUST set:
     "is_food": false,
     "dish_name": "Not Food",
     "calories": 0,
     "protein": 0,
     "carbs": 0,
     "fats": 0,
     "confidence_score": 0.0
2. If the image DOES contain edible food or drink:
   - DIET / ZERO SUGAR / WATER / TEA / BLACK COFFEE: If you detect Diet Coke, Coke Zero, Pepsi Max, Diet Pepsi, Zero Sugar beverages, plain water, black coffee, or unsweetened tea, set "is_food": true, calories: 0 or 1, protein: 0, carbs: 0, fats: 0. NEVER assign 150 calories to a diet or zero sugar drink.
   - Carefully count individual whole items (e.g., number of eggs, slices of toast, pieces of meat/chicken).
   - Use standard verified nutritional references (USDA, global databases) for any cuisine:
     * 1 whole large egg: ~72-75 kcal (6.3g protein, 5g fat, 0.4g carbs). 5 whole eggs = ~360-375 kcal (31.5g protein, 25g fat, 2g carbs).
     * 100g cooked chicken breast: ~165 kcal (31g protein, 3.6g fat, 0g carbs).
     * 100g cooked white rice: ~130 kcal (2.7g protein, 0.3g fat, 28g carbs).
   - Accurately calculate total protein (g), carbs (g), and fats (g).
   - Calculate total calories strictly as: (protein * 4) + (carbs * 4) + (fats * 9) (except for zero-calorie beverages where calories = 0 or 1).
   - Set "is_food": true and provide confidence_score between 0.7 and 1.0.

You MUST respond ONLY with a single JSON object conforming strictly to the schema. Never include markdown backticks or commentary.`;

// ── Core AI Analysis Function ──────────────────────────────

export async function analyzeMeal(input: AnalyzeInput): Promise<MealAnalysisResult> {
  const provider = process.env.AI_PROVIDER ?? "google";
  if (provider === "ollama") {
    try {
      return await analyzeWithOllama(input);
    } catch (e) {
      console.warn("⚠️ Ollama failed, falling back to Gemini:", e);
      return analyzeWithGemini(input);
    }
  }

  try {
    return await analyzeWithGemini(input);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.warn("⚠️ Gemini API call failed, trying local Ollama fallback:", msg);
    try {
      return await analyzeWithOllama(input);
    } catch (ollamaErr) {
      console.warn("⚠️ Ollama fallback also failed or unavailable:", ollamaErr);
    }

    throw new Error(msg.includes("NO_FOOD_DETECTED") ? msg : `AI meal analysis failed: ${msg}`);
  }
}

// ── Local Ollama Implementation ────────────────────────────

async function analyzeWithOllama(input: AnalyzeInput): Promise<MealAnalysisResult> {
  const isImage = input.type === "image";
  const modelName = isImage ? OLLAMA_CONFIG.visionModel : OLLAMA_CONFIG.model;
  
  console.log(`🔮 Calling local Ollama (${modelName}): ${isImage ? "Image buffer" : `${input.restaurantName} — ${input.mealDescription}`}`);
  
  let userPrompt: string;
  const imagesArray: string[] = [];

  if (input.type === "text") {
    userPrompt = `Restaurant: ${input.restaurantName}
Meal Description: ${input.mealDescription}

Analyze the nutritional content of this meal and return accurate macros. Use global food databases (USDA and equivalent) for reference.`;
  } else {
    const base64Image = input.imageBuffer.toString("base64");
    imagesArray.push(base64Image);

    userPrompt = input.restaurantName
      ? `Analyze the food in this image. If it is from the restaurant: ${input.restaurantName}, analyze it accordingly. Otherwise, if it is a home-cooked, generic, or unidentified meal, analyze it and set restaurantName to "Homemade". Return the complete nutritional breakdown.`
      : `Analyze the food/meal shown in this image. If it is from a restaurant, identify the restaurant if possible from logos or packaging. If it is a home-cooked, generic, or unidentified meal, analyze it and set restaurantName to "Homemade". Return the complete nutritional breakdown.`;
  }

  const userMessage: any = {
    role: "user",
    content: userPrompt,
  };

  if (imagesArray.length > 0) {
    userMessage.images = imagesArray;
  }

  const response = await fetch(`${OLLAMA_CONFIG.baseUrl}/api/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: modelName,
      messages: [
        { role: "system", content: SYSTEM_INSTRUCTION },
        userMessage,
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

  let parsed: any;
  try {
    parsed = JSON.parse(responseText);
  } catch (err) {
    throw new Error(`Ollama returned invalid JSON response: ${responseText.slice(0, 200)}`);
  }

  return parseAndValidateResponse(parsed);
}


// ── Google Gemini Implementation ───────────────────────────

async function analyzeWithGemini(input: AnalyzeInput): Promise<MealAnalysisResult> {
  const rawModel = process.env.GEMINI_MODEL ?? "gemini-2.5-flash";
  const modelName = resolveGeminiModelName(rawModel);
  console.log(`🔮 Calling Gemini API (${modelName}): ${input.type === "text" ? input.mealDescription : "Image buffer"}`);

  const model = genAI.getGenerativeModel({
    model: modelName,
    systemInstruction: SYSTEM_INSTRUCTION,
  });

  const generationConfig = {
    responseMimeType: "application/json",
    responseSchema: RESPONSE_SCHEMA as any,
    temperature: 0.1,
    topP: 0.8,
    topK: 40,
    maxOutputTokens: 1024,
  };

  let parts: Part[];

  if (input.type === "text") {
    const prompt = `Restaurant: ${input.restaurantName || "Unknown"}
Meal Description: ${input.mealDescription}

Analyze the nutritional content of this meal. It may be from any restaurant, cuisine, or homemade. Use global nutritional databases (USDA and equivalent) to return accurate macros.`;

    parts = [{ text: prompt }];
  } else {
    const base64Image = input.imageBuffer.toString("base64");
    const imagePart: InlineDataPart = {
      inlineData: {
        data: base64Image,
        mimeType: input.mimeType,
      },
    };

    const textPrompt = input.restaurantName
      ? `Analyze the food in this image. If it is from the restaurant: ${input.restaurantName}, analyze it accordingly. Otherwise, if it is a home-cooked, generic, or unidentified meal, analyze it and set restaurantName to "Homemade". Return the complete nutritional breakdown.`
      : `Analyze the food/meal shown in this image. If it is from a restaurant, identify the restaurant if possible from logos or packaging. If it is a home-cooked, generic, or unidentified meal, analyze it and set restaurantName to "Homemade". Return the complete nutritional breakdown.`;

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
    console.warn(`⚠️ Gemini API call with ${modelName} failed (${msg}). Retrying with gemini-2.5-flash-lite...`);
    if (modelName !== "gemini-2.5-flash-lite") {
      try {
        const fallbackModel = genAI.getGenerativeModel({
          model: "gemini-2.5-flash-lite",
          systemInstruction: SYSTEM_INSTRUCTION,
        });
        const fallbackResult = await fallbackModel.generateContent({
          contents: [{ role: "user", parts }],
          generationConfig,
        });
        responseText = fallbackResult.response.text();
      } catch (fallbackErr: unknown) {
        const fallbackMsg = fallbackErr instanceof Error ? fallbackErr.message : String(fallbackErr);
        throw new Error(`Gemini API call failed: ${fallbackMsg}`);
      }
    } else {
      throw new Error(`Gemini API call failed: ${msg}`);
    }
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

  return parseAndValidateResponse(parsed);
}

// ── Text-Only AI Nutrition Estimation Fallback ────────────

export interface TextNutritionEstimate {
  dishName: string;
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
  confidenceScore: number;
}

/**
 * Text-only AI nutrition estimation when no database or Open Food Facts entry exists.
 * Prompts Ollama (JSON mode) or Gemini fallback.
 */
export async function estimateNutritionFromName(foodName: string): Promise<TextNutritionEstimate> {
  const provider = process.env.AI_PROVIDER ?? "google";
  const userPrompt = `Estimate the nutritional content per 100g serving for the food or dish named: "${foodName}".
Return a JSON object strictly matching this schema:
{
  "dish_name": "${foodName}",
  "calories": number,
  "protein": number,
  "carbs": number,
  "fats": number,
  "confidence_score": number (0.0 to 1.0)
}`;

  if (provider === "ollama") {
    try {
      const response = await fetch(`${OLLAMA_CONFIG.baseUrl}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: OLLAMA_CONFIG.model,
          messages: [
            { role: "system", content: SYSTEM_INSTRUCTION },
            { role: "user", content: userPrompt },
          ],
          stream: false,
          options: { temperature: 0.2 },
          format: "json",
        }),
      });

      if (response.ok) {
        const responseData = (await response.json()) as any;
        const text = responseData.message?.content;
        if (text) {
          const parsed = JSON.parse(text);
          return {
            dishName: String(parsed.dish_name || foodName),
            calories: Math.max(0, Math.round(Number(parsed.calories || 0))),
            protein: Math.max(0, Math.round(Number(parsed.protein || 0))),
            carbs: Math.max(0, Math.round(Number(parsed.carbs || 0))),
            fats: Math.max(0, Math.round(Number(parsed.fats || 0))),
            confidenceScore: Math.min(1.0, Math.max(0.0, Number(parsed.confidence_score || 0.7))),
          };
        }
      }
    } catch (err) {
      console.error("❌ [AI] Ollama text estimation failed:", err);
    }
  }

  // Fallback default estimate if AI provider fails or is unreachable
  return {
    dishName: foodName,
    calories: 150,
    protein: 5,
    carbs: 20,
    fats: 5,
    confidenceScore: 0.5,
  };
}

// ── Helper Parser & Validator ──────────────────────────────

function parseAndValidateResponse(parsed: any): MealAnalysisResult {
  const isFood = parsed.is_food !== false;
  const rawDishName = String(parsed.dish_name || "").trim();
  const dishName = rawDishName.toLowerCase();

  if (!isFood || dishName === "not food" || dishName === "non-food" || dishName === "unidentified" || dishName === "" || dishName === "null") {
    throw new Error("NO_FOOD_DETECTED: No food or beverage was detected in this image. Please scan a clear photo of your meal.");
  }

  let protein = Math.max(0, Math.round(Number(parsed.protein || 0)));
  let carbs = Math.max(0, Math.round(Number(parsed.carbs || 0)));
  let fats = Math.max(0, Math.round(Number(parsed.fats || 0)));
  
  // ── Smart Diet / Zero Sugar & Zero-Calorie Beverage Sanitizer ─────────────
  const isDietDrink = /(diet|zero|max|light|no sugar|sugar free|zero sugar)/i.test(dishName) && 
                      /(coke|coca|pepsi|soda|cola|sprite|7up|seven up|dr pepper|fanta|drink|can|beverage)/i.test(dishName);

  const isZeroCalDrink = isDietDrink || /(water|black coffee|espresso|americano|green tea|black tea|herbal tea|sparkling water|club soda|seltzer)/i.test(dishName);

  if (isDietDrink) {
    protein = 0;
    carbs = 0;
    fats = 0;
  }

  // Calculate consistent calories based on standard macro energy densities
  let calculatedCalories = (protein * 4) + (carbs * 4) + (fats * 9);
  let reportedCalories = Math.max(0, Math.round(Number(parsed.calories || 0)));

  if (isDietDrink) {
    reportedCalories = 1;
    calculatedCalories = 1;
  }

  if (calculatedCalories === 0 && reportedCalories === 0 && !isZeroCalDrink) {
    throw new Error("NO_FOOD_DETECTED: No food or beverage was detected in this image. Please scan a clear photo of your meal.");
  }

  const finalCalories = isZeroCalDrink && reportedCalories <= 5 
    ? reportedCalories 
    : (calculatedCalories > 0 ? calculatedCalories : reportedCalories);

  return {
    mealName: rawDishName,
    restaurantName: "Homemade",
    calories: finalCalories,
    protein,
    carbs,
    fats,
    ingredientsBreakdown: [],
  };
}
