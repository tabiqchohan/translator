import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/translate_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation_card.dart';

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final TranslateService _translateService = TranslateService();

  File? _imageFile;
  String _extractedText = '';
  String _translatedText = '';
  String _targetLang = 'ur';
  bool _isOcrLoading = false;
  bool _isTranslating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _targetLang = settings.defaultTargetLang;
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _extractedText = '';
          _translatedText = '';
          _errorMessage = null;
        });
        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not open image: $e');
      }
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;
    setState(() {
      _isOcrLoading = true;
      _errorMessage = null;
    });

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();

      if (!mounted) return;

      setState(() {
        _extractedText = text;
        _isOcrLoading = false;
        if (text.isEmpty) {
          _errorMessage =
              'No readable text found in the image. Try another photo.';
        }
      });

      if (text.isNotEmpty) {
        await _translate(text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOcrLoading = false;
          _errorMessage = 'Failed to scan image: $e';
        });
      }
    }
  }

  Future<void> _translate(String text) async {
    setState(() {
      _isTranslating = true;
      _errorMessage = null;
    });

    final res = await _translateService.translateText(
      text: text,
      targetLang: _targetLang,
      sourceLang: 'auto',
    );

    if (mounted) {
      if (res['success'] == true) {
        final output = res['translatedText'] ?? '';
        setState(() {
          _translatedText = output;
          _isTranslating = false;
        });

        final history = Provider.of<HistoryProvider>(context, listen: false);
        history.addEntry(
          sourceText: text,
          translatedText: output,
          sourceLang: 'auto',
          targetLang: _targetLang,
          type: 'camera',
        );
        Provider.of<SettingsProvider>(context, listen: false)
            .incrementTranslateCount();
      } else {
        setState(() {
          _isTranslating = false;
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
                      onChanged: (val) {
                        setState(() => _targetLang = val);
                        if (_extractedText.isNotEmpty) {
                          _translate(_extractedText);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Camera Viewport Card
            Container(
              height: 220,
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
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.document_scanner_rounded,
                              size: 40, color: primary),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Scan text from camera or photo',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded,
                                  size: 18),
                              label: const Text('Camera'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded,
                                  size: 18),
                              label: const Text('Gallery'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake Photo'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_rounded),
                    label: const Text('Pick Another'),
                  ),
                ],
              ),
            ],

            if (_isOcrLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Scanning text with AI OCR...',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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

            if (_extractedText.isNotEmpty && !_isOcrLoading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
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
                        Icon(Icons.text_snippet_rounded,
                            size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          'Extracted Text:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_extractedText,
                        style: const TextStyle(fontSize: 15, height: 1.4)),
                  ],
                ),
              ),
            ],

            if (_isTranslating)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_translatedText.isNotEmpty && !_isTranslating) ...[
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
