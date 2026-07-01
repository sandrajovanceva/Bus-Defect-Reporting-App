import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _localeKey = 'locale_code';
const FlutterSecureStorage _storage = FlutterSecureStorage();

/// Macedonian is the default language for JSP staff.
const Locale defaultLocale = Locale('mk');

/// Reads the saved language before the app starts (called from main()).
Future<Locale> loadInitialLocale() async {
  try {
    final code = await _storage.read(key: _localeKey);
    if (code == 'en') return const Locale('en');
  } on Exception {
    // Ignore storage errors and fall back to the default.
  }
  return defaultLocale;
}

class LocaleController extends Notifier<Locale> {
  LocaleController(this._initial);

  final Locale _initial;

  @override
  Locale build() => _initial;

  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    state = locale;
    try {
      await _storage.write(key: _localeKey, value: locale.languageCode);
    } on Exception {
      // Persisting is best-effort; the in-memory switch already applied.
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  () => LocaleController(defaultLocale),
);
