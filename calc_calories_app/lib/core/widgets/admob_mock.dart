// lib/core/widgets/admob_mock.dart
// Mock implementation of google_mobile_ads to support offline compilation and emulator testing.

import 'package:flutter/material.dart';

class MobileAds {
  static final instance = MobileAds._();
  MobileAds._();
  Future<void> initialize() async {}
}

class AdRequest {
  const AdRequest();
}

class AdSize {
  final int width;
  final int height;
  const AdSize({required this.width, required this.height});
  static const banner = AdSize(width: 320, height: 50);
}

class LoadAdError {
  final String message;
  const LoadAdError(this.message);
}

class BannerAdListener {
  final Function(Ad ad)? onAdLoaded;
  final Function(Ad ad, LoadAdError error)? onAdFailedToLoad;

  const BannerAdListener({
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });
}

abstract class Ad {
  void dispose();
}

class BannerAd extends Ad {
  final String adUnitId;
  final AdSize size;
  final AdRequest request;
  final BannerAdListener listener;

  BannerAd({
    required this.adUnitId,
    required this.size,
    required this.request,
    required this.listener,
  });

  void load() {
    // Simulate async ad load in development
    Future.delayed(const Duration(milliseconds: 200), () {
      if (listener.onAdLoaded != null) {
        listener.onAdLoaded!(this);
      }
    });
  }

  @override
  void dispose() {}
}

class AdWidget extends StatelessWidget {
  final BannerAd ad;

  const AdWidget({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      color: const Color(0xFF2C2C2C),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Google AdMob Test Banner (Offline Mode)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
