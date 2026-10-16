import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StaticContentScreen(
      title: 'Privacy Policy',
      sections: [
        _Section(
          title: '1. Data We Collect',
          body:
              'LingoVerse processes text, speech, and images you provide in order to produce translations. '
              'This content may be sent to our translation servers to deliver the service. '
              'We also collect account information (name, email) when you sign up. '
              'Your translation history and favorites are stored so you can review them later.',
        ),
        _Section(
          title: '2. How We Use Data',
          body:
              'Your data is used solely to provide translation services, save your history, and keep the app functional. '
              'We do not sell your personal data to third parties.',
        ),
        _Section(
          title: '3. On-Device Processing',
          body:
              'When possible, language detection and speech recognition run on your device. '
              'Translated content is transmitted to our API only when you perform a translation.',
        ),
        _Section(
          title: '4. Data Retention',
          body: 'Translation history is retained until you delete it. '
              'You can delete individual entries or your entire account at any time, which removes your stored data.',
        ),
        _Section(
          title: '5. Contact',
          body: 'For privacy questions, contact us at support@translater.app.',
        ),
      ],
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}

class _StaticContentScreen extends StatelessWidget {
  final String title;
  final List<_Section> sections;
  const _StaticContentScreen({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF131C2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in sections)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: theme.textTheme.bodySmall?.color,
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
