// lib/core/widgets/ad_banner.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../features/premium/data/services/purchase_service.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_state.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Official Google AdMob Test Banner Unit IDs
  static final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
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
          isPremium = state.user['isPremium'] == true;
        }

        // If user is Premium, hide ads completely
        if (isPremium) {
          return const SizedBox.shrink();
        }

        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        // Render Google AdMob Banner if loaded
        if (_isAdLoaded && _bannerAd != null) {
          return Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: AdWidget(ad: _bannerAd!),
          );
        }

        // House Ad / Native Ad Banner Fallback
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                  color: const Color(0xFF7A8B7B).withOpacity(0.2),
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
                          ? 'أورا بريميوم — بدون إعلانات وبذكاء اصطناعي'
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
                          ? 'إزالة الإعلانات وفتح 10 مسحات يومياً. اضغط للتغيير →'
                          : 'Remove ads & unlock 10 AI scans daily. Tap to upgrade →',
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
