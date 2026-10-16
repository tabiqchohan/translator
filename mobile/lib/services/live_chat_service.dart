import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the native live-chat translator: method channel for control and
/// an event stream for status + translation events coming from the background
/// notification/accessibility services.
class LiveChatService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('com.tabiqchohan.translater/live_chat');
  static const EventChannel _events =
      EventChannel('com.tabiqchohan.translater/live_chat/events');

  bool _initialized = false;
  bool _enabled = false;
  bool _notifGranted = false;
  bool _notifRunning = false;
  bool _accGranted = false;
  bool _accRunning = false;
  bool _bubbleDark = false;
  bool _autoReply = false;
  bool _canDrawOverlay = false;
  bool _notify = true;
  bool _bubble = false;
  bool _keyboardEnabled = false;
  bool _notifPermGranted = true;
  String _targetLang = 'en';
  String _keyboardLang = 'en';
  Set<String> _apps = {};
  List<Map<String, dynamic>> _history = [];
  StreamSubscription<Object?>? _sub;

  bool get enabled => _enabled;
  bool get notifGranted => _notifGranted;
  bool get notifRunning => _notifRunning;
  bool get accGranted => _accGranted;
  bool get accRunning => _accRunning;
  bool get bubbleDark => _bubbleDark;
  bool get autoReply => _autoReply;
  bool get canDrawOverlay => _canDrawOverlay;
  bool get notify => _notify;
  bool get bubble => _bubble;
  bool get keyboardEnabled => _keyboardEnabled;
  bool get notifPermGranted => _notifPermGranted;
  String get targetLang => _targetLang;
  String get keyboardLang => _keyboardLang;
  Set<String> get apps => Set.unmodifiable(_apps);
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _sub = _events.receiveBroadcastStream().listen(_onEvent, onError: (_) {});
    } catch (_) {}
    await refreshStatus();
    await loadHistory();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(Object? event) {
    if (event is! Map) return;
    final type = event['type'];
    if (type == 'translated') {
      _history.insert(
        0,
        {
          'id':
              '${event['timestamp'] ?? DateTime.now().millisecondsSinceEpoch}',
          'source': event['source'] ?? 'Chat',
          'original': event['original'] ?? '',
          'translated': event['translated'] ?? '',
          'targetLang': event['targetLang'] ?? 'en',
          'timestamp':
              event['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (_history.length > 50) _history = _history.sublist(0, 50);
      notifyListeners();
    } else if (type == 'status') {
      _applyStatus({'settings': event['settings']});
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    try {
      final status =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
      _applyStatus(status);
      notifyListeners();
    } catch (_) {}
  }

  void _applyStatus(Map<dynamic, dynamic>? status) {
    if (status == null) return;
    final s = (status['settings'] as Map<dynamic, dynamic>?) ?? const {};
    _enabled = s['lc_enabled'] == true;
    _notifGranted = s['lc_notif_granted'] == true;
    _notifRunning = s['lc_notif_running'] == true;
    _accGranted = s['lc_accessibility_granted'] == true;
    _accRunning = s['lc_acc_running'] == true;
    _bubbleDark = s['lc_bubble_dark'] == true;
    _autoReply = s['lc_auto_reply'] == true;
    _notify = s['lc_notify'] != false;
    _bubble = s['lc_bubble'] == true;
    _targetLang = (s['lc_target_lang'] as String?) ?? 'en';
    _keyboardLang = (s['lc_kb_lang'] as String?) ?? 'en';
    final rawApps = s['lc_apps'];
    if (rawApps is List) {
      _apps = rawApps.whereType<String>().toSet();
    }
    _canDrawOverlay = status['canDrawOverlay'] == true;
    _keyboardEnabled = status['keyboardEnabled'] == true;
    _notifPermGranted = status['notifPermGranted'] != false;
  }

  Future<void> setEnabled(bool value) async {
    await _safe('setEnabled', {'enabled': value});
    _enabled = value;
    notifyListeners();
  }

  Future<void> setTargetLang(String code) async {
    await _safe('setTargetLang', {'lang': code});
    _targetLang = code;
    notifyListeners();
  }

  Future<void> setApps(Set<String> apps) async {
    await _safe('setApps', {'apps': apps.toList()});
    _apps = Set.from(apps);
    notifyListeners();
  }

  Future<void> setBubbleDark(bool dark) async {
    await _safe('setBubbleDark', {'dark': dark});
    _bubbleDark = dark;
    notifyListeners();
  }

  Future<void> setAutoReply(bool value) async {
    await _safe('setAutoReply', {'autoReply': value});
    _autoReply = value;
    notifyListeners();
  }

  Future<void> setNotify(bool value) async {
    await _safe('setNotify', {'notify': value});
    _notify = value;
    notifyListeners();
  }

  Future<void> setBubble(bool value) async {
    await _safe('setBubble', {'bubble': value});
    _bubble = value;
    notifyListeners();
  }

  Future<void> setKeyboardLang(String code) async {
    await _safe('setKeyboardLang', {'lang': code});
    _keyboardLang = code;
    notifyListeners();
  }

  Future<void> openKeyboardSettings() =>
      _safe('openKeyboardSettings', const {});

  Future<void> showKeyboardPicker() => _safe('showKeyboardPicker', const {});

  /// Requests the Android 13+ POST_NOTIFICATIONS runtime permission.
  Future<void> requestNotificationPermission() async {
    await _safe('requestNotificationPermission', const {});
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await refreshStatus();
  }

  Future<void> openAppNotificationSettings() =>
      _safe('openAppNotificationSettings', const {});

  Future<void> showReplyBar({String source = 'Chat'}) =>
      _safe('showReplyBar', {'source': source});

  Future<void> hideReplyBar() => _safe('hideReplyBar', const {});

  Future<void> hideBubble() => _safe('hideBubble', const {});

  /// Simulates an incoming message so the whole pipeline can be tested
  /// (translate -> bubble -> history) without a real chat app.
  Future<void> sendTestMessage({
    String text = 'Aap kaisay hain?',
    String source = 'Test chat',
  }) =>
      _safe('testMessage', {'text': text, 'source': source});

  Future<void> openNotifPermission() => _safe('openNotifPermission', const {});
  Future<void> openAccessibilityPermission() =>
      _safe('openAccessibilityPermission', const {});
  Future<void> openOverlayPermission() =>
      _safe('openOverlayPermission', const {});

  Future<void> loadHistory() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getHistory');
      _history = (raw ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => {
                'id': '${e['id'] ?? DateTime.now().millisecondsSinceEpoch}',
                'source': e['source'] ?? 'Chat',
                'original': e['original'] ?? '',
                'translated': e['translated'] ?? '',
                'targetLang': e['targetLang'] ?? 'en',
                'timestamp':
                    e['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
              })
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    await _safe('clearHistory', const {});
    _history = [];
    notifyListeners();
  }

  Future<void> _safe(String method, Map<String, dynamic> args) async {
    try {
      await _channel.invokeMethod(method, args);
    } catch (_) {}
  }
}
