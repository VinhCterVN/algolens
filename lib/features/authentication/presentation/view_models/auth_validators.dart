abstract final class AuthValidators {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    return name.isEmpty || name.length > 100 ? 'Enter your name (up to 100 characters).' : null;
  }

  static List<bool> passwordRules(String value) => [
    value.length >= 8,
    RegExp(r'\d').hasMatch(value),
    RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value),
  ];

  static String? password(String? value) =>
      passwordRules(value ?? '').every((rule) => rule) ? null : 'Use 8+ characters, a number, and a symbol.';

  static String? requiredPassword(String? value) => value == null || value.isEmpty ? 'Enter your password.' : null;

  static String? code(String? value) =>
      RegExp(r'^\d{6}$').hasMatch(value ?? '') ? null : 'Enter the 6-digit email code.';
}
