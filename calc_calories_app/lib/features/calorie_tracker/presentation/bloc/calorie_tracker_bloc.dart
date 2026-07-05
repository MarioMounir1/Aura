// lib/features/calorie_tracker/presentation/bloc/calorie_tracker_bloc.dart
// Calc-Calories — BLoC (pure business logic, no UI dependencies)

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import 'calorie_tracker_event.dart';
import 'calorie_tracker_state.dart';

class CalorieTrackerBloc
    extends Bloc<CalorieTrackerEvent, CalorieTrackerState> {
  final MealRepository _repository;
  final AuthRepository _authRepository;

  CalorieTrackerBloc({
    required MealRepository repository,
    required AuthRepository authRepository,
  })  : _repository = repository,
        _authRepository = authRepository,
        super(const CalorieTrackerInitial()) {
    on<AnalyzeTextMealSubmitted>(_onAnalyzeTextMeal);
    on<ImageSelected>(_onImageSelected);
    on<FetchMealHistory>(_onFetchHistory);
    on<DeleteMealLog>(_onDeleteMealLog);
    on<ResetCalorieTracker>(_onReset);
    on<InitializeAds>(_onInitializeAds);

    _checkPremiumAndInit();
  }

  // ── Analyze Text Meal ──────────────────────────────────

  Future<void> _onAnalyzeTextMeal(
    AnalyzeTextMealSubmitted event,
    Emitter<CalorieTrackerState> emit,
  ) async {
    emit(const CalorieTrackerAnalyzing(isImageMode: false));

    final result = await _repository.analyzeTextMeal(
      restaurantName: event.restaurantName,
      mealDescription: event.mealDescription,
    );

    result.fold(
      (failure) => emit(_failureToState(failure)),
      (mealLog) => emit(
        CalorieTrackerAnalysisSuccess(mealLog: mealLog, source: 'ai'),
      ),
    );
  }

  // ── Analyze Image Meal ─────────────────────────────────

  Future<void> _onImageSelected(
    ImageSelected event,
    Emitter<CalorieTrackerState> emit,
  ) async {
    emit(const CalorieTrackerAnalyzing(isImageMode: true));

    final result = await _repository.analyzeImageMeal(
      imagePath: event.imagePath,
      restaurantName: event.restaurantName,
    );

    result.fold(
      (failure) => emit(_failureToState(failure)),
      (mealLog) => emit(
        CalorieTrackerAnalysisSuccess(mealLog: mealLog, source: 'ai'),
      ),
    );
  }

  // ── Fetch History ──────────────────────────────────────

  Future<void> _onFetchHistory(
    FetchMealHistory event,
    Emitter<CalorieTrackerState> emit,
  ) async {
    emit(const CalorieTrackerHistoryLoading());

    final result = await _repository.getMealHistory(
      page: event.page,
      date: event.dateFilter,
    );

    await result.fold(
      (failure) async {
        // If network failed, try cache
        if (failure is NetworkFailure) {
          await _loadFromCache(emit);
        } else {
          emit(_failureToState(failure));
        }
      },
      (logs) async {
        emit(
          CalorieTrackerHistoryLoaded(
            logs: logs,
            currentPage: event.page,
            totalPages: 1,
            hasMore: logs.length >= 20,
            isOffline: false,
          ),
        );
      },
    );
  }

  Future<void> _loadFromCache(Emitter<CalorieTrackerState> emit) async {
    final cached = await _repository.getCachedMealLogs();
    cached.fold(
      (failure) => emit(
        const CalorieTrackerFailure(
          message: 'No internet connection and no cached data available.',
          code: 'OFFLINE_NO_CACHE',
        ),
      ),
      (logs) => emit(
        CalorieTrackerHistoryLoaded(
          logs: logs,
          currentPage: 1,
          totalPages: 1,
          hasMore: false,
          isOffline: true,
        ),
      ),
    );
  }

  // ── Delete Meal Log ────────────────────────────────────

  Future<void> _onDeleteMealLog(
    DeleteMealLog event,
    Emitter<CalorieTrackerState> emit,
  ) async {
    final result = await _repository.deleteMealLog(event.mealLogId);

    result.fold(
      (failure) => emit(_failureToState(failure)),
      (_) => emit(CalorieTrackerDeleteSuccess(event.mealLogId)),
    );
  }

  // ── Reset ──────────────────────────────────────────────

  void _onReset(
    ResetCalorieTracker event,
    Emitter<CalorieTrackerState> emit,
  ) {
    emit(const CalorieTrackerInitial());
  }

  // ── Error Mapping ──────────────────────────────────────

  CalorieTrackerFailure _failureToState(Failure failure) {
    if (failure is RateLimitFailure) {
      return CalorieTrackerFailure(
        message: failure.message,
        code: failure.code,
        isRateLimit: true,
        retryAfterSeconds: failure.retryAfterSeconds,
      );
    }
    return CalorieTrackerFailure(
      message: failure.message,
      code: failure.code,
    );
  }

  // ── Ads Helper Methods ─────────────────────────────────

  Future<void> _checkPremiumAndInit() async {
    final isPremium = await _authRepository.isUserPremium();
    if (!isPremium) {
      add(const InitializeAds());
    }
  }

  Future<void> _onInitializeAds(
    InitializeAds event,
    Emitter<CalorieTrackerState> emit,
  ) async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Gracefully catch any AdMob initialization issues on test platforms
    }
  }
}
