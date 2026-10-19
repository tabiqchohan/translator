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
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
  static const _indigo = Color(0xFF6366F1);

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
    final service = context.watch<LiveChatService>();
    final enabled = service.keyboardEnabled;

    final cardColor = isDark ? const Color(0xFF131C2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _hero(theme, enabled),
          const SizedBox(height: 24),

          _sectionTitle(context, 'Setup'),
          _card(
            cardColor: cardColor,
            borderColor: borderColor,
            child: Column(
              children: [
                _actionButton(
                  label: 'Enable LingoVerse Keyboard',
                  step: '1',
                  icon: Icons.settings_suggest_rounded,
                  filled: true,
                  onTap: service.openKeyboardSettings,
                ),
                const SizedBox(height: 12),
                _actionButton(
                  label: 'Switch to LingoVerse Keyboard',
                  step: '2',
                  icon: Icons.keyboard_rounded,
                  filled: false,
                  onTap: service.showKeyboardPicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle(context, 'Translate into'),
          _card(
            cardColor: cardColor,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick the language you want your message translated into. '
                  'The keyboard remembers your choice.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 14),
                LanguageSelector(
                  selectedCode: service.keyboardLang,
                  allowAuto: false,
                  onChanged: (code) => service.setKeyboardLang(code),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate_rounded,
                          size: 15, color: _indigo),
                      const SizedBox(width: 6),
                      Text(
                        'Current: ${AppConstants.getLanguageName(service.keyboardLang)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle(context, 'How to use'),
          _card(
            cardColor: cardColor,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _step(context, '1',
                    'Enable the keyboard once (button above), then switch to it.'),
                _step(context, '2',
                    'Open WhatsApp or any chat and type your message normally (e.g. in Roman Urdu).'),
                _step(context, '3',
                    'Tap "Translate" on the keyboard bar — your text is replaced with the translation.'),
                _step(context, '4', 'Press Send in the chat app.', last: true),
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
        ],
      ),
    );
  }

  Widget _hero(ThemeData theme, bool enabled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.keyboard_alt_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translate while you type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enabled
                      ? 'Ready — switch to it in any chat.'
                      : 'Set up in 2 quick steps.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        enabled
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 14,
                        color: enabled
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        enabled ? 'Enabled' : 'Not enabled',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: enabled
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required String step,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final child = Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled
                ? Colors.white.withValues(alpha: 0.22)
                : _indigo.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : _indigo,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 18, color: filled ? Colors.white : _indigo),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: filled ? Colors.white : _indigo,
            ),
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            size: 20, color: filled ? Colors.white : _indigo),
      ],
    );

    return Material(
      color: filled ? _indigo : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: _indigo.withValues(alpha: 0.5), width: 1.4),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _card({
    required Color cardColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: primary),
      ),
    );
  }

  Widget _step(BuildContext context, String n, String text,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 14 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _gradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
