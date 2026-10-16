import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            '1. Acceptance of Terms',
            'By using LingoVerse, you agree to these terms. If you do not agree, please discontinue use of the app.',
          ),
          _card(
            context,
            '2. Use of Service',
            'You may use LingoVerse for lawful purposes only. You are responsible for the content you translate and for ensuring you have the right to process it.',
          ),
          _card(
            context,
            '3. Translations',
            'Translations are provided as-is and may not always be perfectly accurate. Use translated content at your own discretion, especially in legal, medical, or safety-critical contexts.',
          ),
          _card(
            context,
            '4. Accounts',
            'You are responsible for keeping your account credentials secure. Notify us immediately if you suspect unauthorized access to your account.',
          ),
          _card(
            context,
            '5. No Warranty',
            'The service is provided on an "as is" and "as available" basis without warranties of any kind, express or implied.',
          ),
          _card(
            context,
            '6. Limitation of Liability',
            'To the maximum extent permitted by law, LingoVerse shall not be liable for any indirect, incidental, or consequential damages arising from your use of the app.',
          ),
          _card(
            context,
            '7. Changes',
            'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the updated terms.',
          ),
          _card(
            context,
            '8. Contact',
            'For questions about these terms, contact us at support@LingoVerse.app.',
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String title, String body) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF131C2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
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
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
