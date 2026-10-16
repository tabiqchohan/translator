import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/paywall_screen.dart';
import '../services/translate_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation_card.dart';

class DocumentTab extends StatefulWidget {
  const DocumentTab({super.key});

  @override
  State<DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends State<DocumentTab> {
  final ApiClient _client = ApiClient();
  final TranslateService _translateService = TranslateService();

  File? _file;
  String? _fileName;
  String _targetLang = 'ur';
  String _extractedText = '';
  String _translatedText = '';
  bool _isLoading = false;
  String? _statusText;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _targetLang = settings.defaultTargetLang;
  }

  Future<void> _pickFile() async {
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!sub.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _fileName = result.files.single.name;
        _extractedText = '';
        _translatedText = '';
        _errorMessage = null;
      });
    }
  }

  Future<void> _translateDocument() async {
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!sub.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    if (_file == null) return;

    setState(() {
      _isLoading = true;
      _statusText = 'Parsing document...';
      _errorMessage = null;
    });

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _file!.path,
          filename: _fileName,
        ),
      });

      final parseRes = await _client.dio.post(
        '/api/document',
        data: formData,
      );

      if (parseRes.statusCode == 200 &&
          parseRes.data?['originalText'] != null) {
        final text = parseRes.data['originalText'] as String;
        setState(() {
          _extractedText = text;
          _statusText = 'Translating document...';
        });

        final transRes = await _translateService.translateText(
          text: text,
          targetLang: _targetLang,
          sourceLang: 'auto',
        );

        if (mounted) {
          if (transRes['success'] == true) {
            final output = transRes['translatedText'] ?? '';
            setState(() {
              _translatedText = output;
              _isLoading = false;
              _statusText = null;
            });

            final history =
                Provider.of<HistoryProvider>(context, listen: false);
            history.addEntry(
              sourceText: text,
              translatedText: output,
              sourceLang: 'auto',
              targetLang: _targetLang,
              type: 'document',
            );
            Provider.of<SettingsProvider>(context, listen: false)
                .incrementTranslateCount();
          } else {
            setState(() {
              _isLoading = false;
              _statusText = null;
              _errorMessage = transRes['error'] ?? 'Translation failed';
            });
          }
        }
      } else {
        String error = 'Failed to parse document';
        final data = parseRes.data;
        if (data is Map && data['error'] != null) {
          error = data['error'].toString();
        }
        setState(() {
          _isLoading = false;
          _statusText = null;
          _errorMessage = error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = null;
          _errorMessage = 'Failed to process document: $e';
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                  const Text(
                    'Translate to:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
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

            // Upload Dropzone
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.cloud_upload_rounded,
                          size: 38, color: primary),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _fileName ?? 'Tap to select document',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Supported formats: PDF, DOCX, TXT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_file != null)
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
                  onPressed: _isLoading ? null : _translateDocument,
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
                    _isLoading
                        ? _statusText ?? 'Translating...'
                        : 'Translate Document',
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

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _statusText ?? 'Processing...',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(
                message: _errorMessage!,
                onDismiss: () => setState(() => _errorMessage = null),
              ),
            ],

            if (_translatedText.isNotEmpty && !_isLoading) ...[
              const SizedBox(height: 16),
              TranslationCard(
                sourceText: _extractedText,
                translatedText: _translatedText,
                sourceLang: 'auto',
                targetLang: _targetLang,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
