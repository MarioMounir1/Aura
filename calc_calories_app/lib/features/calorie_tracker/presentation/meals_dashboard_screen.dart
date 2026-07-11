// lib/features/calorie_tracker/presentation/meals_dashboard_screen.dart
// Calc-Calories — Meals Dashboard UI (Elite Fitness Aesthetic)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../domain/entities/meal_log_entity.dart';

// Elite fitness aesthetic palette constants
class DashboardThemeColors {
  DashboardThemeColors._();

  static const Color background = Color(0xFF030712);       // Slate-955 / Dark Navy
  static const Color cardBackground = Color(0xFF111827);   // Slate-900
  static const Color accentEmerald = Color(0xFF10B981);    // Emerald-500
  static const Color accentLime = Color(0xFFA3E635);       // Lime-400
  
  static const Color textPrimary = Color(0xFFF9FAFB);      // Slate-50
  static const Color textSecondary = Color(0xFF9CA3AF);    // Slate-400
  static const Color textMuted = Color(0xFF6B7280);        // Slate-500
  static const Color trackBackground = Color(0xFF1F2937);  // Slate-800
}

class MealsDashboard extends StatefulWidget {
  final Map<String, dynamic>? foodSummary;
  final List<MealLogEntity>? mealLogs;

  const MealsDashboard({
    super.key,
    this.foodSummary,
    this.mealLogs,
  });

  @override
  State<MealsDashboard> createState() => _MealsDashboardState();
}

class _MealsDashboardState extends State<MealsDashboard> {
  // Mock fallback data to ensure visual excellence and standalone execution
  late double caloriesConsumed;
  late double caloriesTarget;
  late double proteinConsumed;
  late double proteinTarget;
  late double carbsConsumed;
  late double carbsTarget;
  late double fatsConsumed;
  late double fatsTarget;

  late List<MealLogEntity> logs;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Totals and goals mapping
    final totals = widget.foodSummary?['totals'] as Map<String, dynamic>? ?? {};
    final goals = widget.foodSummary?['goals'] as Map<String, dynamic>? ?? {};

    caloriesConsumed = (totals['calories'] as num?)?.toDouble() ?? 1780.0;
    caloriesTarget = (goals['calories'] as num?)?.toDouble() ?? 2400.0;

    proteinConsumed = (totals['protein'] as num?)?.toDouble() ?? 135.0;
    proteinTarget = (goals['protein'] as num?)?.toDouble() ?? 170.0;

    carbsConsumed = (totals['carbs'] as num?)?.toDouble() ?? 180.0;
    carbsTarget = (goals['carbs'] as num?)?.toDouble() ?? 250.0;

    fatsConsumed = (totals['fats'] as num?)?.toDouble() ?? 52.0;
    fatsTarget = (goals['fats'] as num?)?.toDouble() ?? 80.0;

