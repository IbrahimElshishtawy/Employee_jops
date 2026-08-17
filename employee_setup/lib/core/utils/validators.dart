class Validators {
  Validators._();

  static String? required(String? value, [String message = 'هذا الحقل مطلوب']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? positiveNumber(String? value, [String message = 'يرجى إدخال مبلغ صحيح أكبر من الصفر']) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num <= 0) {
      return message;
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? message]) {
    if (value == null || value.trim().length < min) {
      return message ?? 'يجب ألا يقل النص عن $min أحرف';
    }
    return null;
  }
}
