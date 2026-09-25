// lib/features/calorie_tracker/presentation/widgets/ai_coach_briefing_card.dart
// Aura — Daily AI Coach Briefing Card (Light Sage & Forest Green Aura Theme)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import 'weekly_insights_sheet.dart';

class AiCoachBriefingCard extends StatefulWidget {
  final VoidCallback? onWeeklyInsightsTap;
  final double? calorieTarget;
  final double? caloriesConsumed;
  final double? proteinTarget;
  final double? proteinConsumed;

  const AiCoachBriefingCard({
    super.key,
    this.onWeeklyInsightsTap,
    this.calorieTarget,
    this.caloriesConsumed,
    this.proteinTarget,
    this.proteinConsumed,
  });

  @override
  State<AiCoachBriefingCard> createState() => _AiCoachBriefingCardState();
}

class _AiCoachBriefingCardState extends State<AiCoachBriefingCard> {
  static String _cachedHeadline = 'Weekly Insights';
  static String _cachedMessage =
      'Track your meals to stay on pace with your daily calorie and protein targets.';
  static String _cachedFocusArea = 'Daily Progress';
  static Map<String, dynamic>? _cachedYesterday;

  final bool _isLoading = false;
  late String _headline;
  late String _message;
  late String _focusArea;
  Map<String, dynamic>? _yesterdayStats = _cachedYesterday;
  bool _initializedLocal = false;

