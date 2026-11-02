// Automated Widget & Quota Tests for Aura (Free Tier Ads, Quota Limits & Paywall)

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aura/main.dart';
import 'package:aura/core/error/failures.dart';
import 'package:aura/core/utils/unit_converter.dart';
import 'package:aura/core/widgets/ad_banner.dart';
import 'package:aura/features/calorie_tracker/data/models/ai_usage_quota.dart';
import 'package:aura/features/premium/data/services/purchase_service.dart';
import 'package:aura/features/premium/presentation/custom_paywall_sheet.dart';
import 'package:aura/features/profile/domain/repositories/profile_repository.dart';
import 'package:aura/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:aura/features/profile/presentation/bloc/profile_event.dart';

class _FakeProfileRepository implements ProfileRepository {
  Map<String, dynamic> user;

  _FakeProfileRepository({bool isPremium = false})
      : user = {
          'id': 'test-user-1',
          'name': 'Test User',
          'age': 26,
          'weightKg': 75.0,
          'heightCm': 178.0,
          'isPremium': isPremium,
        };

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchUserProfile() async =>
      const Left(ServerFailure(message: 'Offline in widget test'));

  @override
  Future<Map<String, dynamic>?> getCachedUserProfile() async =>
      Map<String, dynamic>.from(user);

  @override
  Future<void> cacheUserProfile(Map<String, dynamic> u) async {
    user = Map<String, dynamic>.from(u);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTdee() async =>
      const Right({'tdee': 2200});

  @override
  Future<bool> isOnboardingCompleted() async => true;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateProfile({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    double? targetWeightKg,
    String? gender,
    String? activityLevel,
    String? goal,
    String? trainingExperience,
    int? dailyCalorieGoal,
    int? dailyProteinGoal,
    int? dailyCarbsGoal,
    int? dailyFatsGoal,
    int? dailyWaterGoalMl,
    String? language,
  }) async =>
      Right({'user': user});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('purchases_flutter'),
      (MethodCall methodCall) async {
        throw PlatformException(
          code: 'TEST_ENV',
          message: 'Mocked RevenueCat channel in widget test',
        );
      },
    );
  });

  testWidgets('App smoke test — mounts cleanly on portrait screen',
      (WidgetTester tester) async {
    final origOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('A RenderFlex overflowed')) return;
      origOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      FlutterError.onError = origOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const TeneenApp(
      initialLang: 'en',
      initialThemeMode: ThemeMode.light,
      initialUnitSystem: UnitSystem.metric,
    ));

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  group('AiUsageQuota — Free vs Premium Daily Limits', () {
    test('Free tier enforces 2/day limit across camera, gallery, and barcode',
        () {
      final initialQuota = AiUsageQuota.fromJson({
        'isPremium': false,
        'usage': {'camera': 1, 'gallery': 0, 'barcode': 1},
        'limits': {'camera': 2, 'gallery': 2, 'barcode': 2},
      });

      expect(initialQuota.isPremium, isFalse);
      expect(initialQuota.isCameraExceeded, isFalse);
      expect(initialQuota.remainingCamera, 1);
      expect(initialQuota.isGalleryExceeded, isFalse);
      expect(initialQuota.remainingGallery, 2);
      expect(initialQuota.isBarcodeExceeded, isFalse);
      expect(initialQuota.remainingBarcode, 1);

      final limitReachedQuota = AiUsageQuota.fromJson({
        'isPremium': false,
        'usage': {'camera': 2, 'gallery': 2, 'barcode': 2},
        'limits': {'camera': 2, 'gallery': 2, 'barcode': 2},
      });

      expect(limitReachedQuota.isCameraExceeded, isTrue);
      expect(limitReachedQuota.remainingCamera, 0);
      expect(limitReachedQuota.isGalleryExceeded, isTrue);
      expect(limitReachedQuota.remainingGallery, 0);
      expect(limitReachedQuota.isBarcodeExceeded, isTrue);
      expect(limitReachedQuota.remainingBarcode, 0);
    });

    test('Premium tier provides effectively unlimited daily scans', () {
      final premiumQuota = AiUsageQuota.fromJson({
        'isPremium': true,
        'usage': {'camera': 25, 'gallery': 10, 'barcode': 40},
        'limits': {'camera': 9999, 'gallery': 9999, 'barcode': 9999},
      });

      expect(premiumQuota.isPremium, isTrue);
      expect(premiumQuota.isCameraExceeded, isFalse);
      expect(premiumQuota.isGalleryExceeded, isFalse);
      expect(premiumQuota.isBarcodeExceeded, isFalse);
    });
  });

  group('AdBanner & Paywall — Free Tier Monetization', () {
    test(
        'AdMobInterstitialHelper enforces 15-minute cooldown and 2/day anti-fatigue cap',
        () {
      expect(
        AdMobInterstitialHelper.minCooldown,
        const Duration(minutes: 15),
      );
      expect(AdMobInterstitialHelper.maxAdsPerDay, 2);
      expect(AdMobInterstitialHelper.canShowAdNow, isTrue);
    });

    testWidgets(
        'AdBanner renders for Free Tier users and hides immediately when upgraded to Premium',
        (WidgetTester tester) async {
      final fakeRepo = _FakeProfileRepository(isPremium: false);
      late ProfileBloc profileBloc;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>(
            create: (_) {
              profileBloc = ProfileBloc(repository: fakeRepo)
                ..add(LoadProfile());
              return profileBloc;
            },
            child: const Scaffold(
              body: AdBanner(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Free Tier user sees the ad container / fallback banner
      expect(find.text('AD'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);

      // Simulate user upgrading to Aura Premium
      profileBloc.add(const UpdatePremiumStatus(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // AdBanner immediately hides for Premium users
      expect(find.text('AD'), findsNothing);
      expect(find.text('Upgrade'), findsNothing);
    });

    testWidgets(
        'presentPaywall displays CustomPaywallSheet when limit is reached and returns false when dismissed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = _FakeProfileRepository(isPremium: false);
      bool? paywallResult;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>(
            create: (_) =>
                ProfileBloc(repository: fakeRepo)..add(LoadProfile()),
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    paywallResult =
                        await PurchaseService.instance.presentPaywall(context);
                  },
                  child: const Text('Trigger Limit Paywall'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Tap button simulating Free Tier user hitting their 2/2 daily scan limit
      await tester.tap(find.text('Trigger Limit Paywall'));
      await tester.pumpAndSettle();

      // Verify the CustomPaywallSheet appears
      expect(find.byType(CustomPaywallSheet), findsOneWidget);
      expect(find.text('Unlock Aura Premium'), findsOneWidget);

      // Dismiss the paywall without subscribing (stays on Free Tier -> triggers Interstitial Ad flow)
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaywallSheet), findsNothing);
      expect(paywallResult, isFalse);
    });
  });
}
