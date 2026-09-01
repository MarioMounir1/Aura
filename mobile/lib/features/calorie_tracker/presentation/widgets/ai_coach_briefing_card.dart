// lib/features/calorie_tracker/presentation/widgets/ai_coach_briefing_card.dart
// Aura — Daily AI Coach Briefing Card (Light Sage & Forest Green Aura Theme)

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
  String _headline = '';
  String _message = '';
  String _focusArea = '';

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
      } else {
        if (mounted) {
          setState(() {
            _headline = 'Daily Coaching Insight ✨';
            _message = 'Keep tracking your meals and workouts to stay aligned with your daily calorie goal.';
            _focusArea = 'Consistency';
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _headline = 'Daily Coaching Insight ✨';
          _message = 'Keep tracking your meals and workouts to stay aligned with your daily calorie goal.';
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
