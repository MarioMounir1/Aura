// ============================================================
//  src/services/ai.service.ts
//  Aura — Multimodal AI Service (Google Gemini: text + image → macros)
// ============================================================

import {
  GoogleGenerativeAI,
  SchemaType,
  Part,
  InlineDataPart,
} from "@google/generative-ai";
import { resolveGeminiModelName } from "../config";

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
   - CRITICAL DISH NAMING: NEVER return generic names like 'Healthy Meal', 'Balanced Meal', 'Food Plate', or 'Meal'. You MUST identify the specific dish name accurately (e.g., 'Large Chicken Pizza with Soda', 'Grilled Chicken Salad', 'Oatmeal with Sliced Banana and Grapes', 'Cheeseburger & Fries'). If a pizza is visible, specify the pizza type (e.g., 'Chicken BBQ Pizza' or 'Large Chicken Pizza'). If a beverage or soda can is visible alongside the food, explicitly include it in the dish name.
   - REALISTIC PORTIONS & FAST FOOD CALORIES:
     * Whole Pizza (medium/large): 1200 - 2400 kcal (50-80g protein, 120-220g carbs, 50-100g fat). NEVER estimate 450 kcal for a whole pizza!
     * Single Pizza Slice: 250 - 420 kcal.
     * Regular Soda / Soft Drink can (330ml): ~140 - 160 kcal (38g carbs, 0g protein, 0g fat).
     * Diet / Zero Sugar Soda / Black Coffee / Water: 0 kcal, 0g protein, 0g carbs, 0g fat. NEVER assign 150 calories to a diet or zero sugar drink.
   - Carefully count individual whole items (e.g., number of eggs, slices of toast, pieces of meat/chicken).
   - Use standard verified nutritional references (USDA, global databases) for any cuisine:
     * 1 whole large egg: ~72-75 kcal (6.3g protein, 5g fat, 0.4g carbs). 5 whole eggs = ~360-375 kcal (31.5g protein, 25g fat, 2g carbs).
     * 100g cooked chicken breast: ~165 kcal (31g protein, 3.6g fat, 0g carbs).
     * 100g cooked white rice: ~130 kcal (2.7g protein, 0.3g fat, 28g carbs).
   - Accurately calculate total protein (g), carbs (g), and fats (g).
   - Calculate realistic macros and calories. The macronutrient energy ((protein * 4) + (carbs * 4) + (fats * 9)) should align with total calories within a reasonable margin of 100 calories to allow for visual portion variance and natural food density differences.
   - Set "is_food": true and provide confidence_score between 0.7 and 1.0.

You MUST respond ONLY with a single JSON object conforming strictly to the schema. Never include markdown backticks or commentary.`;

// ── Core AI Analysis Function ──────────────────────────────

export async function analyzeMeal(input: AnalyzeInput): Promise<MealAnalysisResult> {
  return await analyzeWithGemini(input);
}

// ── Local Ollama Vision & LLM Implementation ───────────────

async function analyzeWithOllama(input: AnalyzeInput): Promise<MealAnalysisResult> {
  const baseUrl = process.env.OLLAMA_BASE_URL ?? "http://127.0.0.1:11434";

  if (input.type === "image") {
    const visionModel = process.env.OLLAMA_VISION_MODEL ?? "llava";
    console.log(`🔮 Calling local Ollama Vision (${visionModel}) on ${baseUrl}...`);

    const base64Image = input.imageBuffer.toString("base64");
    const prompt = `You are a world-class nutritionist AI. Carefully analyze the food or beverage in this image.
CRITICAL INSTRUCTIONS:
1. Identify the exact food/dish name (e.g. 'Large Chicken Pizza with Soda', 'Cheeseburger & Fries', 'Grilled Chicken Salad'). NEVER return generic names like 'Healthy Meal' or 'Balanced Meal'. If it is pizza, say Pizza! If there is a drink (e.g. Primos Cola), mention it.
2. Estimate REALISTIC calories, protein (g), carbs (g), and fats (g) for the ENTIRE visible portion.
   - Large pizza: 1200 - 2200 kcal (60g protein, 120g carbs, 50g fat).
   - Pizza slice: 280 - 400 kcal.
   - Regular soda/cola can: 140 - 160 kcal (39g carbs).
   - Diet / Zero soda: 0 kcal.
