import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();
    _user = await _authService.getSession();
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final res = await _authService.login(email: email, password: password);
    if (res['success'] == true && res['user'] != null) {
      _user = res['user'];
    }
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final res = await _authService.register(
      name: name,
      email: email,
      password: password,
    );
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteAccount(String password) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.deleteAccount(password);
    if (success) {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
    return {
      'success': success,
      'error': success
          ? null
          : 'Failed to delete account. Please check your password.',
    };
  }
}
