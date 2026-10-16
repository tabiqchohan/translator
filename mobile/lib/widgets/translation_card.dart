import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../core/language_detector.dart';
import '../providers/settings_provider.dart';

class TranslationCard extends StatefulWidget {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const TranslationCard({
    super.key,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  State<TranslationCard> createState() => _TranslationCardState();
}

class _TranslationCardState extends State<TranslationCard> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _speak() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    setState(() => _isPlaying = true);
    try {
      await _flutterTts.setSpeechRate(settings.ttsRate);
      await _flutterTts.setPitch(settings.ttsPitch);
      final locale = await _resolveLocale(widget.targetLang);
      if (locale != null) {
        await _flutterTts.setLanguage(locale);
      }
      await _flutterTts.speak(widget.translatedText);
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
      Fluttertoast.showToast(msg: "Speech not available for this language");
    }
  }

  Future<String?> _resolveLocale(String code) async {
    try {
      final dynamic langs = await _flutterTts.getLanguages;
      final target = code.toLowerCase();
      if (langs is List) {
        for (final l in langs) {
          final s = l.toString().toLowerCase();
          if (s == target ||
              s.startsWith('$target-') ||
              s.split('-').first == target) {
            return l.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.translatedText));
    Fluttertoast.showToast(msg: "Copied to clipboard!");
  }

  void _share() {
    SharePlus.instance.share(ShareParams(
      text:
          '${widget.sourceText}\n\nTranslation (${AppConstants.getLanguageName(widget.targetLang)}):\n${widget.translatedText}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final detectedLang = widget.sourceLang == 'auto'
        ? LanguageDetector.detect(widget.sourceText)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E1B4B).withValues(alpha: 0.6),
                  const Color(0xFF1E293B),
                ]
              : [
                  const Color(0xFFEEF2FF),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppConstants.getLanguageName(widget.targetLang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
              Row(
                children: [
                  _buildIconButton(
                    icon: _isPlaying
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    color: _isPlaying ? Colors.redAccent : primary,
                    onTap: _speak,
                    tooltip: 'Listen',
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.copy_rounded,
                    color: Colors.grey.shade600,
                    onTap: _copy,
                    tooltip: 'Copy',
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.share_rounded,
                    color: Colors.grey.shade600,
                    onTap: _share,
                    tooltip: 'Share',
                  ),
                ],
              ),
            ],
          ),
          if (detectedLang != null) ...[
            const SizedBox(height: 10),
            _detectedBadge(context, detectedLang),
          ],
          const SizedBox(height: 12),
          SelectableText(
            widget.translatedText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detectedBadge(BuildContext context, String lang) {
    const green = Color(0xFF16A34A);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: green.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 13, color: green),
          const SizedBox(width: 4),
          Text(
            'Detected: ${AppConstants.getLanguageName(lang)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
