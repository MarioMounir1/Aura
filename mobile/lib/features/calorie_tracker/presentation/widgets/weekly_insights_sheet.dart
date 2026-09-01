// lib/features/calorie_tracker/presentation/widgets/weekly_insights_sheet.dart
// Aura — Weekly AI Health & Fitness Insights Sheet with Shareable Story Card

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/constants.dart';

class WeeklyInsightsSheet extends StatefulWidget {
  const WeeklyInsightsSheet({super.key});

  @override
  State<WeeklyInsightsSheet> createState() => _WeeklyInsightsSheetState();
}

class _WeeklyInsightsSheetState extends State<WeeklyInsightsSheet> {
  bool _isLoading = true;
  int _consistencyScore = 85;
  String _headline = 'Strong Weekly Progress ⚡';
  String _summary = 'You remained consistent with nutrition and workout adherence this week.';
  String _keyWin = 'Completed all scheduled workout sessions';
  String _nextWeekFocus = 'Maintain protein targets on rest days';
  int _totalWorkouts = 4;
  int _avgDailyCalories = 2100;
  int _calorieTarget = 2200;
  int _daysLogged = 6;
  double? _weightDelta;

  @override
  void initState() {
    super.initState();
    _fetchWeeklyInsights();
  }

  Future<void> _fetchWeeklyInsights() async {
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

      final response = await dio.get('/coach/weekly-insights');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final stats = data['stats'] as Map<String, dynamic>? ?? {};

        if (mounted) {
          setState(() {
            _consistencyScore = (data['consistencyScore'] as num?)?.toInt() ?? 80;
            _headline = data['headline'] ?? 'Strong Weekly Progress ⚡';
            _summary = data['summary'] ?? '';
            _keyWin = data['keyWin'] ?? '';
            _nextWeekFocus = data['nextWeekFocus'] ?? '';
            _totalWorkouts = (stats['totalWorkouts'] as num?)?.toInt() ?? 0;
            _avgDailyCalories = (stats['avgDailyCalories'] as num?)?.toInt() ?? 2000;
            _calorieTarget = (stats['calorieTarget'] as num?)?.toInt() ?? 2000;
            _daysLogged = (stats['daysLoggedCount'] as num?)?.toInt() ?? 0;
            _weightDelta = (stats['weightDeltaKg'] as num?)?.toDouble();
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showShareProgressDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A2B), Color(0xFF0D1812)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF388E68), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF55D6A0).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF55D6A0).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFF55D6A0), size: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AURA',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'WEEKLY HIGHLIGHTS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFF55D6A0),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Stat Grid
              Row(
                children: [
                  Expanded(
                    child: _buildShareStatBox(
                      label: 'Consistency',
                      value: '$_consistencyScore%',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareStatBox(
                      label: 'Workouts',
                      value: '$_totalWorkouts sessions',
                      icon: Icons.fitness_center_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildShareStatBox(
                      label: 'Avg Calories',
                      value: '$_avgDailyCalories kcal',
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareStatBox(
                      label: 'Days Logged',
                      value: '$_daysLogged / 7 days',
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Close / Done
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF55D6A0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D1812),
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

  Widget _buildShareStatBox({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF55D6A0), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131A15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF283A2E), width: 1.5)),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Color(0xFF55D6A0)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF235A42).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF55D6A0), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Weekly AI Insights',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Headline Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2E23), Color(0xFF16211A)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF2C4535)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _headline,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF55D6A0).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_consistencyScore% Score',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF55D6A0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _summary,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFCAD8CE),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metric Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Workouts Crushed',
                          value: '$_totalWorkouts',
                          subtitle: 'sessions this week',
                          icon: Icons.fitness_center_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Avg Daily Cals',
                          value: '$_avgDailyCalories',
                          subtitle: 'goal: $_calorieTarget kcal',
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Days Logged',
                          value: '$_daysLogged / 7',
                          subtitle: 'tracking adherence',
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Weight Delta',
                          value: _weightDelta != null
                              ? '${_weightDelta! > 0 ? "+" : ""}${_weightDelta!.toStringAsFixed(1)} kg'
                              : 'Steady',
                          subtitle: '7-day trend',
                          icon: Icons.monitor_weight_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Key Win Callout
                  if (_keyWin.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B241E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2B3A2F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD166), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KEY WIN THIS WEEK',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFFFFD166),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _keyWin,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Next Week Focus
                  if (_nextWeekFocus.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B241E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2B3A2F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.track_changes_rounded, color: Color(0xFF55D6A0), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEXT WEEK\'S FOCUS',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF55D6A0),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _nextWeekFocus,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Share Progress Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showShareProgressDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF235A42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'Share Progress Card',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18221B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26362A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF55D6A0), size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
