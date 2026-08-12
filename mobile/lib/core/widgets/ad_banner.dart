// lib/core/widgets/ad_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/premium/data/services/purchase_service.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_state.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

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
              // Ad Tag Badge
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
              // Ad Text
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
              // Upgrade Button
              GestureDetector(
                onTap: () => PurchaseService.instance.presentPaywall(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF235A42),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isArabic ? 'إزالة' : 'Remove',
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
