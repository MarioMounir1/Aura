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
import '../../../../core/theme/app_colors.dart';
import '../data/models/barcode_product.dart';
import '../data/services/barcode_service.dart';

typedef _C = AppColors;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: _C.red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to log meal: $e',
                    style: GoogleFonts.inter(fontSize: 12, color: _C.textPri),
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
    final serving = _currentServing;

    return Container(
      decoration: const BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: _C.track,
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
                    color: _C.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.barcode_reader, color: _C.amber, size: 22),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _C.textPri,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            widget.product.dataSource == 'ai-estimated'
                                ? Icons.auto_awesome
                                : Icons.verified_outlined,
                            size: 11,
                            color: _C.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.product.dataSource == 'ai-estimated'
                                ? 'AI Estimated · per 100g'
                                : 'Open Food Facts · per 100g',
                            style: GoogleFonts.inter(fontSize: 11, color: _C.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Serving input ────────────────────────────────
            Row(
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
                          color: _C.textSec,
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
                          color: _C.textPri,
                        ),
                        decoration: InputDecoration(
                          suffixText: 'g',
                          suffixStyle: GoogleFonts.inter(fontSize: 14, color: _C.textSec),
                          filled: true,
                          fillColor: _C.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _C.amber, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _C.red, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Quick-pick buttons
                Column(
                  children: [
                    Text('', style: GoogleFonts.outfit(fontSize: 13)),
                    const SizedBox(height: 8),
                    _quickPick(30),
                    const SizedBox(height: 6),
                    _quickPick(100),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Live macro grid ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.amber.withValues(alpha: 0.2)),
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
                          color: _C.textMuted,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _C.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Live update',
                          style: GoogleFonts.inter(fontSize: 10, color: _C.amber, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _macroChip('🔥', serving.calories.round().toString(), 'kcal', _C.lime),
                      const SizedBox(width: 8),
                      _macroChip('💪', serving.protein.toStringAsFixed(1), 'g P', _C.emerald),
                      const SizedBox(width: 8),
                      _macroChip('🌾', serving.carbs.toStringAsFixed(1), 'g C', _C.blue),
                      const SizedBox(width: 8),
                      _macroChip('🫙', serving.fats.toStringAsFixed(1), 'g F', _C.red),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      _isLogging ? 'Logging...' : 'Log Meal',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.amber,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: _C.amber.withValues(alpha: 0.5),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _isLogging ? null : () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.textSec,
                    side: const BorderSide(color: _C.track),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
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

  Widget _quickPick(int grams) {
    final isActive = _servingGrams == grams.toDouble();
    return GestureDetector(
      onTap: () {
        _servingController.text = '$grams';
        setState(() => _servingGrams = grams.toDouble());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _C.amber.withValues(alpha: 0.2) : _C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.amber : _C.track,
          ),
        ),
        child: Text(
          '${grams}g',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? _C.amber : _C.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _macroChip(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.textPri,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9, color: _C.textSec),
            ),
          ],
        ),
      ),
    );
  }
}
