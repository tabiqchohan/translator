class PasswordValidator {
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _digit = RegExp(r'[0-9]');

  /// Matches at least one special character. Built with a triple-quoted raw
  /// string so that quotes/backslashes inside the class are not mis-parsed.
  static final RegExp _special =
      RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;']''');

  /// Returns an error message, or null when the password is valid.
  static String? validate(String password) {
    if (password.isEmpty) return 'Please fill all fields';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_upper.hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter';
    }
    if (!_digit.hasMatch(password)) {
      return 'Password must contain at least 1 number';
    }
    if (!_special.hasMatch(password)) {
      return r'Password must contain at least 1 special character (!@#$...)';
    }
    return null;
  }
}