  @override
  void initState() {
    super.initState();
    _headline = _cachedHeadline;
    _message = _cachedMessage;
    _focusArea = _cachedFocusArea;
    _loadFromPreferences();
    _fetchBriefing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedLocal) {
      _initializedLocal = true;
      _resolveLocalData();
    }
  }

  @override
  void didUpdateWidget(covariant AiCoachBriefingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calorieTarget != oldWidget.calorieTarget ||
        widget.caloriesConsumed != oldWidget.caloriesConsumed ||
        widget.proteinTarget != oldWidget.proteinTarget ||
        widget.proteinConsumed != oldWidget.proteinConsumed) {
      _resolveLocalData();
      _fetchBriefing();
    }
  }

  void _applyLocal(String h, String m, String f) {
    _cachedHeadline = h;
    _cachedMessage = m;
    _cachedFocusArea = f;
    _headline = h;
    _message = m;
    _focusArea = f;
  }

  int _getActiveCalorieTarget() {
    if (widget.calorieTarget != null && widget.calorieTarget! > 0) {
      return widget.calorieTarget!.round();
    }

    try {
      final profileState = context.read<ProfileBloc?>()?.state;
      if (profileState is ProfileLoaded) {
        final u = profileState.user;
        final rawCal = u['dailyCalorieGoal'] ?? u['targetCalories'] ?? u['calories'];
        if (rawCal is num && rawCal > 0) {
          return rawCal.toInt();
        }
        final goals = u['goals'];
        if (goals is Map) {
          final gCal = goals['dailyCalories'] ?? goals['calories'] ?? goals['dailyCalorieGoal'];
          if (gCal is num && gCal > 0) {
            return gCal.toInt();
          }
        }

        // TDEE calculation from user biometrics
        final w = double.tryParse((u['weightKg'] ?? '').toString());
        final h = double.tryParse((u['heightCm'] ?? '').toString());
        final a = int.tryParse((u['age'] ?? '').toString());
        final g = (u['gender'] ?? 'male').toString().toLowerCase();
        final act = (u['activityLevel'] ?? 'moderate').toString();
        final goalType = (u['goal'] ?? 'maintain').toString();

        if (w != null && h != null && a != null) {
          final double bmr = (10 * w) + (6.25 * h) - (5 * a) + (g == 'male' ? 5 : -161);
          final double mult = act == 'sedentary'
              ? 1.2
              : act == 'lightly_active'
                  ? 1.375
                  : act == 'very_active'
                      ? 1.725
                      : 1.55;
          final double adj = goalType == 'lose'
              ? -500
              : goalType == 'gain'
                  ? 500
                  : 0;
          return (bmr * mult + adj).round().clamp(1200, 5000);
        }
      }
    } catch (_) {}

    return 2000;
  }

  int _getActiveProteinTarget() {
    final cal = _getActiveCalorieTarget();
    if (widget.proteinTarget != null && widget.proteinTarget! > 0) {
      if (!(widget.proteinTarget!.round() == 150 && cal > 2400)) {
        return widget.proteinTarget!.round();
      }
    }

    try {
      final profileState = context.read<ProfileBloc?>()?.state;
      if (profileState is ProfileLoaded) {
        final u = profileState.user;
        final pGoal = u['dailyProteinGoal'] ?? u['proteinGoal'];
        final w = double.tryParse((u['weightKg'] ?? '').toString());

        int? dynamicTarget;
        if (w != null && w > 0) {
          final pFromWeight = (w * 2.0).round();
          final pFromCal = ((cal * 0.25) / 4).round();
          final highest = pFromWeight > pFromCal ? pFromWeight : pFromCal;
          dynamicTarget = highest.clamp(80, 250);
        }

        if (pGoal is num && pGoal > 0) {
          if (pGoal == 150 && dynamicTarget != null && dynamicTarget > 165) {
            return dynamicTarget;
          }
          return pGoal.toInt();
        }
        if (dynamicTarget != null) {
          return dynamicTarget;
        }
        final goals = u['goals'];
        if (goals is Map && goals['protein'] is num && goals['protein'] > 0) {
          return (goals['protein'] as num).toInt();
        }
        if (u['weightKg'] is num) {
          return (u['weightKg'] * 1.8).round();
        }
      }
    } catch (_) {}

    if (cal > 2400) {
      return ((cal * 0.25) / 4).round().clamp(120, 260);
    }

    return 130;
  }

  void _resolveLocalData() {
    try {
      final calorieTarget = _getActiveCalorieTarget();
      final proteinTarget = _getActiveProteinTarget();

      final calFormatted = calorieTarget.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );

      final double consumed = widget.caloriesConsumed ?? 0.0;
      final double consumedProt = widget.proteinConsumed ?? 0.0;

      String headline = 'Weekly Insights';
      String message =
          'Your daily target is $calFormatted kcal with ${proteinTarget}g protein. Log your first meal to start today\'s progress!';
      String focusArea = 'Daily Progress';

      if (consumed > 0) {
        final remaining = calorieTarget - consumed.round();
        if (remaining > 0) {
          final remFormatted = remaining.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
          headline = '$remFormatted kcal Remaining 🎯';
          message =
              'You\'ve logged ${consumed.round()} of $calFormatted kcal and ${consumedProt.round()}g protein. Keep pacing your meals!';
          focusArea = 'Daily Progress';
        } else {
          headline = 'Daily Goal Met! 🏆';
          message =
              'You\'ve reached $calFormatted kcal today with ${consumedProt.round()}g protein. Great job hitting your nutrition targets!';
          focusArea = 'Goal Reached';
        }
      } else if (_yesterdayStats != null &&
          ((_yesterdayStats!['mealCount'] as num? ?? 0) > 0 ||
              (_yesterdayStats!['calories'] as num? ?? 0) > 0)) {
        final yCal = (_yesterdayStats!['calories'] as num? ?? 0).round();
        final yProt = (_yesterdayStats!['protein'] as num? ?? 0).round();
        final yCount = (_yesterdayStats!['mealCount'] as num? ?? 0).toInt();
        final mealWord = yCount == 1 ? 'meal' : 'meals';
        final yCalFmt = yCal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

        headline = 'Yesterday: $yCalFmt kcal & ${yProt}g Protein 🎯';
        message =
            'You logged $yCount $mealWord yesterday ($yCalFmt of $calFormatted kcal, ${yProt}g protein). Let\'s hit your $calFormatted kcal target today!';
        focusArea = 'Yesterday\'s Recap';
      }

      if (mounted) {
        setState(() {
          _applyLocal(headline, message, focusArea);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var h = prefs.getString('cached_coach_headline');
      final m = prefs.getString('cached_coach_message');
      final f = prefs.getString('cached_coach_focus');

      final cachedY = prefs.getString('cached_yesterday_stats');
      if (cachedY != null) {
        try {
          final parsed = jsonDecode(cachedY) as Map<String, dynamic>;
          _cachedYesterday = parsed;
          _yesterdayStats = parsed;
        } catch (_) {}
      }

      // Purge and delete any outdated workout split cache from disk
      final isOutdatedWorkout = h != null &&
          (h.contains('Split') || h.contains('Day 🔥') || (m != null && m.contains("Today's session is")));

      if (isOutdatedWorkout) {
        await prefs.remove('cached_coach_headline');
        await prefs.remove('cached_coach_message');
        await prefs.remove('cached_coach_focus');
      } else if (h != null && m != null && mounted) {
        // Remap legacy 'Ready to Progress' from cache
        if (h.contains('Ready to Progress')) {
          h = 'Weekly Insights';
          await prefs.setString('cached_coach_headline', 'Weekly Insights');
        }

        final isYesterdayMessage = (h.contains('Yesterday')) || (f != null && f.contains('Yesterday'));

        if (!isYesterdayMessage) {
          // If cached message contains a stale calorie or protein figure, regenerate locally
          final activeTarget = _getActiveCalorieTarget();
          final activeProtein = _getActiveProteinTarget();
          final activeFormatted = activeTarget.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match match) => '${match[1]},',
          );
          if (m.contains('kcal') && !m.contains(activeFormatted) && !m.contains(activeTarget.toString())) {
            _resolveLocalData();
            return;
          }
          if (m.contains('protein') && !m.contains('${activeProtein}g protein') && activeProtein > 160) {
            _resolveLocalData();
            return;
          }
        }

        setState(() {
          _applyLocal(h, m, f ?? _focusArea);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchBriefing() async {
    try {
      final calorieTarget = _getActiveCalorieTarget();
      final proteinTarget = _getActiveProteinTarget();
      final consumed = widget.caloriesConsumed?.round() ?? 0;
      final consumedProt = widget.proteinConsumed?.round() ?? 0;

      final queryParams = <String, dynamic>{
        'calorieTarget': calorieTarget,
        'proteinTarget': proteinTarget,
        'caloriesConsumed': consumed,
        'proteinConsumed': consumedProt,
      };

      final response = await ApiClient().dio.get(
        '/coach/daily-briefing',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        String? newHeadline = (data['headline'] as String?)?.trim();
        String? newMessage = (data['message'] as String?)?.trim();
        final newFocus = (data['focusArea'] as String?)?.trim();

        if (data['yesterday'] is Map<String, dynamic>) {
          final yMap = data['yesterday'] as Map<String, dynamic>;
          _cachedYesterday = yMap;
          _yesterdayStats = yMap;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_yesterday_stats', jsonEncode(yMap));
          } catch (_) {}
        }

        // Strict guard: Reject any workout split text that may come from an old cloud build or cache
        final isWorkoutText = (newHeadline?.contains('Split') ?? false) ||
            (newHeadline?.contains('Day 🔥') ?? false) ||
            (newMessage?.contains("Today's session is") ?? false);

        if (isWorkoutText) {
          return;
        }

        // Remap legacy 'Ready to Progress' from cloud backend or cache to 'Weekly Insights'
        if (newHeadline != null && newHeadline.contains('Ready to Progress')) {
          newHeadline = 'Weekly Insights';
        }

        if (newMessage != null && newMessage.contains('150g protein') && proteinTarget > 150) {
          newMessage = newMessage.replaceAll('150g protein', '${proteinTarget}g protein');
        }

        if (newHeadline != null &&
            newHeadline.isNotEmpty &&
            newMessage != null &&
            newMessage.isNotEmpty) {
          final validHeadline = newHeadline;
          final validMessage = newMessage;
          _cachedHeadline = validHeadline;
          _cachedMessage = validMessage;
          if (newFocus != null && newFocus.isNotEmpty) {
            _cachedFocusArea = newFocus;
          }

          if (mounted) {
            setState(() {
              _headline = validHeadline;
              _message = validMessage;
              if (newFocus != null && newFocus.isNotEmpty) {
                _focusArea = newFocus;
              }
            });
          }

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_coach_headline', validHeadline);
            await prefs.setString('cached_coach_message', validMessage);
            if (newFocus != null && newFocus.isNotEmpty) {
              await prefs.setString('cached_coach_focus', newFocus);
            }
          } catch (_) {}
        }
      }
    } catch (_) {
      // Retain instant cached data silently on network errors
    }
  }

  void _openWeeklyInsights() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WeeklyInsightsSheet(),
    );
  }

  Widget _buildMacroBadge(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F2),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD6E7DC), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10.5)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF235A42),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2EFE5), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 90,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 70,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6F2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6F2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    final displayHeadline = _headline.contains('Ready to Progress') ? 'Weekly Insights' : _headline;
    final activeProt = _getActiveProteinTarget();
    final displayMessage = (_message.contains('150g protein') && activeProt > 150)
        ? _message.replaceAll('150g protein', '${activeProt}g protein')
        : _message;

    final isYesterdayRecap = _focusArea.contains('Yesterday') || displayHeadline.contains('Yesterday');
    final double consumed = widget.caloriesConsumed ?? 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isYesterdayRecap ? const Color(0xFFC7E2D1) : const Color(0xFFDCEEE3),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081E3A2B),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openWeeklyInsights,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Aura Coach badge + Focus Tag + Weekly Insights Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4EC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBE3D1), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF235A42), size: 12),
                              const SizedBox(width: 5),
                              Text(
                                'AURA COACH',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF235A42),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_focusArea.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isYesterdayRecap
                                  ? const Color(0xFFEBF5EE)
                                  : const Color(0xFFF4F7F5),
                              borderRadius: BorderRadius.circular(8),
                              border: isYesterdayRecap
                                  ? Border.all(color: const Color(0xFFBFE3CD), width: 0.8)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isYesterdayRecap) ...[
                                  const Icon(Icons.history_rounded, size: 12, color: Color(0xFF235A42)),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _focusArea,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isYesterdayRecap
                                        ? const Color(0xFF235A42)
                                        : const Color(0xFF5A7060),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Weekly',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF235A42),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF235A42),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Headline
                Text(
                  displayHeadline,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A2B),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Actionable 2-sentence guidance
                Text(
                  displayMessage,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5A7060),
                    height: 1.4,
                  ),
                ),

                // Yesterday mini macro pills when it's a new day (0 kcal logged today)
                if (consumed == 0 &&
                    _yesterdayStats != null &&
                    ((_yesterdayStats!['mealCount'] as num? ?? 0) > 0 ||
                        (_yesterdayStats!['calories'] as num? ?? 0) > 0)) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildMacroBadge(
                        '🔥',
                        '${(_yesterdayStats!['calories'] as num? ?? 0).round()} kcal',
                      ),
                      _buildMacroBadge(
                        '🥩',
                        '${(_yesterdayStats!['protein'] as num? ?? 0).round()}g prot',
                      ),
                      _buildMacroBadge(
                        '🍽️',
                        '${(_yesterdayStats!['mealCount'] as num? ?? 0).toInt()} meals',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
