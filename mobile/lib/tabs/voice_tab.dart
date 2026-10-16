import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/constants.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/translate_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation_card.dart';

class VoiceTab extends StatefulWidget {
  const VoiceTab({super.key});

  @override
  State<VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<VoiceTab>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TranslateService _translateService = TranslateService();

  late AnimationController _animController;
  bool _isListening = false;
  String _transcript = '';
  String _translatedText = '';
  String _sourceLang = 'en';
  String _targetLang = 'ur';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _targetLang = settings.defaultTargetLang;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            if (_transcript.isNotEmpty) _translate();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _errorMessage = error.errorMsg;
            });
          }
        },
      );

      if (!mounted) return;

      if (available) {
        setState(() {
          _isListening = true;
          _errorMessage = null;
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _transcript = val.recognizedWords;
          }),
        );
      } else {
        setState(() => _errorMessage =
            'Speech recognition is not available. Please check microphone permissions.');
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_transcript.isNotEmpty) _translate();
    }
  }

  Future<void> _translate() async {
    if (_transcript.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _translateService.translateText(
      text: _transcript,
      targetLang: _targetLang,
      sourceLang: _sourceLang,
    );

    if (mounted) {
      if (res['success'] == true) {
        final output = res['translatedText'] ?? '';
        setState(() {
          _translatedText = output;
          _isLoading = false;
        });

        // Save to history
        final history = Provider.of<HistoryProvider>(context, listen: false);
        history.addEntry(
          sourceText: _transcript,
          translatedText: output,
          sourceLang: _sourceLang,
          targetLang: _targetLang,
          type: 'voice',
        );
        Provider.of<SettingsProvider>(context, listen: false)
            .incrementTranslateCount();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res['error'] ?? 'Translation failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Language selectors
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: LanguageSelector(
                      selectedCode: _sourceLang,
                      allowAuto: false,
                      onChanged: (val) => setState(() => _sourceLang = val),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: primary, size: 20),
                  ),
                  Expanded(
                    child: LanguageSelector(
                      selectedCode: _targetLang,
                      allowAuto: false,
                      onChanged: (val) => setState(() => _targetLang = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Pulsing Glow Voice Mic
            GestureDetector(
              onTap: _listen,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [const Color(0xFFEF4444), const Color(0xFFF97316)]
                            : [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6)
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6366F1))
                              .withValues(
                                  alpha: _isListening
                                      ? 0.3 + (_animController.value * 0.3)
                                      : 0.35),
                          blurRadius: _isListening ? 36 : 20,
                          spreadRadius: _isListening ? 12 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isListening
                  ? 'Listening to speech... Tap to translate'
                  : 'Tap microphone to speak',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _isListening
                    ? const Color(0xFFEF4444)
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 28),

            // Speech Transcript Card
            if (_transcript.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded,
                            size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          'Detected (${AppConstants.getLanguageName(_sourceLang)}):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcript,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4),
                    ),
                  ],
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
              ),

            // Translation Result
            if (_translatedText.isNotEmpty && !_isLoading)
              TranslationCard(
                sourceText: _transcript,
                translatedText: _translatedText,
                sourceLang: _sourceLang,
                targetLang: _targetLang,
              ),
          ],
        ),
      ),
    );
  }
}