3. If not food/drink, set is_food: false and dish_name: "Not Food".
4. Return ONLY a single raw JSON object:
{
  "is_food": true,
  "dish_name": "exact food name",
  "calories": 1200,
  "protein": 60,
  "carbs": 100,
  "fats": 50
}`;

    const res = await fetch(`${baseUrl}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: visionModel,
        prompt,
        images: [base64Image],
        stream: false,
        format: "json",
      }),
    });

    if (!res.ok) {
      throw new Error(`Ollama Vision returned ${res.status}: ${res.statusText}`);
    }

    const data: any = await res.json();
    const rawText = data.response ?? "";
    const cleanText = rawText.replace(/```json|```/g, "").trim();
    const parsed = JSON.parse(cleanText);

    return parseAndValidateResponse(parsed);
  } else {
    const textModel = process.env.OLLAMA_MODEL ?? "llama3";
    console.log(`🔮 Calling local Ollama LLM (${textModel}) for text: "${input.mealDescription}"...`);

    const prompt = `You are a world-class nutritionist AI. Estimate the calories and macronutrients for:
"${input.mealDescription}" (Restaurant: ${input.restaurantName || "Homemade"}).
Provide realistic portion estimation and return strictly JSON:
{
  "is_food": true,
  "dish_name": "${input.mealDescription}",
  "calories": 450,
  "protein": 30,
  "carbs": 40,
  "fats": 15
}`;

    const res = await fetch(`${baseUrl}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: textModel,
        prompt,
        stream: false,
        format: "json",
      }),
    });

    if (!res.ok) {
      throw new Error(`Ollama returned ${res.status}: ${res.statusText}`);
    }

    const data: any = await res.json();
    const rawText = data.response ?? "";
    const cleanText = rawText.replace(/```json|```/g, "").trim();
    const parsed = JSON.parse(cleanText);

    return parseAndValidateResponse(parsed);
  }
}

function withTimeout<T>(promise: Promise<T>, ms: number, errorMsg: string): Promise<T> {
  let timeoutHandle: NodeJS.Timeout;
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeoutHandle = setTimeout(() => reject(new Error(errorMsg)), ms);
  });
  return Promise.race([promise, timeoutPromise]).finally(() => {
    clearTimeout(timeoutHandle);
  });
}

// ── Google Gemini Implementation ───────────────────────────

async function analyzeWithGemini(input: AnalyzeInput): Promise<MealAnalysisResult> {
  // Prioritize verified fast and reliable models: 3.5-flash (primary, ~3-4s) and 3-flash-preview (instant fallback)
  const candidateModels = [
    "gemini-3.5-flash",
    "gemini-3-flash-preview",
  ];

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

  let responseText: string | undefined;
  let lastError: Error | null = null;

  for (const currentModel of candidateModels) {
    try {
      console.log(`🔮 Calling Gemini API (${currentModel}): ${input.type === "text" ? input.mealDescription : "Image buffer"}`);
      const model = genAI.getGenerativeModel({
        model: currentModel,
        systemInstruction: SYSTEM_INSTRUCTION,
      });

      const result = await withTimeout(
        model.generateContent({
          contents: [{ role: "user", parts }],
          generationConfig,
        }),
        7000,
        `Gemini API (${currentModel}) exceeded 7s timeout`
      );

      responseText = result.response.text();
      if (responseText && responseText.trim().length > 0) {
        break;
      }
    } catch (err: unknown) {
      lastError = err instanceof Error ? err : new Error(String(err));
      console.warn(`⚠️ Gemini API call with ${currentModel} failed (${lastError.message}). Trying next candidate model...`);
    }
  }

  if (!responseText || responseText.trim() === "") {
    if (input.type === "text") {
      return fallbackTextEstimate(input);
    }
    throw new Error(`Gemini API call failed across all candidate models: ${lastError?.message ?? "Empty response"}`);
  }

  let parsed: any;
  try {
    parsed = JSON.parse(responseText);
  } catch {
    if (input.type === "text") {
      return fallbackTextEstimate(input);
    }
    throw new Error(`Gemini returned invalid JSON: ${responseText.slice(0, 200)}`);
  }

  return parseAndValidateResponse(parsed);
}

function fallbackTextEstimate(input: AnalyzeTextInput): MealAnalysisResult {
  return {
    mealName: input.mealDescription,
    restaurantName: input.restaurantName || "Homemade",
    calories: 250,
    protein: 15,
    carbs: 30,
    fats: 8,
    ingredientsBreakdown: [],
  };
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
  try {
    const rawModel = process.env.GEMINI_MODEL ?? "gemini-2.5-flash";
    const modelName = resolveGeminiModelName(rawModel);
    const model = genAI.getGenerativeModel({ model: modelName });
    const prompt = `Estimate the nutritional content per 100g serving for the food or dish named: "${foodName}".
Respond strictly with a JSON object: {"dish_name": "${foodName}", "calories": number, "protein": number, "carbs": number, "fats": number, "confidence_score": number}`;

    const result = await model.generateContent(prompt);
    const text = result.response.text().trim();
    const cleanText = text.replace(/```json|```/g, "").trim();
    const parsed = JSON.parse(cleanText);

    return {
      dishName: String(parsed.dish_name || foodName),
      calories: Math.max(0, Math.round(Number(parsed.calories || 0))),
      protein: Math.max(0, Math.round(Number(parsed.protein || 0))),
      carbs: Math.max(0, Math.round(Number(parsed.carbs || 0))),
      fats: Math.max(0, Math.round(Number(parsed.fats || 0))),
      confidenceScore: Math.min(1.0, Math.max(0.0, Number(parsed.confidence_score || 0.8))),
    };
  } catch (err) {
    console.warn("⚠️ [AI] Gemini text estimation fallback to default:", err);
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

  // ── 100-Calorie Margin Tolerance ──────────────────────────────────────────
  // In real food analysis, macros and calories can vary slightly due to dietary fiber,
  // organic acids, and visual portion estimation variance.
  // If reported calories is within a 100-calorie margin of calculated macros, preserve reported calories.
  // If difference > 100 calories, reconcile calories to within the 100-calorie margin.
  let finalCalories: number;
  if (isZeroCalDrink && reportedCalories <= 5) {
    finalCalories = reportedCalories;
  } else if (reportedCalories > 0 && calculatedCalories > 0) {
    const diff = Math.abs(reportedCalories - calculatedCalories);
    if (diff <= 100) {
      finalCalories = reportedCalories;
    } else if (reportedCalories > calculatedCalories) {
      finalCalories = calculatedCalories + 100;
    } else {
      finalCalories = Math.max(0, calculatedCalories - 100);
    }
  } else {
    finalCalories = calculatedCalories > 0 ? calculatedCalories : reportedCalories;
  }

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
