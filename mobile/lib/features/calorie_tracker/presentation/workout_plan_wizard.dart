// lib/features/calorie_tracker/presentation/workout_plan_wizard.dart
// Aura — Step-by-Step Guided Workout Plan Builder + AI Coach Conversation

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/workout_models.dart';

class WorkoutPlanWizard extends StatefulWidget {
  final Dio dio;
  final bool isArabic;
  final VoidCallback onRoutineConfirmed;

  const WorkoutPlanWizard({
    super.key,
    required this.dio,
    required this.isArabic,
    required this.onRoutineConfirmed,
  });

  @override
  State<WorkoutPlanWizard> createState() => _WorkoutPlanWizardState();
}

class _WorkoutPlanWizardState extends State<WorkoutPlanWizard> {
  int _currentStep = 1; // 1: Days, 2: Split, 3: Goal, 4: AI Review & Chat

  // Selection states
  int _selectedDays = 4;
  late RoutineSuggestion _selectedRoutine;
  String _selectedGoal = 'hypertrophy';
  String _selectedFocus = 'balanced';

  // AI Chat state in Step 4
  final List<_WizardChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInterpreting = false;
  bool _isSavingRoutine = false;

  @override
  void initState() {
    super.initState();
    final suggestions = RoutineCatalogue.forDays(_selectedDays);
    _selectedRoutine = suggestions.first;
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectDays(int days) {
    setState(() {
      _selectedDays = days;
      final suggestions = RoutineCatalogue.forDays(days);
      _selectedRoutine = suggestions.first;
    });
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });

