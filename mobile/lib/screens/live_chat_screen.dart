import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/live_chat_service.dart';
import '../widgets/language_selector.dart';

const _knownApps = [
  ('com.whatsapp', 'WhatsApp', Icons.chat_bubble_outline_rounded),
  ('com.facebook.orca', 'Messenger', Icons.forum_outlined),
  ('org.telegram.messenger', 'Telegram', Icons.send_outlined),
  ('com.instagram.android', 'Instagram', Icons.camera_alt_outlined),
  ('com.google.android.apps.messaging', 'SMS (Messages)', Icons.sms_outlined),
  ('com.snapchat.android', 'Snapchat', Icons.face_outlined),
  ('com.viber.voip', 'Viber', Icons.call_outlined),
  ('com.skype.raider', 'Skype', Icons.videocam_outlined),
  ('com.imo.android.imoim', 'IMO', Icons.chat_outlined),
  ('com.linecorp.line', 'LINE', Icons.alternate_email),
  ('com.tencent.mm', 'WeChat', Icons.mark_chat_unread_outlined),
];

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<LiveChatService>();
      svc.refreshStatus();
      if (!svc.notifPermGranted) svc.requestNotificationPermission();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Chat Translate'),
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
          // Master toggle
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: service.enabled
                  ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                  : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: service.enabled
                    ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                    : borderColor,
              ),
            ),
            child: SwitchListTile(
              value: service.enabled,
              onChanged: (v) {
                service.setEnabled(v);
                if (v && !service.notifPermGranted) {
                  service.requestNotificationPermission();
                }
              },
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF6366F1),
              title: const Text(
                'Live Chat Translation',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              subtitle: Text(
                service.enabled
                    ? 'Active — messages from enabled chat apps are translated'
                    : 'Turn on to translate chat messages in real time',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Permissions & engines
          _sectionTitle(context, 'Engines & Permissions'),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _permissionTile(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Notification reader',
                  subtitle: 'Incoming messages from any chat app',
                  granted: service.notifGranted,
                  running: service.notifRunning,
                  onOpen: service.openNotifPermission,
                  license: 'required',
                ),
                _divider(borderColor),
                _permissionTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notification permission',
                  subtitle: 'Lets LingoVerse show translations (Android 13+)',
                  granted: service.notifPermGranted,
                  running: service.notifPermGranted,
                  onOpen: () => service.notifPermGranted
                      ? service.openAppNotificationSettings()
                      : service.requestNotificationPermission(),
                  license: 'required',
                ),
                _divider(borderColor),
                _permissionTile(
                  context,
                  icon: Icons.splitscreen_outlined,
                  title: 'Floating bubble (overlay)',
                  subtitle: 'Shows translations on top of chat apps',
                  granted: service.canDrawOverlay,
                  running: false,
                  onOpen: service.openOverlayPermission,
                  license: 'required',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chat apps
          _sectionTitle(context, 'Chat Apps to Translate'),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _knownApps.length; i++)
                  _appTile(context, service, _knownApps[i].$1, _knownApps[i].$2,
                      _knownApps[i].$3, i, borderColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Translation preferences
          _sectionTitle(context, 'Translation'),
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
                const Text(
                  'Translate into',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                LanguageSelector(
                  selectedCode: service.targetLang,
                  allowAuto: false,
                  onChanged: (code) => service.setTargetLang(code),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: service.notify,
                  onChanged: (v) => service.setNotify(v),
                  title: const Text('Show in notification bar',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                      'Persistent notification — stays until you dismiss it'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: service.bubble,
                  onChanged: (v) => service.setBubble(v),
                  title: const Text('Floating bubble',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle:
                      const Text('Quick bubble over the chat that auto-hides'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: service.bubbleDark,
                  onChanged: (v) => service.setBubbleDark(v),
                  title: const Text('Dark theme bubble',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Dark style for the bubble & reply bar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reply translator
          _sectionTitle(context, 'Reply Translator'),
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
                  'Opens a floating bar over any chat. Type your reply, translate it '
                  'into the other person\'s language, then copy & paste it.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (!service.canDrawOverlay) {
                        service.openOverlayPermission();
                      } else {
                        service.showReplyBar();
                      }
                    },
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: const Text('Open reply translator',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // History
          _sectionTitle(context, 'Live Translation History'),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                if (service.history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 36, color: primary.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Text(
                          'No live translations yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final h in service.history.take(10))
                    _historyTile(context, h),
                _divider(borderColor),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => service.sendTestMessage(),
                      icon: const Icon(Icons.science_outlined, size: 18),
                      label: const Text('Test sample message'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => service.clearHistory(),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'The notification reader picks up incoming messages from the chat apps you '
                  'enable. Each translation is posted as a persistent notification (with Copy, '
                  'Reply and Dismiss buttons) and optionally shown as a floating bubble. The '
                  'Reply translator helps you compose a reply in the other person\'s language. '
                  'Everything is translated on LingoVerse servers and only your last 100 live '
                  'translations are stored on this device.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: theme.textTheme.bodySmall?.color),
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

  Widget _divider(Color borderColor) => Divider(height: 1, color: borderColor);

  Widget _permissionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool granted,
    required bool running,
    required VoidCallback onOpen,
    required String license,
  }) {
    final theme = Theme.of(context);
    final color =
        granted && running ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: license == 'required'
                  ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              license,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: license == 'required'
                    ? const Color(0xFF6366F1)
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(subtitle,
          style:
              TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
      trailing: granted && running
          ? const Icon(Icons.check_circle_rounded,
              color: Color(0xFF16A34A), size: 22)
          : TextButton(
              onPressed: onOpen,
              child: const Text('Enable',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _appTile(BuildContext context, LiveChatService service, String pkg,
      String name, IconData icon, int index, Color borderColor) {
    final enabled = service.apps.contains(pkg);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        final next = Set<String>.from(service.apps);
        if (enabled) {
          next.remove(pkg);
        } else {
          next.add(pkg);
        }
        service.setApps(next);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Checkbox(
              value: enabled,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                final next = Set<String>.from(service.apps);
                enabled ? next.remove(pkg) : next.add(pkg);
                service.setApps(next);
              },
              activeColor: const Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(BuildContext context, Map<String, dynamic> h) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Text(h['translated'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(
        '${h['source'] ?? 'Chat'} • ${AppConstants.getLanguageName((h['targetLang'] ?? 'en').toString())}\n${h['original'] ?? ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
      ),
    );
  }
}
