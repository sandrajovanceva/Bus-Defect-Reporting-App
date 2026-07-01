import '../l10n/app_localizations.dart';

enum MaintenanceDepartment {
  electrical,
  mechanical,
  bodywork,
  general;

  String label(AppLocalizations t) {
    switch (this) {
      case MaintenanceDepartment.electrical:
        return t.deptElectrical;
      case MaintenanceDepartment.mechanical:
        return t.deptMechanical;
      case MaintenanceDepartment.bodywork:
        return t.deptBodywork;
      case MaintenanceDepartment.general:
        return t.deptGeneral;
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
