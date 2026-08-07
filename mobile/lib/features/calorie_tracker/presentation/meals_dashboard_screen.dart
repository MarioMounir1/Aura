// lib/features/calorie_tracker/presentation/meals_dashboard_screen.dart
// Calc-Calories â€” Meals Dashboard (Smart Scanner Rebuild)
//
// Architecture: StatefulWidget with 3 LayoutStates
//   - LayoutState.idle       â†’ Clean slate with Snap/Upload action cards
//   - LayoutState.processing â†’ Shimmer + pulsing analysis text
//   - LayoutState.resultLoaded â†’ Analysis Result Card + contextual banner
//
// Networking: LocalLlamaService (Dio multipart/form-data)
// Data Model: LlamaMealResponse (fully typed)
// Manual Logging: ManualMealService (Dio JSON POST to /meals/manual)

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/entities/meal_log_entity.dart';
import '../data/models/llama_meal_response.dart';
import '../data/models/ai_usage_quota.dart';
import '../data/models/barcode_product.dart';
import '../../premium/data/services/purchase_service.dart';
import '../data/services/local_llama_service.dart';
import '../data/services/barcode_service.dart';
import 'barcode_confirmation_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_metric_ring.dart';
import '../../../../core/widgets/app_action_tile.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../core/widgets/ad_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/bloc/profile_state.dart';

// â”€â”€ Layout State Enum â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum LayoutState { idle, processing, resultLoaded }

// â”€â”€ Theme Constants (Delegated to AppColors) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

typedef DashboardThemeColors = AppColors;

// â”€â”€ Existing MealWarning / MealEntry models (preserved) â”€â”€â”€â”€â”€â”€â”€

class MealWarning {
  final String warningText;
  final bool isSevere;
  const MealWarning({required this.warningText, required this.isSevere});
  factory MealWarning.fromJson(Map<String, dynamic> json) => MealWarning(
        warningText: json['warningText'] as String? ?? '',
        isSevere: json['isSevere'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() => {'warningText': warningText, 'isSevere': isSevere};
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
  final String source;
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

  factory MealEntry.fromLlamaResponse(LlamaMealResponse r) {
    final a = r.mealAnalysis;
    final List<MealWarning> warnings = [];
    if (a.carbs > 70 && a.protein < 30) {
      warnings.add(const MealWarning(warningText: 'High carb / low protein ratio', isSevere: false));
    }
    if (a.calories > 800) {
      warnings.add(const MealWarning(warningText: 'High calorie meal detected', isSevere: true));
    }
    if (a.fats > 30) {
      warnings.add(const MealWarning(warningText: 'Elevated fat content', isSevere: false));
    }
    return MealEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: a.detectedFood,
      restaurantName: 'Smart Scanner',
      protein: a.protein.toDouble(),
      carbs: a.carbs.toDouble(),
      fat: a.fats.toDouble(),
      calories: a.calories.toDouble(),
      warnings: warnings,
      isHighlyNutritious: a.isNutritious,
      createdAt: DateTime.now(),
      source: 'image',
      ingredientsBreakdown: const [],
    );
  }
}

// â”€â”€ Main Dashboard Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class MealsDashboard extends StatefulWidget {
  final Map<String, dynamic>? foodSummary;
  final List<MealLogEntity>? mealLogs;

  const MealsDashboard({super.key, this.foodSummary, this.mealLogs});

  @override
  State<MealsDashboard> createState() => _MealsDashboardState();
}

class _MealsDashboardState extends State<MealsDashboard> {
  // â”€â”€ Macro totals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late double caloriesConsumed;
  late double caloriesTarget;
  late double proteinConsumed;
  late double proteinTarget;
  late double carbsConsumed;
  late double carbsTarget;
  late double fatsConsumed;
  late double fatsTarget;

  // â”€â”€ Feed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late List<MealEntry> logs;

  // â”€â”€ Scanner State machine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  LayoutState _layoutState = LayoutState.idle;
  LlamaMealResponse? _llamaResult;
  // ignore: unused_field
  String? _errorMessage;
  File? _selectedImage;
  AiUsageQuota? _quota;

  // â”€â”€ Services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _llamaService   = LocalLlamaService();
  final _imagePicker    = ImagePicker();
  final _manualService  = ManualMealService();
  final _barcodeService = BarcodeService();

  @override
  void initState() {
    super.initState();
    _initData();
    _fetchQuota();
  }

  Future<void> _fetchQuota() async {
    try {
      final quota = await _llamaService.fetchAiUsage();
      if (mounted) {
        setState(() {
          _quota = quota;
        });
      }
    } catch (e) {
      debugPrint('Quota fetch error: $e');
    }
  }

