// ============================================================
//  src/__tests__/ollama.vision.test.ts
//  Aura — Unit tests for AI vision service & 100-calorie macro margin
// ============================================================

import { analyzeMeal, AnalyzeImageInput } from '../services/ai.service';

const mockGenerateContent = jest.fn();

jest.mock('@google/generative-ai', () => ({
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
    BOOLEAN: 'boolean',
  },
}));

describe('Gemini Vision Service — analyzeMeal() & 100-Calorie Margin', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.GEMINI_API_KEY = 'test-api-key';
  });

  it('preserves reported calories when within 100-calorie margin of calculated macros', async () => {
    // 40*4 + 45*4 + 22*9 = 160 + 180 + 198 = 538 kcal
    // Reported: 550 kcal (diff = 12 <= 100 kcal) -> should preserve 550
    mockGenerateContent.mockResolvedValueOnce({
      response: {
        text: () =>
          JSON.stringify({
            is_food: true,
            dish_name: 'Grilled Salmon with Rice',
            calories: 550,
            protein: 40,
            carbs: 45,
            fats: 22,
            confidence_score: 0.92,
          }),
      },
    });

    const mockImageBuffer = Buffer.from('fake-image-data-base64');
    const input: AnalyzeImageInput = {
      type: 'image',
      imageBuffer: mockImageBuffer,
      mimeType: 'image/png',
      restaurantName: 'Test Restaurant',
    };

    const result = await analyzeMeal(input);

    expect(result).toEqual({
      mealName: 'Grilled Salmon with Rice',
      restaurantName: 'Homemade',
      calories: 550, // Preserved because |550 - 538| = 12 <= 100
      protein: 40,
      carbs: 45,
      fats: 22,
      ingredientsBreakdown: [],
    });
  });

  it('reconciles reported calories when exceeding 100-calorie margin of calculated macros', async () => {
    // 40*4 + 45*4 + 22*9 = 538 kcal
    // Reported: 700 kcal (diff = 162 > 100 kcal) -> should clamp to 538 + 100 = 638
    mockGenerateContent.mockResolvedValueOnce({
      response: {
        text: () =>
          JSON.stringify({
            is_food: true,
            dish_name: 'Grilled Salmon with Rice',
            calories: 700,
            protein: 40,
            carbs: 45,
            fats: 22,
            confidence_score: 0.92,
          }),
      },
    });

    const mockImageBuffer = Buffer.from('fake-image-data-base64');
    const input: AnalyzeImageInput = {
      type: 'image',
      imageBuffer: mockImageBuffer,
      mimeType: 'image/png',
    };

    const result = await analyzeMeal(input);

    expect(result.calories).toBe(638); // Clamped to calculated (538) + 100
  });
});
