import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum AppButtonVariant { primary, outline, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final upper = label.toUpperCase();

    final spinner = SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: variant == AppButtonVariant.primary
            ? Colors.white
            : AppColors.accent,
      ),
    );

    final content = isLoading
        ? spinner
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 10),
              ],
              Text(upper),
            ],
          );

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
        break;
    }

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
