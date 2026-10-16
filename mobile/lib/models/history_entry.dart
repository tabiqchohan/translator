class HistoryEntry {
  final String id;
  final String? userId;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String type;
  bool isFavorite;
  final DateTime? createdAt;

  HistoryEntry({
    required this.id,
    this.userId,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    this.type = 'text',
    this.isFavorite = false,
    this.createdAt,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] ?? '',
      userId: json['userId'],
      sourceText: json['sourceText'] ?? '',
      translatedText: json['translatedText'] ?? '',
      sourceLang: json['sourceLang'] ?? 'auto',
      targetLang: json['targetLang'] ?? 'en',
      type: json['type'] ?? 'text',
      isFavorite: json['isFavorite'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sourceText': sourceText,
      'translatedText': translatedText,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'type': type,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
