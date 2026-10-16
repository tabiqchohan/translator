import 'package:flutter_test/flutter_test.dart';
import 'package:translater/models/history_entry.dart';
import 'package:translater/models/user.dart';

void main() {
  group('User', () {
    test('fromJson maps fields', () {
      final user = User.fromJson({
        'id': 'u1',
        'name': 'Ali',
        'email': 'ali@example.com',
        'image': 'avatar.png',
      });

      expect(user.id, 'u1');
      expect(user.name, 'Ali');
      expect(user.email, 'ali@example.com');
      expect(user.image, 'avatar.png');
    });

    test('fromJson uses safe defaults for missing fields', () {
      final user = User.fromJson({});

      expect(user.id, '');
      expect(user.name, '');
      expect(user.email, '');
      expect(user.image, isNull);
    });

    test('toJson round-trips', () {
      final user = User(id: 'u2', name: 'Sara', email: 'sara@example.com');
      final json = user.toJson();

      expect(json['id'], 'u2');
      expect(json['name'], 'Sara');
      expect(json['email'], 'sara@example.com');
    });
  });

  group('HistoryEntry', () {
    test('fromJson maps camelCase keys', () {
      final entry = HistoryEntry.fromJson({
        'id': 'h1',
        'userId': 'u1',
        'sourceText': 'Hello',
        'translatedText': 'Hola',
        'sourceLang': 'en',
        'targetLang': 'es',
        'type': 'voice',
        'isFavorite': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(entry.id, 'h1');
      expect(entry.userId, 'u1');
      expect(entry.sourceText, 'Hello');
      expect(entry.translatedText, 'Hola');
      expect(entry.sourceLang, 'en');
      expect(entry.targetLang, 'es');
      expect(entry.type, 'voice');
      expect(entry.isFavorite, isTrue);
      expect(entry.createdAt, isNotNull);
    });

    test('fromJson uses safe defaults', () {
      final entry = HistoryEntry.fromJson({'id': 'h2'});

      expect(entry.sourceText, '');
      expect(entry.translatedText, '');
      expect(entry.sourceLang, 'auto');
      expect(entry.targetLang, 'en');
      expect(entry.type, 'text');
      expect(entry.isFavorite, isFalse);
      expect(entry.createdAt, isNull);
    });

    test('isFavorite is mutable', () {
      final entry = HistoryEntry(
        id: 'h3',
        sourceText: 'a',
        translatedText: 'b',
        sourceLang: 'en',
        targetLang: 'ur',
      );

      expect(entry.isFavorite, isFalse);
      entry.isFavorite = true;
      expect(entry.isFavorite, isTrue);
    });
  });
}
