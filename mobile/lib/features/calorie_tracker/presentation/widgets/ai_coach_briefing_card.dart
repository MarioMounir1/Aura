// lib/features/calorie_tracker/presentation/widgets/ai_coach_briefing_card.dart
// Aura — Daily AI Coach Briefing Card (Light Sage & Forest Green Aura Theme)

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

  const AiCoachBriefingCard({super.key, this.onWeeklyInsightsTap});

  @override
  State<AiCoachBriefingCard> createState() => _AiCoachBriefingCardState();
}

class _AiCoachBriefingCardState extends State<AiCoachBriefingCard> {
  static String _cachedHeadline = 'Ready to Progress? 🎯';
  static String _cachedMessage =
      'Track your meals to stay on pace with your daily calorie and protein targets.';
  static String _cachedFocusArea = 'Daily Progress';

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
        int calorieTarget = 2000;
        final rawCal = u['dailyCalorieGoal'] ?? u['targetCalories'] ?? u['calories'];
        if (rawCal is num) {
          calorieTarget = rawCal.toInt();
        } else if (rawCal != null) {
          calorieTarget = int.tryParse(rawCal.toString()) ?? 2000;
        }

        int proteinTarget = 130;
        final pGoal = u['dailyProteinGoal'] ?? u['proteinGoal'];
        if (pGoal is num) {
          proteinTarget = pGoal.toInt();
        } else if (u['weightKg'] is num) {
          proteinTarget = (u['weightKg'] * 1.8).round();
        }

        final calFormatted = calorieTarget.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

        if (mounted) {
          setState(() {
            _applyLocal(
              'Ready to Progress? 🎯',
              'Your daily target is $calFormatted kcal with ${proteinTarget}g protein. Log your first meal to start today\'s progress!',
              'Daily Progress',
            );
          });
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

      // Purge and delete any outdated workout split cache from disk
      final isOutdatedWorkout = h != null &&
          (h.contains('Split') || h.contains('Day 🔥') || (m != null && m.contains("Today's session is")));

      if (isOutdatedWorkout) {
        await prefs.remove('cached_coach_headline');
        await prefs.remove('cached_coach_message');
        await prefs.remove('cached_coach_focus');
      } else if (h != null && m != null && mounted) {
        setState(() {
          _applyLocal(h, m, f ?? _focusArea);
        });
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

        // Strict guard: Reject any workout split text that may come from an old cloud build or cache
        final isWorkoutText = (newHeadline?.contains('Split') ?? false) ||
            (newHeadline?.contains('Day 🔥') ?? false) ||
            (newMessage?.contains("Today's session is") ?? false);

        if (isWorkoutText) {
          return;
        }

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
