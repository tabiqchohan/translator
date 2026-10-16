/// Lightweight, offline language detector based on Unicode script ranges.
///
/// The backend `/api/translate` endpoint does not return a detected language,
/// so this is used to show a "Detected" badge when the source language is
/// set to auto. It intentionally only reports non-Latin scripts (and Urdu vs
/// Arabic) where detection is reliable, returning null otherwise.
class LanguageDetector {
  static String? detect(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final counts = <String, int>{};
    var urduMarkers = 0;
    for (final rune in trimmed.runes) {
      final script = _scriptFor(rune);
      if (script == null) continue;
      counts[script] = (counts[script] ?? 0) + 1;
      if (_isUrduMarker(rune)) urduMarkers++;
    }
    if (counts.isEmpty) return null;

    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0 || top.value / total < 0.25) return null;

    switch (top.key) {
      case 'arabic':
        return urduMarkers > 0 ? 'ur' : 'ar';
      case 'devanagari':
        return 'hi';
      case 'bengali':
        return 'bn';
      case 'gurmukhi':
        return 'pa';
      case 'gujarati':
        return 'gu';
      case 'tamil':
        return 'ta';
      case 'telugu':
        return 'te';
      case 'kannada':
        return 'kn';
      case 'malayalam':
        return 'ml';
      case 'greek':
        return 'el';
      case 'hebrew':
        return 'he';
      case 'thai':
        return 'th';
      case 'myanmar':
        return 'my';
      case 'georgian':
        return 'ka';
      case 'armenian':
        return 'hy';
      case 'cyrillic':
        return 'ru';
      case 'hangul':
        return 'ko';
      case 'kana':
        return 'ja';
      case 'han':
        return counts.containsKey('kana') ? 'ja' : 'zh';
      default:
        return null;
    }
  }

  static bool _isUrduMarker(int rune) {
    // Urdu-specific Arabic letters (not used in standard Arabic).
    const urduOnly = {
      0x0679, // ٹ
      0x0688, // ڈ
      0x0691, // ڑ
      0x0686, // چ (also Persian)
      0x06BE, // ھ
      0x06C1, // ہ
      0x06D2, // ے
      0x06BA, // ں
      0x06AF, // گ (also Persian)
      0x067E, // پ (also Persian)
      0x06CC, // ی (also Persian)
    };
    return urduOnly.contains(rune);
  }

  static String? _scriptFor(int rune) {
    if (_inRange(rune, 0x0600, 0x06FF) || _inRange(rune, 0x0750, 0x077F)) {
      return 'arabic';
    }
    if (_inRange(rune, 0x0900, 0x097F)) return 'devanagari';
    if (_inRange(rune, 0x0980, 0x09FF)) return 'bengali';
    if (_inRange(rune, 0x0A00, 0x0A7F)) return 'gurmukhi';
    if (_inRange(rune, 0x0A80, 0x0AFF)) return 'gujarati';
    if (_inRange(rune, 0x0B80, 0x0BFF)) return 'tamil';
    if (_inRange(rune, 0x0C00, 0x0C7F)) return 'telugu';
    if (_inRange(rune, 0x0C80, 0x0CFF)) return 'kannada';
    if (_inRange(rune, 0x0D00, 0x0D7F)) return 'malayalam';
    if (_inRange(rune, 0x0370, 0x03FF)) return 'greek';
    if (_inRange(rune, 0x0590, 0x05FF)) return 'hebrew';
    if (_inRange(rune, 0x0E00, 0x0E7F)) return 'thai';
    if (_inRange(rune, 0x1000, 0x109F)) return 'myanmar';
    if (_inRange(rune, 0x10A0, 0x10FF)) return 'georgian';
    if (_inRange(rune, 0x0530, 0x058F)) return 'armenian';
    if (_inRange(rune, 0x0400, 0x04FF)) return 'cyrillic';
    if (_inRange(rune, 0xAC00, 0xD7AF)) return 'hangul';
    if (_inRange(rune, 0x3040, 0x30FF)) return 'kana';
    if (_inRange(rune, 0x4E00, 0x9FFF)) return 'han';
    return null;
  }

  static bool _inRange(int rune, int start, int end) =>
      rune >= start && rune <= end;
}
