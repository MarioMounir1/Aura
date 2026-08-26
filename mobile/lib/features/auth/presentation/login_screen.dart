// lib/features/auth/presentation/login_screen.dart
// Aura — Redesigned Sign In Screen (Google Material 3 Standard & Responsive Layout)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'register_screen.dart';
import 'widgets/auth_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  void _toggleObscure() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _handleGoogleSignIn() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(const GoogleSignInSubmitted());
  }

  void _handleAppleSignIn() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AppleSignInSubmitted());
  }

  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuraAuthTokens.sageBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Reset Password',
                style: GoogleFonts.fraunces(
                  textStyle: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AuraAuthTokens.brandDeep,
                  ),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AuraAuthTokens.brandDeep,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the email associated with your Aura account and we will send you a reset link.',
                style: GoogleFonts.inter(
                  textStyle: textTheme.bodyMedium?.copyWith(
                    color: AuraAuthTokens.textSecondary,
                    height: 1.4,
                  ),
                  fontSize: 13.5,
                  color: AuraAuthTokens.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              AuraInputField(
                label: 'Email address',
                hintText: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              AuraPrimaryButton(
                label: 'Send Reset Link',
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'If an account exists for that email, a reset link has been sent.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: AuraAuthTokens.brandDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const RegisterScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBF9),
        body: AuraAuthBackground(
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (_, cur) => cur is AuthFailure || cur is Authenticated,
            listener: (context, state) {
              if (state is AuthFailure) {
                if (state.message.contains('\n') ||
                    state.code != null ||
                    state.details != null ||
                    state.message.contains('Google')) {
                  showAuraAuthErrorDialog(
                    context,
                    title: state.message.contains('Google')
                        ? 'Google Sign-In Error'
                        : 'Sign-In Error',
                    message: state.message,
                    code: state.code,
                    details: state.details,
                  );
                } else {
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
                        backgroundColor: const Color(0xFFD9534F),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                }
              } else if (state is Authenticated) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AuraAuthTokens.maxContentWidth,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top Header: Brand Logo & Switch link ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const AuraBrandHeader(
                                  showWordmark: true,
                                  iconSize: 40,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'New here? ',
                                      style: GoogleFonts.inter(
                                        textStyle: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AuraAuthTokens.textSecondary,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AuraAuthTokens.textSecondary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: isLoading ? null : _navigateToRegister,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Create account',
                                              style: GoogleFonts.inter(
                                                textStyle: textTheme.labelMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AuraAuthTokens.brandDark,
                                                  decoration: TextDecoration.underline,
                                                ),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AuraAuthTokens.brandDark,
                                                decoration: TextDecoration.underline,
                                                decorationColor: AuraAuthTokens.brandDark,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 14,
                                              color: AuraAuthTokens.brandDark,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // ── Eyebrow with Shield Check Icon ───────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5F2E9),
                                        borderRadius: BorderRadius.circular(11),
                                        border: Border.all(
                                          color: const Color(0xFFD4E8DC),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.verified_user_outlined,
                                          color: AuraAuthTokens.brandDark,
                                          size: 19,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: AuraAuthTokens.amberBadge,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'YOUR DAILY RITUAL',
                                  style: GoogleFonts.inter(
                                    textStyle: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                      color: AuraAuthTokens.terracotta,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                    color: AuraAuthTokens.terracotta,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ── Main Editorial Serif Headline ────────────────
                            Text(
                              'Good to have you\nback.',
                              style: GoogleFonts.fraunces(
                                textStyle: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  height: 1.15,
                                  color: AuraAuthTokens.brandDeep,
                                ),
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                height: 1.15,
                                color: AuraAuthTokens.brandDeep,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ── Subtitle ─────────────────────────────────────
                            Text(
                              'Pick up where you left off. A calmer way to care for your nutrition and wellness.',
                              style: GoogleFonts.inter(
                                textStyle: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AuraAuthTokens.textSecondary,
                                  height: 1.45,
                                ),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: AuraAuthTokens.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 26),

                            // ── Main Form Card Container ─────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                              decoration: BoxDecoration(
                                color: AuraAuthTokens.cardBg,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: AuraAuthTokens.sageBorder,
                                  width: 1.1,
                                ),
                                boxShadow: const [
                                BoxShadow(
                                    color: AuraAuthTokens.cardShadow,
                                    blurRadius: 24,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Email Input ─────────────────────────────
                                  AuraInputField(
                                    label: 'Email address',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icons.mail_outline_rounded,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Password Input ──────────────────────────
                                  AuraInputField(
                                    label: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    trailingLabelWidget: InkWell(
                                      onTap: _showForgotPasswordSheet,
                                      borderRadius: BorderRadius.circular(4),
                                      child: Text(
                                        'Forgot\npassword?',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.inter(
                                          textStyle: textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AuraAuthTokens.terracotta,
                                            height: 1.1,
                                          ),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AuraAuthTokens.terracotta,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      splashRadius: 18,
                                      onPressed: _toggleObscure,
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AuraAuthTokens.textMuted,
                                        size: 19,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (v.trim().length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 22),

                                  // ── Sign in CTA Button ──────────────────────
                                  AuraPrimaryButton(
                                    label: 'Sign in to Aura',
                                    isLoading: isLoading,
                                    onPressed: _submit,
                                  ),
                                  const SizedBox(height: 20),

                                  // ── OR Divider ──────────────────────────────
                                  const AuraDividerWithText(text: 'OR CONTINUE WITH'),
                                  const SizedBox(height: 18),

                                  // ── Google Sign-In ──────────────────────────
                                  AuraGoogleButton(
                                    isLoading: isLoading,
                                    onPressed: _handleGoogleSignIn,
                                  ),

                                  // ── Apple Sign-In (iOS) ──────────────────────
                                  AuraAppleButton(
                                    isLoading: isLoading,
                                    onPressed: _handleAppleSignIn,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Trust & Privacy Footer ───────────────────────
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AuraAuthTokens.terracotta,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your data stays private and yours',
                                    style: GoogleFonts.inter(
                                      textStyle: textTheme.bodySmall?.copyWith(
                                        color: AuraAuthTokens.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AuraAuthTokens.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AuraAuthTokens.terracotta,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
