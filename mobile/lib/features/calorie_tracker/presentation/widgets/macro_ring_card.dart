// lib/features/calorie_tracker/presentation/widgets/macro_ring_card.dart
// Calc-Calories — Animated macro result card with progress rings

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../../../core/theme/app_colors.dart';

class MacroRingCard extends StatefulWidget {
  final MealLogEntity meal;

  const MacroRingCard({super.key, required this.meal});

  @override
  State<MacroRingCard> createState() => _MacroRingCardState();
}

class _MacroRingCardState extends State<MacroRingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      meal.restaurantName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    meal.source == 'image'
                        ? Icons.image_rounded
                        : Icons.text_fields_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                meal.mealName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // ── Donut Ring + Center Calories ─────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            startDegreeOffset: -90,
                            sectionsSpace: 3,
                            centerSpaceRadius: 44,
                            sections: [
                              _buildSection(
                                value: meal.proteinPercent * _animation.value,
                                color: AppColors.protein,
                              ),
                              _buildSection(
                                value: meal.carbsPercent * _animation.value,
                                color: AppColors.carbs,
                              ),
                              _buildSection(
                                value: meal.fatsPercent * _animation.value,
                                color: AppColors.fats,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(meal.calories * _animation.value).round()}',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'kcal',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // ── Macro Bars ───────────────────────────
                  Expanded(
                    child: Column(
                      children: [
                        _MacroBar(
                          label: 'Protein',
                          value: meal.protein,
                          total: meal.protein + meal.carbs + meal.fats,
                          color: AppColors.protein,
                          animValue: _animation.value,
                        ),
                        const SizedBox(height: 12),
                        _MacroBar(
                          label: 'Carbs',
                          value: meal.carbs,
                          total: meal.protein + meal.carbs + meal.fats,
                          color: AppColors.carbs,
                          animValue: _animation.value,
                        ),
                        const SizedBox(height: 12),
                        _MacroBar(
                          label: 'Fats',
                          value: meal.fats,
                          total: meal.protein + meal.carbs + meal.fats,
                          color: AppColors.fats,
                          animValue: _animation.value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Ingredients Breakdown ────────────────────
              if (meal.ingredientsBreakdown.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                Text(
                  'Ingredients Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ...meal.ingredientsBreakdown.take(6).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.ingredient,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '~${item.estimatedWeightGrams.round()}g',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }

  PieChartSectionData _buildSection({
    required double value,
    required Color color,
  }) {
    return PieChartSectionData(
      value: value.clamp(0.01, 1.0),
      color: color,
      radius: 18,
      showTitle: false,
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;
  final double animValue;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * animValue).round()}g',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent * animValue,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
