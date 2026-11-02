// lib/core/widgets/ad_banner.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../features/premium/data/services/purchase_service.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_state.dart';

/// Manages preloading and showing full-screen Google AdMob Interstitial Ads
/// when a Free Tier user reaches their daily scan/usage limit, with built-in
/// frequency capping so Free Tier users never experience ad fatigue.
class AdMobInterstitialHelper {
  AdMobInterstitialHelper._();

  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;

  // Anti-fatigue frequency cap: max 1 interstitial every 15 minutes, max 2 per day
  static const Duration minCooldown = Duration(minutes: 15);
  static const int maxAdsPerDay = 2;

  static DateTime? _lastShownAt;
  static String? _shownDateKey;
  static int _shownCountToday = 0;

  // Live Google AdMob Interstitial Unit IDs (with env var overrides)
  static const _envAndroidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-9359621894968645/7239494985',
  );
  static const _envIosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-9359621894968645/7239494985',
  );

  static String get _adUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _envAndroidInterstitialId : _envIosInterstitialId;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Checks whether showing a full-screen interstitial ad right now is allowed
  /// under the anti-fatigue cooldown (15 min) and daily cap (2/day).
  static bool get canShowAdNow {
    final today = _todayKey();
    if (_shownDateKey != today) {
      _shownDateKey = today;
      _shownCountToday = 0;
    }
    if (_shownCountToday >= maxAdsPerDay) {
      return false;
    }
    if (_lastShownAt != null &&
        DateTime.now().difference(_lastShownAt!) < minCooldown) {
      return false;
    }
    return true;
  }

  static void _recordAdShown() {
    final today = _todayKey();
    if (_shownDateKey != today) {
      _shownDateKey = today;
      _shownCountToday = 0;
    }
    _shownCountToday++;
    _lastShownAt = DateTime.now();
  }

  /// Preload an interstitial ad in the background so it displays instantly on limit reached.
  static void preload() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (!canShowAdNow) return;
    if (_interstitialAd != null || _isLoading) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _interstitialAd = ad;
          debugPrint('✅ AdMob Interstitial Ad preloaded and ready.');
        },
        onAdFailedToLoad: (err) {
          _isLoading = false;
          _interstitialAd = null;
          debugPrint('⚠️ AdMob Interstitial failed to preload: ${err.message}');
        },
      ),
    );
  }

  /// Shows a full-screen Google Interstitial Ad when a Free Tier user exceeds their limit,
  /// respecting the 15-minute cooldown and 2/day cap so the user is never spammed.
  static Future<void> showOnLimitExceeded({VoidCallback? onCompleted}) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      onCompleted?.call();
      return;
    }

    if (!canShowAdNow) {
      debugPrint(
        'ℹ️ Skipping AdMob Interstitial (cooldown or 2/day cap active to prevent ad fatigue).',
      );
      onCompleted?.call();
      return;
    }

    final ad = _interstitialAd;
    if (ad != null) {
      _interstitialAd = null;
      _recordAdShown();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          preload();
          onCompleted?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('⚠️ AdMob Interstitial failed to show: ${err.message}');
          ad.dispose();
          preload();
          onCompleted?.call();
        },
      );
      await ad.show();
      return;
    }

    // If not yet preloaded, attempt an immediate load-and-show
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (loadedAd) {
          _recordAdShown();
          loadedAd.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              preload();
              onCompleted?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              preload();
              onCompleted?.call();
            },
          );
          loadedAd.show();
        },
        onAdFailedToLoad: (err) {
          debugPrint('⚠️ AdMob Interstitial on-demand load failed: ${err.message}');
          onCompleted?.call();
        },
      ),
    );
  }
}

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  static const _envAndroidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: 'ca-app-pub-9359621894968645/1734393571',
  );
  static const _envIosBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: 'ca-app-pub-9359621894968645/1734393571',
  );

  static String get _adUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _envAndroidBannerId : _envIosBannerId;
  }

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    AdMobInterstitialHelper.preload();
  }

  void _loadBannerAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('⚠️ AdMob Banner failed to load: ${err.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        bool isPremium = false;
        if (state is ProfileLoaded) {
          isPremium = state.isPremium;
        }

        // Hide ads completely for Premium members
        if (isPremium) {
          return const SizedBox.shrink();
        }

        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        // Render Google AdMob Banner when loaded
        if (_isAdLoaded && _bannerAd != null) {
          return Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: AdWidget(ad: _bannerAd!),
          );
        }

        // House Ad fallback while loading or if offline
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6F4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EBE4), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A8B7B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isArabic ? 'إعلان' : 'AD',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A6E5D),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic
                          ? 'أورا بريميوم — بدون إعلانات وبذكاء اصطناعي غير محدود'
                          : 'Aura Premium — 100% Ad-Free & Unlimited AI',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C2B1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'إزالة الإعلانات وفتح المسح الذكي غير المحدود. اضغط للترقية ←'
                          : 'Remove ads & unlock unlimited AI scans. Tap to upgrade →',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF5A6E5D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => PurchaseService.instance.presentPaywall(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF235A42),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isArabic ? 'ترقية' : 'Upgrade',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
