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
    setState(() => _isUpgrading = true);
    try {
      bool success = false;
      if (package != null) {
        success = await PurchaseService.instance.purchasePackage(package);
      } else if (PurchaseService.isTestMode) {
        debugPrint('ℹ️ Simulating 1-second purchase in Test Mode...');
        await Future.delayed(const Duration(seconds: 1));
        success = true;
      } else {
        throw Exception('Subscription package is unavailable. Please try again later.');
      }

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
                backgroundColor: Color(0xFF4CAF50),
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
              content: Text('Subscription purchase was not completed.'),
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF090C15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag Indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // Header Row with Close Button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Premium Icon/Badge
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFBBF24).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 56,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Unlock Aura Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get the ultimate Smart nutrition and fitness experience for just \$1/month.',
                      style: TextStyle(
                        color: Color(0xFF8E929C),
                        fontSize: 15,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Features List
                    _buildFeatureRow(
                      icon: Icons.auto_awesome,
                      title: 'Smart Meal Scanner',
                      subtitle: '100% Offline & Private.',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureRow(
                      icon: Icons.fitness_center_rounded,
                      title: 'Advanced Set Tracker & Progressive Overload',
                      subtitle: 'Live session tracking & analytics.',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureRow(
                      icon: Icons.repeat_rounded,
                      title: 'Unlimited Custom Training Splits',
                      subtitle: 'Design and customize your routines.',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureRow(
                      icon: Icons.block_rounded,
                      title: '100% Ad-Free Experience',
                      subtitle: 'Focus entirely on your goals without distractions.',
                    ),
                    const SizedBox(height: 28),
                    // Pricing Option Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121824).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFBBF24).withOpacity(0.3),
                          width: 1.5,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B2232).withOpacity(0.6),
                            const Color(0xFF121824).withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFFBBF24),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Premium Access',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cancel anytime, no commitment.',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF8E929C),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                '/mo',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF8E929C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Purchase Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _loadingOfferings
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFBBF24),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isUpgrading
                                  ? null
                                  : () => _handleSubscribe(package),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFBBF24),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isUpgrading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : const Text(
                                      'Subscribe Now — \$1/mo',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cancel anytime. Subscription auto-renews monthly.',
                      style: TextStyle(
                        color: Color(0xFF5D616B),
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

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF222B3F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF00BCD4), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8E929C),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
