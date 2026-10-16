import '../core/api_client.dart';
import '../models/history_entry.dart';

class HistoryService {
  final ApiClient _client = ApiClient();

  Future<List<HistoryEntry>> getHistory() async {
    try {
      final response = await _client.dio.get('/api/history');
      if (response.statusCode == 200 && response.data?['entries'] != null) {
        final List list = response.data['entries'];
        return list.map((e) => HistoryEntry.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<HistoryEntry?> saveHistory({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
    String type = 'text',
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/history',
        data: {
          'sourceText': sourceText,
          'translatedText': translatedText,
          'sourceLang': sourceLang,
          'targetLang': targetLang,
          'type': type,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data?['entry'] != null) {
        return HistoryEntry.fromJson(response.data['entry']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteHistory(String id) async {
    try {
      final response = await _client.dio.delete(
        '/api/history',
        queryParameters: {'id': id},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String id) async {
    try {
      final response = await _client.dio.patch(
        '/api/history',
        queryParameters: {'id': id},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