  @override
  void didUpdateWidget(MealsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mealLogs != oldWidget.mealLogs || widget.foodSummary != oldWidget.foodSummary) {
      _initData();
    }
  }

  // â”€â”€ Data initialization (preserved from original) â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _initData() {
    if (widget.mealLogs != null && widget.mealLogs!.isNotEmpty) {
      final sortedEntities = List<MealLogEntity>.from(widget.mealLogs!)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      logs = sortedEntities.map((entity) {
        final isNutritious = entity.protein > 25 && entity.calories < 400;
        final List<MealWarning> warnings = [];
        if (entity.carbs > 80)     warnings.add(const MealWarning(warningText: 'High carb load detected', isSevere: false));
        if (entity.fats > 20)      warnings.add(const MealWarning(warningText: 'High saturated fat warning', isSevere: false));
        if (entity.calories > 700) warnings.add(const MealWarning(warningText: 'Sodium & saturated fat spike detected', isSevere: true));
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
      logs = [];
    }
    _recalcTotals();
  }

  void _recalcTotals() {
    final goals = widget.foodSummary?['goals'] as Map<String, dynamic>? ?? {};
    caloriesTarget = (goals['calories'] as num?)?.toDouble() ?? 2400.0;
    proteinTarget  = (goals['protein']  as num?)?.toDouble() ?? 170.0;
    carbsTarget    = (goals['carbs']    as num?)?.toDouble() ?? 250.0;
    fatsTarget     = (goals['fats']     as num?)?.toDouble() ?? 80.0;

    caloriesConsumed = logs.fold(0.0, (s, m) => s + m.calories);
    proteinConsumed  = logs.fold(0.0, (s, m) => s + m.protein);
    carbsConsumed    = logs.fold(0.0, (s, m) => s + m.carbs);
    fatsConsumed     = logs.fold(0.0, (s, m) => s + m.fat);
  }

  // â”€â”€ Image Pick & Upload â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _isPickingImage = false;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (picked == null) {
        _isPickingImage = false;
        return;
      }

      final scanType = source == ImageSource.camera ? 'camera' : 'gallery';

      setState(() {
        _selectedImage = File(picked.path);
        _layoutState   = LayoutState.processing;
        _llamaResult   = null;
        _errorMessage  = null;
      });

      final result = await _llamaService.scanMealImage(_selectedImage!, scanType);

      if (!mounted) return;
      setState(() {
        _llamaResult = result;
        _layoutState = LayoutState.resultLoaded;
      });
      _fetchQuota();
    } on LlamaApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _layoutState  = LayoutState.idle;
      });
      _showErrorSnackbar(e.message);
    } on LlamaNetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _layoutState  = LayoutState.idle;
      });
      _showErrorSnackbar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _layoutState  = LayoutState.idle;
      });
      _showErrorSnackbar('Scan failed: $e');
    } finally {
      _isPickingImage = false;
    }
  }

  void _showUpgradeDialog(String scanType, AiUsageQuota quota) {
    final isPremium = quota.isPremium;
    final limit = scanType == 'camera' ? quota.cameraLimit : quota.galleryLimit;
    final typeLabel = scanType == 'camera' ? 'camera' : 'screenshot';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardThemeColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPremium ? 'Daily Limit Reached' : 'Upgrade to Premium',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPremium 
            ? 'You have reached your daily limit of $limit $typeLabel scans. Your scans will reset tomorrow at midnight UTC.' 
            : 'You have used all $limit of your free $typeLabel scans for today. Upgrade to Premium to get up to 7 daily scans for each type!',
          style: GoogleFonts.inter(color: DashboardThemeColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isPremium ? 'Got it' : 'Maybe Later', style: GoogleFonts.inter(color: DashboardThemeColors.textMuted)),
          ),
          if (!isPremium)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardThemeColors.accentEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                PurchaseService.instance.presentPaywall(context);
              },
              child: Text('Upgrade Now', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _logResultToFeed() {
    if (_llamaResult == null) return;
    final entry = MealEntry.fromLlamaResponse(_llamaResult!);
    setState(() {
      logs.insert(0, entry);
      _recalcTotals();
      _layoutState  = LayoutState.idle;
      _llamaResult  = null;
      _selectedImage = null;
    });
  }

  void _discardResult() {
    setState(() {
      _layoutState   = LayoutState.idle;
      _llamaResult   = null;
      _selectedImage = null;
    });
  }

  // â”€â”€ Manual Macro Log Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showManualLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualLogSheet(
        onSaved: (entry) {
          setState(() {
            logs.insert(0, entry);
            _recalcTotals();
          });
        },
        service: _manualService,
        onError: _showErrorSnackbar,
      ),
    );
  }

  void _showEditSheet(MealEntry meal) {
    final idx = logs.indexOf(meal);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualLogSheet(
        initialEntry: meal,
        onSaved: (updated) {
          setState(() {
            if (idx >= 0 && idx < logs.length) {
              logs[idx] = updated;
            } else {
              logs.insert(0, updated);
            }
            _recalcTotals();
          });
        },
        service: _manualService,
        onError: _showErrorSnackbar,
      ),
    );
  }

  Future<void> _handleDeleteEntry(MealEntry meal, int idx) async {
    // 1. Optimistic remove
    setState(() {
      logs.removeAt(idx);
      _recalcTotals();
    });

    bool undone = false;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: DashboardThemeColors.accentRed, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Removed "${meal.foodName}"',
                style: GoogleFonts.inter(fontSize: 12, color: DashboardThemeColors.textPrimary),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: DashboardThemeColors.accentEmerald,
          onPressed: () {
            undone = true;
            setState(() {
              final insertAt = idx.clamp(0, logs.length);
              logs.insert(insertAt, meal);
              _recalcTotals();
            });
          },
        ),
      ),
    ).closed.then((_) async {
      if (undone) return;
      // Fire actual DELETE only after undo window closes without undo
      try {
        if (meal.source == 'food_db') {
          await _manualService.deleteFoodLog(meal.id);
        } else {
          await _manualService.deleteMealLog(meal.id);
        }
      } catch (e) {
        // Re-insert on failure
        if (mounted) {
          setState(() {
            final insertAt = idx.clamp(0, logs.length);
            logs.insert(insertAt, meal);
            _recalcTotals();
          });
          _showErrorSnackbar('Delete failed: $e');
        }
      }
    });
  }


  void _showErrorSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: DashboardThemeColors.accentRed, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: DashboardThemeColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  // ——— BUILD —————————————————————————————————————————————————————

  @override
  void _showNutrientsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NutrientsBottomSheet(
        caloriesConsumed: caloriesConsumed,
        caloriesTarget: caloriesTarget,
        proteinConsumed: proteinConsumed,
        proteinTarget: proteinTarget,
        carbsConsumed: carbsConsumed,
        carbsTarget: carbsTarget,
        fatsConsumed: fatsConsumed,
        fatsTarget: fatsTarget,
      ),
    );
  }

  void _showQuickLogChoiceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3E4D7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Log a Meal',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A2B)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCEEE3), child: Icon(Icons.camera_alt_rounded, color: Color(0xFF1E3A2B))),
              title: Text('Snap Meal Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              subtitle: Text('Scan food with AI camera', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyze(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCEEE3), child: Icon(Icons.photo_library_outlined, color: Color(0xFF1E3A2B))),
              title: Text('Upload Screenshot', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              subtitle: Text('Pick photo from gallery', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyze(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCEEE3), child: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1E3A2B))),
              title: Text('Scan Barcode', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              subtitle: Text('Instant nutrition lookup', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _scanBarcode();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCEEE3), child: Icon(Icons.search_rounded, color: Color(0xFF1E3A2B))),
              title: Text('Search Foods', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              subtitle: Text('Global database lookup', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed('/foods/search');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPremium = false;
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      isPremium = profileState.isPremium;
    }

    if (_layoutState != LayoutState.idle) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8F5),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildAiCanvas(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // 1. Top Header
              _TimelineDashboardHeader(
                onCameraTap: () => _pickAndAnalyze(ImageSource.camera),
              ),
              const SizedBox(height: 16),

              // 2. Daily Summary Banner
              _DailySummaryBanner(
                caloriesConsumed: caloriesConsumed,
                caloriesTarget: caloriesTarget,
              ),
              const SizedBox(height: 22),

              // 3. Meal Timeline Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MEAL TIMELINE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5A6E5D),
                      letterSpacing: 0.6,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showNutrientsSheet,
                    child: Row(
                      children: [
                        Text(
                          'See nutrients',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A2B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF1E3A2B),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Meal Timeline Items
              if (logs.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (ctx, index) {
                    final meal = logs[index];
                    return _MealTimelineTile(
                      key: ValueKey(meal.id),
                      meal: meal,
                      isLast: index == logs.length - 1,
                      onTap: () => _showEditSheet(meal),
                    );
                  },
                ),

              const SizedBox(height: 4),

              // 5. Quick Log Card
              _QuickLogCard(
                onTap: _showQuickLogChoiceSheet,
              ),

              const SizedBox(height: 20),

              // Ads Banner for Free Users
              if (!isPremium) ...[
                const AdBanner(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }



  // (macro rings extracted to _MacroRingsSection below)

  // ——— AI CANVAS (STATE SWITCH) ——————————————————————————————————

  Widget _buildAiCanvas() {
    switch (_layoutState) {
      case LayoutState.processing:
        return _ProcessingStateWidget(
          key: const ValueKey('processing'),
          selectedImage: _selectedImage,
        );
      case LayoutState.resultLoaded:
        return _ResultCardWidget(
          key: const ValueKey('result'),
          llamaResult: _llamaResult!,
          selectedImage: _selectedImage,
          onLog: _logResultToFeed,
          onDiscard: _discardResult,
        );
      case LayoutState.idle:
        return _SmartScannerSection(
          key: const ValueKey('idle'),
          quota: _quota,
          onCamera:  () => _pickAndAnalyze(ImageSource.camera),
          onGallery: () => _pickAndAnalyze(ImageSource.gallery),
          onBarcode: _scanBarcode,
          onSearch: () => Navigator.of(context).pushNamed('/foods/search'),
        );
    }
  }

  // ——— Barcode Scanner Flow ——————————————————————————————————————

  Future<void> _scanBarcode() async {
    // Step 1: Open camera-based barcode scanner overlay
    String? detectedBarcode;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BarcodeScannerOverlay(
        onDetected: (code) {
          detectedBarcode = code;
          Navigator.of(ctx).pop();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );

    if (detectedBarcode == null || detectedBarcode!.isEmpty) return;
    if (!mounted) return;

    // Step 2: Show a brief loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F1F1F),
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: DashboardThemeColors.accentAmber),
            ),
            const SizedBox(width: 12),
            Text(
              'Looking up barcode...',
              style: GoogleFonts.inter(
                  fontSize: 12, color: DashboardThemeColors.textPrimary),
            ),
          ],
        ),
      ),
    );

    // Step 3: Query the backend
    BarcodeProduct? product;
    try {
      product = await _barcodeService.lookupBarcode(detectedBarcode!);
    } on BarcodeNotFoundException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // ——— NOT FOUND —→ prompt user for product name & AI estimate ———
      product = await _promptForBarcodeEstimation(context, detectedBarcode!);
      if (product == null || !mounted) return;
    } on BarcodeNetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackbar('Barcode lookup failed: ${e.message}');
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackbar('Unexpected error: $e');
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Step 4: Show confirmation sheet
    final serving = await showModalBottomSheet<BarcodeServing>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeConfirmationSheet(
        product: product!,
        service: _barcodeService,
      ),
    );

    if (serving == null || !mounted) return;

    // Step 5: Add to today's feed
    final entry = MealEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: serving.product.productName,
      restaurantName: 'Barcode Scan',
      protein: serving.protein,
      carbs: serving.carbs,
      fat: serving.fats,
      calories: serving.calories,
      warnings: const [],
      isHighlyNutritious: serving.protein >= 20 && serving.calories < 400,
      createdAt: DateTime.now(),
      source: 'barcode',
      ingredientsBreakdown: const [],
    );

    setState(() {
      logs.insert(0, entry);
      _recalcTotals();
    });
  }

  Future<BarcodeProduct?> _promptForBarcodeEstimation(
    BuildContext context,
    String barcode,
  ) async {
    return showModalBottomSheet<BarcodeProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BarcodeNamePromptSheet(
        barcode: barcode,
        service: _barcodeService,
      ),
    );
  }

  int _calculateStreak(List<MealEntry> mealLogs) {
    if (mealLogs.isEmpty) return 1;
    final dates = mealLogs
        .map((l) => DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day))
        .toSet();
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime checkDate = dates.contains(today) ? today : (dates.contains(yesterday) ? yesterday : today);
    int streak = 0;
    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak > 0 ? streak : 1;
  }
}
// ↑ End of _MealsDashboardState

