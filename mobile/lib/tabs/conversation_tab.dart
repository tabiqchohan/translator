import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/constants.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/translate_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/language_selector.dart';

class _ChatMessage {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  const _ChatMessage({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
  });
}

class ConversationTab extends StatefulWidget {
  const ConversationTab({super.key});

  @override
  State<ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<ConversationTab> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TranslateService _translateService = TranslateService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  String _langA = 'en';
  String _langB = 'ur';
  bool _typingInA = true;
  bool _isListening = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _langB =
        Provider.of<SettingsProvider>(context, listen: false).defaultTargetLang;
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _swapPair() {
    setState(() {
      final temp = _langA;
      _langA = _langB;
      _langB = temp;
    });
  }

  Future<void> _sendFromText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final from = _typingInA ? _langA : _langB;
    final to = _typingInA ? _langB : _langA;
    await _translateAndAdd(text, from, to);
  }

  Future<void> _listen(bool fromA) async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
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

    if (!available) {
      setState(() => _errorMessage =
          'Speech recognition is not available. Please check microphone permissions.');
      return;
    }

    setState(() {
      _isListening = true;
      _errorMessage = null;
    });

    await _speech.listen(
      onResult: (val) {
        if (val.finalResult && val.recognizedWords.trim().isNotEmpty) {
          final from = fromA ? _langA : _langB;
          final to = fromA ? _langB : _langA;
          _translateAndAdd(val.recognizedWords.trim(), from, to);
        }
      },
    );
  }

  Future<void> _translateAndAdd(String text, String from, String to) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _translateService.translateText(
      text: text,
      targetLang: to,
      sourceLang: from,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final output = res['translatedText'] ?? '';
      setState(() {
        _messages.add(_ChatMessage(
          sourceText: text,
          translatedText: output,
          sourceLang: from,
          targetLang: to,
        ));
        _isLoading = false;
      });
      _scrollToEnd();

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.incrementTranslateCount();
      _tts.setSpeechRate(settings.ttsRate);
      _tts.setPitch(settings.ttsPitch);
      _tts.speak(output);

      if (context.mounted) {
        Provider.of<HistoryProvider>(context, listen: false).addEntry(
          sourceText: text,
          translatedText: output,
          sourceLang: from,
          targetLang: to,
          type: 'conversation',
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['error'] ?? 'Translation failed';
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        // Language pair bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: LanguageSelector(
                    selectedCode: _langA,
                    allowAuto: false,
                    onChanged: (val) => setState(() => _langA = val),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: _swapPair,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.swap_horiz_rounded,
                          color: primary, size: 20),
                    ),
                  ),
                ),
                Expanded(
                  child: LanguageSelector(
                    selectedCode: _langB,
                    allowAuto: false,
                    onChanged: (val) => setState(() => _langB = val),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Chat list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.forum_rounded, size: 48, color: primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Start a conversation',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Type or tap a microphone to translate between the two languages.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final fromA = msg.sourceLang == _langA;
                    return _bubble(context, msg, fromA);
                  },
                ),
        ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ErrorBanner(
              message: _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

        // Input row
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(
              children: [
                _micButton(primary, true),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          child: TextField(
                            controller: _textController,
                            onSubmitted: (_) => _sendFromText(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'Type in ${AppConstants.getLanguageName(_typingInA ? _langA : _langB)}',
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _typingInA = !_typingInA);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            child: Text(
                              AppConstants.getLanguageName(
                                      _typingInA ? _langA : _langB)
                                  .split(' ')
                                  .first,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _micButton(primary, false),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sendFromText,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _micButton(Color primary, bool fromA) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: fromA ? 'Speak in language A' : 'Speak in language B',
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _listen(fromA);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isListening
                ? const Color(0xFFEF4444)
                : (isDark
                    ? const Color(0xFF1E293B)
                    : primary.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: _isListening ? Colors.white : primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _bubble(BuildContext context, _ChatMessage msg, bool fromA) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: fromA ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: fromA
              ? (isDark ? const Color(0xFF131C2E) : Colors.white)
              : primary.withValues(alpha: isDark ? 0.25 : 0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromA ? 4 : 18),
            bottomRight: Radius.circular(fromA ? 18 : 4),
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.getLanguageName(msg.sourceLang),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.sourceText,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
            ),
            const Divider(height: 14),
            Text(
              msg.translatedText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
