/// Centralized Input Validation Rules
class Validator {
  Validator._();

  static String? requiredField(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, [String? message]) {
    if (value == null || value.length < minLength) {
      return message ?? 'Must be at least $minLength characters';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String? message]) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a number';
    }
    final numVal = num.tryParse(value.trim());
    if (numVal == null || numVal <= 0) {
      return message ?? 'Must be a positive number';
    }
    return null;
  }
}
