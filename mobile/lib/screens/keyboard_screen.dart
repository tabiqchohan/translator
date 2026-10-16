import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/live_chat_service.dart';
import '../widgets/language_selector.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveChatService>().refreshStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<LiveChatService>().refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final service = context.watch<LiveChatService>();

    final cardColor = isDark ? const Color(0xFF131C2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final enabled = service.keyboardEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LingoVerse Keyboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh status',
            onPressed: () => service.refreshStatus(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: enabled
                    ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  enabled
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: enabled
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    enabled
                        ? 'Keyboard is enabled. Switch to it in any chat and start typing.'
                        : 'Keyboard is not enabled yet. Enable it below.',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          _sectionTitle(context, 'Setup'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => service.openKeyboardSettings(),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                    label: const Text('1. Enable LingoVerse Keyboard',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => service.showKeyboardPicker(),
                    icon: const Icon(Icons.keyboard_rounded, size: 18),
                    label: const Text('2. Switch to LingoVerse Keyboard',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Target language
          _sectionTitle(context, 'Translate into'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick the language you want your message translated into. '
                  'The keyboard remembers your choice.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                LanguageSelector(
                  selectedCode: service.keyboardLang,
                  allowAuto: false,
                  onChanged: (code) => service.setKeyboardLang(code),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current: ${AppConstants.getLanguageName(service.keyboardLang)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // How to use
          _sectionTitle(context, 'How to use'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _step(context, '1',
                    'Enable the keyboard once (button above), then switch to it.'),
                _step(context, '2',
                    'Open WhatsApp or any chat and type your message normally (e.g. in Roman Urdu).'),
                _step(context, '3',
                    'Tap "Translate" on the keyboard bar — your text is replaced with the translation.'),
                _step(context, '4', 'Press Send in the chat app.'),
                const SizedBox(height: 4),
                Text(
                  'Note: the keyboard only translates what you typed with it. '
                  'Translation happens on LingoVerse servers.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: primary),
      ),
    );
  }

  Widget _step(BuildContext context, String n, String text) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
