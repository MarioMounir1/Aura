// lib/features/calorie_tracker/presentation/market_screen.dart
// The Teneen — Teneen Market tab

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _activeCategoryIndex = 0;

  // Wallet points value mock
  final int _userPoints = 2450;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Zone ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'سوق التنين' : 'Teneen Market',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  _buildWalletCard(isArabic),
                ],
              ),
            ),

            // ── Category Filter Tabs (The 3 Pillars) ──────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryTab(
                    index: 0,
                    icon: Icons.opacity_rounded,
                    labelEn: 'Supplements',
                    labelAr: 'مكملات',
                    isArabic: isArabic,
                  ),
                  _buildCategoryTab(
                    index: 1,
                    icon: Icons.eco_rounded,
                    labelEn: 'Healthy Food',
                    labelAr: 'أغذية صحية',
                    isArabic: isArabic,
                  ),
                  _buildCategoryTab(
                    index: 2,
                    icon: Icons.shopping_cart_rounded,
                    labelEn: 'Supermarkets',
                    labelAr: 'سوبرماركت',
                    isArabic: isArabic,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Scrollable Body Area ──────────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90), // Spacing for custom bottom nav
                children: [
                  // Featured Partner Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeaturedBanner(isArabic),
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _getCategorySectionTitle(isArabic),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildProductGrid(isArabic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wallet / Points Widget ─────────────────────────────────────────
  Widget _buildWalletCard(bool isArabic) {
    final pointsText = isArabic ? '$_userPoints نقطة' : '$_userPoints Points';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            pointsText,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Pill Tab Builder ─────────────────────────────────────
  Widget _buildCategoryTab({
    required int index,
    required IconData icon,
    required String labelEn,
    required String labelAr,
    required bool isArabic,
  }) {
    final isSelected = _activeCategoryIndex == index;
    final label = isArabic ? labelAr : labelEn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => setState(() => _activeCategoryIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Featured Partner Banner ───────────────────────────────────────
  Widget _buildFeaturedBanner(bool isArabic) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF0369A1),
            Color(0xFF0F172A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Graphic abstract circle elements
          Positioned(
            right: isArabic ? null : -20,
            left: isArabic ? -20 : null,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: isArabic ? null : 30,
            left: isArabic ? 30 : null,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Content Layout
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isArabic ? 'عرض حصري' : 'SPONSORED DEAL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Headline
                Text(
                  'Mach Supplements',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),

                // Subtitle / Offer details
                Expanded(
                  child: Text(
                    isArabic
                        ? 'خصم ١٥٪ + شيكر مجاني مع كل طلب'
                        : 'Exclusive Deal: 15% OFF + Free Shaker',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Get section title based on category ────────────────────
  String _getCategorySectionTitle(bool isArabic) {
    switch (_activeCategoryIndex) {
      case 0:
        return isArabic ? 'مكملات مميزة' : 'Featured Supplements';
      case 1:
        return isArabic ? 'أغذية صحية مميزة' : 'Featured Healthy Food';
      case 2:
        return isArabic ? 'سوبرماركت معتمد' : 'Verified Supermarkets';
      default:
        return '';
    }
  }

  // ── Product Grid Builder ───────────────────────────────────────────
  Widget _buildProductGrid(bool isArabic) {
    final List<Map<String, dynamic>> products = _getProductsForCategory(_activeCategoryIndex, isArabic);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.69,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, isArabic);
      },
    );
  }

  // ── Single Product Card Builder ─────────────────────────────────────
  Widget _buildProductCard(Map<String, dynamic> product, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock Image Area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceVariant,
                    AppColors.surface,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  product['imageIcon'] as IconData,
                  color: AppColors.primary.withValues(alpha: 0.45),
                  size: 44,
                ),
              ),
            ),
          ),

          // Details Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Price
                Text(
                  product['price'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),

                // Point Earnings (Glowing Accent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary, // glowing teal dot
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isArabic
                            ? 'اكسب ${product['points']} ن'
                            : 'Earn +${product['points']} Pts',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mock Database for Products ─────────────────────────────────────
  List<Map<String, dynamic>> _getProductsForCategory(int categoryIndex, bool isArabic) {
    if (categoryIndex == 0) {
      // Supplements
      return [
        {
          'name': isArabic ? 'ماك بروتين بار (شوكولاتة بندق)' : 'Mach Protein Bar (Choco-Almond)',
          'price': isArabic ? '٦٠ ج.م' : 'EGP 60',
          'points': 30,
          'imageIcon': Icons.breakfast_dining_rounded,
        },
        {
          'name': isArabic ? 'كرياتين نقي (٣٠٠ جرام)' : 'Pure Creatine (300g)',
          'price': isArabic ? '٧٥٠ ج.م' : 'EGP 750',
          'points': 150,
          'imageIcon': Icons.fitness_center_rounded,
        },
      ];
    } else if (categoryIndex == 1) {
      // Healthy Food
      return [
        {
          'name': isArabic ? 'زبدة فول سوداني عضوية' : 'Organic Peanut Butter',
          'price': isArabic ? '١٢٠ ج.م' : 'EGP 120',
          'points': 40,
          'imageIcon': Icons.cookie_rounded,
        },
        {
          'name': isArabic ? 'علبة سلطة كينوا' : 'Quinoa Salad Box',
          'price': isArabic ? '٨٥ ج.م' : 'EGP 85',
          'points': 25,
          'imageIcon': Icons.restaurant_rounded,
        },
      ];
    } else {
      // Supermarkets
      return [
        {
          'name': isArabic ? 'حليب شوفان ١ لتر' : 'Oat Milk 1L',
          'price': isArabic ? '٩٥ ج.م' : 'EGP 95',
          'points': 30,
          'imageIcon': Icons.local_drink_rounded,
        },
        {
          'name': isArabic ? 'زبادي يوناني (٤ قطع)' : 'Greek Yogurt (Pack of 4)',
          'price': isArabic ? '٨٠ ج.م' : 'EGP 80',
          'points': 20,
          'imageIcon': Icons.layers_rounded,
        },
      ];
    }
  }
}
