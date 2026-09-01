// lib/features/calorie_tracker/presentation/widgets/ai_coach_briefing_card.dart
// Aura — Daily AI Coach Briefing Card with Personalized Insights

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/constants.dart';
import 'weekly_insights_sheet.dart';

class AiCoachBriefingCard extends StatefulWidget {
  final VoidCallback? onWeeklyInsightsTap;

  const AiCoachBriefingCard({super.key, this.onWeeklyInsightsTap});

  @override
  State<AiCoachBriefingCard> createState() => _AiCoachBriefingCardState();
}

class _AiCoachBriefingCardState extends State<AiCoachBriefingCard> {
  bool _isLoading = true;
  String _headline = 'Powering Your Day ⚡';
  String _message = 'Analyzing your nutrition and workouts for personalized insights...';
  String _focusArea = 'Daily Focus';

  @override
  void initState() {
    super.initState();
    _fetchBriefing();
  }

  Future<void> _fetchBriefing() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.tokenKey);

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiV1,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 12),
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.get('/coach/daily-briefing');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _headline = data['headline'] ?? 'Ready to Crush It 🔥';
            _message = data['message'] ?? 'Stay hydrated and hit your daily macros!';
            _focusArea = data['focusArea'] ?? 'Daily Focus';
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _headline = 'Welcome to Aura ✨';
          _message = 'Log your meals and workouts consistently to unlock tailored AI coach recommendations.';
          _focusArea = 'Consistency';
          _isLoading = false;
        });
      }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2D23), Color(0xFF141F18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E4334), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF235A42).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badge + Focus Tag + Weekly Insights link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF235A42).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF388E68), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF55D6A0), size: 12),
                        const SizedBox(width: 5),
                        Text(
                          'AURA COACH',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFF55D6A0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _focusArea,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _openWeeklyInsights,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Weekly',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF55D6A0),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF55D6A0), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Headline
          if (_isLoading)
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            Text(
              _headline,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          const SizedBox(height: 6),

          // Actionable message
          if (_isLoading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            )
          else
            Text(
              _message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFFCAD8CE),
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }
}
