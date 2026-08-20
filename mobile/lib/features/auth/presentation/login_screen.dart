// lib/features/auth/presentation/login_screen.dart
// Aura — Login Screen (Dynamic Theme & Keyboard Dismissal Enabled)

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  late final AnimationController _btnAnim;

  @override
  void initState() {
    super.initState();
    _btnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _btnAnim.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  void _toggleObscure() => setState(() => _obscurePassword = !_obscurePassword);

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: auraTheme.background,
        body: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (_, cur) => cur is AuthFailure || cur is Authenticated,
          listener: (context, state) {
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: auraTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
            } else if (state is Authenticated) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          buildWhen: (prev, cur) => (prev is AuthLoading) != (cur is AuthLoading),
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            isLoading ? _btnAnim.forward() : _btnAnim.reverse();

            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Brand Logo & Header ───────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: auraTheme.card,
                                  border: Border.all(
                                    color: auraTheme.primary.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: auraTheme.primary.withOpacity(0.15),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/aura_logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: auraTheme.primary,
                                        child: Center(
                                          child: Text(
                                            'A',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'AURA',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: auraTheme.textPrimary,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track Your Nutrition & Workouts',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: auraTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Card container for inputs ─────────────────────
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: auraTheme.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: auraTheme.border,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Email ─────────────────────────────────
                              Text(
                                'Email Address',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: auraTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  color: auraTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  hintText: 'e.g. ahmed@gmail.com',
                                  hintStyle: GoogleFonts.inter(
                                    color: auraTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: auraTheme.textMuted,
                                    size: 18,
                                  ),
                                  filled: true,
                                  fillColor: auraTheme.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.primary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.error),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.error, width: 1.5),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.contains('@')) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Password ──────────────────────────────
                              Text(
                                'Password',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: auraTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                style: GoogleFonts.inter(
                                  color: auraTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  hintText: '••••••••',
                                  hintStyle: GoogleFonts.inter(
                                    color: auraTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: auraTheme.textMuted,
                                    size: 18,
                                  ),
                                  suffixIcon: IconButton(
                                    splashRadius: 18,
                                    onPressed: _toggleObscure,
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: auraTheme.textMuted,
                                      size: 18,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: auraTheme.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.primary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.error),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: auraTheme.error, width: 1.5),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Password is required';
                                  if (v.trim().length < 8) return 'Password must be at least 8 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),

                              // ── Submit Button (animated) ───────────────
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: auraTheme.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: auraTheme.primary.withOpacity(0.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: isLoading
                                        ? const SizedBox(
                                            key: ValueKey('loading'),
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            key: const ValueKey('label'),
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── OR divider ────────────────────────────
                              Row(
                                children: [
                                  Expanded(child: Divider(color: auraTheme.border, thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.inter(
                                        color: auraTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: auraTheme.border, thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ── Google Sign-In ────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => _handleGoogleSignIn(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: auraTheme.border, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    foregroundColor: auraTheme.textPrimary,
                                    backgroundColor: auraTheme.surface,
                                  ),
                                  icon: Image.asset(
                                    'assets/icons/google.png',
                                    height: 18,
                                    width: 18,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: auraTheme.textPrimary,
                                      size: 22,
                                    ),
                                  ),
                                  label: Text(
                                    'Continue with Google',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: auraTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),

                              // ── Apple Sign-In (iOS only) ───────────────
                              if (Platform.isIOS) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading
                                        ? null
                                        : () => context.read<AuthBloc>().add(AppleSignInSubmitted()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: auraTheme.textPrimary,
                                      foregroundColor: auraTheme.background,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(
                                      Icons.apple_rounded,
                                      color: auraTheme.background,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Continue with Apple',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: auraTheme.background,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Switch to Register ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: auraTheme.textSecondary,
                              ),
                            ),
                            InkWell(
                              onTap: isLoading
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, anim, __) => const RegisterScreen(),
                                          transitionsBuilder: (_, anim, __, child) => FadeTransition(
                                            opacity: anim,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0.05, 0),
                                                end: Offset.zero,
                                              ).animate(CurvedAnimation(
                                                parent: anim,
                                                curve: Curves.easeOut,
                                              )),
                                              child: child,
                                            ),
                                          ),
                                          transitionDuration: const Duration(milliseconds: 240),
                                        ),
                                      ),
                              borderRadius: BorderRadius.circular(4),
                              child: Text(
                                'Register',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: auraTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleGoogleSignIn(BuildContext context) {
    context.read<AuthBloc>().add(const GoogleSignInSubmitted());
  }
}

class _AuraLogoPainter extends CustomPainter {
  final Color color;

  const _AuraLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final apex = Offset(w * 0.50, h * 0.10);
    final bottomLeft = Offset(w * 0.12, h * 0.88);
    final bottomRight = Offset(w * 0.88, h * 0.88);
    final crossLeft = Offset(w * 0.28, h * 0.58);
    final crossRight = Offset(w * 0.95, h * 0.42);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..moveTo(crossLeft.dx, crossLeft.dy)
      ..lineTo(crossRight.dx, crossRight.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
