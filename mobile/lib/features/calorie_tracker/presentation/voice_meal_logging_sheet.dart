// lib/features/calorie_tracker/presentation/voice_meal_logging_sheet.dart
// Aura — AI Voice Meal Logging Bottom Sheet Modal
// Transcribes voice via speech_to_text and calls Gemini NLP for instant macros.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/error/error_handler.dart';
import '../../../../core/utils/constants.dart';
import 'meals_dashboard_screen.dart' show MealEntry;

class VoiceMealLoggingSheet extends StatefulWidget {
  const VoiceMealLoggingSheet({super.key});

  @override
  State<VoiceMealLoggingSheet> createState() => _VoiceMealLoggingSheetState();
}

class _VoiceMealLoggingSheetState extends State<VoiceMealLoggingSheet>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSpeechAvailable = false;
  bool _isAnalyzing = false;
  String _transcript = '';
  late TextEditingController _textController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _textController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );

      if (mounted) {
        setState(() => _isSpeechAvailable = available);
        if (available) {
          _startListening();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSpeechAvailable = false);
      }
    }
  }

  void _startListening() async {
    if (!_isSpeechAvailable) return;

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _transcript = result.recognizedWords;
            _textController.text = _transcript;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _analyzeAndLog() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please speak or type what you ate.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E2620),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    _stopListening();
    setState(() => _isAnalyzing = true);

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.tokenKey);

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiV1,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.post(
        '/meals/voice-log',
        data: {'transcript': text},
      );

      if (!mounted) return;

      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final entry = MealEntry(
          id: (data['logId'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
          foodName: (data['mealName'] as String?) ?? text,
          restaurantName: 'Voice Log',
          protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
          carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
          fat: (data['fats'] as num?)?.toDouble() ?? 0.0,
          calories: (data['calories'] as num?)?.toInt() ?? 0,
        );

        Navigator.of(context).pop(entry);
      } else {
        throw Exception(response.data['error'] ?? 'Voice analysis failed');
      }
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = AppErrorHandler.getUserMessage(e, 'Could not analyze voice meal.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanMsg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
          backgroundColor: const Color(0xFF1E2620),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161E18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2E3D31), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF235A42).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mic_rounded, color: Color(0xFF55D6A0), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Talk to Log',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Glowing animated mic button
          GestureDetector(
            onTap: _isAnalyzing
                ? null
                : () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
            child: ScaleTransition(
              scale: _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [const Color(0xFF235A42), const Color(0xFF388E68)]
                        : [const Color(0xFF263329), const Color(0xFF1E2821)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: const Color(0xFF55D6A0).withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          )
                        ]
                      : [],
                  border: Border.all(
                    color: _isListening ? const Color(0xFF55D6A0) : const Color(0xFF384A3B),
                    width: 2,
                  ),
                ),
                child: _isAnalyzing
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF55D6A0),
                          ),
                        ),
                      )
                    : Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? const Color(0xFF55D6A0) : Colors.white70,
                        size: 36,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _isAnalyzing
                ? 'Estimating exact calories & macros with Gemini...'
                : _isListening
                    ? 'Listening... Speak naturally'
                    : 'Tap mic to start or edit below',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isListening ? const Color(0xFF55D6A0) : Colors.white60,
            ),
          ),
          const SizedBox(height: 20),

          // Editable transcript text field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1511),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF263529)),
            ),
            child: TextField(
              controller: _textController,
              maxLines: 3,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.4),
              decoration: InputDecoration(
                hintText: 'e.g. "I had 2 fried eggs, a buttered croissant, and an iced latte"',
                hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeAndLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF235A42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF55D6A0), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Analyze & Log Meal',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
