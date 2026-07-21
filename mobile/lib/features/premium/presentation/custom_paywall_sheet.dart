// lib/features/premium/presentation/custom_paywall_sheet.dart

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
          content: Text('No active RevenueCat subscription package loaded. Please check offerings setup.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUpgrading = true);
    try {
      final bool success = await PurchaseService.instance.purchasePackage(package);

      if (success) {
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
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Backend failed to confirm premium subscription.');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase was not completed or entitlement is not active.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFF44336),
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
        color: Color(0xFF0F172A), // Dark slate theme
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            // Top Drag Pill
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 6),
            // Close Button Bar
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Premium Glowing Crown Badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.25),
                            const Color(0xFF10B981).withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 44,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unlock Aura Premium',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get full access to smart nutrition AI, progressive analytics & ad-free workouts.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // Glass Feature List
                    _buildFeatureCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF10B981), // Emerald
                      title: 'Smart AI Meal Scanner',
                      subtitle: 'Offline, instant & 100% private meal logging.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'Pro Workout Tracker',
                      iconColor: const Color(0xFF06B6D4), // Cyan
                      subtitle: 'Live session analytics & progressive overload.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.repeat_rounded,
                      title: 'Unlimited Custom Splits',
                      iconColor: const Color(0xFF8B5CF6), // Purple
                      subtitle: 'Design tailored workout routines with zero caps.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.block_rounded,
                      title: '100% Ad-Free Experience',
                      iconColor: const Color(0xFFF59E0B), // Amber
                      subtitle: 'No banners, popups or interruptions.',
                    ),
                    const SizedBox(height: 24),
                    // Price Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Membership',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cancel anytime in store settings',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF94A3B8),
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
                                '\$1.00',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                '/month',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
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
                    // Action Subscribe Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _loadingOfferings
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF10B981),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.35),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isUpgrading
                                    ? null
                                    : () => _handleSubscribe(package),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isUpgrading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Join Premium — \$1.00/mo',
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Auto-renews monthly. Manage or cancel anytime.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
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
