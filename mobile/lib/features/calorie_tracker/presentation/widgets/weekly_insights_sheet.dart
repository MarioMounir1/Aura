// lib/features/calorie_tracker/presentation/widgets/weekly_insights_sheet.dart
// Aura — Weekly AI Health & Fitness Insights Sheet (Aura Light Theme)

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';

class WeeklyInsightsSheet extends StatefulWidget {
  const WeeklyInsightsSheet({super.key});

  @override
  State<WeeklyInsightsSheet> createState() => _WeeklyInsightsSheetState();
}

class _WeeklyInsightsSheetState extends State<WeeklyInsightsSheet> {
  static const String _cacheKey = 'cached_weekly_insights_data';

  bool _isLoading = true;
  int _consistencyScore = 0;
  String _headline = 'Weekly Progress Overview';
  String _summary = '';
  String _keyWin = '';
  String _nextWeekFocus = '';
  int _totalWorkouts = 0;
  int _avgDailyCalories = 0;
  int _calorieTarget = 2000;
  int _daysLogged = 0;
  double? _weightDelta;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _fetchWeeklyInsights();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final root = jsonDecode(cached) as Map<String, dynamic>;
        final stats = root['stats'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _consistencyScore = (root['consistencyScore'] as num?)?.toInt() ?? 0;
            _headline = root['headline'] ?? 'Weekly Progress Overview';
            _summary = root['summary'] ?? '';
            _keyWin = root['keyWin'] ?? '';
            _nextWeekFocus = root['nextWeekFocus'] ?? '';
            _totalWorkouts = (stats['totalWorkouts'] as num?)?.toInt() ?? 0;
            _avgDailyCalories = (stats['avgDailyCalories'] as num?)?.toInt() ?? 0;
            _calorieTarget = (stats['calorieTarget'] as num?)?.toInt() ?? 2000;
            _daysLogged = (stats['daysLoggedCount'] as num?)?.toInt() ?? 0;
            _weightDelta = (stats['weightDeltaKg'] as num?)?.toDouble();
            _isLoading = false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchWeeklyInsights() async {
    try {
      final response = await ApiClient().dio.get(
        '/coach/weekly-insights',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final stats = data['stats'] as Map<String, dynamic>? ?? {};

        if (mounted) {
          setState(() {
            _consistencyScore = (data['consistencyScore'] as num?)?.toInt() ?? 0;
            _headline = data['headline'] ?? 'Weekly Progress Overview';
            _summary = data['summary'] ?? '';
            _keyWin = data['keyWin'] ?? '';
            _nextWeekFocus = data['nextWeekFocus'] ?? '';
            _totalWorkouts = (stats['totalWorkouts'] as num?)?.toInt() ?? 0;
            _avgDailyCalories = (stats['avgDailyCalories'] as num?)?.toInt() ?? 0;
            _calorieTarget = (stats['calorieTarget'] as num?)?.toInt() ?? 2000;
            _daysLogged = (stats['daysLoggedCount'] as num?)?.toInt() ?? 0;
            _weightDelta = (stats['weightDeltaKg'] as num?)?.toDouble();
            _isLoading = false;
          });
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(data));
        } catch (_) {}
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // If no cache was present, provide a friendly default so it doesn't spin forever
          if (_summary.isEmpty) {
            _headline = 'Start Your Weekly Journey 🚀';
            _summary = 'Log your daily meals and workout sessions to track consistency and hit your goals.';
            _keyWin = 'Dashboard ready to record your progress';
            _nextWeekFocus = 'Log your first meal and workout today';
          }
          _isLoading = false;
        });
      }
    }
  }

  String _generateShareText() {
    final weightStr = _weightDelta != null
        ? '\n• Weight Change: ${_weightDelta! >= 0 ? "+" : ""}${_weightDelta!.toStringAsFixed(1)} kg'
        : '';
    final winStr = _keyWin.isNotEmpty ? '\n🏆 Key Win: $_keyWin' : '';
    return '''✨ My Weekly Progress on Aura ✨
🎯 $_headline

📊 This Week's Highlights:
• Consistency: $_consistencyScore%
• Workouts: $_totalWorkouts sessions
• Avg Calories: $_avgDailyCalories kcal (Goal: $_calorieTarget kcal)
• Days Logged: $_daysLogged / 7 days$weightStr$winStr

Transform your nutrition & fitness with Aura:
https://aura-fit.com''';
  }

  Future<void> _shareToWhatsApp() async {
    final text = _generateShareText();
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp not detected. Summary copied to clipboard!'),
            backgroundColor: Color(0xFF235A42),
          ),
        );
      }
    }
  }

  Future<void> _shareToInstagram() async {
    final text = _generateShareText();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress summary copied! Opening Instagram...'),
          backgroundColor: Color(0xFFE1306C),
          duration: Duration(seconds: 2),
        ),
      );
    }
    final instaAppUrl = Uri.parse('instagram://app');
    final instaWebUrl = Uri.parse('https://instagram.com');
    try {
      final launched = await launchUrl(instaAppUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(instaWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(instaWebUrl, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _shareViaSystem() async {
    final text = _generateShareText();
    try {
      const platform = MethodChannel('com.mario.aura/app_info');
      await platform.invokeMethod('shareText', {
        'text': text,
        'title': 'Share My Aura Progress',
      });
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress summary copied to clipboard! Paste into your favorite app.'),
            backgroundColor: Color(0xFF235A42),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    final text = _generateShareText();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Progress summary & link copied to clipboard!'),
            ],
          ),
          backgroundColor: Color(0xFF235A42),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveScreenshot(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/aura_progress_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Card screenshot saved (${file.path.split('/').last})!')),
              ],
            ),
            backgroundColor: const Color(0xFF235A42),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save screenshot image.')),
        );
      }
    }
  }

  void _showShareProgressDialog() {
    final boundaryKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBF8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD4E5D8), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E1E3A2B),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Share Weekly Card',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A2B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF5A7060), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Card Preview (captured for screenshot)
                RepaintBoundary(
                  key: boundaryKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF2F8F4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFD2E6D8), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C1E3A2B),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Aura Logo & Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF235A42),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AURA',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: const Color(0xFF1E3A2B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'WEEKLY HIGHLIGHTS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: const Color(0xFF4A6B56),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _headline,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A2B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4 Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildShareStatBox(
                                label: 'Consistency',
                                value: '$_consistencyScore%',
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildShareStatBox(
                                label: 'Workouts',
                                value: '$_totalWorkouts sessions',
                                icon: Icons.fitness_center_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildShareStatBox(
                                label: 'Avg Calories',
                                value: '$_avgDailyCalories kcal',
                                icon: Icons.local_fire_department_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildShareStatBox(
                                label: 'Days Logged',
                                value: '$_daysLogged / 7 days',
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Card Footer Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFF235A42), size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'aura-fit.com • AI Health & Nutrition',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5A7060),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Share To Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SHARE TO',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: const Color(0xFF5A7060),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Social Sharing Buttons Row
                Row(
                  children: [
                    // WhatsApp
                    Expanded(
                      child: InkWell(
                        onTap: _shareToWhatsApp,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0x2025D366), blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'WhatsApp',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Instagram
                    Expanded(
                      child: InkWell(
                        onTap: _shareToInstagram,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0x20E1306C), blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Instagram',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // More Apps (System Share)
                    Expanded(
                      child: InkWell(
                        onTap: _shareViaSystem,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF235A42),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0x20235A42), blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'More',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Secondary Action Row: Copy Link & Save Image
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC8DEC9), width: 1.1),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF235A42), size: 15),
                        label: Text(
                          'Copy Summary',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF235A42),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _saveScreenshot(boundaryKey),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC8DEC9), width: 1.1),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.download_rounded, color: Color(0xFF235A42), size: 15),
                        label: Text(
                          'Save Image',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF235A42),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEEE3)),
        boxShadow: const [
          BoxShadow(color: Color(0x061E3A2B), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF235A42), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3A2B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5A7060),
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
        color: Color(0xFFF6F8F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFFD4E5D8), width: 1.5)),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Color(0xFF235A42)),
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
                        color: const Color(0xFFC8DACD),
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
                              color: const Color(0xFF235A42).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF235A42), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Weekly Insights',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E3A2B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF5A7060), size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Headline Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEEE3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFCBE3D1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _headline,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E3A2B),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_consistencyScore% Score',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF235A42),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_summary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _summary,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF3B5745),
                              height: 1.45,
                            ),
                          ),
                        ],
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDECE1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFD4A017), size: 20),
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
                                    color: const Color(0xFF9A7410),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _keyWin,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A2B),
                                  ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDECE1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.track_changes_rounded, color: Color(0xFF235A42), size: 20),
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
                                    color: const Color(0xFF235A42),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _nextWeekFocus,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A2B),
                                  ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDECE1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061E3A2B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF235A42), size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3A2B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A2B)),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF5A7060)),
          ),
        ],
      ),
    );
  }
}
