// ============================================================
//  src/routes/v1.routes.ts
//  Calc-Calories — API v1 Router
//  All mobile app endpoints live here under /api/v1
// ============================================================

import { Router } from "express";
import { register, login, getMe, updateGoals } from "../controllers/user.controller";
import { analyzeMealHandler } from "../controllers/meal.controller";
import { getMealHistory, deleteMealLog } from "../controllers/history.controller";
import { getSuggestions } from "../controllers/suggestion.controller";
import { requireAuth } from "../middleware/auth.middleware";
import { analyzeMealLimiter, authLimiter } from "../middleware/rateLimit.middleware";

const router = Router();

// ── Auth Routes ────────────────────────────────────────────

/**
 * @route   POST /api/v1/auth/register
 * @desc    Create a new Calc-Calories user account
 * @access  Public
 * @body    { name, email, password, dailyCalorieGoal? }
 */
router.post("/auth/register", authLimiter, register);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Authenticate and receive a JWT token
 * @access  Public
 * @body    { email, password }
 */
router.post("/auth/login", authLimiter, login);

// ── User Routes ────────────────────────────────────────────

/**
 * @route   GET /api/v1/users/me
 * @desc    Get current user profile + today's macro summary
 * @access  Private (JWT required)
 */
router.get("/users/me", requireAuth, getMe);

/**
 * @route   PUT /api/v1/users/me/goals
 * @desc    Update daily calorie and macro goals
 * @access  Private (JWT required)
 * @body    { dailyCalorieGoal?, proteinGoal?, carbsGoal?, fatsGoal? }
 */
router.put("/users/me/goals", requireAuth, updateGoals);

// ── Meal Analysis Routes ───────────────────────────────────

/**
 * @route   POST /api/v1/meals/analyze
 * @desc    Analyze a meal via text description OR image screenshot
 * @access  Private (JWT required)
 * @body    multipart/form-data: { restaurantName?, mealDescription?, image? }
 *          OR application/json: { restaurantName, mealDescription }
 * @rateLimit 30 requests per minute per user
 */
router.post("/meals/analyze", requireAuth, analyzeMealLimiter, analyzeMealHandler);

/**
 * @route   GET /api/v1/meals/history
 * @desc    Get paginated meal log history
 * @access  Private (JWT required)
 * @query   page?, limit?, date? (YYYY-MM-DD)
 */
router.get("/meals/history", requireAuth, getMealHistory);

/**
 * @route   GET /api/v1/meals/suggestions
 * @desc    Get macro suggestions and recommended protein products
 * @access  Private (JWT required)
 */
router.get("/meals/suggestions", requireAuth, getSuggestions);

/**
 * @route   DELETE /api/v1/meals/:id
 * @desc    Delete a specific meal log entry
 * @access  Private (JWT required, ownership enforced)
 */
router.delete("/meals/:id", requireAuth, deleteMealLog);

export default router;
