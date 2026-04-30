import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.rectangle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(
              color: AppColors.border,
              thickness: 1,
              height: 1,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