// ——— Dashboard Header ——————————————————————————————————————————

class _DashboardHeader extends StatelessWidget {
  final int streakCount;

  const _DashboardHeader({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('EEEE, d MMMM').format(DateTime.now());
    String userName = '';
    try {
      final profileState = BlocProvider.of<ProfileBloc>(context).state;
      if (profileState is ProfileLoaded) {
        userName = profileState.user['name'] ?? '';
      }
    } catch (_) {}

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.5),
                            child: Image.asset(
                              'assets/images/aura_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Aura',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.auraTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                todayStr,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.auraTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ——— Processing State Widget (Isolated Ticker) —————————————————

class _ProcessingStateWidget extends StatefulWidget {
  final File? selectedImage;

  const _ProcessingStateWidget({super.key, this.selectedImage});

  @override
  State<_ProcessingStateWidget> createState() => _ProcessingStateWidgetState();
}

class _ProcessingStateWidgetState extends State<_ProcessingStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('processing'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DashboardThemeColors.borderMid, width: 1),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      widget.selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DashboardThemeColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(40, 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerLine(width: 0.6, height: 16),
                        const SizedBox(height: 6),
                        _shimmerLine(width: 0.35, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _shimmerBox(double.infinity, 70)),
                  const SizedBox(width: 10),
                  Expanded(child: _shimmerBox(double.infinity, 70)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _shimmerBox(double.infinity, 70)),
                  const SizedBox(width: 10),
                  Expanded(child: _shimmerBox(double.infinity, 70)),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: DashboardThemeColors.accentEmerald,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DashboardThemeColors.accentEmerald.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Analyzing meal components locally...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DashboardThemeColors.accentEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerLine({required double width, required double height}) {
    return FractionallySizedBox(
      widthFactor: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: DashboardThemeColors.trackBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: DashboardThemeColors.trackBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ——— Result Card Widget (Redesigned per aura_design_spec.md Section 2) ———

class _ResultCardWidget extends StatefulWidget {
  final LlamaMealResponse llamaResult;
  final File? selectedImage;
  final VoidCallback onLog;
  final VoidCallback onDiscard;

  const _ResultCardWidget({
    super.key,
    required this.llamaResult,
    this.selectedImage,
    required this.onLog,
    required this.onDiscard,
  });

  @override
  State<_ResultCardWidget> createState() => _ResultCardWidgetState();
}

class _ResultCardWidgetState extends State<_ResultCardWidget> {
  double _servingMultiplier = 1.0;

  String _getCategoryBadgeText() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'BREAKFAST';
    if (hour >= 11 && hour < 16) return 'LUNCH';
    if (hour >= 16 && hour < 22) return 'DINNER';
    return 'SNACK';
  }

  int _calculateHealthScore(LlamaMealAnalysis analysis) {
    if (analysis.calories <= 0) return 75;
    final pCal = (analysis.protein * 4) / analysis.calories;
    final cCal = (analysis.carbs * 4) / analysis.calories;
    final fCal = (analysis.fats * 9) / analysis.calories;

    double score = 50.0;
    score += (pCal * 100).clamp(0, 30);
    if (cCal >= 0.3 && cCal <= 0.6) score += 15;
    if (fCal >= 0.15 && fCal <= 0.35) score += 15;
    if (analysis.calories < 650) score += 10;

    return score.round().clamp(20, 98);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final analysis = widget.llamaResult.mealAnalysis;
    final rec = widget.llamaResult.llamaRecommendation;

    final scaledCalories = (analysis.calories * _servingMultiplier).round();
    final scaledProtein  = (analysis.protein * _servingMultiplier).round();
    final scaledCarbs    = (analysis.carbs * _servingMultiplier).round();
    final scaledFats     = (analysis.fats * _servingMultiplier).round();

    final healthScore = _calculateHealthScore(analysis);
    final categoryText = _getCategoryBadgeText();

    // Generate ingredient pill items for photo overlay
    final rawNameParts = analysis.detectedFood.split(RegExp(r'[,&+]| and '));
    final List<String> tagItems = [];
    if (rawNameParts.length > 1) {
      for (var p in rawNameParts) {
        final trimmed = p.trim();
        if (trimmed.isNotEmpty) tagItems.add(trimmed);
      }
    }
    if (tagItems.isEmpty) {
      tagItems.addAll([
        analysis.detectedFood.split(' ').take(2).join(' '),
        'Protein · ${scaledProtein}g',
        'Carbs · ${scaledCarbs}g',
      ]);
    }

    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ——— 1. PHOTO HEADER WITH FLOATING ANNOTATION TAGS ———————————————————
        if (widget.selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.borderMid, width: 1),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      widget.selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Verified Badge top-right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.card.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_outlined, size: 13, color: AppColors.cyan),
                          const SizedBox(width: 4),
                          Text(
                            'Locally Verified',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Floating Ingredient Tags Overlaid on Image
                  if (tagItems.isNotEmpty)
                    Positioned(
                      top: 24,
                      left: 16,
                      child: _buildFloatingTag(tagItems[0], theme),
                    ),
                  if (tagItems.length > 1)
                    Positioned(
                      bottom: 24,
                      left: 16,
                      child: _buildFloatingTag(tagItems[1], theme),
                    ),
                  if (tagItems.length > 2)
                    Positioned(
                      bottom: 24,
                      right: 16,
                      child: _buildFloatingTag(tagItems[2], theme),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // ——— MAIN STRUCTURED RESULT CARD —————————————————————————————————————
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.borderMid.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ——— 2. CATEGORY BADGE, MEAL NAME & SERVING STEPPER —————————————————
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            categoryText,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: theme.primary,
                            ),
                          ),
                        ),

                        // Quantity / Serving Stepper
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _servingMultiplier > 0.5
                                    ? () => setState(() => _servingMultiplier -= 0.5)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.remove, size: 16, color: theme.textPrimary),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${_servingMultiplier % 1 == 0 ? _servingMultiplier.toInt() : _servingMultiplier}x',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textPrimary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _servingMultiplier += 0.5),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.add, size: 16, color: theme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      analysis.detectedFood,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // ——— 3. 2x2 ICON + MACRO GRID ————————————————————————————————————————
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMacroCard(
                            title: 'Calories',
                            value: '$scaledCalories kcal',
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.success,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMacroCard(
                            title: 'Carbs',
                            value: '${scaledCarbs}g',
                            icon: Icons.grain_rounded,
                            iconColor: AppColors.carbs,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMacroCard(
                            title: 'Protein',
                            value: '${scaledProtein}g',
                            icon: Icons.fitness_center_rounded,
                            iconColor: AppColors.protein,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMacroCard(
                            title: 'Fats',
                            value: '${scaledFats}g',
                            icon: Icons.opacity_rounded,
                            iconColor: AppColors.fats,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ——— 4. HEALTH SCORE ROW —————————————————————————————————————————————
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, size: 16, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                'Health Score',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$healthScore / 100',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: healthScore >= 70
                                  ? AppColors.success
                                  : (healthScore >= 50 ? AppColors.warning : AppColors.error),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (healthScore / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: theme.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            healthScore >= 70
                                ? AppColors.success
                                : (healthScore >= 50 ? AppColors.warning : AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ——— AI COACH NOTE (Renamed from "Llama says") ——————————————————————
              if (rec.message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: rec.triggerWarning
                          ? AppColors.warning.withValues(alpha: 0.12)
                          : theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: rec.triggerWarning
                            ? AppColors.warning.withValues(alpha: 0.4)
                            : theme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              rec.triggerWarning
                                  ? Icons.warning_amber_rounded
                                  : Icons.auto_awesome,
                              color: rec.triggerWarning ? AppColors.warning : theme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Your AI Coach',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: rec.triggerWarning ? AppColors.warning : theme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rec.message,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.4,
                            color: theme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ——— 5. TWO ACTION BUTTONS AT BOTTOM ————————————————————————————————
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    // Fix Results (Outlined ghost button)
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Fix results',
                        icon: Icons.edit_outlined,
                        iconColor: AppColors.warning,
                        onPressed: widget.onDiscard,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Done (Solid fill primary button)
                    Expanded(
                      child: AppButton.primary(
                        label: 'Done',
                        icon: Icons.check_circle_rounded,
                        onPressed: widget.onLog,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingTag(String text, AuraThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMacroCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required AuraThemeExtension theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ——— Barcode Scanner Overlay (½-screen modal) ———————————————————

/// Full-screen-ish camera overlay that reads barcodes via mobile_scanner.
/// Pops immediately on first detection, returning the scanned barcode string.
class _BarcodeScannerOverlay extends StatefulWidget {
  final void Function(String barcode) onDetected;
  final VoidCallback onCancel;

  const _BarcodeScannerOverlay({
    required this.onDetected,
    required this.onCancel,
  });

  @override
  State<_BarcodeScannerOverlay> createState() => _BarcodeScannerOverlayState();
}

class _BarcodeScannerOverlayState extends State<_BarcodeScannerOverlay> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _detected = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: false,
    );
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() => _permissionDenied = true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Permission.camera.status.then((status) {
        if (status.isGranted && mounted) {
          setState(() => _permissionDenied = false);
          _controller.start();
        }
      });
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: DashboardThemeColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: DashboardThemeColors.trackBg,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DashboardThemeColors.accentAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.barcode_reader,
                      color: DashboardThemeColors.accentAmber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan Barcode',
                          style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.bold,
                            color: DashboardThemeColors.textPrimary,
                          )),
                      Text('Point camera at product barcode',
                          style: GoogleFonts.inter(
                            fontSize: 11.5, color: DashboardThemeColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Flashlight',
                  icon: const Icon(Icons.flash_on_rounded, color: DashboardThemeColors.accentAmber, size: 20),
                  onPressed: () => _controller.toggleTorch(),
                ),
                IconButton(
                  tooltip: 'Switch Camera',
                  icon: const Icon(Icons.cameraswitch_outlined, color: DashboardThemeColors.textSecondary, size: 20),
                  onPressed: () => _controller.switchCamera(),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: DashboardThemeColors.textSecondary),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Camera view
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _permissionDenied
                    ? Container(
                        color: DashboardThemeColors.surface,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt_outlined, color: DashboardThemeColors.accentAmber, size: 48),
                                const SizedBox(height: 14),
                                Text(
                                  'Camera Access Needed',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardThemeColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Please enable camera permission in app settings to scan barcodes.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 12, color: DashboardThemeColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: openAppSettings,
                                  icon: const Icon(Icons.settings, size: 18),
                                  label: const Text('Open App Settings'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DashboardThemeColors.accentAmber,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          MobileScanner(
                            controller: _controller,
                            errorBuilder: (context, error, child) {
                              final isPerm = error.errorCode == MobileScannerErrorCode.permissionDenied;
                              return Container(
                                color: DashboardThemeColors.surface,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPerm ? Icons.camera_alt_outlined : Icons.videocam_outlined,
                                          color: DashboardThemeColors.accentAmber,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          isPerm ? 'Camera Access Needed' : 'Camera Ready',
                                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardThemeColors.textPrimary),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isPerm
                                              ? 'Please enable camera permission in settings to scan barcodes.'
                                              : 'Tap restart to initialize the camera preview.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(fontSize: 12, color: DashboardThemeColors.textSecondary),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            if (isPerm) {
                                              await openAppSettings();
                                            } else {
                                              await _controller.start();
                                            }
                                          },
                                          icon: Icon(isPerm ? Icons.settings : Icons.refresh_rounded, size: 18),
                                          label: Text(isPerm ? 'Open App Settings' : 'Restart Camera'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: DashboardThemeColors.accentAmber,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            onDetect: (capture) {
                              if (_detected) return;
                              for (final barcode in capture.barcodes) {
                                final rawValue = barcode.rawValue ?? barcode.displayValue;
                                if (rawValue != null && rawValue.trim().isNotEmpty) {
                                  _detected = true;
                                  widget.onDetected(rawValue.trim());
                                  break;
                                }
                              }
                            },
                          ),
                          // Aiming reticle overlay
                          Center(
                            child: Container(
                              width: 240,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: DashboardThemeColors.accentAmber,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          // Bottom hint
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Align barcode inside the frame',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: DashboardThemeColors.accentAmber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ——— Extracted: Daily Performance Rings —————————————————————————

class _MacroRingsSection extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesTarget;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatsConsumed;
  final double fatsTarget;
  final VoidCallback onTap;

  const _MacroRingsSection({
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatsConsumed,
    required this.fatsTarget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final calProgress = caloriesTarget > 0 ? (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0) : 0.0;
    final calRemaining = (caloriesTarget - caloriesConsumed).round();
    final remainingText = calRemaining >= 0 ? '$calRemaining kcal left' : '${-calRemaining} kcal over';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: theme.primary.withValues(alpha: 0.06),
        highlightColor: theme.primary.withValues(alpha: 0.03),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderMid.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row with Title and Signature Cyan Streak Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daily Performance',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: 'Tap to log manually',
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 17,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.cyan),
                        const SizedBox(width: 4),
                        Text(
                          '${caloriesTarget > 0 ? ((caloriesConsumed / caloriesTarget) * 100).round() : 0}% Target',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // â”€â”€ 1. DOMINANT PRIMARY CALORIE LINEAR BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Text(
                '${caloriesConsumed.round()}',
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                remainingText,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: calProgress),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Goal: ${caloriesTarget.round()} kcal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MacroChip(
                      label: 'Protein',
                      consumed: proteinConsumed,
                      target: proteinTarget,
                      color: AppColors.protein,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroChip(
                      label: 'Carbs',
                      consumed: carbsConsumed,
                      target: carbsTarget,
                      color: AppColors.carbs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroChip(
                      label: 'Fats',
                      consumed: fatsConsumed,
                      target: fatsTarget,
                      color: AppColors.fats,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderMid.withValues(alpha: 0.5)),
                ),
                child: Material(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/nutrition/progress'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bar_chart_rounded, size: 16, color: Colors.white),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View progress',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '7-day trend, averages & goal history',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${consumed.round()} / ${target.round()}g',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Senior Flutter: Cal AI Smart Scanner Hero â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SmartScannerSection extends StatelessWidget {
  final AiUsageQuota? quota;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onBarcode;
  final VoidCallback onSearch;

  const _SmartScannerSection({
    super.key,
    this.quota,
    required this.onCamera,
    required this.onGallery,
    required this.onBarcode,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final int cameraUsage = quota?.cameraUsage ?? 0;
    final int cameraLimit = quota?.cameraLimit ?? 2;
    final int galleryUsage = quota?.galleryUsage ?? 0;
    final int galleryLimit = quota?.galleryLimit ?? 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Two square/equal-sized gradient tiles side by side
        Row(
          children: [
            // Snap Meal Tile
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCamera,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 96,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: theme.snapMealGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                        const Spacer(),
                        Text(
                          'Snap meal',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Camera · $cameraUsage/$cameraLimit today',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Upload Screenshot Tile
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onGallery,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 96,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: theme.uploadScreenshotGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
                        ),
                        const Spacer(),
                        Text(
                          'Upload screenshot',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gallery · $galleryUsage/$galleryLimit today',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Search Food Flat Row
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSearch,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search_rounded, color: AppColors.success, size: 17),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search food',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Global search across millions of foods',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 3. Scan Barcode Gradient Row
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBarcode,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: theme.scanBarcodeGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan barcode',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Instant nutrition Â· Unlimited',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Senior Flutter: MyFitnessPal Categorized Food Diary â”€â”€â”€â”€â”€â”€

class _FeedSection extends StatelessWidget {
  final List<MealEntry> logs;
  final VoidCallback onSnap;
  final void Function(MealEntry) onEdit;
  final void Function(MealEntry, int) onDelete;

  const _FeedSection({
    required this.logs,
    required this.onSnap,
    required this.onEdit,
    required this.onDelete,
  });

  Map<String, List<MealEntry>> _categorizeLogs() {
    final Map<String, List<MealEntry>> categorized = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snacks': [],
    };

    for (var log in logs) {
      final hour = log.createdAt.hour;
      if (hour >= 5 && hour < 11) {
        categorized['Breakfast']!.add(log);
      } else if (hour >= 11 && hour < 16) {
        categorized['Lunch']!.add(log);
      } else if (hour >= 16 && hour < 22) {
        categorized['Dinner']!.add(log);
      } else {
        categorized['Snacks']!.add(log);
      }
    }
    return categorized;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final categorized = _categorizeLogs();
    final categories = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      "Daily Food Diary",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.border),
                    ),
                    child: Text(
                      '${logs.length} logged',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/foods/search'),
              icon: const Icon(Icons.search_rounded, size: 16, color: AppColors.cyan),
              label: Text(
                'Search',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: theme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No meals logged yet today',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Snap a photo or search to log your breakfast, lunch, or dinner.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (var cat in categories)
                if (categorized[cat]!.isNotEmpty) ...[
                  _MealCategorySlotCard(
                    categoryTitle: cat,
                    categoryLogs: categorized[cat]!,
                    onSnap: onSnap,
                    onEdit: onEdit,
                    onDelete: (meal) {
                      final idx = logs.indexOf(meal);
                      if (idx >= 0) onDelete(meal, idx);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
      ],
    );
  }
}

class _MealCategorySlotCard extends StatelessWidget {
  final String categoryTitle;
  final List<MealEntry> categoryLogs;
  final VoidCallback onSnap;
  final void Function(MealEntry) onEdit;
  final void Function(MealEntry) onDelete;

  const _MealCategorySlotCard({
    required this.categoryTitle,
    required this.categoryLogs,
    required this.onSnap,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getCategoryIcon() {
    switch (categoryTitle) {
      case 'Breakfast':
        return Icons.free_breakfast_outlined;
      case 'Lunch':
        return Icons.lunch_dining_outlined;
      case 'Dinner':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.cookie_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final totalCalories = categoryLogs.fold<double>(0, (sum, item) => sum + item.calories).round();

    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getCategoryIcon(), color: theme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      categoryTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$totalCalories kcal',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: totalCalories > 0 ? theme.primary : theme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Logged Food Item Rows
          if (categoryLogs.isNotEmpty) ...[
            for (var meal in categoryLogs) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.foodName,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${meal.calories.round()} kcal',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'P: ${meal.protein.round()}g Â· C: ${meal.carbs.round()}g Â· F: ${meal.fat.round()}g',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: theme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      color: theme.textSecondary,
                      onPressed: () => onEdit(meal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      color: AppColors.danger,
                      onPressed: () => onDelete(meal),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
            ],
          ],

          // Quick + Add Food Button
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/foods/search'),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 4),
                  Text(
                    'ADD FOOD',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Extracted: Single Meal Log Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MealLogCard extends StatelessWidget {
  final MealEntry meal;
  final int index;
  final void Function(MealEntry) onEdit;
  final void Function(MealEntry, int) onDelete;

  const _MealLogCard({
    super.key,
    required this.meal,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mealTime  = DateFormat('h:mm a').format(meal.createdAt.toLocal());
    final hasSevere = meal.warnings.any((w) => w.isSevere);
    final hasWarn   = meal.warnings.isNotEmpty;
    Color borderColor = DashboardThemeColors.trackBg;
    if (hasSevere) {
      borderColor = DashboardThemeColors.accentRed;
    } else if (hasWarn) {
      borderColor = DashboardThemeColors.accentAmber;
    } else if (meal.isHighlyNutritious) {
      borderColor = DashboardThemeColors.accentEmerald;
    }

    return Dismissible(
      key: ValueKey('dismiss_${meal.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete(meal, index);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: DashboardThemeColors.accentRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DashboardThemeColors.accentRed.withValues(alpha: 0.3)),
        ),
        child: const Icon(
          Icons.delete_sweep_outlined,
          color: DashboardThemeColors.accentRed,
          size: 26,
        ),
      ),
      child: GestureDetector(
        onTap: () => onEdit(meal),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DashboardThemeColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: hasWarn || meal.isHighlyNutritious ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasWarn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: (hasSevere
                            ? DashboardThemeColors.accentRed
                            : DashboardThemeColors.accentAmber)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (hasSevere
                              ? DashboardThemeColors.accentRed
                              : DashboardThemeColors.accentAmber)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      hasSevere
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: hasSevere
                          ? DashboardThemeColors.accentRed
                          : DashboardThemeColors.accentAmber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal.warnings.map((w) => w.warningText).join(', '),
                        style: GoogleFonts.inter(
                          color: hasSevere
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFFCD34D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]),
                ),
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
                          : (hasSevere
                              ? DashboardThemeColors.accentRed
                              : DashboardThemeColors.accentLime),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: DashboardThemeColors.accentEmerald
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ðŸŒ¿ NUTRITIOUS',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: DashboardThemeColors.accentEmerald,
                                ),
                              ),
                            ),
                          ],
                        ]),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: DashboardThemeColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: DashboardThemeColors.trackBg),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                        ]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 11,
                              color: DashboardThemeColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: DashboardThemeColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _macroLabel('Protein', '${meal.protein.round()}g', DashboardThemeColors.accentEmerald),
                  _macroLabel('Carbs',   '${meal.carbs.round()}g',   DashboardThemeColors.accentBlue),
                  _macroLabel('Fats',    '${meal.fat.round()}g',     DashboardThemeColors.accentRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _macroLabel(String label, String value, Color color) {
    return Row(children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    ]);
  }
}

// â”€â”€ Manual Meal Service (Dio POST/PUT/DELETE to /meals & /food-logs) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ManualMealService {
  static const Duration _timeout = Duration(seconds: 20);
  late final Dio _dio;

  ManualMealService() {
    const secureStorage = FlutterSecureStorage();
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiV1,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );
    // Inject JWT on every request â€” same pattern as LocalLlamaService
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // â”€â”€ Create â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> postManualLog({
    required String mealName,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    await _dio.post<dynamic>(
      '/meals/manual',
      data: {
        'mealName': mealName.isEmpty ? 'Manual Entry' : mealName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'loggedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // â”€â”€ Update MealLog (manual / ai scan) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> updateMealLog(
    String id, {
    required String mealName,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    await _dio.put<dynamic>(
      '/meals/$id',
      data: {
        'mealName': mealName.isEmpty ? 'Manual Entry' : mealName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      },
    );
  }

  // â”€â”€ Update FoodLog (db-search entries â€” servings only) â”€â”€â”€â”€

  Future<void> updateFoodLog(String id, {required double servings}) async {
    await _dio.put<dynamic>('/food-logs/$id', data: {'servings': servings});
  }

  // â”€â”€ Delete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> deleteMealLog(String id) async {
    await _dio.delete<dynamic>('/meals/$id');
  }

  Future<void> deleteFoodLog(String id) async {
    await _dio.delete<dynamic>('/food-logs/$id');
  }
}


// â”€â”€ Manual Log Bottom Sheet Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ManualLogSheet extends StatefulWidget {
  final void Function(MealEntry entry) onSaved;
  final ManualMealService service;
  final void Function(String) onError;
  final MealEntry? initialEntry; // non-null â†’ edit mode

  const _ManualLogSheet({
    required this.onSaved,
    required this.service,
    required this.onError,
    this.initialEntry,
  });

  @override
  State<_ManualLogSheet> createState() => _ManualLogSheetState();
}

class _ManualLogSheetState extends State<_ManualLogSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _mealNameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl  = TextEditingController();
  final _carbsCtrl    = TextEditingController();
  final _fatsCtrl     = TextEditingController();
  bool _isSaving      = false;
  bool get _isEdit    => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    if (e != null) {
      _mealNameCtrl.text = e.foodName;
      _caloriesCtrl.text = e.calories.round().toString();
      _proteinCtrl.text  = e.protein.round().toString();
      _carbsCtrl.text    = e.carbs.round().toString();
      _fatsCtrl.text     = e.fat.round().toString();
    }
  }

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final calories = double.parse(_caloriesCtrl.text.trim());
    final protein  = double.parse(_proteinCtrl.text.trim());
    final carbs    = double.parse(_carbsCtrl.text.trim());
    final fats     = double.parse(_fatsCtrl.text.trim());
    final name     = _mealNameCtrl.text.trim();

    if (_isEdit) {
      final orig = widget.initialEntry!;
      try {
        if (orig.source == 'food_db') {
          await widget.service.updateFoodLog(orig.id, servings: 1.0);
        } else {
          await widget.service.updateMealLog(
            orig.id,
            mealName: name.isEmpty ? orig.foodName : name,
            calories: calories,
            protein:  protein,
            carbs:    carbs,
            fats:     fats,
          );
        }

        final updatedEntry = MealEntry(
          id:                  orig.id,
          foodName:            name.isEmpty ? orig.foodName : name,
          restaurantName:      orig.restaurantName,
          protein:             protein,
          carbs:               carbs,
          fat:                 fats,
          calories:            calories,
          warnings:            orig.warnings,
          isHighlyNutritious:  protein > 25 && calories < 400,
          createdAt:           orig.createdAt,
          source:              orig.source,
          ingredientsBreakdown: orig.ingredientsBreakdown,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSaved(updatedEntry);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        widget.onError('Could not sync edit to server: $e');
      }
    } else {
      try {
        await widget.service.postManualLog(
          mealName: name,
          calories: calories,
          protein:  protein,
          carbs:    carbs,
          fats:     fats,
        );

        final entry = MealEntry(
          id:                  DateTime.now().millisecondsSinceEpoch.toString(),
          foodName:            name.isEmpty ? 'Manual Entry' : name,
          restaurantName:      'Manual Log',
          protein:             protein,
          carbs:               carbs,
          fat:                 fats,
          calories:            calories,
          warnings:            const [],
          isHighlyNutritious:  protein > 25 && calories < 400,
          createdAt:           DateTime.now(),
          source:              'manual',
          ingredientsBreakdown: const [],
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSaved(entry);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        widget.onError('Could not sync to server: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: DashboardThemeColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Sheet handle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: DashboardThemeColors.trackBg,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // â”€â”€ Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_isEdit
                        ? DashboardThemeColors.accentBlue
                        : DashboardThemeColors.accentEmerald
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_rounded : Icons.edit_note_rounded,
                    color: _isEdit
                        ? DashboardThemeColors.accentBlue
                        : DashboardThemeColors.accentEmerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Edit Meal' : 'Manual Macro Log',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DashboardThemeColors.textPrimary,
                      ),
                    ),
                    Text(
                      _isEdit
                          ? 'Update macros for this entry'
                          : 'Log a meal by entering macros directly',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: DashboardThemeColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // â”€â”€ Meal name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _MacroField(
              controller: _mealNameCtrl,
              label: 'Meal Name',
              hint: 'e.g. Grilled Chicken & Rice',
              unit: '',
              icon: Icons.restaurant_menu_outlined,
              isOptional: true,
              validator: null,
            ),

            const SizedBox(height: 12),

            // â”€â”€ Macro fields in 2Ã—2 grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              children: [
                Expanded(
                  child: _MacroField(
                    controller: _caloriesCtrl,
                    label: 'Calories',
                    hint: '0',
                    unit: 'kcal',
                    icon: Icons.local_fire_department_outlined,
                    iconColor: DashboardThemeColors.accentLime,
                    validator: _numValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroField(
                    controller: _proteinCtrl,
                    label: 'Protein',
                    hint: '0',
                    unit: 'g',
                    icon: Icons.fitness_center_outlined,
                    iconColor: DashboardThemeColors.accentEmerald,
                    validator: _numValidator,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _MacroField(
                    controller: _carbsCtrl,
                    label: 'Carbs',
                    hint: '0',
                    unit: 'g',
                    icon: Icons.grain_outlined,
                    iconColor: DashboardThemeColors.accentBlue,
                    validator: _numValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroField(
                    controller: _fatsCtrl,
                    label: 'Fats',
                    hint: '0',
                    unit: 'g',
                    icon: Icons.opacity_outlined,
                    iconColor: DashboardThemeColors.accentRed,
                    validator: _numValidator,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // â”€â”€ Save button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Icon(_isEdit ? Icons.save_outlined : Icons.check_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Save Log'),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEdit
                      ? DashboardThemeColors.accentBlue
                      : DashboardThemeColors.accentEmerald,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      DashboardThemeColors.accentEmerald.withValues(alpha: 0.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _numValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a number';
    if (n < 0) return 'Must be â‰¥ 0';
    return null;
  }
}

// â”€â”€ Reusable Macro Input Field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€


class _MacroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  final IconData icon;
  final Color? iconColor;
  final bool isOptional;
  final String? Function(String?)? validator;

  const _MacroField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
    required this.icon,
    this.iconColor,
    this.isOptional = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: isOptional
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      validator: isOptional ? null : validator,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DashboardThemeColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (optional)' : ''),
        hintText: hint,
        suffixText: unit.isEmpty ? null : unit,
        prefixIcon: Icon(
          icon,
          size: 18,
          color: iconColor ?? DashboardThemeColors.textMuted,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: DashboardThemeColors.textMuted,
        ),
        hintStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: DashboardThemeColors.textMuted.withValues(alpha: 0.5),
        ),
        suffixStyle: GoogleFonts.inter(
          fontSize: 11,
          color: DashboardThemeColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: DashboardThemeColors.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardThemeColors.trackBg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardThemeColors.trackBg),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DashboardThemeColors.accentEmerald,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardThemeColors.accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DashboardThemeColors.accentRed,
            width: 1.5,
          ),
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 10,
          color: DashboardThemeColors.accentRed,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

// â”€â”€ Custom Circular Progress Painter (preserved) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2,
      2 * 3.1415926535 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomCircularProgressPainter old) =>
      old.progress != progress || old.color != color ||
      old.trackColor != trackColor || old.strokeWidth != strokeWidth;
}

class _BarcodeNamePromptSheet extends StatefulWidget {
  final String barcode;
  final BarcodeService service;

  const _BarcodeNamePromptSheet({
    required this.barcode,
    required this.service,
  });

  @override
  State<_BarcodeNamePromptSheet> createState() => _BarcodeNamePromptSheetState();
}

class _BarcodeNamePromptSheetState extends State<_BarcodeNamePromptSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEstimating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isEstimating) return;
    setState(() => _isEstimating = true);

    try {
      final product = await widget.service.estimateBarcode(
        barcode: widget.barcode,
        productName: _nameController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(product);
    } catch (e) {
      if (mounted) {
        setState(() => _isEstimating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Estimation failed: $e',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DashboardThemeColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DashboardThemeColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DashboardThemeColors.accentAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: DashboardThemeColors.accentAmber, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Not Found',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: DashboardThemeColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Enter product name for AI nutrition estimation',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: DashboardThemeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.inter(color: DashboardThemeColors.textPrimary),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a product name';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'e.g. Greek Yogurt 200g',
                hintStyle: GoogleFonts.inter(color: DashboardThemeColors.textMuted),
                filled: true,
                fillColor: DashboardThemeColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: DashboardThemeColors.accentCyan, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isEstimating ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardThemeColors.accentCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isEstimating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : Text(
                        'Estimate Nutrition with AI',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// REDESIGNED TIMELINE DASHBOARD WIDGETS
// ══════════════════════════════════════════════════════════════

class _TimelineDashboardHeader extends StatelessWidget {
  final VoidCallback onCameraTap;
  const _TimelineDashboardHeader({required this.onCameraTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7A8B7B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your meals',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C2B1E),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onCameraTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A2B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x201E3A2B),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailySummaryBanner extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesTarget;

  const _DailySummaryBanner({
    required this.caloriesConsumed,
    required this.caloriesTarget,
  });

  @override
  Widget build(BuildContext context) {
    final double target = caloriesTarget > 0 ? caloriesTarget : 2000.0;
    final int percent = ((caloriesConsumed / target) * 100).clamp(0, 100).round();
    final formatter = NumberFormat('#,###');
    final String consumedStr = formatter.format(caloriesConsumed.round());
    final String targetStr = formatter.format(target.round());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEE3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 18,
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY SUMMARY',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4A6B56),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A good day\nstarts here.',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A2B),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$consumedStr of $targetStr kcal logged',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B5745),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x101E3A2B),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$percent%',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A2B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTimelineTile extends StatelessWidget {
  final MealEntry meal;
  final bool isLast;
  final VoidCallback onTap;

  const _MealTimelineTile({
    super.key,
    required this.meal,
    required this.isLast,
    required this.onTap,
  });

  String _getMealCategory(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 15) return 'Lunch';
    if (hour >= 15 && hour < 18) return 'Afternoon';
    return 'Dinner';
  }

  @override
  Widget build(BuildContext context) {
    final category = _getMealCategory(meal.createdAt);
    final timeStr = DateFormat('HH:mm').format(meal.createdAt);
    final calStr = '${meal.calories.round()} kcal';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: 0,
                    left: 15,
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2EBE4),
                    ),
                  ),
                Positioned(
                  top: 24,
                  left: 9,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEEE3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1E3A2B),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: const Color(0xFFF1F6F2),
                            child: const Center(
                              child: Text('🥗', style: TextStyle(fontSize: 28)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    category,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1C2B1E),
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: Color(0xFF7A8B7B),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7A8B7B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                meal.foodName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7C6E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '🔥 $calStr',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFE07A5F),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFB0C0B4),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickLogCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD3E4D7),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Color(0xFF1E3A2B),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log your next meal',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A2B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Snap a photo or search foods',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6B7C6E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutrientsBottomSheet extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesTarget;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatsConsumed;
  final double fatsTarget;

  const _NutrientsBottomSheet({
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatsConsumed,
    required this.fatsTarget,
  });

  Widget _buildNutrientRow(String label, double consumed, double target, Color accentColor, String unit) {
    final double pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1C2B1E)),
            ),
            Text(
              '${consumed.round()} / ${target.round()} $unit',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7C6E)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2EBE4),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3E4D7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Daily Nutrients',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A2B)),
          ),
          const SizedBox(height: 18),
          _buildNutrientRow('Calories', caloriesConsumed, caloriesTarget, const Color(0xFFE07A5F), 'kcal'),
          _buildNutrientRow('Protein', proteinConsumed, proteinTarget, const Color(0xFF2563EB), 'g'),
          _buildNutrientRow('Carbs', carbsConsumed, carbsTarget, const Color(0xFFF59E0B), 'g'),
          _buildNutrientRow('Fats', fatsConsumed, fatsTarget, const Color(0xFF10B981), 'g'),
        ],
      ),
    );
  }
}

