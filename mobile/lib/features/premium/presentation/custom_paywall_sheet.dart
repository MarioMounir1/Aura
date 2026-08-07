// lib/features/premium/presentation/custom_paywall_sheet.dart

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/bloc/profile_event.dart';
import '../data/services/purchase_service.dart';

class CustomPaywallSheet extends StatefulWidget {
  const CustomPaywallSheet({super.key});

  @override
  State<CustomPaywallSheet> createState() => _CustomPaywallSheetState();
}

class _CustomPaywallSheetState extends State<CustomPaywallSheet> {
  Offerings? _offerings;
  bool _loadingOfferings = true;
  String? _offeringsError;
  bool _isUpgrading = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await PurchaseService.instance.fetchOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _loadingOfferings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offeringsError = e.toString();
          _loadingOfferings = false;
        });
      }
    }
  }

  Future<void> _handleSubscribe(Package? package) async {
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active RevenueCat offering package loaded. Please verify your RevenueCat Public API Key & Offerings in RevenueCat dashboard.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isUpgrading = true);
    try {
      final bool success = await PurchaseService.instance.purchasePackage(package);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase was cancelled or payment failed. Account remains free tier.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final dio = ApiClient().dio;
      final response = await dio.post('/users/subscribe');
      
      final data = response.data;
      final bool isBackendSuccess = response.statusCode == 200 || 
                                    response.statusCode == 201 ||
                                    (data != null && data['success'] == true);

      if (isBackendSuccess) {
        PurchaseService.instance.setMockPremiumStatus(true);
        if (mounted) {
          context.read<ProfileBloc>().add(const UpdatePremiumStatus(true));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Aura Premium!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Backend failed to confirm premium subscription.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpgrading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = _offerings?.current?.monthly;
    final mediaQuery = MediaQuery.of(context);
    final displayPrice = package?.storeProduct.priceString ?? '\$1.00';

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Top Drag Handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3E4D7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // Close Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF5A6E5D), size: 24),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Premium Icon Badge
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEAF5EE),
                        border: Border.all(
                          color: const Color(0xFF235A42),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x15235A42),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 42,
                          color: Color(0xFF235A42),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Unlock Aura Premium',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1C2B1E),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get unlimited AI nutrition analysis, progressive workout tracking & an ad-free experience.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF5A6E5D),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Features Section
                    _buildFeatureItem(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF235A42),
                      title: 'Smart AI Meal Scanner',
                      subtitle: 'Offline, private and instant meal analysis.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.fitness_center_rounded,
                      iconColor: const Color(0xFF235A42),
                      title: 'Pro Workout Tracker',
                      subtitle: 'Live session tracking with progressive overload analytics.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.repeat_rounded,
                      iconColor: const Color(0xFF235A42),
                      title: 'Unlimited Training Splits',
                      subtitle: 'Custom routine builder with zero caps.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.block_rounded,
                      iconColor: const Color(0xFF235A42),
                      title: '100% Ad-Free Experience',
                      subtitle: 'Focus entirely on your health without interruptions.',
                    ),
                    const SizedBox(height: 24),
                    // Pricing Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5EE),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF235A42),
                          width: 1.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF235A42),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Membership',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1C2B1E),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cancel anytime, no commitment',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF5A6E5D),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                displayPrice,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1C2B1E),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                '/month',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF5A6E5D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Subscribe Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _loadingOfferings
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF235A42),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isUpgrading
                                  ? null
                                  : () => _handleSubscribe(package),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF235A42),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isUpgrading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Unlock Aura Premium — $displayPrice/mo',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Auto-renews monthly. Manage or cancel anytime.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7A8B7B),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF235A42), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1C2B1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5A6E5D),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
