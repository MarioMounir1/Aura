// lib/features/calorie_tracker/presentation/home_shell_screen.dart
// The Teneen — Tabbed Navigation Shell

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/dashboard_bloc.dart';
import 'bloc/dashboard_state.dart';
import 'bloc/dashboard_event.dart';
import 'meals_dashboard_screen.dart';
import 'workout_screen.dart';
import 'settings_screen.dart';

class DashboardTabWrapper extends StatefulWidget {
  const DashboardTabWrapper({super.key});

  @override
  State<DashboardTabWrapper> createState() => _DashboardTabWrapperState();
}

class _DashboardTabWrapperState extends State<DashboardTabWrapper> {
  DashboardLoaded? _lastLoaded;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          _lastLoaded = state;
        }

        if (_lastLoaded != null) {
          return MealsDashboard(
            foodSummary: _lastLoaded!.foodSummary,
            mealLogs: _lastLoaded!.todayMealLogs,
          );
        }

        if (state is DashboardInitial || state is DashboardLoading) {
          return const MealsDashboard(
            foodSummary: null,
            mealLogs: [],
          );
        }

        if (state is DashboardFailure) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DashboardBloc>().add(const LoadDashboard()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return const MealsDashboard(
          foodSummary: null,
          mealLogs: [],
        );
      },
    );
  }
}

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardTabWrapper(),
    WorkoutScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildCustomNavBar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavBar(BuildContext context) {
    final theme = context.auraTheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, 0, false),
          _buildNavItem(Icons.fitness_center_rounded, 1, true),
          _buildNavItem(Icons.person_rounded, 2, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool hasHalo) {
    final theme = context.auraTheme;
    final isSelected = _currentIndex == index;
    final color = isSelected ? theme.primary : theme.textSecondary.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 64,
        child: Center(
          child: Container(
            decoration: isSelected && hasHalo
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : null,
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}

