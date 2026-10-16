import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        String error = 'Registration failed';
        if (data is Map && data['error'] != null) {
          error = data['error'].toString();
        }
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Fetch CSRF Token
      final csrfRes = await _client.dio.get('/api/auth/csrf');
      dynamic csrfData = csrfRes.data;
      if (csrfData is String) {
        try {
          csrfData = jsonDecode(csrfData);
        } catch (_) {}
      }

      String csrfToken = '';
      if (csrfData is Map && csrfData['csrfToken'] != null) {
        csrfToken = csrfData['csrfToken'].toString();
      }

      // Step 2: POST credentials with urlencoded body
      final response = await _client.dio.post(
        '/api/auth/callback/credentials',
        data: {
          'email': email.trim(),
          'password': password,
          'csrfToken': csrfToken,
          'callbackUrl': '/',
          'json': 'true',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => true,
        ),
      );

      // NextAuth returns 200 or 302/redirect
      // Let's check session to confirm authentication
      final user = await getSession();
      if (user != null) {
        return {'success': true, 'user': user};
      } else {
        dynamic data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        String errorMsg = 'Invalid email or password';
        if (data is Map && data['error'] != null) {
          errorMsg = data['error'].toString();
        } else if (data is Map &&
            data['url'] != null &&
            data['url'].toString().contains('error=')) {
          errorMsg = 'Invalid email or password';
        }
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Login error: ${e.toString()}'};
    }
  }

  Future<User?> getSession() async {
    try {
      final response = await _client.dio.get('/api/auth/session');
      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (response.statusCode == 200 &&
          data is Map &&
          data['user'] != null &&
          data['user'] is Map) {
        return User.fromJson(Map<String, dynamic>.from(data['user']));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final csrfRes = await _client.dio.get('/api/auth/csrf');
      dynamic csrfData = csrfRes.data;
      if (csrfData is String) {
        try {
          csrfData = jsonDecode(csrfData);
        } catch (_) {}
      }
      String csrfToken = '';
      if (csrfData is Map && csrfData['csrfToken'] != null) {
        csrfToken = csrfData['csrfToken'].toString();
      }

      await _client.dio.post(
        '/api/auth/signout',
        data: {'csrfToken': csrfToken, 'json': 'true'},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => true,
        ),
      );
    } catch (_) {}
    await _client.clearCookies();
  }

  Future<bool> deleteAccount(String password) async {
    try {
      final response = await _client.dio.post(
        '/api/account/delete',
        data: {'password': password},
      );
      if (response.statusCode == 200) {
        await _client.clearCookies();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
