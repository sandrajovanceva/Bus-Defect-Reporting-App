import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/bus_service.dart';

/// Bus number picker, backed by the fleet registry.
///
/// This replaces a free-text field. With ~300 buses a plain dropdown is a long
/// scroll on a phone, so this filters as you type: a driver types "22" and
/// sees 1122, 1222, 2122 and the rest. Only a number that exists can be submitted, which
/// is the whole point of the registry.
class BusPickerField extends ConsumerWidget {
  const BusPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busesState = ref.watch(busesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.fieldBusNumber.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        busesState.when(
          loading: () => const _PickerShell(
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
          error: (error, _) => _PickerShell(
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.busesLoadFailed,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(busesProvider),
                  child: Text(t.actionRefresh),
                ),
              ],
            ),
          ),
          data: (buses) {
            return DropdownMenu<String>(
              initialSelection: value,
              enabled: enabled,
              width: double.infinity,
              enableFilter: true,
              requestFocusOnTap: true,
              hintText: t.reportBusHint,
              errorText: errorText,
              leadingIcon: const Icon(
                Icons.directions_bus_filled_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              menuHeight: 320,
              textStyle: theme.textTheme.bodyLarge,
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
              onSelected: onChanged,
              dropdownMenuEntries: [
                for (final bus in buses)
                  DropdownMenuEntry<String>(
                    value: bus.number,
                    label: bus.number,
                    labelWidget: Row(
                      children: [
                        Text(
                          bus.number,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (bus.depot != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            _depotLabel(t, bus.depot!),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static String _depotLabel(AppLocalizations t, BusDepot depot) {
    switch (depot) {
      case BusDepot.avtokomanda:
        return t.depotAvtokomanda;
      case BusDepot.gjorchePetrov:
        return t.depotGjorchePetrov;
    }
  }
}

/// Matches the height and border of the real control so the form does not
/// jump while the fleet loads.
class _PickerShell extends StatelessWidget {
  const _PickerShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
