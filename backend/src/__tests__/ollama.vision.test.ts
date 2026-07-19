// ============================================================
//  src/__tests__/ollama.vision.test.ts
//  Calc-Calories — Unit tests for local Ollama vision service
// ============================================================

import { analyzeMeal, AnalyzeImageInput } from '../services/ai.service';
import { OLLAMA_CONFIG } from '../config';

// Mock global fetch
const mockFetch = jest.fn();
global.fetch = mockFetch as any;

describe('Ollama Vision Service — analyzeMeal()', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.AI_PROVIDER = 'ollama';
    process.env.OLLAMA_VISION_MODEL = 'llava';
  });

  afterEach(() => {
    delete process.env.AI_PROVIDER;
    delete process.env.OLLAMA_VISION_MODEL;
  });

  it('correctly formats and sends base64 image data to Ollama vision model', async () => {
    const mockJson = {
      message: {
        content: JSON.stringify({
          dish_name: 'Grilled Salmon with Rice',
          calories: 550,
          protein: 40,
          carbs: 45,
          fats: 22,
          confidence_score: 0.92
        })
      }
    };

    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockJson,
    });

    const mockImageBuffer = Buffer.from('fake-image-data-base64');
    const input: AnalyzeImageInput = {
      type: 'image',
      imageBuffer: mockImageBuffer,
      mimeType: 'image/png',
      restaurantName: 'Test Restaurant'
    };

    const result = await analyzeMeal(input);

    // Verify fetch call parameters
    expect(mockFetch).toHaveBeenCalledTimes(1);
    const [url, options] = mockFetch.mock.calls[0];
    expect(url).toBe(`${OLLAMA_CONFIG.baseUrl}/api/chat`);
    
    const body = JSON.parse(options.body);
    expect(body.model).toBe('llava');
    expect(body.messages[1].images).toContain(mockImageBuffer.toString('base64'));

    // Verify calculated output macros match expected values based on mock
    expect(result).toEqual({
      mealName: 'Grilled Salmon with Rice',
      restaurantName: 'Homemade',
      calories: 538, // (40 * 4) + (45 * 4) + (22 * 9) = 160 + 180 + 198 = 538
      protein: 40,
      carbs: 45,
      fats: 22,
      ingredientsBreakdown: []
    });
  });
});
