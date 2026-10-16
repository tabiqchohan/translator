import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  late PersistCookieJar cookieJar;
  bool _initialized = false;

  ApiClient._internal();

  Future<void> init() async {
    if (_initialized) return;

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String cookiePath = '${appDocDir.path}/.cookies/';
    cookieJar = PersistCookieJar(
      storage: FileStorage(cookiePath),
      ignoreExpires: true,
    );

    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'LingoVerse-Mobile-App/2.0',
        },
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    _initialized = true;
  }

  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }
}
