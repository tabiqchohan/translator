import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/login_screen.dart';
import '../screens/live_chat_screen.dart';
import '../screens/keyboard_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/terms_screen.dart';
import '../services/export_service.dart';
import '../widgets/language_selector.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _confirmDeleteAccount(
      BuildContext context, AuthProvider auth) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted == true && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _exportHistory(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final history = Provider.of<HistoryProvider>(context, listen: false);
    if (history.entries.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No history to export yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await const ExportService().exportHistory(history.entries);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not export history. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Profile Card
          if (auth.user != null)
            Container(
              padding: const EdgeInsets.all(18),
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
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        auth.user!.name.isNotEmpty
                            ? auth.user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user!.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user!.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Appearance Header
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (val) {
                if (val != null) settings.setTheme(val);
              },
              child: Column(
                children: [
                  const RadioListTile<ThemeMode>(
                    title: Text('System Default',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    secondary: Icon(Icons.brightness_auto_rounded),
                    value: ThemeMode.system,
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Mode',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    secondary: Icon(Icons.light_mode_rounded,
                        color: Colors.amber.shade600),
                    value: ThemeMode.light,
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                  const RadioListTile<ThemeMode>(
                    title: Text('Dark Mode',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    secondary:
                        Icon(Icons.dark_mode_rounded, color: Color(0xFF8B5CF6)),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Translation Preferences
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'Translation Preferences',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Default Target Language',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                LanguageSelector(
                  selectedCode: settings.defaultTargetLang,
                  allowAuto: false,
                  onChanged: (val) => settings.setDefaultTargetLang(val),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Voice Speech Rate (TTS)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${settings.ttsRate.toStringAsFixed(1)}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.ttsRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  activeColor: primary,
                  onChanged: (val) => settings.setTtsRate(val),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Voice Pitch (TTS)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${settings.ttsPitch.toStringAsFixed(1)}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.ttsPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  activeColor: primary,
                  onChanged: (val) => settings.setTtsPitch(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Live Chat Translate
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'Live Chat',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              leading:
                  const Icon(Icons.flash_on_rounded, color: Color(0xFF6366F1)),
              title: const Text('Live Chat Translate',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: const Text(
                  'Translate WhatsApp, Messenger, Telegram & more in real time'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveChatScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              leading:
                  const Icon(Icons.keyboard_rounded, color: Color(0xFF8B5CF6)),
              title: const Text('LingoVerse Keyboard',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: const Text(
                  'Type in any language and translate inside any chat app'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeyboardScreen()),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Account & Data
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'Account & Data',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_rounded, color: primary),
                  title: const Text('Profile',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9)),
                ListTile(
                  leading: Icon(Icons.download_rounded, color: primary),
                  title: const Text('Export History (CSV)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Share or save your translations'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _exportHistory(context),
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9)),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: primary),
                  title: const Text('Privacy Policy',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9)),
                ListTile(
                  leading: Icon(Icons.gavel_rounded, color: primary),
                  title: const Text('Terms of Service',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sign Out Button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              ),
            ),
            child: TextButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Delete Account Button
          if (auth.user != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
              ),
              child: TextButton.icon(
                onPressed: () => _confirmDeleteAccount(context, auth),
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444)),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.deleteAccount(password);

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _error = res['error'] ?? 'Failed to delete account';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Account',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action is permanent. All your history, favorites and account data will be deleted and cannot be recovered.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon:
                  Icon(Icons.lock_outline_rounded, color: primary, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _delete,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Delete',
                  style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
