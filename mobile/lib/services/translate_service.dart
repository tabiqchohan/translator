import '../core/api_client.dart';
import 'ad_service.dart';

class TranslateService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> translateText({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/translate',
        data: {
          'text': text,
          'targetLang': targetLang,
          'sourceLang': sourceLang,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final translated = response.data['text'] ?? '';
        AdService.instance.onTranslationSuccess();
        return {
          'success': true,
          'translatedText': translated,
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'quotaExceeded': true,
          'error': response.data?['message'] ??
              "Today's free translation limit is reached. Please try again tomorrow.",
        };
      } else {
        return {
          'success': false,
          'error': response.data?['message'] ??
              response.data?['error'] ??
              'Translation failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
