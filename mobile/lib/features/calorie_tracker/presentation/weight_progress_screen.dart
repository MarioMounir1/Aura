// lib/features/calorie_tracker/presentation/weight_progress_screen.dart
// The Teneen — Weight Progress Tracking with Line Charts

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cubit/unit_cubit.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/weight_bloc.dart';
import 'bloc/weight_event.dart';
import 'bloc/weight_state.dart';
import 'bloc/dashboard_bloc.dart';
import 'bloc/dashboard_event.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/bloc/profile_event.dart';
import '../../../core/widgets/app_button.dart';

class WeightProgressScreen extends StatefulWidget {
  const WeightProgressScreen({super.key});

  @override
  State<WeightProgressScreen> createState() => _WeightProgressScreenState();
}

class _WeightProgressScreenState extends State<WeightProgressScreen> {
  final _weightInputController = TextEditingController();
  WeightLoaded? _lastLoadedState;

  @override
  void dispose() {
    _weightInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.weightTitle),
        centerTitle: false,
      ),
      body: BlocListener<WeightBloc, WeightState>(
        listener: (context, state) {
          if (state is WeightLogSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.primary),
            );
            // Refresh dashboard + profile blocs to update user weight value globally
            context.read<DashboardBloc>().add(const RefreshDashboard());
            context.read<ProfileBloc>().add(LoadProfile());
          } else if (state is WeightFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<WeightBloc, WeightState>(
          builder: (context, state) {
            if (state is WeightLoaded) {
              _lastLoadedState = state;
            }

            if (state is WeightInitial && _lastLoadedState == null) {
              context.read<WeightBloc>().add(const LoadWeightHistory(days: 30));
            }

            final displayState = _lastLoadedState ?? const WeightLoaded(
              logs: [],
              currentWeight: 0.0,
              goal: 'maintain',
              stats: null,
              coachNote: 'Loading...',
              activeDaysFilter: 30,
            );

            if (state is WeightFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<WeightBloc>().add(const LoadWeightHistory(days: 30)),
                      child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                _buildContent(context, displayState, l10n),
                if (state is WeightLoading || _lastLoadedState == null)
                  const Positioned(
                    top: 0, left: 0, right: 0,
                    child: LinearProgressIndicator(minHeight: 3, color: AppColors.primary),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeightLoaded state, AppLocalizations l10n) {
    final hasHistory = state.logs.isNotEmpty;
    final unitSystem = context.watch<UnitCubit>().state;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // ── Days filter selection ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [7, 30, 90, 180].map((days) {
              final isSelected = state.activeDaysFilter == days;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${days}d'),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      context.read<WeightBloc>().add(LoadWeightHistory(days: days));
                    }
                  },
                  selectedColor: AppColors.accent.withOpacity(0.15),
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Line Chart of Weight Progress ─────────────────────────────────
          if (hasHistory)
            _buildWeightChart(state.logs, unitSystem)
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              child: Text(l10n.weightNoHistory, style: const TextStyle(color: AppColors.textSecondary)),
            ),

          // ── AI Weight Coach Guidance Card ──────────────────────────────
          if (state.coachNote != null && state.coachNote!.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.coachNote!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Weight Logger Action Button ───────────────────────────────────
          AppButton.primary(
            label: l10n.weightLogToday,
            icon: Icons.add_rounded,
            onPressed: () => _showLogWeightDialog(context, l10n),
          ),
          const SizedBox(height: 24),

          // ── Stats Summary Grid ────────────────────────────────────────────
          if (hasHistory && state.stats != null)
            _buildStatsGrid(state.stats!, l10n, unitSystem),
          const SizedBox(height: 32),

          // ── Recent Weight logs ────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.homeRecentMeals.replaceFirst(l10n.homeRecentMeals.split(' ')[0], l10n.waterToday),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          _buildLogsList(context, state.logs, l10n, unitSystem),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<dynamic> logs, UnitSystem unitSystem) {
    // Parse data points
    final List<FlSpot> spots = [];
    double minWeight = 2000.0;
    double maxWeight = 0.0;

    for (int i = 0; i < logs.length; i++) {
      final double weightKg = (logs[i]['weightKg'] as num).toDouble();
      final double weight = unitSystem == UnitSystem.imperial ? UnitConverter.kgToLbs(weightKg) : weightKg;
      spots.add(FlSpot(i.toDouble(), weight));

      if (weight < minWeight) minWeight = weight;
      if (weight > maxWeight) maxWeight = weight;
    }

    final double yPadding = unitSystem == UnitSystem.imperial ? 4.0 : 2.0;
    final double minY = (minWeight - yPadding).clamp(0.0, 2000.0);
    final double maxY = maxWeight + yPadding;

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (logs.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length < 15,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.accent,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, AppLocalizations l10n, UnitSystem unitSystem) {
    final double totalDeltaKg = (stats['totalDelta'] as num).toDouble();
    final double deltaVal = unitSystem == UnitSystem.imperial ? UnitConverter.kgToLbs(totalDeltaKg) : totalDeltaKg;
    final String unitSuffix = unitSystem == UnitSystem.imperial ? 'lbs' : 'kg';

    String deltaText = l10n.weightStable;
    Color deltaColor = AppColors.textSecondary;

    if (deltaVal < 0) {
      deltaText = '-${deltaVal.abs().toStringAsFixed(1)} $unitSuffix';
      deltaColor = AppColors.primary;
    } else if (deltaVal > 0) {
      deltaText = '+${deltaVal.toStringAsFixed(1)} $unitSuffix';
      deltaColor = AppColors.accent;
    }

    String trendText = l10n.weightTrendStable;
    if (stats['trend'] == 'losing') trendText = l10n.weightTrendLosing;
    if (stats['trend'] == 'gaining') trendText = l10n.weightTrendGaining;

    final double minKg = (stats['minWeight'] as num).toDouble();
    final double maxKg = (stats['maxWeight'] as num).toDouble();
    final String minStr = UnitConverter.formatWeight(minKg, unitSystem);
    final String maxStr = UnitConverter.formatWeight(maxKg, unitSystem);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatTile(l10n.homeGoal.replaceFirst(l10n.homeGoal.split(' ')[0], 'Delta'), deltaText, deltaColor),
        _buildStatTile('Trend', trendText, deltaColor),
        _buildStatTile('Minimum', minStr, AppColors.textPrimary),
        _buildStatTile('Maximum', maxStr, AppColors.textPrimary),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, List<dynamic> logs, AppLocalizations l10n, UnitSystem unitSystem) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(l10n.noDataYet, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final reversed = logs.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final log = reversed[index];
        final String id = log['id'];
        final double weight = (log['weightKg'] as num).toDouble();
        final String date = _formatDate(log['loggedAt']);

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.error,
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (dir) => _confirmDeleteDialog(context, l10n),
          onDismissed: (dir) {
            context.read<WeightBloc>().add(DeleteWeightLogEvent(id));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              color: AppColors.surface,
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.scale_rounded, color: AppColors.accent),
                title: Text(
                  UnitConverter.formatWeight(weight, unitSystem),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                subtitle: Text(date, style: const TextStyle(color: AppColors.textSecondary)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                  onPressed: () async {
                    final bloc = context.read<WeightBloc>();
                    final confirm = await _confirmDeleteDialog(context, l10n);
                    if (confirm == true) {
                      bloc.add(DeleteWeightLogEvent(id));
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return '';
    }
  }

  Future<bool?> _confirmDeleteDialog(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.deleteButton),
          content: const Text('Delete this weight entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );
  }

  void _showLogWeightDialog(BuildContext context, AppLocalizations l10n) {
    final unitSystem = context.read<UnitCubit>().state;
    final unitSuffix = unitSystem == UnitSystem.imperial ? 'lbs' : 'kg';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.weightLogToday),
          content: TextFormField(
            controller: _weightInputController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. ${unitSystem == UnitSystem.imperial ? "165" : "75"}',
              suffixText: unitSuffix,
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _weightInputController.clear();
                Navigator.pop(ctx);
              },
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                final input = double.tryParse(_weightInputController.text.trim());
                if (input != null && input > 0) {
                  final weightKg = unitSystem == UnitSystem.imperial ? UnitConverter.lbsToKg(input) : input;
                  context.read<WeightBloc>().add(LogWeightMeasurement(weightKg));
                }
                _weightInputController.clear();
                Navigator.pop(ctx);
              },
              child: Text(l10n.addButton),
            ),
          ],
        );
      },
    );
  }
}
