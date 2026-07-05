// test/calorie_tracker/bloc/calorie_tracker_bloc_test.dart
// Calc-Calories — BLoC Unit Tests

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calc_calories/core/error/failures.dart';
import 'package:calc_calories/features/calorie_tracker/domain/entities/meal_log_entity.dart';
import 'package:calc_calories/features/calorie_tracker/domain/repositories/meal_repository.dart';
import 'package:calc_calories/features/calorie_tracker/presentation/bloc/calorie_tracker_bloc.dart';
import 'package:calc_calories/features/calorie_tracker/presentation/bloc/calorie_tracker_event.dart';
import 'package:calc_calories/features/calorie_tracker/presentation/bloc/calorie_tracker_state.dart';

class MockMealRepository extends Mock implements MealRepository {}

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
    test('emits [Analyzing, AnalysisSuccess] on success', () async {
      when(() => mockRepository.analyzeTextMeal(
            restaurantName: any(named: 'restaurantName'),
            mealDescription: any(named: 'mealDescription'),
          )).thenAnswer((_) async => Right(tMealLog));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const CalorieTrackerAnalyzing(isImageMode: false),
          CalorieTrackerAnalysisSuccess(mealLog: tMealLog, source: 'ai'),
        ]),
      );

      bloc.add(const AnalyzeTextMealSubmitted(
        restaurantName: 'Buffalo Burger',
        mealDescription: 'Single Bacon Mushroom Jack',
      ));

      await expectation;
    });

    test('emits [Analyzing, Failure] on server error', () async {
      when(() => mockRepository.analyzeTextMeal(
            restaurantName: any(named: 'restaurantName'),
            mealDescription: any(named: 'mealDescription'),
          )).thenAnswer((_) async => const Left(
            ServerFailure(message: 'AI analysis failed', code: 'AI_ERROR'),
          ));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const CalorieTrackerAnalyzing(isImageMode: false),
          const CalorieTrackerFailure(
            message: 'AI analysis failed',
            code: 'AI_ERROR',
          ),
        ]),
      );

      bloc.add(const AnalyzeTextMealSubmitted(
        restaurantName: 'Test',
        mealDescription: 'Test Meal',
      ));

      await expectation;
    });

    test('emits [Analyzing, Failure with isRateLimit=true] on rate limit', () async {
      when(() => mockRepository.analyzeTextMeal(
            restaurantName: any(named: 'restaurantName'),
            mealDescription: any(named: 'mealDescription'),
          )).thenAnswer((_) async => const Left(
            RateLimitFailure(retryAfterSeconds: 30),
          ));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const CalorieTrackerAnalyzing(isImageMode: false),
          const CalorieTrackerFailure(
            message: 'Too many requests. Please wait before trying again.',
            code: 'RATE_LIMIT_EXCEEDED',
            isRateLimit: true,
            retryAfterSeconds: 30,
          ),
        ]),
      );

      bloc.add(const AnalyzeTextMealSubmitted(
        restaurantName: 'Test',
        mealDescription: 'Test Meal',
      ));

      await expectation;
    });
  });

  group('ImageSelected', () {
    test('emits [Analyzing(image=true), AnalysisSuccess] on success', () async {
      when(() => mockRepository.analyzeImageMeal(
            imagePath: any(named: 'imagePath'),
            restaurantName: any(named: 'restaurantName'),
          )).thenAnswer((_) async => Right(tMealLog));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const CalorieTrackerAnalyzing(isImageMode: true),
          CalorieTrackerAnalysisSuccess(mealLog: tMealLog, source: 'ai'),
        ]),
      );

      bloc.add(const ImageSelected(
        imagePath: '/path/to/screenshot.jpg',
        restaurantName: 'Buffalo Burger',
      ));

      await expectation;
    });
  });

  group('FetchMealHistory', () {
    test('emits [HistoryLoading, HistoryLoaded] on success', () async {
      when(() => mockRepository.getMealHistory(
            page: any(named: 'page'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => Right([tMealLog]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const CalorieTrackerHistoryLoading(),
          CalorieTrackerHistoryLoaded(
            logs: [tMealLog],
            currentPage: 1,
            totalPages: 1,
            hasMore: false,
            isOffline: false,
          ),
        ]),
      );

      bloc.add(const FetchMealHistory());

      await expectation;
    });

    test('falls back to cache on network failure', () async {
      when(() => mockRepository.getMealHistory(
            page: any(named: 'page'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => const Left(NetworkFailure()));
      when(() => mockRepository.getCachedMealLogs())
          .thenAnswer((_) async => Right([tMealLog]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const CalorieTrackerHistoryLoading(),
          CalorieTrackerHistoryLoaded(
            logs: [tMealLog],
            currentPage: 1,
            totalPages: 1,
            hasMore: false,
            isOffline: true,
          ),
        ]),
      );

      bloc.add(const FetchMealHistory());

      await expectation;
    });
  });

  group('ResetCalorieTracker', () {
    test('emits [Initial] from another state', () async {
      when(() => mockRepository.analyzeTextMeal(
            restaurantName: any(named: 'restaurantName'),
            mealDescription: any(named: 'mealDescription'),
          )).thenAnswer((_) async => Right(tMealLog));

      bloc.add(const AnalyzeTextMealSubmitted(
        restaurantName: 'Buffalo Burger',
        mealDescription: 'Single Bacon Mushroom Jack',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(isA<CalorieTrackerAnalysisSuccess>()),
      );

      final expectation = expectLater(
        bloc.stream,
        emits(const CalorieTrackerInitial()),
      );

      bloc.add(const ResetCalorieTracker());

      await expectation;
    });
  });
}
