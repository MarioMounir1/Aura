// lib/main.dart
// The Teneen — App Entry Point
// Supports: AR/EN localization, RTL, dark theme

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'l10n/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/constants.dart';
import 'core/theme/theme_cubit.dart';
import 'features/calorie_tracker/data/models/meal_log_model.dart';
import 'features/calorie_tracker/data/repositories/meal_repository_impl.dart';
import 'features/calorie_tracker/domain/repositories/meal_repository.dart';
import 'features/calorie_tracker/presentation/ai_suggestion_screen.dart';
import 'features/calorie_tracker/presentation/bloc/calorie_tracker_bloc.dart';
import 'features/calorie_tracker/presentation/history_screen.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_event.dart';
import 'features/profile/presentation/bloc/profile_state.dart';
import 'features/profile/presentation/onboarding_screen.dart';

import 'features/calorie_tracker/domain/repositories/tracker_repository.dart';
import 'features/calorie_tracker/data/repositories/tracker_repository_impl.dart';
import 'features/calorie_tracker/presentation/bloc/dashboard_bloc.dart';
import 'features/calorie_tracker/presentation/bloc/food_search_bloc.dart';
import 'features/calorie_tracker/presentation/home_shell_screen.dart';
import 'features/calorie_tracker/presentation/settings_screen.dart';
import 'features/calorie_tracker/presentation/food_search_screen.dart';
import 'features/calorie_tracker/presentation/weight_progress_screen.dart';
import 'features/calorie_tracker/presentation/bloc/water_bloc.dart';
import 'features/calorie_tracker/presentation/water_tracking_screen.dart';
import 'features/calorie_tracker/presentation/bloc/weight_bloc.dart';
import 'features/calorie_tracker/presentation/bloc/meal_plan_bloc.dart';
import 'features/calorie_tracker/domain/repositories/workout_repository.dart';
import 'features/calorie_tracker/data/repositories/workout_repository_impl.dart';
import 'features/calorie_tracker/presentation/bloc/workout_bloc.dart';
import 'features/calorie_tracker/presentation/bloc/dashboard_event.dart';
import 'features/calorie_tracker/presentation/bloc/workout_event.dart';
import 'features/calorie_tracker/presentation/bloc/calorie_tracker_event.dart';
import 'features/calorie_tracker/presentation/bloc/food_search_event.dart';
import 'features/calorie_tracker/presentation/bloc/water_event.dart';
import 'features/calorie_tracker/presentation/bloc/weight_event.dart';
import 'features/calorie_tracker/presentation/bloc/meal_plan_event.dart';
import 'features/calorie_tracker/presentation/bloc/nutrition_progress_bloc.dart';
import 'features/calorie_tracker/presentation/progress_summary_screen.dart';
import 'features/premium/data/services/purchase_service.dart';

// ── Language Cubit ────────────────────────────────────────────
// Simple cubit to hold and switch the app locale.
// Screens call context.read<LanguageCubit>().setLanguage('ar') to switch.

class LanguageCubit extends Cubit<Locale> {
  static const _prefKey = 'app_language';

  LanguageCubit(String initialLang)
      : super(Locale(initialLang.isNotEmpty ? initialLang : 'en'));

  Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
    emit(Locale(langCode));
  }

  static Future<String> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? 'en';
  }
}
// ── Entry Point ───────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors gracefully
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Force portrait orientation
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation setup error: $e');
  }

  // Configure status bar for light pre-screen
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF6F8F5),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Safe Hive Storage Initialization
  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(IngredientBreakdownModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MealLogModelAdapter());
    }
    await Hive.openBox<MealLogModel>(AppConstants.mealLogsBox);
  } catch (e) {
    debugPrint('Hive storage init error: $e');
  }

  // Fallback defaults for Language and Theme
  String savedLang = 'en';
  ThemeMode savedThemeMode = ThemeMode.light;

  try {
    savedLang = await LanguageCubit.getSavedLanguage();
  } catch (e) {
    debugPrint('LanguageCubit load error: $e');
  }

  try {
    savedThemeMode = await ThemeCubit.getSavedThemeMode();
  } catch (e) {
    debugPrint('ThemeCubit load error: $e');
  }

  runApp(TeneenApp(initialLang: savedLang, initialThemeMode: savedThemeMode));

  // Non-blocking initialization of RevenueCat & Google Mobile Ads in background
  try {
    PurchaseService.instance.init().catchError((e) {
      debugPrint('PurchaseService background init error: $e');
    });
  } catch (e) {
    debugPrint('PurchaseService init error: $e');
  }

  try {
    MobileAds.instance.initialize().catchError((e) {
      debugPrint('MobileAds background init error: $e');
    });
  } catch (e) {
    debugPrint('MobileAds init error: $e');
  }
}

