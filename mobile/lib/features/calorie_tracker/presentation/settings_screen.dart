// lib/features/calorie_tracker/presentation/settings_screen.dart
// The Teneen — Settings & Profile Management Screen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/bloc/profile_event.dart';
import '../../profile/presentation/bloc/profile_state.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';

import '../../premium/presentation/premium_upgrade_screen.dart';
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

    _gender = user['gender'] ?? 'male';
    _activityLevel = user['activityLevel'] ?? 'moderate';
    _goal = user['goal'] ?? 'maintain';
    _isInitialized = true;
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
  }

  Widget _buildPremiumCard(BuildContext context, bool isPremium, bool isArabic) {
    if (isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFF59E0B).withValues(alpha: 0.15), const Color(0xFFF59E0B).withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'عضو مميز' : 'Premium Member',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic ? 'أنت تستمتع بجميع الميزات المميزة' : 'You are enjoying all premium features.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          PurchaseService.instance.presentPaywall(context);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'ترقية إلى المميز' : 'Upgrade to Premium',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic ? 'احصل على وصول غير محدود وبدون إعلانات.' : 'Get unlimited access & remove ads.',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        centerTitle: false,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profileSaved), backgroundColor: AppColors.primary),
            );
          } else if (state is ProfileFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileInitial) {
            context.read<ProfileBloc>().add(LoadProfile());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileLoading && !_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileLoaded) {
            _initializeValues(state.user);
            return _buildForm(context, state.user, l10n, isArabic);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, Map<String, dynamic> user, AppLocalizations l10n, bool isArabic) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumCard(context, user['isPremium'] == true, isArabic),
            const SizedBox(height: 24),
            // ── Section 1: Language Switcher Card ───────────────────────────
            _buildSectionHeader(l10n.profileLanguage),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'اللغة / Language',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Row(
                    children: [
                      _buildLangChip(context, 'العربية', 'ar', isArabic),
                      const SizedBox(width: 8),
                      _buildLangChip(context, 'English', 'en', !isArabic),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 2: Personal Details Card ─────────────────────────────
            _buildSectionHeader(l10n.profilePersonalInfo),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(l10n.profileName),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(l10n.profileAge),
                            TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Years'),
                              style: const TextStyle(color: AppColors.textPrimary),
                              validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(l10n.profileGender),
                            DropdownButtonFormField<String>(
                              value: _gender,
                              dropdownColor: AppColors.surface,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              style: const TextStyle(color: AppColors.textPrimary),
                              items: [
                                DropdownMenuItem(value: 'male', child: Text(l10n.profileGenderMale)),
                                DropdownMenuItem(value: 'female', child: Text(l10n.profileGenderFemale)),
                              ],
                              onChanged: (val) => setState(() => _gender = val ?? 'male'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 3: Physical & Health Card ────────────────────────────
            _buildSectionHeader(l10n.onboardingBodyTitle),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(l10n.profileWeight),
                            TextFormField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'kg'),
                              style: const TextStyle(color: AppColors.textPrimary),
                              validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(l10n.profileHeight),
                            TextFormField(
                              controller: _heightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'cm'),
                              style: const TextStyle(color: AppColors.textPrimary),
                              validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(l10n.profileGoal),
                  DropdownButtonFormField<String>(
                    value: _goal,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: [
                      DropdownMenuItem(value: 'lose', child: Text(l10n.onboardingGoalLose)),
                      DropdownMenuItem(value: 'maintain', child: Text(l10n.onboardingGoalMaintain)),
                      DropdownMenuItem(value: 'gain', child: Text(l10n.onboardingGoalGain)),
                    ],
                    onChanged: (val) => setState(() => _goal = val ?? 'maintain'),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(l10n.profileActivity),
                  DropdownButtonFormField<String>(
                    value: _activityLevel,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: [
                      DropdownMenuItem(value: 'sedentary', child: Text(l10n.onboardingActivitySedentary)),
                      DropdownMenuItem(value: 'lightly_active', child: Text(l10n.onboardingActivityLight)),
                      DropdownMenuItem(value: 'moderate', child: Text(l10n.onboardingActivityModerate)),
                      DropdownMenuItem(value: 'very_active', child: Text(l10n.onboardingActivityVeryActive)),
                    ],
                    onChanged: (val) => setState(() => _activityLevel = val ?? 'moderate'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 4: Targets Settings Card ─────────────────────────────
            _buildSectionHeader(l10n.homeGoal),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(l10n.profileCalorieGoal),
                  TextFormField(
                    controller: _calorieGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'kcal'),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(l10n.profileWaterGoal),
                  TextFormField(
                    controller: _waterGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'ml'),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (val) => val == null || val.trim().isEmpty ? l10n.errorGeneric : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Save Profile button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveProfile(context, l10n),
                child: Text(l10n.saveButton),
              ),
            ),
            const SizedBox(height: 16),

            // ── Logout Action Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutConfirmDialog(context, l10n),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: Text(l10n.profileLogout, style: const TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
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
          title: Text(l10n.profileLogout),
          content: Text(l10n.profileLogoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(LogoutRequested());
                // Instantly pop settings back to home where auth wrapper triggers login redirect
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l10n.profileLogout),
            ),
          ],
        );
      },
    );
  }
}
