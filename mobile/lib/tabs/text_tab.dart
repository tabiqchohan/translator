import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/translate_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation_card.dart';

class TextTab extends StatefulWidget {
  const TextTab({super.key});

  @override
  State<TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<TextTab> {
  final _textController = TextEditingController();
  final _translateService = TranslateService();

  String _sourceLang = 'auto';
  String _targetLang = 'ur';
  String _translatedText = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _targetLang = settings.defaultTargetLang;
  }

  void _swapLanguages() {
    if (_sourceLang == 'auto') return;
    setState(() {
      final tempLang = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = tempLang;

      final tempText = _textController.text;
      _textController.text = _translatedText;
      _translatedText = tempText;
    });
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _translateService.translateText(
      text: text,
      targetLang: _targetLang,
      sourceLang: _sourceLang,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final output = res['translatedText'] ?? '';
      setState(() {
        _translatedText = output;
        _isLoading = false;
      });

      // Save to history
      final history = Provider.of<HistoryProvider>(context, listen: false);
      history.addEntry(
        sourceText: text,
        translatedText: output,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      Provider.of<SettingsProvider>(context, listen: false)
          .incrementTranslateCount();
    } else {
      setState(() {
        _errorMessage = res['error'] ?? 'Translation failed';
        _isLoading = false;
      });
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language selection bar
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: LanguageSelector(
                      selectedCode: _sourceLang,
                      allowAuto: true,
                      onChanged: (val) => setState(() => _sourceLang = val),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: _sourceLang == 'auto' ? null : _swapLanguages,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _sourceLang == 'auto'
                              ? Colors.grey.withValues(alpha: 0.1)
                              : primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: _sourceLang == 'auto' ? Colors.grey : primary,
                          size: 20,
                        ),
                      ),
                    ),
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
            const SizedBox(height: 16),

            // Source Input Glass Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    minLines: 4,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Type or paste text to translate...',
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_textController.text.length} characters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      if (_textController.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _textController.clear();
                              _translatedText = '';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Translate Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _translate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white),
                label: Text(
                  _isLoading ? 'Translating with AI...' : 'Translate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error Banner
            if (_errorMessage != null)
              ErrorBanner(
                message: _errorMessage!,
                onDismiss: () => setState(() => _errorMessage = null),
              ),

            // Translation Result Card
            if (_translatedText.isNotEmpty) ...[
              const SizedBox(height: 8),
              TranslationCard(
                sourceText: _textController.text,
                translatedText: _translatedText,
                sourceLang: _sourceLang,
                targetLang: _targetLang,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
