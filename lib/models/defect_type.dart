import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'maintenance_department.dart';

enum DefectType {
  /// Not yet classified — the state every new report starts in until
  /// Арматура reviews it and picks the real category.
  unclassified,
  electrical,
  mechanical,
  doors,
  brakes,
  lights,
  climate,
  bodywork,
  other,
}

extension DefectTypeX on DefectType {
  String label(AppLocalizations t) {
    switch (this) {
      case DefectType.unclassified:
        return t.typeUnclassified;
      case DefectType.electrical:
        return t.typeElectrical;
      case DefectType.mechanical:
        return t.typeMechanical;
      case DefectType.doors:
        return t.typeDoors;
      case DefectType.brakes:
        return t.typeBrakes;
      case DefectType.lights:
        return t.typeLights;
      case DefectType.climate:
        return t.typeClimate;
      case DefectType.bodywork:
        return t.typeBodywork;
      case DefectType.other:
        return t.typeOther;
    }
  }

  IconData get icon {
    switch (this) {
      case DefectType.unclassified:
        return Icons.pending_outlined;
      case DefectType.electrical:
        return Icons.bolt_rounded;
      case DefectType.mechanical:
        return Icons.build_rounded;
      case DefectType.doors:
        return Icons.meeting_room_outlined;
      case DefectType.brakes:
        return Icons.disc_full_rounded;
      case DefectType.lights:
        return Icons.lightbulb_outline_rounded;
      case DefectType.climate:
        return Icons.thermostat_rounded;
      case DefectType.bodywork:
        return Icons.directions_bus_filled_rounded;
      case DefectType.other:
        return Icons.more_horiz_rounded;
    }
  }

  MaintenanceDepartment get department {
    switch (this) {
      case DefectType.unclassified:
        return MaintenanceDepartment.unassigned;
      case DefectType.electrical:
      case DefectType.lights:
      case DefectType.climate:
        return MaintenanceDepartment.electrical;
      case DefectType.mechanical:
      case DefectType.brakes:
        return MaintenanceDepartment.mechanical;
      case DefectType.bodywork:
      case DefectType.doors:
        return MaintenanceDepartment.bodywork;
      case DefectType.other:
        return MaintenanceDepartment.general;
    }
  }
}
