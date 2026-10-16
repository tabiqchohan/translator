import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_entry.dart';

class ExportService {
  const ExportService();

  /// Exports history entries as a CSV file and opens the share sheet.
  Future<void> exportHistory(List<HistoryEntry> entries) async {
    if (entries.isEmpty) {
      throw Exception('No history to export');
    }

    final rows = <List<dynamic>>[
      [
        'Source Text',
        'Translated Text',
        'Source Language',
        'Target Language',
        'Type',
        'Favorite',
        'Created At',
      ],
      for (final e in entries)
        [
          e.sourceText,
          e.translatedText,
          e.sourceLang,
          e.targetLang,
          e.type,
          e.isFavorite ? 'yes' : 'no',
          e.createdAt?.toIso8601String() ?? '',
        ],
    ];

    final csvData = Csv().encode(rows);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/translater_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'LingoVerse History',
        text: 'My translation history exported from LingoVerse',
      ),
    );
  }
}
