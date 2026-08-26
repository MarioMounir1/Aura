// lib/features/auth/presentation/register_screen.dart
// Aura — Redesigned Sign Up Screen (Google Material 3 Standard & Responsive Layout)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'widgets/auth_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          RegisterSubmitted(
            name: _nameController.text.trim(),
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
                        : 'Registration Error',
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
                            // ── Top Bar: Circular Back Button & Sign In Link ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AuraCircularBackButton(
                                  onTap: isLoading ? null : () => Navigator.of(context).maybePop(),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ALREADY A MEMBER? ',
                                      style: GoogleFonts.inter(
                                        textStyle: textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: AuraAuthTokens.textSecondary,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: AuraAuthTokens.textSecondary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: isLoading ? null : () => Navigator.of(context).maybePop(),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                        child: Text(
                                          'SIGN IN',
                                          style: GoogleFonts.inter(
                                            textStyle: textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: AuraAuthTokens.brandDark,
                                              decoration: TextDecoration.underline,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: AuraAuthTokens.brandDark,
                                            decoration: TextDecoration.underline,
                                            decorationColor: AuraAuthTokens.brandDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Brand Squircle Logo Header ───────────────────
                            const AuraBrandHeader(
                              showWordmark: true,
                              iconSize: 40,
                            ),
                            const SizedBox(height: 22),

                            // ── Category Eyebrow Tag ─────────────────────────
                            Text(
                              'A GENTLER STARTING POINT',
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
                            const SizedBox(height: 12),

                            // ── Main Editorial Serif Headline ────────────────
                            Text(
                              'Make room for\nyour well-being.',
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
                              'A little support for the meals, movement, and moments that make you feel good.',
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

                            // ── Main Card Container ──────────────────────────
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
                                  // ── Reassurance Value Chip ─────────────────
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F8F5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2EEE6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: AuraAuthTokens.checkPillBg,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: AuraAuthTokens.checkPillIcon,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Your first step takes less than a minute.',
                                            style: GoogleFonts.inter(
                                              textStyle: textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AuraAuthTokens.brandDark,
                                              ),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: AuraAuthTokens.brandDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Your Name Input ─────────────────────────
                                  AuraInputField(
                                    label: 'Your name',
                                    hintText: 'e.g. Amara Lee',
                                    prefixIcon: Icons.person_outline_rounded,
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Name is required';
                                      }
                                      if (v.trim().length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Email Address Input ─────────────────────
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

                                  // ── Create Password Input ───────────────────
                                  AuraInputField(
                                    label: 'Create a password',
                                    hintText: '8 characters or more',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
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
                                      if (v.trim().length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 22),

                                  // ── Create My Aura CTA Button ───────────────
                                  AuraPrimaryButton(
                                    label: 'Create my Aura',
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
                            const SizedBox(height: 24),
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
