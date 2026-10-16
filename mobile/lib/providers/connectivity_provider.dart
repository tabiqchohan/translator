import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _isOnline = _hasConnection(await Connectivity().checkConnectivity());
      notifyListeners();
      _sub = Connectivity().onConnectivityChanged.listen((results) {
        final online = _hasConnection(results);
        if (online != _isOnline) {
          _isOnline = online;
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  bool _hasConnection(List<ConnectivityResult> result) {
    return result.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