    if (step == 4 && _messages.isEmpty) {
      _initAICoachMessage();
    }
  }

  void _initAICoachMessage() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialNote = widget.isArabic
          ? 'لقد قمت بإعداد خطة ${_selectedRoutine.name} ($_selectedDays أيام) المخصصة لهدفك! هل ترغب في تعديل أي شيء أو استبدال تمارين معينة؟'
          : "I've crafted your ${_selectedRoutine.name} ($_selectedDays days/week) optimized for your goal! Would you like me to adjust any focus areas, rest days, or swap exercises?";

      setState(() {
        _messages.add(_WizardChatMessage(
          text: initialNote,
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChatMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isInterpreting) return;

    _chatController.clear();
    setState(() {
      _messages.add(_WizardChatMessage(text: query, isUser: true));
      _messages.add(const _WizardChatMessage(text: '', isUser: false, isTyping: true));
      _isInterpreting = true;
    });
    _scrollToBottom();

    try {
      final resp = await widget.dio.post('/workouts/session/interpret', data: {'message': query});
      final data = resp.data['data'];
      final reply = data?['reply'] as String? ?? (widget.isArabic ? 'تم تحديث خطتك بناءً على طلبك!' : 'Updated your plan based on your request!');

      if (data?['splitType'] != null) {
        final newSplitType = data['splitType'] as String;
        final newDays = data['daysPerWeek'] as int? ?? _selectedDays;
        final suggestions = RoutineCatalogue.forDays(newDays);
        final found = suggestions.where((s) => s.splitType == newSplitType).toList();
        if (found.isNotEmpty) {
          _selectedDays = newDays;
          _selectedRoutine = found.first;
        }
      }

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isTyping);
          _messages.add(_WizardChatMessage(text: reply, isUser: false));
          _isInterpreting = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isTyping);
          _messages.add(_WizardChatMessage(
            text: widget.isArabic
                ? 'فهمت طلبك! قمت بضبط خطتك لتناسب تفضيلاتك.'
                : 'Got it! I adjusted your workout plan to match your preferences.',
            isUser: false,
          ));
          _isInterpreting = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _confirmAndSaveRoutine() async {
    setState(() => _isSavingRoutine = true);
    try {
      final resp = await widget.dio.post('/workouts/setup', data: {
        'daysPerWeek': _selectedDays,
        'splitType': _selectedRoutine.splitType,
        'splitName': _selectedRoutine.name,
      });

      if (mounted && (resp.statusCode == 200 || resp.statusCode == 201 || resp.data?['success'] == true)) {
        widget.onRoutineConfirmed();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.isArabic ? 'حدث خطأ أثناء حفظ الخطة' : 'Error saving workout plan';
        if (e is DioException && e.response?.data is Map) {
          errorMsg = e.response?.data['error'] as String? ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingRoutine = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD3E4D7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A2B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Step Indicators & Back Button
          _buildHeader(isAr),
          const SizedBox(height: 18),

          // Dynamic Step Body
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(isAr),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (_currentStep > 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF235A42)),
                    onPressed: () => _goToStep(_currentStep - 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (_currentStep > 1) const SizedBox(width: 8),
                Text(
                  isAr ? 'إنشاء خطة التمارين' : 'Workout Plan Builder',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A2B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7E2D1)),
              ),
              child: Text(
                '${isAr ? "الخطوة" : "Step"} $_currentStep / 4',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF235A42),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Step progress line
        Row(
          children: List.generate(4, (index) {
            final stepIndex = index + 1;
            final isCompleted = _currentStep >= stepIndex;
            final isCurrent = _currentStep == stepIndex;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF235A42) : const Color(0xFFE2ECE5),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(0xFF235A42).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(bool isAr) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Frequency(isAr);
      case 2:
        return _buildStep2Split(isAr);
      case 3:
        return _buildStep3Goal(isAr);
      case 4:
      default:
        return _buildStep4ReviewAndChat(isAr);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 1: Frequency Selector
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep1Frequency(bool isAr) {
    final options = [
      {
        'days': 3,
        'title': isAr ? '٣ أيام أسبوعياً' : '3 Days / Week',
        'subtitle': isAr ? 'تمرين كامل للجسم — متوازن ومرن' : 'Full Body Split — Balanced & Efficient',
        'badge': isAr ? 'شامل' : 'Balanced',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'days': 4,
        'title': isAr ? '٤ أيام أسبوعياً' : '4 Days / Week',
        'subtitle': isAr ? 'علوي / سفلي — الأفضل لزيادة الحجم والقوة' : 'Upper / Lower — Hypertrophy & Strength',
        'badge': isAr ? 'الأكثر شيوعاً' : 'Most Popular',
        'icon': Icons.bolt_rounded,
      },
      {
        'days': 5,
        'title': isAr ? '٥ أيام أسبوعياً' : '5 Days / Week',
        'subtitle': isAr ? 'تقسيم هجين / عضلات مخصصة' : 'Hybrid / Dedicated Muscle Groups',
        'badge': isAr ? 'تركيز عالي' : 'High Focus',
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'days': 6,
        'title': isAr ? '٦ أيام أسبوعياً' : '6 Days / Week',
        'subtitle': isAr ? 'دفع / سحب / أرجل (PPL) — أقصى كثافة تدريبية' : 'Push Pull Legs (PPL) — Maximum Volume',
        'badge': isAr ? 'متقدم' : 'Advanced',
        'icon': Icons.military_tech_rounded,
      },
    ];

    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'كم يوماً في الأسبوع تريد التدريب؟' : 'How many days do you want to train?',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A2B)),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'اختر الأيام المناسبة لجدولك اليومي.' : 'Select the weekly commitment that best fits your lifestyle.',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6E5D)),
        ),
        const SizedBox(height: 16),
        ...options.map((opt) {
          final days = opt['days'] as int;
          final isSelected = _selectedDays == days;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _onSelectDays(days),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEAF5EE) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF235A42) : const Color(0xFFE2ECE5),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF235A42) : const Color(0xFFF1F6F3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        opt['icon'] as IconData,
                        size: 20,
                        color: isSelected ? Colors.white : const Color(0xFF5A6E5D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                opt['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E3A2B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF235A42).withValues(alpha: 0.12) : const Color(0xFFEFF4F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  opt['badge'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? const Color(0xFF235A42) : const Color(0xFF5A6E5D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt['subtitle'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5A6E5D)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? const Color(0xFF235A42) : const Color(0xFFCBDCD0),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        _buildActionButton(
          label: isAr ? 'التالي: اختيار تقسيم التمارين' : 'Next: Select Split Style',
          onPressed: () => _goToStep(2),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 2: Split Style Selector
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep2Split(bool isAr) {
    final availableSplits = RoutineCatalogue.forDays(_selectedDays);

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'اختر نظام تقسيم العضلات' : 'Choose Your Training Split',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A2B)),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'الأنظمة المقترحة لـ $_selectedDays أيام أسبوعياً:' : 'Optimized splits for $_selectedDays days/week:',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6E5D)),
        ),
        const SizedBox(height: 16),
        ...availableSplits.map((split) {
          final isSelected = _selectedRoutine.splitType == split.splitType;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedRoutine = split),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEAF5EE) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF235A42) : const Color(0xFFE2ECE5),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          split.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A2B),
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? const Color(0xFF235A42) : const Color(0xFFCBDCD0),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      split.tagline,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6E5D)),
                    ),
                    const SizedBox(height: 12),
                    // Weekly breakdown tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: split.breakdown.take(7).map((dayName) {
                        final isRest = dayName.toLowerCase().contains('rest');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isRest ? const Color(0xFFF3F5F4) : const Color(0xFFD8ECDF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dayName,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isRest ? const Color(0xFF8B9B8E) : const Color(0xFF1E3A2B),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        _buildActionButton(
          label: isAr ? 'التالي: اختيار الهدف والتركيز' : 'Next: Choose Goals & Focus',
          onPressed: () => _goToStep(3),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 3: Goal & Focus Selector
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep3Goal(bool isAr) {
    final goals = [
      {'id': 'hypertrophy', 'label': isAr ? 'بناء العضلات والضخامة' : 'Muscle Growth (Hypertrophy)', 'icon': Icons.fitness_center_rounded},
      {'id': 'strength', 'label': isAr ? 'زيادة القوة والأوزان' : 'Strength & Power', 'icon': Icons.bolt_rounded},
      {'id': 'fat_loss', 'label': isAr ? 'حرق الدهون ونحت الجسم' : 'Fat Loss & Conditioning', 'icon': Icons.local_fire_department_rounded},
      {'id': 'endurance', 'label': isAr ? 'اللياقة العامة والصحة' : 'General Fitness & Health', 'icon': Icons.favorite_rounded},
    ];

    final focuses = [
      {'id': 'balanced', 'label': isAr ? 'متوازن لكل العضلات' : 'Balanced Full Coverage'},
      {'id': 'upper', 'label': isAr ? 'تركيز على الصدر والذراعين' : 'Upper / Chest & Arms Emphasis'},
      {'id': 'lower', 'label': isAr ? 'تركيز على الأرجل والأرداف' : 'Legs & Lower Body Emphasis'},
      {'id': 'back', 'label': isAr ? 'تركيز على الظهر والأكتاف' : 'Back & Shoulder Width'},
    ];

    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'ما هو هدفك التدريبي الأساسي؟' : 'What is your primary training goal?',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A2B)),
        ),
        const SizedBox(height: 12),
        ...goals.map((g) {
          final isSelected = _selectedGoal == g['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedGoal = g['id'] as String),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEAF5EE) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF235A42) : const Color(0xFFE2ECE5),
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(g['icon'] as IconData, size: 18, color: isSelected ? const Color(0xFF235A42) : const Color(0xFF5A6E5D)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        g['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF1E3A2B),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded, color: Color(0xFF235A42), size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          isAr ? 'منطقة التركيز المفضلة:' : 'Target Muscle Emphasis:',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A2B)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: focuses.map((f) {
            final isSelected = _selectedFocus == f['id'];
            return InkWell(
              onTap: () => setState(() => _selectedFocus = f['id'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF235A42) : const Color(0xFFF1F6F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  f['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF235A42),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          label: isAr ? 'إنشاء الخطة ومراجعة المدرب الذكي' : 'Generate & Review with AI Coach',
          onPressed: () => _goToStep(4),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 4: AI Review & Live Conversation
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep4ReviewAndChat(bool isAr) {
    final chips = isAr
        ? ['ركز أكثر على الذراعين', 'بدّل البار بالدمبلز', 'اجعلها ٥ أيام', 'أضف تمارين بطن']
        : ['Add more Arm volume', 'Swap Barbell for Dumbbells', 'Make it 5 days instead', 'Add Core / Abs focus'];

    return Column(
      key: const ValueKey('step4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E8DC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedRoutine.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A2B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF235A42),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_selectedDays ${isAr ? "أيام" : "Days"}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedRoutine.breakdown.take(7).map((d) {
                  final isRest = d.toLowerCase().contains('rest');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isRest ? const Color(0xFFE8ECE9) : const Color(0xFFD6ECD9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      d,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isRest ? const Color(0xFF718274) : const Color(0xFF1E3A2B),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Suggestion Chips
        Text(
          isAr ? 'اقتراحات سريعة للمدرب:' : 'Quick AI Adjustments:',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF5A6E5D)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips.map((c) {
            return ActionChip(
              label: Text(c),
              labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF235A42)),
              backgroundColor: const Color(0xFFEAF5EE),
              side: const BorderSide(color: Color(0xFFCBE2D4), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onPressed: () => _sendChatMessage(c),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Chat conversation history box
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAF9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2ECE5)),
          ),
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final msg = _messages[i];
              if (msg.isTyping) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF235A42)),
                      ),
                      SizedBox(width: 8),
                      Text('AI Coach is thinking...', style: TextStyle(fontSize: 11, color: Color(0xFF5A6E5D))),
                    ],
                  ),
                );
              }
              return Align(
                alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: msg.isUser ? const Color(0xFF235A42) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: msg.isUser ? null : Border.all(color: const Color(0xFFD6E8DC)),
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: msg.isUser ? Colors.white : const Color(0xFF1E3A2B),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Input field for custom prompt
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: isAr ? 'اسأل المدرب أو اطلب تعديلاً...' : 'Ask coach or request tweak...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B9B8E)),
                  filled: true,
                  fillColor: const Color(0xFFF1F6F3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _sendChatMessage,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _sendChatMessage(_chatController.text),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF235A42),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Confirm & Start button
        _buildActionButton(
          label: _isSavingRoutine
              ? (isAr ? 'جاري الحفظ...' : 'Saving Routine...')
              : (isAr ? 'تأكيد وبدء الخطة التدريبية' : 'Confirm & Start Routine'),
          isLoading: _isSavingRoutine,
          onPressed: _isSavingRoutine ? null : _confirmAndSaveRoutine,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF235A42),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _WizardChatMessage {
  final String text;
  final bool isUser;
  final bool isTyping;

  const _WizardChatMessage({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });
}