    // Use default meal logs if none are provided
    logs = widget.mealLogs ?? _generateMockMeals();
  }

  List<MealLogEntity> _generateMockMeals() {
    final now = DateTime.now();
    return [
      MealLogEntity(
        id: '1',
        restaurantName: 'Abo Tareq Koshary',
        mealName: 'Koshary Plate (Medium)',
        calories: 680,
        protein: 18,
        carbs: 110,
        fats: 16,
        ingredientsBreakdown: const [
          IngredientBreakdown(ingredient: 'Pasta & Rice Mix', estimatedWeightGrams: 220),
          IngredientBreakdown(ingredient: 'Lentils & Chickpeas', estimatedWeightGrams: 80),
          IngredientBreakdown(ingredient: 'Tomato Spicy Sauce', estimatedWeightGrams: 60),
        ],
        source: 'text',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      MealLogEntity(
        id: '2',
        restaurantName: 'Buffalo Burger',
        mealName: 'Old School 200g (No Mayo)',
        calories: 820,
        protein: 48,
        carbs: 58,
        fats: 28,
        ingredientsBreakdown: const [
          IngredientBreakdown(ingredient: 'Grilled Beef Patty', estimatedWeightGrams: 200),
          IngredientBreakdown(ingredient: 'Cheddar Cheese Slice', estimatedWeightGrams: 25),
          IngredientBreakdown(ingredient: 'Brioche Bun', estimatedWeightGrams: 80),
        ],
        source: 'image',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      MealLogEntity(
        id: '3',
        restaurantName: 'El Ezba Grill',
        mealName: 'Shish Tawook Wrap',
        calories: 280,
        protein: 29,
        carbs: 12,
        fats: 8,
        ingredientsBreakdown: const [
          IngredientBreakdown(ingredient: 'Grilled Chicken Breast', estimatedWeightGrams: 120),
          IngredientBreakdown(ingredient: 'Bell Peppers & Onion', estimatedWeightGrams: 40),
          IngredientBreakdown(ingredient: 'Saj Flatbread', estimatedWeightGrams: 40),
        ],
        source: 'text',
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: DashboardThemeColors.background,
        colorScheme: const ColorScheme.dark(
          primary: DashboardThemeColors.accentEmerald,
          secondary: DashboardThemeColors.accentLime,
          surface: DashboardThemeColors.cardBackground,
        ),
      ),
      child: Scaffold(
        backgroundColor: DashboardThemeColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 28),
                _buildCircularProgressSection(),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMealLogsSection(),
                          const SizedBox(height: 24),
                          _buildAiRecommendationsCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final todayStr = DateFormat('EEEE, d MMMM').format(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ELITE NUTRITION',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: DashboardThemeColors.accentLime,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Meals Feed',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DashboardThemeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              todayStr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DashboardThemeColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DashboardThemeColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DashboardThemeColors.trackBackground,
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: DashboardThemeColors.accentEmerald,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DashboardThemeColors.trackBackground,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Performance",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DashboardThemeColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${((caloriesConsumed / caloriesTarget) * 100).round()}% Target',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: DashboardThemeColors.accentEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 12.0;
              final double itemWidth = (constraints.maxWidth - (spacing * 3)) / 4;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProgressItem(
                    label: 'CALORIES',
                    consumed: caloriesConsumed,
                    target: caloriesTarget,
                    unit: 'kcal',
                    color: DashboardThemeColors.accentLime,
                    width: itemWidth,
                  ),
                  _buildProgressItem(
                    label: 'PROTEIN',
                    consumed: proteinConsumed,
                    target: proteinTarget,
                    unit: 'g',
                    color: DashboardThemeColors.accentEmerald,
                    width: itemWidth,
                  ),
                  _buildProgressItem(
                    label: 'CARBS',
                    consumed: carbsConsumed,
                    target: carbsTarget,
                    unit: 'g',
                    color: const Color(0xFF60A5FA), // Accent Blue for carbs
                    width: itemWidth,
                  ),
                  _buildProgressItem(
                    label: 'FATS',
                    consumed: fatsConsumed,
                    target: fatsTarget,
                    unit: 'g',
                    color: const Color(0xFFF87171), // Accent Red/Orange for fats
                    width: itemWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required String label,
    required double consumed,
    required double target,
    required String unit,
    required Color color,
    required double width,
  }) {
    final double percentage = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    
    return SizedBox(
      width: width,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percentage),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return CustomPaint(
                size: Size(width - 4, width - 4),
                painter: CustomCircularProgressPainter(
                  progress: animValue,
                  color: color,
                  trackColor: DashboardThemeColors.trackBackground,
                  strokeWidth: 6.5,
                ),
                child: SizedBox(
                  width: width - 4,
                  height: width - 4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${consumed.round()}',
                          style: GoogleFonts.outfit(
                            fontSize: width > 75 ? 16 : 14,
                            fontWeight: FontWeight.w800,
                            color: DashboardThemeColors.textPrimary,
                          ),
                        ),
                        Text(
                          unit,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: DashboardThemeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: DashboardThemeColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Goal: ${target.round()}',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: DashboardThemeColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Today's Feed",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DashboardThemeColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DashboardThemeColors.trackBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${logs.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DashboardThemeColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16, color: DashboardThemeColors.accentLime),
              label: Text(
                'Add Log',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DashboardThemeColors.accentLime,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: DashboardThemeColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "No meals logged yet today.",
                style: GoogleFonts.inter(color: DashboardThemeColors.textSecondary),
              ),
            ),
          )
        else
          Column(
            children: logs.map((meal) => _buildMealLogCard(meal)).toList(),
          ),
      ],
    );
  }

  Widget _buildMealLogCard(MealLogEntity meal) {
    final mealTime = DateFormat('h:mm a').format(meal.createdAt.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DashboardThemeColors.trackBackground,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DashboardThemeColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  meal.source == 'image'
                      ? Icons.camera_alt_outlined
                      : Icons.restaurant_outlined,
                  color: DashboardThemeColors.accentLime,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.restaurantName.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: DashboardThemeColors.accentEmerald,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.mealName,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: DashboardThemeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mealTime,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: DashboardThemeColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DashboardThemeColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DashboardThemeColors.trackBackground,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${meal.calories.round()}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: DashboardThemeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'kcal',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: DashboardThemeColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Macros breakdown row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroLabel('Protein', '${meal.protein.round()}g', DashboardThemeColors.accentEmerald),
              _buildMacroLabel('Carbs', '${meal.carbs.round()}g', const Color(0xFF60A5FA)),
              _buildMacroLabel('Fats', '${meal.fats.round()}g', const Color(0xFFF87171)),
            ],
          ),
          if (meal.ingredientsBreakdown.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: DashboardThemeColors.trackBackground, height: 1),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: meal.ingredientsBreakdown.map((ing) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardThemeColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${ing.ingredient} (${ing.estimatedWeightGrams.round()}g)',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: DashboardThemeColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroLabel(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: DashboardThemeColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: DashboardThemeColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAiRecommendationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            DashboardThemeColors.cardBackground,
            Color(0xFF0F172A), // Slate-900 fading into slightly darker slate
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.03),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: DashboardThemeColors.accentEmerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Recommendation',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DashboardThemeColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "To hit your protein target of 170g today, you're currently 35g short. We recommend adding a snack of Greek yogurt or a grilled chicken skewer.",
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: DashboardThemeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardThemeColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DashboardThemeColors.trackBackground),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  color: DashboardThemeColors.accentLime,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Try 'Shish Tawook Wrap' at El Ezba Grill (Only 280 kcal & 29g protein)",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DashboardThemeColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardThemeColors.accentEmerald,
                foregroundColor: DashboardThemeColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Explore Recommended Restaurants',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Premium Circular Progress Indicators
class CustomCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  CustomCircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Track Paint
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc Paint
    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * 3.1415926535 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2, // Start at the top (90 degrees counterclockwise)
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
