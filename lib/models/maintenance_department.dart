enum MaintenanceDepartment {
  electrical,
  mechanical,
  bodywork,
  general;

  String get label {
    switch (this) {
      case MaintenanceDepartment.electrical:
        return 'Електро оддел';
      case MaintenanceDepartment.mechanical:
        return 'Механички оддел';
      case MaintenanceDepartment.bodywork:
        return 'Каросериски оддел';
      case MaintenanceDepartment.general:
        return 'Општо одржување';
    }
  }

  String get code {
    switch (this) {
      case MaintenanceDepartment.electrical:
        return 'ELEC';
      case MaintenanceDepartment.mechanical:
        return 'MECH';
      case MaintenanceDepartment.bodywork:
        return 'BODY';
      case MaintenanceDepartment.general:
        return 'GEN';
    }
  }
}
