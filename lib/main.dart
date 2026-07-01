import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/settings/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialLocale = await loadInitialLocale();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(() => LocaleController(initialLocale)),
      ],
      child: const BusDefectApp(),
    ),
  );
}
