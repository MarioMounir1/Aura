// lib/features/premium/presentation/premium_upgrade_screen.dart

import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/bloc/profile_event.dart';
import '../data/services/purchase_service.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Offerings? _offerings;
  bool _loadingOfferings = true;
  String? _offeringsError;
  bool _isUpgrading = false;
  bool _isAnnualSelected = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubscribe(Package? package) async {
    setState(() => _isUpgrading = true);
    try {
      bool success = false;
      if (package != null) {
        // Perform simulated / real purchase
        success = await PurchaseService.instance.purchasePackage(package);
      } else {
        // Fallback mock checkout since package is null (RevenueCat not configured yet)
        print('ℹ️ Simulating 1-second purchase in Test Mode (fallback)...');
        await Future.delayed(const Duration(seconds: 1));
        success = true;
      }

      if (success) {
        // ONLY IF purchase succeeded, send request to the backend to update isPremium: true
        final dio = ApiClient().dio;
        final response = await dio.post('/users/subscribe');
        
        final data = response.data;
        final bool isBackendSuccess = response.statusCode == 200 || 
                                      response.statusCode == 201 ||
                                      (data != null && data['success'] == true);

        if (isBackendSuccess) {
          // State & UI Sync: Update local state and stream status ONLY AFTER backend confirms
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
            Navigator.pop(context, true); // Close Paywall BottomSheet/Screen
          }
        } else {
          throw Exception('Backend failed to confirm premium subscription.');
        }
      } else {
        // IF the payment is cancelled, pending, or fails
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
      // IF the payment fails or backend fails, DO NOT change isPremium or state. Show error message.
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

    return Scaffold(
      backgroundColor: const Color(0xFF090C15), // Deep dark bg
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFBBF24).withOpacity(0.15), // Amber glow
                // ignore: prefer_const_constructors
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      
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
                          size: 64,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      const Text(
                        'Unlock Aura Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      const Text(
                        'Get 10 AI scans per day, unlimited AI Workout Coach Chat & an ad-free experience.',
                        style: TextStyle(
                          color: Color(0xFF8E929C),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 36),
                      
                      // Features List
                      _buildFeatureRow(
                        icon: Icons.auto_awesome,
                        title: '10 AI Meal Scans Daily',
                        subtitle: '10 scans/day (2/day on free tier).',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Unlimited AI Workout Coach Chat',
                        subtitle: 'Interactive AI coach & routine builder.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        icon: Icons.block_rounded,
                        title: '100% Ad-Free Experience',
                        subtitle: 'Zero banner or popup ads.',
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Pricing Options (Annual vs Monthly)
                      _buildPlanTileDark(
                        isAnnual: true,
                        isSelected: _isAnnualSelected,
                        badgeText: 'BEST VALUE — SAVE 58%',
                        title: 'Annual Pass',
                        subtitle: '\$2.08/mo · Billed \$24.99/year',
                        priceText: '\$24.99',
                        periodText: '/yr',
                        comparisonText: '🔥 69% cheaper than MyFitnessPal (\$79.99/yr)',
                        onTap: () => setState(() => _isAnnualSelected = true),
                      ),
                      const SizedBox(height: 12),
                      _buildPlanTileDark(
                        isAnnual: false,
                        isSelected: !_isAnnualSelected,
                        badgeText: null,
                        title: 'Monthly Pass',
                        subtitle: 'Flexible · Cancel anytime',
                        priceText: '\$4.99',
                        periodText: '/mo',
                        comparisonText: null,
                        onTap: () => setState(() => _isAnnualSelected = false),
                      ),

                      const Spacer(),

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
                                    : () => _handleSubscribe(
                                          _isAnnualSelected
                                              ? (_offerings?.current?.annual ?? package)
                                              : package,
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFBBF24), // Amber primary
                                  foregroundColor: Colors.black, // Dark text
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
                                    : Text(
                                        _isAnnualSelected
                                            ? 'Unlock Annual — \$24.99/yr'
                                            : 'Unlock Monthly — \$4.99/mo',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        _isAnnualSelected
                            ? 'Billed \$24.99 annually. Cancel anytime.'
                            : 'Billed \$4.99 monthly. Cancel anytime.',
                        style: const TextStyle(
                          color: Color(0xFF5D616B),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          child: Icon(icon, color: const Color(0xFF00BCD4), size: 24), // Cyan icon
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8E929C),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTileDark({
    required bool isAnnual,
    required bool isSelected,
    required String? badgeText,
    required String title,
    required String subtitle,
    required String priceText,
    required String periodText,
    required String? comparisonText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B2232) : const Color(0xFF121824).withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFF262E3E),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFF5D616B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8E929C),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      priceText,
                      style: GoogleFonts.inter(
                        color: isSelected ? const Color(0xFFFBBF24) : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      periodText,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8E929C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (comparisonText != null) ...[
              const SizedBox(height: 8),
              Text(
                comparisonText,
                style: GoogleFonts.inter(
                  color: const Color(0xFFFBBF24),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