// ── Root App Widget ───────────────────────────────────────────

class TeneenApp extends StatelessWidget {
  final String initialLang;
  final ThemeMode initialThemeMode;
  const TeneenApp({super.key, required this.initialLang, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    final apiClient       = ApiClient(secureStorage: const FlutterSecureStorage());
    final MealRepository  mealRepository = MealRepositoryImpl(apiClient);
    final AuthRepository  authRepository = AuthRepositoryImpl(apiClient);
    final ProfileRepository profileRepository = ProfileRepositoryImpl(apiClient);
    final trackerRepository = TrackerRepositoryImpl(apiClient);
    final WorkoutRepository workoutRepository = WorkoutRepositoryImpl(apiClient);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MealRepository>.value(value: mealRepository),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
        RepositoryProvider<TrackerRepository>.value(value: trackerRepository),
        RepositoryProvider<WorkoutRepository>.value(value: workoutRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // Theme switching
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(initialThemeMode),
          ),
          // Language switching
          BlocProvider<LanguageCubit>(
            create: (_) => LanguageCubit(initialLang),
          ),
          // Auth Session
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<AuthRepository>(),
            )..add(AppStarted()),
          ),
          // Profile
          BlocProvider<ProfileBloc>(
            create: (ctx) => ProfileBloc(
              repository: ctx.read<ProfileRepository>(),
            )..add(LoadProfile()),
          ),
          // Dashboard
          BlocProvider<DashboardBloc>(
            create: (ctx) => DashboardBloc(
              repository: ctx.read<TrackerRepository>(),
              mealRepository: ctx.read<MealRepository>(),
            )..add(const LoadDashboard()),
          ),
          // Meal tracker
          BlocProvider<CalorieTrackerBloc>(
            create: (ctx) => CalorieTrackerBloc(
              repository:     ctx.read<MealRepository>(),
              authRepository: ctx.read<AuthRepository>(),
            ),
          ),
          // Food Search
          BlocProvider<FoodSearchBloc>(
            create: (ctx) => FoodSearchBloc(
              repository: ctx.read<TrackerRepository>(),
            ),
          ),
          // Water tracking
          BlocProvider<WaterBloc>(
            create: (ctx) => WaterBloc(
              repository: ctx.read<TrackerRepository>(),
            ),
          ),
          // Weight tracking
          BlocProvider<WeightBloc>(
            create: (ctx) => WeightBloc(
              repository: ctx.read<TrackerRepository>(),
            ),
          ),
          // Meal plans
          BlocProvider<MealPlanBloc>(
            create: (ctx) => MealPlanBloc(
              repository: ctx.read<TrackerRepository>(),
            ),
          ),
          // Workout Tracker
          BlocProvider<WorkoutBloc>(
            create: (ctx) => WorkoutBloc(
              ctx.read<WorkoutRepository>(),
            ),
          ),
          // Nutrition Progress
          BlocProvider<NutritionProgressBloc>(
            create: (ctx) => NutritionProgressBloc(
              ctx.read<TrackerRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title:                   'Aura',
              debugShowCheckedModeBanner: false,
              theme:                   AppTheme.lightTheme,
              darkTheme:               AppTheme.darkTheme,
              themeMode:               themeMode,

              // ── Localization ────────────────────────────
              locale:                  const Locale('en'),
              supportedLocales: const [
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // ── Global Compact Scaling & LTR ───────────
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: const TextScaler.linear(0.82),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: child!,
                  ),
                );
              },

