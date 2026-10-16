import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';
import '../services/history_service.dart';

class HistoryProvider extends ChangeNotifier {
  static const _cacheKey = 'historyCache';

  final HistoryService _historyService = HistoryService();
  List<HistoryEntry> _entries = [];
  bool _isLoading = false;

  List<HistoryEntry> get entries => _entries;
  List<HistoryEntry> get favorites =>
      _entries.where((e) => e.isFavorite).toList();
  bool get isLoading => _isLoading;

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    final entries = await _historyService.getHistory();
    if (entries.isEmpty) {
      _entries = await _loadCache();
    } else {
      _entries = entries;
      await _saveCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
    String type = 'text',
  }) async {
    final entry = await _historyService.saveHistory(
      sourceText: sourceText,
      translatedText: translatedText,
      sourceLang: sourceLang,
      targetLang: targetLang,
      type: type,
    );
    if (entry != null) {
      _entries.insert(0, entry);
      notifyListeners();
      await _saveCache();
    }
  }

  Future<bool> deleteEntry(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return false;
    final removed = _entries.removeAt(index);
    notifyListeners();

    final success = await _historyService.deleteHistory(id);
    if (success) {
      await _saveCache();
    } else {
      _entries.insert(index, removed);
      notifyListeners();
    }
    return success;
  }

  /// Restores an entry that was optimistically removed (used for undo).
  void restoreEntry(HistoryEntry entry, int index) {
    if (_entries.any((e) => e.id == entry.id)) return;
    final safeIndex = index.clamp(0, _entries.length);
    _entries.insert(safeIndex, entry);
    notifyListeners();
    _saveCache();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final previous = _entries[index].isFavorite;
    _entries[index].isFavorite = !previous;
    notifyListeners();

    final success = await _historyService.toggleFavorite(id);
    if (success) {
      await _saveCache();
    } else {
      final current = _entries.indexWhere((e) => e.id == id);
      if (current != -1) {
        _entries[current].isFavorite = previous;
        notifyListeners();
      }
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, json);
    } catch (_) {}
  }

  Future<List<HistoryEntry>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => HistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
