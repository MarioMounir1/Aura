// lib/features/calorie_tracker/presentation/home_shell_screen.dart
// The Teneen — Tabbed Navigation Shell

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'analyze_meal_screen.dart';
import 'food_search_screen.dart';
import 'meal_plans_screen.dart';
import 'settings_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const FoodSearchScreen(),
    const AnalyzeMealScreen(),
    const MealPlansScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_rounded),
            label: l10n.navSearch,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.camera_enhance_rounded),
            label: l10n.navScan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_rounded),
            label: l10n.navPlans,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
