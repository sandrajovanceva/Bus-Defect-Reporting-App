import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}


class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                prefixIcon == null ? null : Icon(prefixIcon, size: 20),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<T>(
                  value: option.value,
                  child: Row(
                    children: [
                      if (option.icon != null) ...[
                        Icon(
                          option.icon,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          option.label,
                          style: theme.textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
        ),
      ],
    );
  }
}
