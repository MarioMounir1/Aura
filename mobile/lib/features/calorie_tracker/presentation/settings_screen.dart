// lib/features/calorie_tracker/presentation/settings_screen.dart
// Modernized Profile & Settings Screen for Aura

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
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
    _calorieGoalController = TextEditingController(text: (user['dailyCalorieGoal'] ?? '').toString());
    _waterGoalController = TextEditingController(text: (user['dailyWaterGoalMl'] ?? '').toString());

    _nameController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _calorieGoalController.addListener(_onFieldChanged);
    _waterGoalController.addListener(_onFieldChanged);

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.profileSaved),
                backgroundColor: AppColors.primary,
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is ProfileLoading && !_isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Top User Header with Avatar & Metrics Summary ──────────
            _buildUserAvatarHeader(name, email, isPremium),
            const SizedBox(height: 16),
            _buildKeyMetricsSummaryRow(l10n),
            const SizedBox(height: 24),

            // ── 2. Membership Banner ──────────────────────────────────────
            _buildMembershipBanner(context, isPremium, isArabic),
            const SizedBox(height: 28),

            // ── 3. Group 1: Fitness & Personal Metrics ────────────────────
            _buildSectionTitle(l10n.profilePersonalInfo, Icons.fitness_center_rounded),
            const SizedBox(height: 12),
            _buildFitnessMetricsGroup(l10n),
            const SizedBox(height: 28),

            // ── 4. Group 2: Preferences ──────────────────────────────────
            _buildSectionTitle(l10n.profileLanguage, Icons.tune_rounded),
            const SizedBox(height: 12),
            _buildPreferencesGroup(context, isArabic),
            const SizedBox(height: 28),

            // ── 5. Group 3: Account Actions ──────────────────────────────
            _buildSectionTitle(isArabic ? 'الحساب' : 'Account Actions', Icons.shield_rounded),
            const SizedBox(height: 12),
            _buildAccountActionsGroup(context, l10n),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header Widget: Avatar + Name + Email ──────────────────────────
  Widget _buildUserAvatarHeader(String name, String email, bool isPremium) {
    final String initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceVariant.withOpacity(0.5),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPremium
                        ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                        : [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPremium ? const Color(0xFFFBBF24) : AppColors.primary).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isPremium ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
              if (isPremium)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFBBF24),
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
              color: AppColors.textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24).withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'عضو مميز في أورا' : 'Aura Premium Member',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic ? 'أنت تستمتع بجميع الميزات المميزة.' : 'You are enjoying full unlimited premium access.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0097A7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'ترقية إلى المميز' : 'Upgrade to Premium',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
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
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Group 1: Fitness & Health Metrics ─────────────────────────────
  Widget _buildFitnessMetricsGroup(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(l10n.profileName),
          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration(hint: 'Full Name', icon: Icons.person_rounded),
            style: GoogleFonts.inter(color: AppColors.textPrimary),
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
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
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
                      dropdownColor: AppColors.surfaceVariant,
                      decoration: _buildInputDecoration(hint: '', icon: Icons.wc_rounded),
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
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
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
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
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
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
            dropdownColor: AppColors.surfaceVariant,
            decoration: _buildInputDecoration(hint: '', icon: Icons.track_changes_rounded),
            style: GoogleFonts.inter(color: AppColors.textPrimary),
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
            dropdownColor: AppColors.surfaceVariant,
            decoration: _buildInputDecoration(hint: '', icon: Icons.directions_run_rounded),
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(l10n.profileCalorieGoal),
                    TextFormField(
                      controller: _calorieGoalController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(hint: 'kcal', icon: Icons.local_fire_department_rounded),
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
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
                    _buildFieldLabel(l10n.profileWaterGoal),
                    TextFormField(
                      controller: _waterGoalController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(hint: 'ml', icon: Icons.water_drop_rounded),
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                      validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Group 2: Preferences (Language, Units, Theme) ────────────────
  Widget _buildPreferencesGroup(BuildContext context, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Language Switcher Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
            ),
            title: Text(
              'اللغة / Language',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLangChip(context, 'العربية', 'ar', isArabic),
                const SizedBox(width: 6),
                _buildLangChip(context, 'English', 'en', !isArabic),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Units Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 20),
            ),
            title: Text(
              isArabic ? 'وحدات القياس' : 'Measurement Units',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              isArabic ? 'المتري (كجم / سم)' : 'Metric (kg / cm)',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Metric',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Dark Theme Status Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dark_mode_rounded, color: AppColors.primary, size: 20),
            ),
            title: Text(
              isArabic ? 'المظهر' : 'App Theme',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              isArabic ? 'الوضع الداكن الفاخر' : 'Ultra Dark Mode (Default)',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Group 3: Account Actions (Logout) ────────────────────────────
  Widget _buildAccountActionsGroup(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => _showLogoutConfirmDialog(context, l10n),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
        ),
        title: Text(
          l10n.profileLogout,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        subtitle: Text(
          l10n.profileLogoutConfirm,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.error, size: 14),
      ),
    );
  }

  // ── Floating Action Bar for Unsaved Changes ──────────────────────
  Widget _buildFloatingSaveBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have unsaved changes',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveProfile(context, l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLangChip(BuildContext context, String label, String langCode, bool isActive) {
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (val) {
        if (val) {
          context.read<LanguageCubit>().setLanguage(langCode);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.profileLogout,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Text(
            l10n.profileLogoutConfirm,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelButton, style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
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
