import 'package:flutter/material.dart';

enum DefectPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case DefectPriority.low:
        return 'Ниски';
      case DefectPriority.medium:
        return 'Среден';
      case DefectPriority.high:
        return 'Висок';
    }
  }

  String get labelEn {
    switch (this) {
      case DefectPriority.low:
        return 'LOW';
      case DefectPriority.medium:
        return 'MEDIUM';
      case DefectPriority.high:
        return 'HIGH';
    }
  }

  IconData get icon {
    switch (this) {
      case DefectPriority.low:
        return Icons.arrow_downward_rounded;
      case DefectPriority.medium:
        return Icons.remove_rounded;
      case DefectPriority.high:
        return Icons.arrow_upward_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DefectPriority.low:
        return const Color(0xFF15803D);   // green
      case DefectPriority.medium:
        return const Color(0xFFB45309);   // amber
      case DefectPriority.high:
        return const Color(0xFFDC2626);   // red
    }
  }
}
