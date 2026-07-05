// test/calorie_tracker/bloc/calorie_tracker_bloc_test.dart
// Calc-Calories — BLoC Unit Tests

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calc_calories/core/error/failures.dart';
import 'package:calc_calories/features/calorie_tracker/domain/entities/meal_log_entity.dart';
import 'package:calc_calories/features/calorie_tracker/domain/repositories/meal_repository.dart';
import 'package:calc_calories/features/calorie_tracker/presentation/bloc/calorie_tracker_bloc.dart';
import 'package:calc_calories/features/calorie_tracker/presentation/bloc/calorie_tracker_event.dart';
import 'package:calc_calories/features/calorie_tracker/presentation/bloc/calorie_tracker_state.dart';

// ── Mock ──────────────────────────────────────────────────

class MockMealRepository extends Mock implements MealRepository {}

// ── Test Data ─────────────────────────────────────────────

final tMealLog = MealLogEntity(
  id: 'test-id-1',
  restaurantName: 'Buffalo Burger',
  mealName: 'Single Bacon Mushroom Jack',
  calories: 650,
  protein: 42,
  carbs: 48,
  fats: 28,
  ingredientsBreakdown: const [
    IngredientBreakdown(
      ingredient: 'Beef Patty',
      estimatedWeightGrams: 113,
    ),
  ],
  source: 'text',
  createdAt: DateTime(2025, 7, 5, 12, 0),
);

// ── Tests ──────────────────────────────────────────────────

void main() {
  late CalorieTrackerBloc bloc;
  late MockMealRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(tMealLog);
  });

  setUp(() {
    mockRepository = MockMealRepository();
    bloc = CalorieTrackerBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  group('Initial State', () {
    test('is CalorieTrackerInitial', () {
      expect(bloc.state, const CalorieTrackerInitial());
    });
  });

  group('AnalyzeTextMealSubmitted', () {
    blocTest<CalorieTrackerBloc, CalorieTrackerState>(
      'emits [Analyzing, AnalysisSuccess] on success',
      build: () {
        when(() => mockRepository.analyzeTextMeal(
              restaurantName: any(named: 'restaurantName'),
              mealDescription: any(named: 'mealDescription'),
            )).thenAnswer((_) async => Right(tMealLog));
        return bloc;
      },
      act: (b) => b.add(const AnalyzeTextMealSubmitted(
        restaurantName: 'Buffalo Burger',
        mealDescription: 'Single Bacon Mushroom Jack',
      )),
      expect: () => [
        const CalorieTrackerAnalyzing(isImageMode: false),
        CalorieTrackerAnalysisSuccess(mealLog: tMealLog, source: 'ai'),
      ],
    );

    blocTest<CalorieTrackerBloc, CalorieTrackerState>(
      'emits [Analyzing, Failure] on server error',
      build: () {
        when(() => mockRepository.analyzeTextMeal(
              restaurantName: any(named: 'restaurantName'),
              mealDescription: any(named: 'mealDescription'),
            )).thenAnswer((_) async => const Left(
              ServerFailure(message: 'AI analysis failed', code: 'AI_ERROR'),
            ));
        return bloc;
      },
      act: (b) => b.add(const AnalyzeTextMealSubmitted(
        restaurantName: 'Test',
        mealDescription: 'Test Meal',
      )),
      expect: () => [
        const CalorieTrackerAnalyzing(isImageMode: false),
        const CalorieTrackerFailure(
          message: 'AI analysis failed',
          code: 'AI_ERROR',
        ),
      ],
    );

    blocTest<CalorieTrackerBloc, CalorieTrackerState>(
      'emits [Analyzing, Failure with isRateLimit=true] on rate limit',
      build: () {
        when(() => mockRepository.analyzeTextMeal(
              restaurantName: any(named: 'restaurantName'),
              mealDescription: any(named: 'mealDescription'),
            )).thenAnswer((_) async => const Left(
              RateLimitFailure(retryAfterSeconds: 30),
            ));
        return bloc;
      },
      act: (b) => b.add(const AnalyzeTextMealSubmitted(
        restaurantName: 'Test',
        mealDescription: 'Test Meal',
      )),
      expect: () => [
        const CalorieTrackerAnalyzing(isImageMode: false),
        const CalorieTrackerFailure(
          message: 'Too many requests. Please wait before trying again.',
          code: 'RATE_LIMIT_EXCEEDED',
          isRateLimit: true,
          retryAfterSeconds: 30,
        ),
      ],
    );
  });

  group('ImageSelected', () {
    blocTest<CalorieTrackerBloc, CalorieTrackerState>(
      'emits [Analyzing(image=true), AnalysisSuccess] on success',
      build: () {
        when(() => mockRepository.analyzeImageMeal(
              imagePath: any(named: 'imagePath'),
              restaurantName: any(named: 'restaurantName'),
            )).thenAnswer((_) async => Right(tMealLog));
        return bloc;
      },
      act: (b) => b.add(const ImageSelected(
        imagePath: '/path/to/screenshot.jpg',
        restaurantName: 'Buffalo Burger',
      )),
      expect: () => [
        const CalorieTrackerAnalyzing(isImageMode: true),
        CalorieTrackerAnalysisSuccess(mealLog: tMealLog, source: 'ai'),
      ],
    );
  });

  group('FetchMealHistory', () {
    blocTest<CalorieTrackerBloc, CalorieTrackerState>(
      'emits [HistoryLoading, HistoryLoaded] on success',
      build: () {
        when(() => mockRepository.getMealHistory(
              page: any(named: 'page'),
              date: any(named: 'date'),
            )).thenAnswer((_) async => Right([tMealLog]));
        return bloc;
      },
      act: (b) => b.add(const FetchMealHistory()),
      expect: () => [
        const CalorieTrackerHistoryLoading(),
        CalorieTrackerHistoryLoaded(
          logs: [tMealLog],
          currentPage: 1,
          totalPages: 1,
          hasMore: false,
          isOffline: false,
        ),
      ],
    );

    blocTest<CalorieTrackerBloc, CalorieTrackerState>(
      'falls back to cache on network failure',
      build: () {
        when(() => mockRepository.getMealHistory(
              page: any(named: 'page'),
              date: any(named: 'date'),
            )).thenAnswer((_) async => const Left(NetworkFailure()));
        when(() => mockRepository.getCachedMealLogs())
            .thenAnswer((_) async => Right([tMealLog]));
        return bloc;
      },
      act: (b) => b.add(const FetchMealHistory()),
      expect: () => [
        const CalorieTrackerHistoryLoading(),
        CalorieTrackerHistoryLoaded(
          logs: [tMealLog],
          currentPage: 1,
          totalPages: 1,
          hasMore: false,
          isOffline: true,
        ),
      ],
    );
  });

  group('ResetCalorieTracker', () {
    blocTest<CalorieTrackerBloc, CalorieTrackerState>(
      'emits [Initial] from any state',
      build: () => bloc,
      seed: () => CalorieTrackerAnalysisSuccess(
        mealLog: tMealLog,
        source: 'ai',
      ),
      act: (b) => b.add(const ResetCalorieTracker()),
      expect: () => [const CalorieTrackerInitial()],
    );
  });
}
