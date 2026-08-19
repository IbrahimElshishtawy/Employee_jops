class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegExp = RegExp(
    r'^(?:\+20|0)?1[0125]\d{8}$|^[+]?[0-9]{9,15}$',
  );

  static final RegExp _nationalIdRegExp = RegExp(
    r'^[23]\d{13}$',
  );

  static String? required(String? value, [String message = 'هذا الحقل مطلوب']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value, [String message = 'يرجى إدخال بريد إلكتروني صحيح']) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? phone(String? value, [String message = 'يرجى إدخال رقم هاتف صحيح']) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    final clean = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!_phoneRegExp.hasMatch(clean)) {
      return message;
    }
    return null;
  }

  static String? nationalId(String? value, [String message = 'يرجى إدخال رقم قومي صحيح مكون من 14 رقم']) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    final clean = value.trim();
    if (!_nationalIdRegExp.hasMatch(clean)) {
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

  static String? maxLength(String? value, int max, [String? message]) {
    if (value != null && value.trim().length > max) {
      return message ?? 'يجب ألا يتجاوز النص $max حرفاً';
    }
    return null;
  }
}
