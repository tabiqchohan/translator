import 'package:flutter_test/flutter_test.dart';
import 'package:translater/core/validators.dart';

void main() {
  group('PasswordValidator', () {
    test('rejects empty', () {
      expect(PasswordValidator.validate(''), 'Please fill all fields');
    });

    test('rejects short passwords', () {
      expect(
        PasswordValidator.validate('Ab1@'),
        'Password must be at least 8 characters',
      );
    });

    test('rejects missing uppercase', () {
      expect(
        PasswordValidator.validate('abcd123@'),
        'Password must contain at least 1 uppercase letter',
      );
    });

    test('rejects missing digit', () {
      expect(
        PasswordValidator.validate('Abcdefg@'),
        'Password must contain at least 1 number',
      );
    });

    test('rejects missing special character', () {
      expect(
        PasswordValidator.validate('Abcdefg1'),
        contains('special character'),
      );
    });

    test('accepts a strong password', () {
      expect(PasswordValidator.validate('Abcdefg1@'), isNull);
    });

    test('accepts various special characters', () {
      for (final special in [
        '!',
        '@',
        '#',
        r'$',
        '%',
        '^',
        '&',
        '*',
        r'\',
        '/',
        '?',
        "'",
        '"',
        '~',
        ';',
        '[',
        ']',
        '{',
        '}'
      ]) {
        expect(
          PasswordValidator.validate('Abcdefg1$special'),
          isNull,
          reason: 'special char "$special" should be accepted',
        );
      }
    });
  });
}
