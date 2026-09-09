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
import '../../data/models/workout_models.dart';
import 'weekly_insights_sheet.dart';

class AiCoachBriefingCard extends StatefulWidget {
  final VoidCallback? onWeeklyInsightsTap;

  const AiCoachBriefingCard({super.key, this.onWeeklyInsightsTap});

  @override
  State<AiCoachBriefingCard> createState() => _AiCoachBriefingCardState();
}

class _AiCoachBriefingCardState extends State<AiCoachBriefingCard> {
  static String _cachedHeadline = 'Daily Coaching Insight ✨';
  static String _cachedMessage =
      'Keep tracking your meals and workouts to stay aligned with your daily calorie goal.';
  static String _cachedFocusArea = 'Consistency';

  final bool _isLoading = false;
  late String _headline;
  late String _message;
  late String _focusArea;
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

  void _applyLocal(String h, String m, String f) {
    _cachedHeadline = h;
    _cachedMessage = m;
    _cachedFocusArea = f;
    _headline = h;
    _message = m;
    _focusArea = f;
  }

  void _resolveLocalData() {
    try {
      final profileState = context.read<ProfileBloc?>()?.state;
      if (profileState is ProfileLoaded) {
        final u = profileState.user;
        final splitName = u['workoutSplitName'] as String? ?? 'Workout';
        final splitType = u['workoutSplitType'] as String?;
        int proteinTarget = 140;
        final pGoal = u['dailyProteinGoal'] ?? u['proteinGoal'];
        if (pGoal is num) {
          proteinTarget = pGoal.toInt();
        } else if (u['weightKg'] is num) {
          proteinTarget = (u['weightKg'] * 1.8).round();
        }

        if (splitType != null && splitType.isNotEmpty) {
          final allSuggestions = [
            ...RoutineCatalogue.forDays(6),
            ...RoutineCatalogue.forDays(5),
            ...RoutineCatalogue.forDays(4),
            ...RoutineCatalogue.forDays(3),
          ];
          final match = allSuggestions.firstWhere(
            (s) => s.splitType == splitType,
            orElse: () => RoutineCatalogue.forDays(6).first,
          );
          final breakdown = match.breakdown;
          if (breakdown.isNotEmpty) {
            final todayIndex = (DateTime.now().weekday - 1) % 7; // Mon = 0
            final todaySession = breakdown[todayIndex % breakdown.length];
            final displayName = splitName.isNotEmpty ? splitName : match.name;

            if (todaySession.toLowerCase() == 'rest') {
              _applyLocal(
                'Active Recovery Day 🧘',
                'Today is a scheduled rest day in your $displayName. Focus on hydration, mobility, and hitting your ${proteinTarget}g protein target!',
                'Active Recovery',
              );
            } else {
              final formattedHeadline = todaySession.toLowerCase().endsWith('day')
                  ? '$todaySession 🔥'
                  : '$todaySession Day 🔥';
              _applyLocal(
                formattedHeadline,
                "Today's session is $todaySession ($displayName). Fuel up with clean energy and prioritize hitting your ${proteinTarget}g protein target!",
                'Strength & Power',
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final h = prefs.getString('cached_coach_headline');
      final m = prefs.getString('cached_coach_message');
      final f = prefs.getString('cached_coach_focus');
      if (h != null && m != null && mounted) {
        setState(() {
          _applyLocal(h, m, f ?? _focusArea);
        });
      }

      // Also check local Workout Hub payload for any saved overrides
      final routineJson = prefs.getString('cached_workout_routine_payload');
      if (routineJson != null) {
        final root = jsonDecode(routineJson) as Map<String, dynamic>;
        final session = root['currentSession'] as Map<String, dynamic>?;
        if (session != null) {
          final todayDay = session['todayDayName'] as String?;
          final rName = session['routineName'] as String? ?? 'Workout';
          final isRest = session['isRestDay'] == true || todayDay?.toLowerCase() == 'rest';
          if (todayDay != null && todayDay.isNotEmpty && mounted) {
            setState(() {
              if (isRest) {
                _applyLocal(
                  'Active Recovery Day 🧘',
                  'Today is a scheduled rest day in your $rName. Focus on hydration, mobility, and recovery!',
                  'Active Recovery',
                );
              } else {
                final formattedHeadline = todayDay.toLowerCase().endsWith('day')
                    ? '$todayDay 🔥'
                    : '$todayDay Day 🔥';
                _applyLocal(
                  formattedHeadline,
                  "Today's session is $todayDay ($rName). Fuel up with clean energy and prioritize hitting your protein target!",
                  'Strength & Power',
                );
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchBriefing() async {
    try {
      final response = await ApiClient().dio.get('/coach/daily-briefing');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newHeadline = (data['headline'] as String?)?.trim();
        final newMessage = (data['message'] as String?)?.trim();
        final newFocus = (data['focusArea'] as String?)?.trim();

        if (newHeadline != null &&
            newHeadline.isNotEmpty &&
            newMessage != null &&
            newMessage.isNotEmpty) {
          _cachedHeadline = newHeadline;
          _cachedMessage = newMessage;
          if (newFocus != null && newFocus.isNotEmpty) {
            _cachedFocusArea = newFocus;
          }

          if (mounted) {
            setState(() {
              _headline = newHeadline;
              _message = newMessage;
              if (newFocus != null && newFocus.isNotEmpty) {
                _focusArea = newFocus;
              }
            });
          }

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_coach_headline', newHeadline);
            await prefs.setString('cached_coach_message', newMessage);
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEEE3), width: 1.2),
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
                              color: const Color(0xFFF4F7F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _focusArea,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5A7060),
                              ),
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
                  _headline,
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
                  _message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5A7060),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