              // ── Routes ──────────────────────────────────
              initialRoute: '/',
              routes: {
                '/':        (_) => const AuthWrapper(),
                '/login':   (_) => const LoginScreen(),
                '/history': (_) => const HistoryScreen(),
                '/settings': (_) => const SettingsScreen(),
                '/foods/search': (_) => const FoodSearchScreen(),
                '/weight/progress': (_) => const WeightProgressScreen(),
                '/water/progress': (_) => const WaterTrackingScreen(),
                '/meals/ai-suggestion': (_) => const AiSuggestionScreen(),
                '/nutrition/progress': (_) => const ProgressSummaryScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Auth Wrapper ──────────────────────────────────────────────

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  ProfileLoaded? _lastProfileLoaded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        _loadAllUserData(context);
      }
    });
  }

  void _loadAllUserData(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(LoadProfile());
      context.read<DashboardBloc>().add(const LoadDashboard());
      context.read<CalorieTrackerBloc>().add(const FetchMealHistory(page: 1));
      context.read<WaterBloc>().add(const LoadWaterToday());
      context.read<WeightBloc>().add(const LoadWeightHistory(days: 30));
      context.read<MealPlanBloc>().add(LoadWeeklyMealPlan());
      context.read<FoodSearchBloc>().add(LoadFoodCategories());
    }
  }

  Widget _buildPreScreenView() {
    return const _PreScreenView();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is Authenticated) {
          _loadAllUserData(context);
        } else if (authState is Unauthenticated) {
          _lastProfileLoaded = null;
          context.read<ProfileBloc>().add(ResetProfileEvent());
          context.read<DashboardBloc>().add(const ResetDashboardEvent());
          context.read<CalorieTrackerBloc>().add(const ResetCalorieTracker());
          context.read<FoodSearchBloc>().add(const ResetFoodSearchEvent());
          context.read<WaterBloc>().add(const ResetWaterEvent());
          context.read<WeightBloc>().add(const ResetWeightEvent());
          context.read<MealPlanBloc>().add(const ResetMealPlanEvent());
          context.read<WorkoutBloc>().add(const ResetWorkoutEvent());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            final profileState = context.watch<ProfileBloc>().state;
            if (profileState is ProfileInitial) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _loadAllUserData(context);
              });
            }
            return BlocListener<ProfileBloc, ProfileState>(
              listener: (context, profileState) {
                if (profileState is ProfileLoaded) {
                  _lastProfileLoaded = profileState;
                  if (profileState.isOnboardingCompleted) {
                    context.read<DashboardBloc>().add(const LoadDashboard());
                  }
                }
                if (profileState is ProfileFailure &&
                    (profileState.message.contains("Authentication required") ||
                     profileState.message.contains("Unauthorized") ||
                     profileState.message.contains("token") ||
                     profileState.message.contains("Session expired"))) {
                  context.read<AuthBloc>().add(LogoutRequested());
                }
              },
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  if (profileState is ProfileLoaded) {
                    _lastProfileLoaded = profileState;
                  }

                  if (_lastProfileLoaded != null) {
                    if (_lastProfileLoaded!.isOnboardingCompleted) {
                      return const HomeShellScreen();
                    } else {
                      return const OnboardingScreen();
                    }
                  }

                  if (profileState is ProfileInitial || profileState is ProfileLoading) {
                    return _buildPreScreenView();
                  }

                  if (profileState is ProfileFailure) {
                    final msg = profileState.message.toLowerCase();
                    final isAuthErr = msg.contains("authentication required") ||
                        msg.contains("unauthorized") ||
                        msg.contains("token") ||
                        msg.contains("bearer") ||
                        msg.contains("session expired") ||
                        msg.contains("401");

                    if (isAuthErr) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          context.read<AuthBloc>().add(LogoutRequested());
                        }
                      });
                      return const LoginScreen();
                    }

                    return Scaffold(
                      backgroundColor: AppColors.background,
                      body: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                profileState.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => context.read<ProfileBloc>().add(LoadProfile()),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const OnboardingScreen();
                },
              ),
            );
          }
          if (authState is AuthInitial || authState is AuthLoading) {
            return _buildPreScreenView();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

// ── Pre-Screen Loading View ───────────────────────────────────────────────────

class _PreScreenView extends StatefulWidget {
  const _PreScreenView();

  @override
  State<_PreScreenView> createState() => _PreScreenViewState();
}

class _PreScreenViewState extends State<_PreScreenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Logo with Rotating Accent Ring (Option 2)
            SizedBox(
              width: 126,
              height: 126,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Smooth Rotating Accent Ring
                  RotationTransition(
                    turns: _ringCtrl,
                    child: Container(
                      width: 124,
                      height: 124,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFF2E7D5E),
                            Color(0xFF81C784),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Inner cutout / logo container
                  Container(
                    width: 116,
                    height: 116,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF6F8F5),
                    ),
                    child: Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF6F8F5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D5E).withOpacity(0.12),
                              blurRadius: 30,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/aura_logo.png',
                            width: 108,
                            height: 108,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'AURA',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C2B1E),
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track · Perform · Evolve',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5A6E5D),
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
