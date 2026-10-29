// lib/features/calorie_tracker/presentation/barcode_confirmation_sheet.dart
// Aura — Barcode Product Confirmation Sheet
//
// A modal bottom sheet shown after a successful barcode lookup.
// Lets the user:
//   1. See the product name and per-100g nutrition
//   2. Enter their serving size in grams
//   3. See live-calculated macros update as they type
//   4. Tap "Log Meal" to persist via BarcodeService
//   5. Tap "Cancel" to dismiss without logging
//
// On successful log, pops with a BarcodeServing (so the caller
// can add it to the feed immediately without a page refresh).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/models/barcode_product.dart';
import '../data/services/barcode_service.dart';

class BarcodeConfirmationSheet extends StatefulWidget {
  final BarcodeProduct product;
  final BarcodeService service;

  const BarcodeConfirmationSheet({
    super.key,
    required this.product,
    required this.service,
  });

  @override
  State<BarcodeConfirmationSheet> createState() => _BarcodeConfirmationSheetState();
}

class _BarcodeConfirmationSheetState extends State<BarcodeConfirmationSheet> {
  final _servingController = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();

  double _servingGrams = 100.0;
  bool _isLogging = false;

  BarcodeServing get _currentServing =>
      widget.product.forServing(_servingGrams);

  @override
  void dispose() {
    _servingController.dispose();
    super.dispose();
  }

  void _onServingChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() => _servingGrams = parsed);
    }
  }

  int _calculateHealthScore(double cal, double prot, double carb, double fat) {
    if (cal <= 0) return 80;
    final pCal = (prot * 4) / cal;
    final cCal = (carb * 4) / cal;
    final fCal = (fat * 9) / cal;

    double score = 50.0;
    score += (pCal * 100).clamp(0, 30);
    if (cCal >= 0.3 && cCal <= 0.6) score += 15;
    if (fCal >= 0.15 && fCal <= 0.35) score += 15;
    if (cal < 650) score += 10;

    return score.round().clamp(20, 98);
  }

  Future<void> _log() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLogging) return;

    setState(() => _isLogging = true);
    try {
      await widget.service.logBarcodeProduct(
        product: widget.product,
        servingGrams: _servingGrams,
      );
      if (mounted) Navigator.of(context).pop(_currentServing);
    } catch (e) {
      if (mounted) {
        setState(() => _isLogging = false);
        final cleanMsg = AppErrorHandler.getUserMessage(e, 'Unable to log meal. Please try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E3A2B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cleanMsg,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final serving = _currentServing;
    final healthScore = _calculateHealthScore(
      serving.calories,
      serving.protein,
      serving.carbs,
      serving.fats,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ──────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded, color: theme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            widget.product.dataSource == 'ai-estimated'
                                ? Icons.auto_awesome
                                : Icons.verified_outlined,
                            size: 13,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.dataSource == 'ai-estimated'
                                ? 'AI Estimated · per 100g'
                                : 'Open Food Facts · per 100g',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Serving input ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serving Size',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _servingController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        onChanged: _onServingChanged,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter a valid amount';
                          if (n > 10000) return 'Max 10,000 g';
                          return null;
                        },
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: theme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          suffixText: 'g',
                          suffixStyle: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondary,
                          ),
                          filled: true,
                          fillColor: theme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: theme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: theme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: theme.primary, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: theme.error, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Quick-pick buttons
                Column(
                  children: [
                    _quickPick(30, theme),
                    const SizedBox(height: 6),
                    _quickPick(100, theme),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Live macro grid (matching Camera Scan result card) ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calculated for ${_servingGrams.toStringAsFixed(_servingGrams % 1 == 0 ? 0 : 1)}g',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Live update',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: theme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _macroCard(
                          title: 'Calories',
                          value: '${serving.calories.round()} kcal',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: theme.success,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _macroCard(
                          title: 'Carbs',
                          value: '${serving.carbs.toStringAsFixed(1)}g',
                          icon: Icons.grain_rounded,
                          iconColor: theme.carbs,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _macroCard(
                          title: 'Protein',
                          value: '${serving.protein.toStringAsFixed(1)}g',
                          icon: Icons.fitness_center_rounded,
                          iconColor: theme.protein,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _macroCard(
                          title: 'Fats',
                          value: '${serving.fats.toStringAsFixed(1)}g',
                          icon: Icons.opacity_rounded,
                          iconColor: theme.fats,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Health Score bar matching Camera Scan result card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.favorite_rounded, size: 15, color: theme.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Health Score',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$healthScore / 100',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: healthScore >= 70
                                    ? theme.success
                                    : (healthScore >= 50 ? theme.warning : theme.error),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (healthScore / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: theme.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              healthScore >= 70
                                  ? theme.success
                                  : (healthScore >= 50 ? theme.warning : theme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Actions ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLogging ? null : _log,
                    icon: _isLogging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isLogging ? 'Logging...' : 'Log Meal',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: theme.primary.withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.white70,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _isLogging ? null : () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.surface,
                    foregroundColor: theme.textSecondary,
                    side: BorderSide(color: theme.borderMid),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickPick(int grams, AuraThemeExtension theme) {
    final isActive = _servingGrams == grams.toDouble();
    return GestureDetector(
      onTap: () {
        _servingController.text = '$grams';
        setState(() => _servingGrams = grams.toDouble());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? theme.primary.withValues(alpha: 0.12) : theme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? theme.primary : theme.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          '${grams}g',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isActive ? theme.primary : theme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _macroCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required AuraThemeExtension theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
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
