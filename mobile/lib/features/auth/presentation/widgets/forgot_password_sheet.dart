// lib/features/auth/presentation/widgets/forgot_password_sheet.dart
// Aura — 6-Digit Email OTP Forgot & Reset Password Modal Sheet

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_components.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final String? initialEmail;
  final ValueChanged<String>? onResetSuccess;

  const ForgotPasswordSheet({
    super.key,
    this.initialEmail,
    this.onResetSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialEmail,
    ValueChanged<String>? onResetSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordSheet(
        initialEmail: initialEmail,
        onResetSuccess: onResetSuccess,
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  // Steps: 0 = Request OTP (Email), 1 = Verify OTP & Set New Password, 2 = Success
  int _currentStep = 0;

  late final TextEditingController _emailController;
  late final TextEditingController _otpController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  // Resend cooldown timer
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _otpController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 1) {
          _resendCountdown--;
        } else {
          _resendCountdown = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleRequestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      HapticFeedback.lightImpact();
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final result = await authRepo.requestPasswordResetOtp(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        HapticFeedback.mediumImpact();
        setState(() => _errorMessage = failure.message);
      },
      (msg) {
        HapticFeedback.lightImpact();
        _startResendTimer();
        setState(() {
          _errorMessage = null;
          _currentStep = 1;
        });
      },
    );
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (otp.length != 6) {
      HapticFeedback.lightImpact();
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    if (newPass.length < 6) {
      HapticFeedback.lightImpact();
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (newPass != confirmPass) {
      HapticFeedback.lightImpact();
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = context.read<AuthRepository>();
    final result = await authRepo.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        HapticFeedback.mediumImpact();
        setState(() => _errorMessage = failure.message);
      },
      (msg) async {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = null;
          _successMessage = msg;
          _currentStep = 2;
        });

        widget.onResetSuccess?.call(email);

        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AuraAuthTokens.sageBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (_currentStep == 0) _buildStep0Email(textTheme),
            if (_currentStep == 1) _buildStep1OtpAndNewPass(textTheme),
            if (_currentStep == 2) _buildStep2Success(textTheme),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Enter Email ──────────────────────────────────────────
  Widget _buildStep0Email(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Password',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AuraAuthTokens.brandDeep,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the email associated with your Aura account. We will send you a 6-digit verification code.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AuraAuthTokens.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),

        AuraInputField(
          label: 'Email address',
          hintText: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleRequestOtp(),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_errorMessage!),
        ],

        const SizedBox(height: 22),
        AuraPrimaryButton(
          label: 'Send Verification Code',
          isLoading: _isLoading,
          onPressed: _handleRequestOtp,
        ),
      ],
    );
  }

  // ── Step 1: OTP & New Password ────────────────────────────────────
  Widget _buildStep1OtpAndNewPass(TextTheme textTheme) {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _errorMessage = null;
                  _currentStep = 0;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AuraAuthTokens.brandDark),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Enter Code & New Password',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AuraAuthTokens.brandDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to $email. Enter the code and set your new password below.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AuraAuthTokens.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        // OTP Code Input
        AuraInputField(
          label: '6-Digit Verification Code',
          hintText: '123456',
          prefixIcon: Icons.pin_outlined,
          controller: _otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        const SizedBox(height: 14),

        // New Password
        AuraInputField(
          label: 'New Password',
          hintText: 'At least 6 characters',
          prefixIcon: Icons.lock_outline_rounded,
          controller: _newPasswordController,
          obscureText: _obscureNewPass,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AuraAuthTokens.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm Password
        AuraInputField(
          label: 'Confirm New Password',
          hintText: 'Repeat new password',
          prefixIcon: Icons.lock_reset_rounded,
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPass,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleResetPassword(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AuraAuthTokens.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_errorMessage!),
        ],

        const SizedBox(height: 20),
        AuraPrimaryButton(
          label: 'Reset Password',
          isLoading: _isLoading,
          onPressed: _handleResetPassword,
        ),

        const SizedBox(height: 14),
        Center(
          child: _resendCountdown > 0
              ? Text(
                  'Resend code in ${_resendCountdown}s',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AuraAuthTokens.textMuted,
                  ),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _handleRequestOtp,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: Text(
                    'Didn\'t receive a code? Resend',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuraAuthTokens.terracotta,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Step 2: Success Confirmation ─────────────────────────────────
  Widget _buildStep2Success(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF81C784), width: 2),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2E7D32),
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Password Reset Complete!',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AuraAuthTokens.brandDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _successMessage ?? 'Your password has been reset. You can now log in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AuraAuthTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF8B4B4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFF9B1C1C), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF9B1C1C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
