import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

/// Controller managing application locale, language switching, and persistence
class LocaleController extends ChangeNotifier {
  static const String _storageKey = 'selected_locale';
  static const Locale defaultLocale = Locale('en');

  final LocalStorage _localStorage;
  late Locale _locale;

  LocaleController(this._localStorage) {
    _loadSavedLocale();
  }

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  void _loadSavedLocale() {
    final savedCode = _localStorage.getString(_storageKey);
    if (savedCode == 'ar') {
      _locale = const Locale('ar');
    } else {
      _locale = const Locale('en');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    await _localStorage.setString(_storageKey, newLocale.languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    await setLocale(Locale(code == 'ar' ? 'ar' : 'en'));
  }

  Future<void> toggleLocale() async {
    if (isArabic) {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('ar'));
    }
  }
}
