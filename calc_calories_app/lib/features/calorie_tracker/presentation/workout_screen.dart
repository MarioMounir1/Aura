// lib/features/calorie_tracker/presentation/workout_screen.dart
// The Teneen — Dedicated Workout Routine Hub tab

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // AI Generator loading state mock
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Zone ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'روتين التمارين' : 'Workout Routine',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  _buildStreakBadge(isArabic),
                ],
              ),
            ),

            // ── Scrollable Content Area ──────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90), // Spacing for custom bottom nav
                children: [
                  // AI Workout Generator Banner (Horizontal card with glow)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAiGeneratorBanner(isArabic),
                  ),

                  const SizedBox(height: 20),

                  // Today's Target Workout Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTodayPlanCard(isArabic),
                  ),

                  const SizedBox(height: 20),

                  // Explore Gyms Link Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildExploreGymsCard(isArabic),
                  ),

                  const SizedBox(height: 24),

                  // Weekly Calendar Overview Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      isArabic ? 'نظرة عامة على الأسبوع' : 'Weekly Overview',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Weekly Calendar Overview Grid/Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildWeeklyCalendar(isArabic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: Streak Badge ──────────────────────────────────────────
  Widget _buildStreakBadge(bool isArabic) {
    final streakText = isArabic ? 'تتابع ٤ أسابيع 🔥' : '4 Week Streak 🔥';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Text(
        streakText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.orangeAccent,
        ),
      ),
    );
  }

  // ── AI Workout Generator Banner ────────────────────────────────────
  Widget _buildAiGeneratorBanner(bool isArabic) {
    return GestureDetector(
      onTap: () {
        setState(() => _isGenerating = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _isGenerating = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isArabic ? 'تم توليد التمرين بنجاح!' : 'AI Generation Complete!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              content: Text(
                isArabic
                    ? 'تم تصميم خطة تمرين دفع مخصصة جديدة لك استناداً إلى أهدافك.'
                    : 'A new custom Push session plan has been crafted based on your goals.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    isArabic ? 'عرض الخطة' : 'View Session',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A), // Dark blue hue
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'مولد التمارين بالذكاء الاصطناعي' : 'AI Workout Generator',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'دع الذكاء الاصطناعي يصمم تمرينك المخصص في ٣ ثوانٍ.'
                          : 'Let AI create a customized training session in 3 seconds.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Today's Plan Card ──────────────────────────────────────────────
  Widget _buildTodayPlanCard(bool isArabic) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Badge / Title
            Text(
              isArabic ? 'خطة اليوم: اليوم ١ - دفع' : 'Today\'s Plan: Day 1 - Push Day',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isArabic
                  ? 'يستهدف: الصدر، الأكتاف، الترايسبس'
                  : 'Targets: Chest, Shoulders, Triceps',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),

            // Bulleted exercise previews
            _buildExercisePreviewRow(isArabic ? 'بنش برس بالبار' : 'Barbell Bench Press', '100 kg | 4-6 Reps'),
            _buildExercisePreviewRow(isArabic ? 'ضغط كتف بالبار' : 'Overhead Press', '60 kg | 6-8 Reps'),
            _buildExercisePreviewRow(isArabic ? 'تجميع رفرفة صدر مائل' : 'Incline Dumbbell Flyes', '22 kg | 10-12 Reps'),

            const SizedBox(height: 20),

            // Start workout teal button
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/workout/active'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'ابدأ التمرين 🏋️‍♂️' : 'Start Workout 🏋️‍♂️',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisePreviewRow(String name, String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            target,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Explore Gyms Banner Card ───────────────────────────────────────
  Widget _buildExploreGymsCard(bool isArabic) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/gyms'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'استكشف الصالات الشريكة بالقرب منك' : 'Explore Partner Gyms',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic
                        ? 'سجل الحضور في صالتك واكسب +٢٠ نقطة مكافأة'
                        : 'Check-in at gyms & claim +20 Pts rewards',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isArabic ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ── Weekly Calendar Grid ──────────────────────────────────────────
  Widget _buildWeeklyCalendar(bool isArabic) {
    final List<Map<String, dynamic>> weekDays = [
      {'dayEn': 'M', 'dayAr': 'ن', 'completed': true, 'rest': false},
      {'dayEn': 'T', 'dayAr': 'ث', 'completed': true, 'rest': false},
      {'dayEn': 'W', 'dayAr': 'ر', 'completed': false, 'rest': true},
      {'dayEn': 'T', 'dayAr': 'خ', 'completed': false, 'rest': false}, // Today
      {'dayEn': 'F', 'dayAr': 'ج', 'completed': false, 'rest': false},
      {'dayEn': 'S', 'dayAr': 'س', 'completed': false, 'rest': true},
      {'dayEn': 'S', 'dayAr': 'ح', 'completed': false, 'rest': false},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(weekDays.length, (index) {
        final day = weekDays[index];
        final label = isArabic ? day['dayAr']! : day['dayEn']!;
        final isCompleted = day['completed'] as bool;
        final isRest = day['rest'] as bool;
        final isToday = index == 3; // Mock Thursday as today

        return Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: isToday ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isToday ? AppColors.surfaceVariant : AppColors.surface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primary
                      : (isToday ? AppColors.primary : AppColors.border),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 18,
                      )
                    : (isRest
                        ? Icon(
                            Icons.hotel_rounded,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            size: 14,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ],
        );
      }),
    );
  }
}
