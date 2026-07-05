// lib/main.dart
// The Teneen — App Entry Point
// Supports: AR/EN localization, RTL, dark theme

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/constants.dart';
import 'features/calorie_tracker/data/models/meal_log_model.dart';
import 'features/calorie_tracker/data/repositories/meal_repository_impl.dart';
import 'features/calorie_tracker/domain/repositories/meal_repository.dart';
import 'features/calorie_tracker/presentation/analyze_meal_screen.dart';
import 'features/calorie_tracker/presentation/bloc/calorie_tracker_bloc.dart';
import 'features/calorie_tracker/presentation/history_screen.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

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

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure status bar for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:                   Colors.transparent,
      statusBarIconBrightness:          Brightness.light,
      systemNavigationBarColor:         Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(IngredientBreakdownModelAdapter());
  Hive.registerAdapter(MealLogModelAdapter());
  await Hive.openBox<MealLogModel>(AppConstants.mealLogsBox);

  // Load saved language preference
  final savedLang = await LanguageCubit.getSavedLanguage();

  runApp(TeneenApp(initialLang: savedLang));
}

// ── Root App Widget ───────────────────────────────────────────

class TeneenApp extends StatelessWidget {
  final String initialLang;
  const TeneenApp({super.key, required this.initialLang});

  @override
  Widget build(BuildContext context) {
    final apiClient       = ApiClient(secureStorage: const FlutterSecureStorage());
    final MealRepository  mealRepository = MealRepositoryImpl(apiClient);
    final AuthRepository  authRepository = AuthRepositoryImpl(apiClient);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MealRepository>.value(value: mealRepository),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // Language switching
          BlocProvider<LanguageCubit>(
            create: (_) => LanguageCubit(initialLang),
          ),
          // Auth
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<AuthRepository>(),
            )..add(AppStarted()),
          ),
          // Meal tracker
          BlocProvider<CalorieTrackerBloc>(
            create: (ctx) => CalorieTrackerBloc(
              repository:     ctx.read<MealRepository>(),
              authRepository: ctx.read<AuthRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            // RTL for Arabic, LTR for English
            final isArabic = locale.languageCode == 'ar';

            return MaterialApp(
              title:                   'The Teneen | التنين',
              debugShowCheckedModeBanner: false,
              theme:                   AppTheme.darkTheme,

              // ── Localization ────────────────────────────
              locale:                  locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // ── RTL / LTR ───────────────────────────────
              builder: (context, child) {
                return Directionality(
                  textDirection: isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: child!,
                );
              },

              // ── Routes ──────────────────────────────────
              initialRoute: '/',
              routes: {
                '/':        (_) => const AuthWrapper(),
                '/login':   (_) => const LoginScreen(),
                '/history': (_) => const HistoryScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Auth Wrapper ──────────────────────────────────────────────

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const AnalyzeMealScreen();
        }
        if (state is Unauthenticated || state is AuthFailure) {
          return const LoginScreen();
        }
        // Splash / loading state
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      },
    );
  }
}

