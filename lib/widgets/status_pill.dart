import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum DefectStatus { newReport, inProgress, resolved }

extension DefectStatusX on DefectStatus {
  String get label {
    switch (this) {
      case DefectStatus.newReport:
        return 'NEW';
      case DefectStatus.inProgress:
        return 'IN PROGRESS';
      case DefectStatus.resolved:
        return 'RESOLVED';
    }
  }

  Color get color {
    switch (this) {
      case DefectStatus.newReport:
        return AppColors.statusNew;
      case DefectStatus.inProgress:
        return AppColors.statusInProgress;
      case DefectStatus.resolved:
        return AppColors.statusResolved;
    }
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.dense = false});

  final DefectStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: dense ? 9 : 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
