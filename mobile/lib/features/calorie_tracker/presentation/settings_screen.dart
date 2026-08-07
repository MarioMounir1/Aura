// lib/features/calorie_tracker/presentation/settings_screen.dart
// Modernized Profile & Settings Screen for Aura (Mint & Forest Green UI Redesign)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/bloc/profile_event.dart';
import '../../profile/presentation/bloc/profile_state.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../premium/data/services/purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _calorieGoalController;
  late TextEditingController _waterGoalController;

  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  bool _isInitialized = false;
  bool _hasUnsavedChanges = false;
  bool _isPersonalInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileBloc>().add(LoadProfile());
      }
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController.dispose();
      _ageController.dispose();
      _weightController.dispose();
      _heightController.dispose();
      _calorieGoalController.dispose();
      _waterGoalController.dispose();
    }
    super.dispose();
  }

  void _initializeValues(Map<String, dynamic> user) {
    if (_isInitialized) return;

    _nameController = TextEditingController(text: user['name'] ?? '');
    _ageController = TextEditingController(text: (user['age'] ?? '').toString());
    _weightController = TextEditingController(text: (user['weightKg'] ?? '').toString());
    _heightController = TextEditingController(text: (user['heightCm'] ?? '').toString());

    final initialCalories = user['dailyCalorieGoal'];
    int calGoal = (initialCalories is int && initialCalories > 0)
        ? initialCalories
        : int.tryParse(user['dailyCalorieGoal']?.toString() ?? '') ?? 0;

    if (calGoal <= 0) {
      final w = double.tryParse((user['weightKg'] ?? '').toString()) ?? 70.0;
      final h = double.tryParse((user['heightCm'] ?? '').toString()) ?? 170.0;
      final a = int.tryParse((user['age'] ?? '').toString()) ?? 25;
      final g = user['gender'] ?? 'male';
      final act = user['activityLevel'] ?? 'moderate';
      final goalType = user['goal'] ?? 'maintain';

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
      calGoal = (bmr * mult + adj).round().clamp(1200, 5000);
    }

    _calorieGoalController = TextEditingController(text: calGoal.toString());
    _waterGoalController = TextEditingController(text: (user['dailyWaterGoalMl'] ?? '2500').toString());

    _nameController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _calorieGoalController.addListener(_onFieldChanged);

    _gender = user['gender'] ?? 'male';
    _activityLevel = user['activityLevel'] ?? 'moderate';
    _goal = user['goal'] ?? 'maintain';
    _isInitialized = true;
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges && mounted) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _saveProfile(BuildContext context, AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 25;
    final weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 170.0;
    final calories = int.tryParse(_calorieGoalController.text.trim()) ?? 2000;
    final water = int.tryParse(_waterGoalController.text.trim()) ?? 2500;

    context.read<ProfileBloc>().add(
          UpdateProfileEvent(
            name: name,
            age: age,
            weightKg: weight,
            heightCm: height,
            gender: _gender,
            activityLevel: _activityLevel,
            goal: _goal,
            dailyCalorieGoal: calories,
            dailyWaterGoalMl: water,
          ),
        );

    setState(() => _hasUnsavedChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.profileSaved),
                  backgroundColor: const Color(0xFF235A42),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is ProfileFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileInitial) {
              context.read<ProfileBloc>().add(LoadProfile());
              return const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 3, color: Color(0xFF235A42)),
              );
            }
            if (state is ProfileLoading && !_isInitialized) {
              return const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 3, color: Color(0xFF235A42)),
              );
            }
            if (state is ProfileLoaded) {
              _initializeValues(state.user);
              return Stack(
                children: [
                  _buildForm(context, state.user, l10n, isArabic),
                  if (_hasUnsavedChanges)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: _buildFloatingSaveBar(context, l10n),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    Map<String, dynamic> user,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final bool isPremium = user['isPremium'] == true;
    final String email = user['email'] ?? '';
    final String name = _nameController.text.isNotEmpty ? _nameController.text : (user['name'] ?? 'User');

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Top Header (Date + Title + Action Avatar) ─────────────
            _buildProfileHeader(context),
            const SizedBox(height: 16),

            // ── 2. User Profile Card ──────────────────────────────────────
            _buildUserAvatarHeader(name, email, isPremium),
            const SizedBox(height: 14),

            // ── 3. Metrics Quick Summary Grid ──────────────────────────────
            _buildKeyMetricsSummaryRow(l10n),
            const SizedBox(height: 18),

            // ── 4. Membership Banner ──────────────────────────────────────
            _buildMembershipBanner(context, isPremium, isArabic),
            const SizedBox(height: 22),

            // ── 5. Personal Info (Collapsible) ────────────────────────────
            _buildCollapsiblePersonalInfo(l10n),
            const SizedBox(height: 22),

            // ── 6. Preferences Section ────────────────────────────────────
            _buildSectionTitle(isArabic ? 'التفضيلات' : 'PREFERENCES'),
            const SizedBox(height: 10),
            _buildPreferencesGroup(context, isArabic),
            const SizedBox(height: 22),

            // ── 7. Account Actions Section ────────────────────────────────
            _buildSectionTitle(isArabic ? 'الحساب' : 'ACCOUNT ACTIONS'),
            const SizedBox(height: 10),
            _buildAccountActionsGroup(context, l10n),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Top App Bar / Header ───────────────────────────────────────────
  Widget _buildProfileHeader(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7A8B7B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Profile',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C2B1E),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── User Avatar Card ──────────────────────────────────────────────
  Widget _buildUserAvatarHeader(String name, String email, bool isPremium) {
    final String initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF235A42),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF235A42).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isPremium)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C2B1E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFBBF24),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C2B1E),
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF7A8B7B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Key Metrics Horizontal Summary Row ────────────────────────────
  Widget _buildKeyMetricsSummaryRow(AppLocalizations l10n) {
    final weightStr = _weightController.text.isNotEmpty ? '${_weightController.text} kg' : '--';
    final heightStr = _heightController.text.isNotEmpty ? '${_heightController.text} cm' : '--';
    final goalStr = _goal == 'lose'
        ? l10n.onboardingGoalLose
        : _goal == 'gain'
            ? l10n.onboardingGoalGain
            : l10n.onboardingGoalMaintain;

    return Row(
      children: [
        Expanded(child: _buildMetricTile(l10n.profileWeight, weightStr, Icons.scale_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricTile(l10n.profileHeight, heightStr, Icons.height_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricTile(l10n.profileGoal, goalStr, Icons.track_changes_rounded)),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5EE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF235A42), size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C2B1E),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7A8B7B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Membership Banner Widget ──────────────────────────────────────
  Widget _buildMembershipBanner(BuildContext context, bool isPremium, bool isArabic) {
    if (isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCEEE3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB5DBC3), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF235A42),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'عضو مميز في أورا' : 'Aura Premium Member',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C2B1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic ? 'أنت تستمتع بجميع الميزات المميزة.' : 'You are enjoying full unlimited premium access.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6E5D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return InkWell(
        onTap: () => PurchaseService.instance.presentPaywall(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF235A42), Color(0xFF1E3A2B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20235A42),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'ترقية إلى أورا برو' : 'Upgrade to Aura Pro',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic ? 'تحليل ذكاء اصطناعي بلا حدود وبدون إعلانات.' : 'Get unlimited AI scans & 100% ad-free experience.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      );
    }
  }

  // ── Section Title Helper ─────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF5A6E5D),
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Collapsible Personal Info Section ───────────────────────────
  Widget _buildCollapsiblePersonalInfo(AppLocalizations l10n) {
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final weight = _weightController.text.trim();
    final height = _heightController.text.trim();
    final goalStr = _goal == 'lose' ? l10n.onboardingGoalLose : _goal == 'gain' ? l10n.onboardingGoalGain : l10n.onboardingGoalMaintain;
    final summaryParts = [
      if (name.isNotEmpty) name,
      if (age.isNotEmpty) '${age}y',
      if (weight.isNotEmpty) '${weight}kg',
      if (height.isNotEmpty) '${height}cm',
      goalStr,
    ];
    final summary = summaryParts.join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row (always visible)
          InkWell(
            onTap: () => setState(() => _isPersonalInfoExpanded = !_isPersonalInfoExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF235A42), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profilePersonalInfo,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C2B1E),
                          ),
                        ),
                        if (!_isPersonalInfoExpanded && summary.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF7A8B7B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isPersonalInfoExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, color: Color(0xFF7A8B7B), size: 22),
                  ),
                ],
              ),
            ),
          ),
          // Expandable fields
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE2EBE4)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildFitnessMetricsGroup(l10n),
                ),
              ],
            ),
            crossFadeState: _isPersonalInfoExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  // ── Group 1: Fitness & Health Metrics ─────────────────────────────
  Widget _buildFitnessMetricsGroup(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(l10n.profileName),
        TextFormField(
          controller: _nameController,
          decoration: _buildInputDecoration(hint: 'Full Name', icon: Icons.person_rounded),
          style: GoogleFonts.inter(color: const Color(0xFF1C2B1E)),
          validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.profileAge),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(hint: 'Years', icon: Icons.cake_rounded),
                    style: GoogleFonts.inter(color: const Color(0xFF1C2B1E)),
                    validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.profileGender),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    dropdownColor: Colors.white,
                    decoration: _buildInputDecoration(hint: '', icon: Icons.wc_rounded),
                    style: GoogleFonts.inter(color: const Color(0xFF1C2B1E)),
                    items: [
                      DropdownMenuItem(value: 'male', child: Text(l10n.profileGenderMale)),
                      DropdownMenuItem(value: 'female', child: Text(l10n.profileGenderFemale)),
                    ],
                    onChanged: (val) {
                      setState(() => _gender = val ?? 'male');
                      _onFieldChanged();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.profileWeight),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _buildInputDecoration(hint: 'kg', icon: Icons.scale_rounded),
                    style: GoogleFonts.inter(color: const Color(0xFF1C2B1E)),
                    validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(l10n.profileHeight),
                  TextFormField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _buildInputDecoration(hint: 'cm', icon: Icons.height_rounded),
                    style: GoogleFonts.inter(color: const Color(0xFF1C2B1E)),
                    validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFieldLabel(l10n.profileGoal),
        DropdownButtonFormField<String>(
          value: _goal,
          dropdownColor: Colors.white,
          decoration: _buildInputDecoration(hint: '', icon: Icons.track_changes_rounded),
          style: GoogleFonts.inter(color: const Color(0xFF1C2B1E)),
          items: [
            DropdownMenuItem(value: 'lose', child: Text(l10n.onboardingGoalLose)),
            DropdownMenuItem(value: 'maintain', child: Text(l10n.onboardingGoalMaintain)),
            DropdownMenuItem(value: 'gain', child: Text(l10n.onboardingGoalGain)),
          ],
          onChanged: (val) {
            setState(() => _goal = val ?? 'maintain');
            _onFieldChanged();
          },
        ),
        const SizedBox(height: 16),
        _buildFieldLabel(l10n.profileActivity),
        DropdownButtonFormField<String>(
          value: _activityLevel,
          dropdownColor: Colors.white,
          decoration: _buildInputDecoration(hint: '', icon: Icons.directions_run_rounded),
          style: GoogleFonts.inter(color: const Color(0xFF1C2B1E), fontSize: 13),
          items: [
            DropdownMenuItem(value: 'sedentary', child: Text(l10n.onboardingActivitySedentary)),
            DropdownMenuItem(value: 'lightly_active', child: Text(l10n.onboardingActivityLight)),
            DropdownMenuItem(value: 'moderate', child: Text(l10n.onboardingActivityModerate)),
            DropdownMenuItem(value: 'very_active', child: Text(l10n.onboardingActivityVeryActive)),
          ],
          onChanged: (val) {
            setState(() => _activityLevel = val ?? 'moderate');
            _onFieldChanged();
          },
        ),
        const SizedBox(height: 16),
        _buildFieldLabel(l10n.profileCalorieGoal),
        TextFormField(
          controller: _calorieGoalController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration(hint: 'kcal', icon: Icons.local_fire_department_rounded),
          style: GoogleFonts.inter(color: const Color(0xFF1C2B1E)),
          validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
        ),
      ],
    );
  }

  // ── Group 2: Preferences (Units) ─────────────────────────────────
  Widget _buildPreferencesGroup(BuildContext context, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFEAF5EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.straighten_rounded, color: Color(0xFF235A42), size: 18),
        ),
        title: Text(
          isArabic ? 'وحدات القياس' : 'Measurement Units',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C2B1E),
          ),
        ),
        subtitle: Text(
          isArabic ? 'المتري (كجم / سم)' : 'Metric (kg / cm)',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A8B7B)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2B1E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Metric',
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Group 3: Account Actions (Logout) ────────────────────────────
  Widget _buildAccountActionsGroup(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0E0), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => _showLogoutConfirmDialog(context, l10n),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFDE8E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 18),
          ),
          title: Text(
            l10n.profileLogout,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE53935),
            ),
          ),
          subtitle: Text(
            l10n.profileLogoutConfirm,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E)),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE53935), size: 14),
        ),
      ),
    );
  }

  // ── Floating Action Bar for Unsaved Changes ──────────────────────
  Widget _buildFloatingSaveBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF235A42),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You have unsaved changes',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveProfile(context, l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDCEEE3),
              foregroundColor: const Color(0xFF1E3A2B),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.saveButton,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Styling Helpers ─────────────────────────────────────────
  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF7A8B7B), size: 18),
      filled: true,
      fillColor: const Color(0xFFF1F6F2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3E4D7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3E4D7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF235A42), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5A6E5D),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.profileLogout,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1C2B1E)),
          ),
          content: Text(
            l10n.profileLogoutConfirm,
            style: GoogleFonts.inter(color: const Color(0xFF5A6E5D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelButton, style: GoogleFonts.inter(color: const Color(0xFF7A8B7B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                l10n.profileLogout,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
