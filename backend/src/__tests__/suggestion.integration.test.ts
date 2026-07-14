// Set env vars BEFORE any module imports
process.env.JWT_SECRET = 'test-jwt-secret-for-ci-pipeline-only';
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test_db';
import request from 'supertest';
import app from '../app';
import jwt from 'jsonwebtoken';

// Mock Prisma to avoid real DB calls
jest.mock('../services/prisma.service', () => ({
  __esModule: true,
  default: {
    user: {
      findUnique: jest.fn(),
    },
    mealLog: {
      findMany: jest.fn(),
    },
    sponsorProduct: {
      findMany: jest.fn(),
    },
    company: {
      upsert: jest.fn().mockResolvedValue({}),
    },
  },
}));

const prisma = require('../services/prisma.service').default;

describe('GET /api/v1/meals/suggestions', () => {
  let authToken: string;

  beforeAll(() => {
    authToken = jwt.sign(
      { userId: 'test-user-id-123', email: 'test@calc-calories.io' },
      process.env.JWT_SECRET!
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/v1/meals/suggestions');
    expect(res.status).toBe(401);
  });

  it('calculates suggestions and returns products when protein deficit > 25g', async () => {
    // Mock user goals (goal = 150g)
    prisma.user.findUnique.mockResolvedValue({
      id: 'test-user-id-123',
      name: 'Test User',
      email: 'test@calc-calories.io',
      proteinGoal: 150,
      carbsGoal: 200,
      fatsGoal: 65,
      dailyCalorieGoal: 2000,
      isActive: true,
    });

    // Mock today's logs summing up to 100g (deficit = 50g)
    prisma.mealLog.findMany.mockResolvedValue([
      { calories: 500, protein: 40, carbs: 60, fats: 15 },
      { calories: 600, protein: 60, carbs: 80, fats: 20 },
    ]);

    // Mock sponsored products query
    const mockProducts = [
      {
        id: 'prod-123',
        name: 'Sponsored Protein Bar',
        imageUrl: 'https://example.com/bar.png',
        proteinContent: 25,
        calorieContent: 200,
        purchaseUrl: 'https://example.com/buy',
        promoCode: 'TEST25',
      },
    ];
    prisma.sponsorProduct.findMany.mockResolvedValue(mockProducts);

    const res = await request(app)
      .get('/api/v1/meals/suggestions')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.deficit).toEqual({
      calories: 900,
      protein: 50,
      carbs: 60,
      fats: 30,
    });
    expect(res.body.data.recommendations).toHaveLength(1);
    expect(res.body.data.recommendations[0]).toEqual(mockProducts[0]);
  });

  it('returns empty recommendations when protein deficit <= 25g', async () => {
    // Mock user goals (goal = 150g)
    prisma.user.findUnique.mockResolvedValue({
      id: 'test-user-id-123',
      name: 'Test User',
      email: 'test@calc-calories.io',
      proteinGoal: 150,
      carbsGoal: 200,
      fatsGoal: 65,
      dailyCalorieGoal: 2000,
      isActive: true,
    });

    // Mock today's logs summing up to 130g (deficit = 20g, which is <= 25g)
    prisma.mealLog.findMany.mockResolvedValue([
      { calories: 800, protein: 70, carbs: 100, fats: 20 },
      { calories: 700, protein: 60, carbs: 80, fats: 20 },
    ]);

    const res = await request(app)
      .get('/api/v1/meals/suggestions')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.deficit.protein).toBe(20);
    expect(res.body.data.recommendations).toHaveLength(0);
    expect(prisma.sponsorProduct.findMany).not.toHaveBeenCalled();
  });
});
