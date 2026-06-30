import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_button.dart';

class AppErrorMessage extends StatelessWidget {
  const AppErrorMessage({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.statusNew.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.statusNew.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.statusNew,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ERROR',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.statusNew,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: 'Retry',
                onPressed: onRetry,
                fullWidth: false,
                variant: AppButtonVariant.outline,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
