// ============================================================
//  src/services/ai.service.ts
//  Calc-Calories — Multimodal AI Service (text + image → macros)
//  Automatically switches between Google Gemini and Local Ollama (Llama 3)
// ============================================================

import {
  GoogleGenerativeAI,
  SchemaType,
  Part,
  InlineDataPart,
} from "@google/generative-ai";
import { OLLAMA_CONFIG } from "../config";

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
    dish_name: { type: SchemaType.STRING },
    calories: { type: SchemaType.INTEGER },
    protein: { type: SchemaType.INTEGER },
    carbs: { type: SchemaType.INTEGER },
    fats: { type: SchemaType.INTEGER },
    confidence_score: { type: SchemaType.NUMBER },
  },
  required: [
    "dish_name",
    "calories",
    "protein",
    "carbs",
    "fats",
    "confidence_score",
  ],
};

// ── System Instruction ─────────────────────────────────────

const SYSTEM_INSTRUCTION = `You are a precise nutritional analysis AI specialized in the Egyptian and international food market. 

Your sole task is to analyze the provided image of a meal, identify the food items, estimate their weights/portions, and calculate the total nutritional value.

You MUST respond ONLY with a single JSON object. Do not include any markdown formatting wrappers (like \`\`\`json), do not include intro text, and do not include explanations.

Response Format:
{
  "dish_name": "string (e.g., Grilled Chicken with White Rice and Salad)",
  "calories": integer,
  "protein": integer (in grams),
  "carbs": integer (in grams),
  "fats": integer (in grams),
  "confidence_score": float (between 0.0 and 1.0)
}

Strict Rule: If you cannot identify the food, return the JSON with 0 for all macro values and a low confidence score. Never output prose.`;

// ── Core AI Analysis Function ──────────────────────────────

export async function analyzeMeal(input: AnalyzeInput): Promise<MealAnalysisResult> {
  const provider = process.env.AI_PROVIDER ?? "google";

  if (provider === "ollama") {
    return analyzeWithOllama(input);
  }

  return analyzeWithGemini(input);
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

Analyze the nutritional content of this specific meal from this Egyptian restaurant and return the macros.`;
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
  const modelName = process.env.GEMINI_MODEL ?? "gemini-1.5-pro";
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
    maxOutputTokens: 4096,
  };

  let parts: Part[];

  if (input.type === "text") {
    const prompt = `Restaurant: ${input.restaurantName}
Meal Description: ${input.mealDescription}

Analyze the nutritional content of this specific meal from this Egyptian restaurant and return the macros.`;

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

  return parseAndValidateResponse(parsed);
}

// ── Helper Parser & Validator ──────────────────────────────

function parseAndValidateResponse(parsed: any): MealAnalysisResult {
  const required = ["dish_name", "calories", "protein", "carbs", "fats", "confidence_score"];
  for (const field of required) {
    if (parsed[field] === undefined || parsed[field] === null) {
      throw new Error(`AI response missing required field: "${field}"`);
    }
  }

  const protein = Math.round(Number(parsed.protein));
  const carbs = Math.round(Number(parsed.carbs));
  const fats = Math.round(Number(parsed.fats));
  
  // Calculate consistent calories based on standard macro energy densities
  const calculatedCalories = (protein * 4) + (carbs * 4) + (fats * 9);

  return {
    mealName: String(parsed.dish_name),
    restaurantName: "Homemade",
    calories: calculatedCalories > 0 ? calculatedCalories : Math.round(Number(parsed.calories)),
    protein,
    carbs,
    fats,
    ingredientsBreakdown: [],
  };
}
