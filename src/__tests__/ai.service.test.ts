// ============================================================
//  src/__tests__/ai.service.test.ts
//  Calc-Calories — Unit tests for multimodal AI service
// ============================================================

import { analyzeMeal, AnalyzeTextInput } from '../services/ai.service';

// Mock the Google Generative AI SDK
jest.mock('@google/generative-ai', () => {
  const mockGenerateContent = jest.fn();
  return {
    GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
      getGenerativeModel: jest.fn().mockReturnValue({
        generateContent: mockGenerateContent,
      }),
    })),
    SchemaType: {
      OBJECT: 'object',
      STRING: 'string',
      NUMBER: 'number',
      ARRAY: 'array',
    },
    __mockGenerateContent: mockGenerateContent,
  };
});

const mockResponse = {
  mealName: 'Single Bacon Mushroom Jack',
  restaurantName: 'Buffalo Burger',
  calories: 650,
  protein: 42,
  carbs: 48,
  fats: 28,
  ingredientsBreakdown: [
    { ingredient: 'Beef Patty (Quarter Pound)', estimatedWeightGrams: 113 },
    { ingredient: 'Brioche Bun', estimatedWeightGrams: 60 },
    { ingredient: 'Bacon Strips', estimatedWeightGrams: 30 },
    { ingredient: 'Mushrooms', estimatedWeightGrams: 40 },
    { ingredient: 'Monterey Jack Cheese', estimatedWeightGrams: 28 },
  ],
};

describe('AI Service — analyzeMeal()', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.GEMINI_API_KEY = 'test-api-key';

    // Access the mock via the module
    const genAI = require('@google/generative-ai');
    genAI.__mockGenerateContent.mockResolvedValue({
      response: {
        text: () => JSON.stringify(mockResponse),
      },
    });
  });

  it('returns structured macros for text input', async () => {
    const input: AnalyzeTextInput = {
      type: 'text',
      restaurantName: 'Buffalo Burger',
      mealDescription: 'Single Bacon Mushroom Jack',
    };

    const result = await analyzeMeal(input);

    expect(result).toMatchObject({
      mealName: expect.any(String),
      restaurantName: expect.any(String),
      calories: expect.any(Number),
      protein: expect.any(Number),
      carbs: expect.any(Number),
      fats: expect.any(Number),
      ingredientsBreakdown: expect.any(Array),
    });
    expect(result.calories).toBeGreaterThan(0);
    expect(result.protein).toBeGreaterThan(0);
    expect(result.ingredientsBreakdown.length).toBeGreaterThan(0);
  });

  it('validates that ingredientsBreakdown items have required fields', async () => {
    const input: AnalyzeTextInput = {
      type: 'text',
      restaurantName: 'KFC Egypt',
      mealDescription: 'Zinger Burger Meal',
    };

    const result = await analyzeMeal(input);

    result.ingredientsBreakdown.forEach((item) => {
      expect(item).toHaveProperty('ingredient');
      expect(item).toHaveProperty('estimatedWeightGrams');
      expect(typeof item.ingredient).toBe('string');
      expect(typeof item.estimatedWeightGrams).toBe('number');
    });
  });

  it('throws when Gemini returns invalid JSON', async () => {
    const genAI = require('@google/generative-ai');
    genAI.__mockGenerateContent.mockResolvedValue({
      response: {
        text: () => 'invalid-json-response',
      },
    });

    const input: AnalyzeTextInput = {
      type: 'text',
      restaurantName: 'Test Restaurant',
      mealDescription: 'Test Meal',
    };

    await expect(analyzeMeal(input)).rejects.toThrow(/invalid JSON/i);
  });

  it('throws when Gemini returns empty response', async () => {
    const genAI = require('@google/generative-ai');
    genAI.__mockGenerateContent.mockResolvedValue({
      response: {
        text: () => '',
      },
    });

    const input: AnalyzeTextInput = {
      type: 'text',
      restaurantName: 'Test Restaurant',
      mealDescription: 'Test Meal',
    };

    await expect(analyzeMeal(input)).rejects.toThrow(/empty response/i);
  });

  it('throws with descriptive error when Gemini API call fails', async () => {
    const genAI = require('@google/generative-ai');
    genAI.__mockGenerateContent.mockRejectedValue(
      new Error('API key not valid. Please pass a valid API key.')
    );

    const input: AnalyzeTextInput = {
      type: 'text',
      restaurantName: 'Test Restaurant',
      mealDescription: 'Test Meal',
    };

    await expect(analyzeMeal(input)).rejects.toThrow(/Gemini API call failed/i);
  });
});
