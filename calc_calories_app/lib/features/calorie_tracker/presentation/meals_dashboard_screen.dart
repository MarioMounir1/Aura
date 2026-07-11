// lib/features/calorie_tracker/presentation/meals_dashboard_screen.dart
// Calc-Calories — Meals Dashboard UI (Elite Fitness Aesthetic)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../domain/entities/meal_log_entity.dart'; // Imports IngredientBreakdown

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

class MealWarning {
  final String warningText;
  final bool isSevere;

  const MealWarning({
    required this.warningText,
    required this.isSevere,
  });

  factory MealWarning.fromJson(Map<String, dynamic> json) {
    return MealWarning(
      warningText: json['warningText'] as String? ?? '',
      isSevere: json['isSevere'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warningText': warningText,
      'isSevere': isSevere,
    };
  }
}

class MealEntry {
  final String id;
  final String foodName;
  final String restaurantName;
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final List<MealWarning> warnings;
  final bool isHighlyNutritious;
  final DateTime createdAt;
  final String source; // "text" | "image"
  final List<IngredientBreakdown> ingredientsBreakdown;

  const MealEntry({
    required this.id,
    required this.foodName,
    required this.restaurantName,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.warnings,
    required this.isHighlyNutritious,
    required this.createdAt,
    required this.source,
    required this.ingredientsBreakdown,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    final macros = json['macros'] as Map<String, dynamic>? ?? {};
    final warningsList = json['warnings'] as List<dynamic>? ?? [];

    final protein = (macros['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (macros['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (macros['fat'] as num?)?.toDouble() ?? 0.0;
    final calories = (json['calories'] as num?)?.toDouble() ?? 0.0;

    final isNutritious = protein > 25 && calories < 450;

    return MealEntry(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: json['foodName'] as String? ?? 'Unknown Meal',
      restaurantName: json['restaurantName'] as String? ?? 'AI Snap Analyzer',
      protein: protein,
      carbs: carbs,
      fat: fat,
      calories: calories,
      warnings: warningsList.map((w) => MealWarning.fromJson(w as Map<String, dynamic>)).toList(),
      isHighlyNutritious: isNutritious,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      source: json['source'] as String? ?? 'text',
      ingredientsBreakdown: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodName': foodName,
      'restaurantName': restaurantName,
      'calories': calories.round(),
      'macros': {
        'protein': protein.round(),
        'carbs': carbs.round(),
        'fat': fat.round(),
      },
      'warnings': warnings.map((w) => w.toJson()).toList(),
      'isHighlyNutritious': isHighlyNutritious,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
    };
  }
}

// Clean asynchronous fetch methods using a mock HTTP service
class MealApiService {
  Future<MealEntry> analyzeMeal(String query, {String? image}) async {
    try {
      // Simulate network call latency
      await Future.delayed(const Duration(milliseconds: 1200));

      // Attempt hypothetical call to /api/meals/analyze
      // Since this is currently simulated or if backend is offline, we force a fallback exception.
      throw Exception('Real API endpoint /api/meals/analyze unavailable');
    } catch (e) {
      // High-fidelity fallback dummy data matching the JSON structure contract
      final lowerQuery = query.toLowerCase();
      final now = DateTime.now();

      final Map<String, dynamic> mockJson = {
        'id': now.millisecondsSinceEpoch.toString(),
        'restaurantName': 'AI Snap Analyzer',
        'createdAt': now.toIso8601String(),
        'source': image != null ? 'image' : 'text',
      };

      if (lowerQuery.contains('burger') ||
          lowerQuery.contains('pizza') ||
          lowerQuery.contains('fries') ||
          lowerQuery.contains('waffle') ||
          lowerQuery.contains('fat') ||
          lowerQuery.contains('crepe')) {
        mockJson.addAll({
          'foodName': query.isNotEmpty ? query : 'Double Pepperoni Cheat Meal',
          'calories': 780,
          'macros': {
            'protein': 26,
            'carbs': 88,
            'fat': 36,
          },
          'warnings': [
            {'warningText': 'Severe saturated fat spike detected', 'isSevere': true},
            {'warningText': 'High sodium load (+1600mg)', 'isSevere': true},
          ],
        });
      } else if (lowerQuery.contains('salad') ||
          lowerQuery.contains('chicken') ||
          lowerQuery.contains('salmon') ||
          lowerQuery.contains('fish') ||
          lowerQuery.contains('tuna') ||
          lowerQuery.contains('egg') ||
          lowerQuery.contains('protein') ||
          lowerQuery.contains('clean')) {
        mockJson.addAll({
          'foodName': query.isNotEmpty ? query : 'Grilled Chicken Protein Salad',
          'calories': 290,
          'macros': {
            'protein': 42,
            'carbs': 12,
            'fat': 8,
          },
          'warnings': [],
        });
      } else {
        mockJson.addAll({
          'foodName': query.isNotEmpty ? query : 'Custom Meal Entry',
          'calories': 386,
          'macros': {
            'protein': 20,
            'carbs': 45,
            'fat': 14,
          },
          'warnings': [
            {'warningText': 'Moderate fat/sodium content', 'isSevere': false},
          ],
        });
      }

      return MealEntry.fromJson(mockJson);
    }
  }
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
  late double caloriesConsumed;
  late double caloriesTarget;
  late double proteinConsumed;
  late double proteinTarget;
  late double carbsConsumed;
  late double carbsTarget;
  late double fatsConsumed;
  late double fatsTarget;

  late List<MealEntry> logs;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.mealLogs != null && widget.mealLogs!.isNotEmpty) {
      logs = widget.mealLogs!.map((entity) {
        final isNutritious = entity.protein > 25 && entity.calories < 400;
        final List<MealWarning> warnings = [];
        if (entity.carbs > 80) {
          warnings.add(const MealWarning(warningText: 'High carb load detected', isSevere: false));
        }
        if (entity.fats > 20) {
          warnings.add(const MealWarning(warningText: 'High saturated fat warning', isSevere: false));
        }
        if (entity.calories > 700) {
          warnings.add(const MealWarning(warningText: 'Sodium & saturated fat spike detected', isSevere: true));
        }

        return MealEntry(
          id: entity.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          foodName: entity.mealName,
          restaurantName: entity.restaurantName,
          protein: entity.protein,
          carbs: entity.carbs,
          fat: entity.fats,
          calories: entity.calories,
          warnings: warnings,
          isHighlyNutritious: isNutritious,
          createdAt: entity.createdAt,
          source: entity.source,
          ingredientsBreakdown: entity.ingredientsBreakdown,
        );
      }).toList();
    } else {
      logs = _generateMockMeals();
    }
    _recalculateTotals();
  }

  void _recalculateTotals() {
    final goals = widget.foodSummary?['goals'] as Map<String, dynamic>? ?? {};

    caloriesTarget = (goals['calories'] as num?)?.toDouble() ?? 2400.0;
    proteinTarget = (goals['protein'] as num?)?.toDouble() ?? 170.0;
    carbsTarget = (goals['carbs'] as num?)?.toDouble() ?? 250.0;
    fatsTarget = (goals['fats'] as num?)?.toDouble() ?? 80.0;

    caloriesConsumed = logs.fold(0.0, (sum, item) => sum + item.calories);
    proteinConsumed = logs.fold(0.0, (sum, item) => sum + item.protein);
    carbsConsumed = logs.fold(0.0, (sum, item) => sum + item.carbs);
    fatsConsumed = logs.fold(0.0, (sum, item) => sum + item.fat);
  }

  List<MealEntry> _generateMockMeals() {
    final now = DateTime.now();
    return [
      MealEntry(
        id: '1',
        restaurantName: 'Abo Tareq Koshary',
        foodName: 'Koshary Plate (Medium)',
        calories: 680,
        protein: 18,
        carbs: 110,
        fat: 16,
        warnings: const [
          MealWarning(warningText: 'High carb load detected', isSevere: false),
        ],
        isHighlyNutritious: false,
        ingredientsBreakdown: const [
          IngredientBreakdown(ingredient: 'Pasta & Rice Mix', estimatedWeightGrams: 220),
          IngredientBreakdown(ingredient: 'Lentils & Chickpeas', estimatedWeightGrams: 80),
          IngredientBreakdown(ingredient: 'Tomato Spicy Sauce', estimatedWeightGrams: 60),
        ],
        source: 'text',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      MealEntry(
        id: '2',
        restaurantName: 'Buffalo Burger',
        foodName: 'Old School 200g (No Mayo)',
        calories: 820,
        protein: 48,
        carbs: 58,
        fat: 28,
        warnings: const [
          MealWarning(warningText: 'Sodium & saturated fat spike detected', isSevere: true),
        ],
        isHighlyNutritious: false,
        ingredientsBreakdown: const [
          IngredientBreakdown(ingredient: 'Grilled Beef Patty', estimatedWeightGrams: 200),
          IngredientBreakdown(ingredient: 'Cheddar Cheese Slice', estimatedWeightGrams: 25),
          IngredientBreakdown(ingredient: 'Brioche Bun', estimatedWeightGrams: 80),
        ],
        source: 'image',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      MealEntry(
        id: '3',
        restaurantName: 'El Ezba Grill',
        foodName: 'Shish Tawook Wrap',
        calories: 280,
        protein: 29,
        carbs: 12,
        fat: 8,
        warnings: const [],
        isHighlyNutritious: true,
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

  // Interactive AI Meal Snap Bottom Sheet
  void _showAiMealSnapBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final textController = TextEditingController();
            String? selectedPhotoName;
            bool isAnalyzing = false;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              decoration: const BoxDecoration(
                color: DashboardThemeColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: DashboardThemeColors.trackBackground, width: 1.5),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DashboardThemeColors.trackBackground,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          color: DashboardThemeColors.accentEmerald,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AI Meal Snap',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: DashboardThemeColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Snap a photo or describe your meal. Our AI reverse-engineers macros instantly.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DashboardThemeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '1. DESCRIBE YOUR MEAL',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: DashboardThemeColors.accentLime,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      style: GoogleFonts.inter(color: DashboardThemeColors.textPrimary),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. 250g grilled chicken breast with basmati rice',
                        hintStyle: GoogleFonts.inter(color: DashboardThemeColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: DashboardThemeColors.background,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DashboardThemeColors.trackBackground),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DashboardThemeColors.trackBackground),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DashboardThemeColors.accentEmerald),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '2. MEAL PHOTO (OPTIONAL)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: DashboardThemeColors.accentLime,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            // ignore: dead_code
                            onPressed: isAnalyzing
                                ? null
                                : () {
                                    setSheetState(() {
                                      selectedPhotoName = 'snap_camera_${DateTime.now().millisecond}.jpg';
                                    });
                                  },
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DashboardThemeColors.background,
                              foregroundColor: DashboardThemeColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: DashboardThemeColors.trackBackground),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            // ignore: dead_code
                            onPressed: isAnalyzing
                                ? null
                                : () {
                                    setSheetState(() {
                                      selectedPhotoName = 'gallery_pick_${DateTime.now().millisecond}.jpg';
                                    });
                                  },
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DashboardThemeColors.background,
                              foregroundColor: DashboardThemeColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: DashboardThemeColors.trackBackground),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedPhotoName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: DashboardThemeColors.accentEmerald, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedPhotoName!,
                                style: GoogleFonts.inter(
                                  color: DashboardThemeColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: DashboardThemeColors.textSecondary),
                              onPressed: () {
                                setSheetState(() {
                                  selectedPhotoName = null;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        // ignore: dead_code
                        onPressed: isAnalyzing
                            ? null
                            : () async {
                                final desc = textController.text.trim();
                                if (desc.isEmpty && selectedPhotoName == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please describe your meal or select a photo.')),
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  isAnalyzing = true;
                                });

                                // Call the clean asynchronous mock API service
                                final apiService = MealApiService();
                                final newEntry = await apiService.analyzeMeal(
                                  desc,
                                  image: selectedPhotoName,
                                );

                                if (mounted) {
                                  setState(() {
                                    logs.insert(0, newEntry);
                                    _recalculateTotals();
                                  });
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: DashboardThemeColors.accentEmerald,
                                      content: Row(
                                        children: [
                                          const Icon(Icons.auto_awesome, color: Colors.black),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Processed successfully: +${newEntry.calories.round()} kcal!',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardThemeColors.accentEmerald,
                          foregroundColor: DashboardThemeColors.background,
                          disabledBackgroundColor: DashboardThemeColors.trackBackground,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(DashboardThemeColors.background),
                                ),
                              )
                            : Text(
                                'Analyze & Log Meal',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                  '${caloriesTarget > 0 ? ((caloriesConsumed / caloriesTarget) * 100).round() : 0}% Target',
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
              onPressed: () => _showAiMealSnapBottomSheet(context),
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

  Widget _buildMealLogCard(MealEntry meal) {
    final mealTime = DateFormat('h:mm a').format(meal.createdAt.toLocal());
    final hasSevere = meal.warnings.any((w) => w.isSevere);
    final hasWarnings = meal.warnings.isNotEmpty;

    // Card border color logic
    Color borderColor = DashboardThemeColors.trackBackground;
    if (hasSevere) {
      borderColor = Colors.red;
    } else if (hasWarnings) {
      borderColor = Colors.amber;
    } else if (meal.isHighlyNutritious) {
      borderColor = DashboardThemeColors.accentEmerald;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: meal.isHighlyNutritious || hasWarnings ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasWarnings) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: (hasSevere ? Colors.red : Colors.amber).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (hasSevere ? Colors.red : Colors.amber).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasSevere ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    color: hasSevere ? Colors.red : Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal.warnings.map((w) => w.warningText).join(", "),
                      style: GoogleFonts.inter(
                        color: hasSevere ? Colors.red[300] : Colors.amber[300],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  color: meal.isHighlyNutritious
                      ? DashboardThemeColors.accentEmerald
                      : (hasSevere ? Colors.red : DashboardThemeColors.accentLime),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        if (meal.isHighlyNutritious) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🌿 NUTRITIOUS',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: DashboardThemeColors.accentEmerald,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.foodName,
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
              _buildMacroLabel('Fats', '${meal.fat.round()}g', const Color(0xFFF87171)),
            ],
          ),
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
