// lib/features/calorie_tracker/presentation/progress_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'bloc/nutrition_progress_bloc.dart';

class ProgressSummaryScreen extends StatefulWidget {
  const ProgressSummaryScreen({super.key});

  @override
  State<ProgressSummaryScreen> createState() => _ProgressSummaryScreenState();
}

class _ProgressSummaryScreenState extends State<ProgressSummaryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NutritionProgressBloc>().add(const LoadNutritionHistory(days: 7));
  }

  void _onToggleDays(int days) {
    context.read<NutritionProgressBloc>().add(LoadNutritionHistory(days: days));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Progress Summary',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocBuilder<NutritionProgressBloc, NutritionProgressState>(
        builder: (context, state) {
          if (state is NutritionProgressLoading || state is NutritionProgressInitial) {
            return const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 3, color: AppColors.primary),
            );
          } else if (state is NutritionProgressError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is NutritionProgressLoaded) {
            final history = state.history;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Buttons
                  _buildToggleButtons(theme, state.selectedDays),
                  const SizedBox(height: 30),
                  
                  // Chart section
                  Text(
                    'Daily Calories',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: _buildChart(history, theme),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Stats Section
                  Text(
                    'Summary',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme: theme,
                          title: 'Avg Calories',
                          value: '${history.stats.averageCalories}',
                          unit: 'kcal/day',
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme: theme,
                          title: 'Avg Protein',
                          value: '${history.stats.averageProtein}',
                          unit: 'g/day',
                          icon: Icons.fitness_center_rounded,
                          color: AppColors.protein,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    theme: theme,
                    title: 'Days Goal Met',
                    value: '${history.stats.daysGoalMet} / ${state.selectedDays}',
                    unit: 'days',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildToggleButtons(AuraThemeExtension theme, int selectedDays) {
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderMid),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleDays(7),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedDays == 7 ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '7 Days',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selectedDays == 7 ? AppColors.primary : theme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleDays(30),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedDays == 30 ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '30 Days',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selectedDays == 30 ? AppColors.primary : theme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(history, AuraThemeExtension theme) {
    if (history.days.isEmpty) {
      return Center(
        child: Text('No data available.', style: TextStyle(color: theme.textSecondary)),
      );
    }
    
    final maxY = (history.goals.calories * 1.5).toDouble();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => theme.card,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = history.days[groupIndex];
              return BarTooltipItem(
                '${day.calories} kcal\\n',
                GoogleFonts.inter(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: DateFormat('MMM d').format(DateTime.parse(day.date)),
                    style: GoogleFonts.inter(
                      color: theme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= history.days.length) return const SizedBox.shrink();
                
                // Show fewer labels for 30 days
                if (history.days.length > 7 && index % 5 != 0 && index != history.days.length - 1) {
                  return const SizedBox.shrink();
                }
                
                final day = history.days[index];
                final date = DateTime.parse(day.date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: GoogleFonts.inter(color: theme.textSecondary, fontSize: 10),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: GoogleFonts.inter(color: theme.textSecondary, fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.borderMid.withValues(alpha: 0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: history.goals.calories.toDouble(),
              color: AppColors.primaryAccent,
              strokeWidth: 1.5,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.primaryAccent, fontWeight: FontWeight.bold),
                labelResolver: (line) => 'Goal',
              ),
            ),
          ],
        ),
        barGroups: List.generate(
          history.days.length,
          (i) {
            final day = history.days[i];
            final isOverGoal = day.calories > history.goals.calories;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: day.calories.toDouble(),
                  color: isOverGoal ? AppColors.warning : AppColors.primary,
                  width: history.days.length > 7 ? 8 : 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required AuraThemeExtension theme,
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderMid),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
