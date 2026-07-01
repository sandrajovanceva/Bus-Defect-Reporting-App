import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// A compact language picker (globe icon + current code) used on the login
/// screen and in app bars.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final t = AppLocalizations.of(context);
    final code = locale.languageCode.toUpperCase();

    return PopupMenuButton<Locale>(
      tooltip: code,
      offset: const Offset(0, 44),
      onSelected: (value) =>
          ref.read(localeProvider.notifier).setLocale(value),
      itemBuilder: (_) => [
        _item(const Locale('mk'), t.languageMacedonian, locale),
        _item(const Locale('en'), t.languageEnglish, locale),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              code,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<Locale> _item(Locale value, String label, Locale current) {
    final selected = value.languageCode == current.languageCode;
    return PopupMenuItem<Locale>(
      value: value,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: selected ? AppColors.accent : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}
