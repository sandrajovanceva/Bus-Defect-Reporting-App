// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JSP Defect Reporting';

  @override
  String get brandCityTransit => 'CITY TRANSIT';

  @override
  String get brandDefectReporting => 'Defect Reporting';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMacedonian => 'Macedonian';

  @override
  String get actionBack => 'Back';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionReplace => 'Replace';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionClose => 'Close';

  @override
  String get splashInitializing => 'Initializing';

  @override
  String get loginTitle => 'Sign in.';

  @override
  String get loginSubtitle =>
      'Use your dispatch-issued email and password to submit and track bus defect reports.';

  @override
  String get fieldEmail => 'Email';

  @override
  String get loginEmailHint => 'name@jsp.mk';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get fieldPassword => 'Password';

  @override
  String get loginPasswordHint => 'Enter password';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordMin6 => 'Password must be at least 6 characters';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginNoAccess => 'NO ACCESS?';

  @override
  String get loginContactDispatch =>
      'Contact dispatch to create or reset your account.';

  @override
  String get homeTitle => 'HOME';

  @override
  String get greetingMorning => 'GOOD MORNING';

  @override
  String get greetingAfternoon => 'GOOD AFTERNOON';

  @override
  String get greetingEvening => 'GOOD EVENING';

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get homeLoadDemo => 'Load demo data';

  @override
  String get homeBadgePrimary => 'PRIMARY';

  @override
  String get homeFooter => 'DISPATCH  ·  CITY TRANSIT';

  @override
  String get actionReportTitle => 'Report a defect';

  @override
  String get actionReportSubtitle => 'Submit a new report';

  @override
  String get actionMyDefectsTitle => 'My defects';

  @override
  String get actionMyDefectsSubtitle => 'View previous reports';

  @override
  String get actionMapTitle => 'Defect map';

  @override
  String get actionMapSubtitle => 'View defects on a map';

  @override
  String get actionAllDefectsTitle => 'All defects';

  @override
  String get actionAllDefectsSubtitle => 'View every reported defect';

  @override
  String get actionManageTitle => 'Management';

  @override
  String get actionManageSubtitle => 'Statuses, drivers and routes';

  @override
  String get actionStaffTitle => 'Users';

  @override
  String get actionStaffSubtitle => 'Create and manage accounts';

  @override
  String seedSuccess(int count) {
    return 'Loaded $count demo defects.';
  }

  @override
  String seedExisting(int count) {
    return 'You already have $count reported defects.';
  }

  @override
  String get seedError => 'Could not load demo data.';

  @override
  String get reportTitle => 'REPORT DEFECT';

  @override
  String get reportBadgeNew => 'NEW REPORT';

  @override
  String get reportFillForm => 'Fill out the form';

  @override
  String get reportFormIntro =>
      'Enter the vehicle details and describe the defect so it can be forwarded to the service department.';

  @override
  String get sectionVehicle => 'Vehicle';

  @override
  String get fieldBusNumber => 'Bus number';

  @override
  String get reportBusHint => 'e.g. 412 or AA-1234-BV';

  @override
  String get validationBusRequired => 'Enter the bus number';

  @override
  String get validationBusShort => 'The bus number is too short';

  @override
  String get fieldDriverName => 'Driver';

  @override
  String get reportDriverHint => 'Full name of the driver';

  @override
  String get validationDriverRequired => 'Enter the driver\'s name';

  @override
  String get validationDriverShort => 'The driver\'s name is too short';

  @override
  String get reportNoDrivers =>
      'No drivers registered yet. Add one to select them here.';

  @override
  String get sectionDefect => 'Defect';

  @override
  String get fieldDefectType => 'Defect type';

  @override
  String get reportTypeHint => 'Select a category';

  @override
  String get validationTypeRequired => 'Select a defect type';

  @override
  String get assignedDepartment => 'ASSIGNED DEPARTMENT';

  @override
  String get fieldPriority => 'Priority';

  @override
  String get fieldDescription => 'Description';

  @override
  String get reportDescriptionHint => 'Briefly describe the defect…';

  @override
  String get validationDescRequired => 'Enter a defect description';

  @override
  String get validationDescShort => 'The description is too short';

  @override
  String get sectionAttachment => 'Attachment';

  @override
  String get attachmentAdd => 'ADD PHOTO';

  @override
  String get attachmentOptional => 'Optional · from camera or gallery';

  @override
  String get attachmentImageFallback => 'Image';

  @override
  String get sectionLocation => 'Location';

  @override
  String get locationAdd => 'ADD LOCATION';

  @override
  String get locationLocating => 'LOCATING…';

  @override
  String get locationOptional => 'Optional · GPS coordinates of the defect';

  @override
  String get locationSaved => 'LOCATION SAVED';

  @override
  String get reportHelperNote =>
      'The report will be forwarded to the dispatcher right after submission.';

  @override
  String get sheetCamera => 'Take a photo';

  @override
  String get sheetGallery => 'Choose from gallery';

  @override
  String get reportErrorTitle => 'SUBMIT ERROR';

  @override
  String reportImageOpenError(String error) {
    return 'Could not open the image: $error';
  }

  @override
  String get reportSignInFirst => 'Please sign in before submitting a report.';

  @override
  String get reportSubmitError =>
      'Unable to submit the report. Check your connection and try again.';

  @override
  String get successSubmitted => 'SUBMITTED';

  @override
  String get successTitle => 'Report sent';

  @override
  String get successSubtitle =>
      'The dispatcher will review it and notify you of the status.';

  @override
  String get submitCancel => 'Cancel';

  @override
  String get submitSend => 'Submit';

  @override
  String get locationServicesOff =>
      'Location services are off. Turn them on and try again.';

  @override
  String get locationDenied => 'Location access was denied.';

  @override
  String get locationDeniedForever =>
      'Location access is permanently denied. Enable it in settings.';

  @override
  String get locationError => 'Could not determine the location.';

  @override
  String get myDefectsTitleAll => 'ALL DEFECTS';

  @override
  String get myDefectsTitleMine => 'MY DEFECTS';

  @override
  String get filterClear => 'CLEAR';

  @override
  String get searchBusHint => 'Search by bus number…';

  @override
  String get emptyFiltered => 'No defects for the selected filters';

  @override
  String get emptyNoDefects => 'No reported defects';

  @override
  String busShort(String bus) {
    return 'Bus #$bus';
  }

  @override
  String get detailsTitle => 'DETAILS';

  @override
  String get detailsNotFound => 'Defect not found.';

  @override
  String get labelBus => 'Bus';

  @override
  String get labelType => 'Type';

  @override
  String get labelDepartment => 'Department';

  @override
  String get labelSubmitted => 'Submitted';

  @override
  String get labelDriver => 'Driver';

  @override
  String get labelReportedBy => 'Logged by';

  @override
  String get labelLocation => 'Location';

  @override
  String busNumbered(String bus) {
    return 'Bus #$bus';
  }

  @override
  String get sectionDescription => 'DESCRIPTION';

  @override
  String get sectionChangeStatus => 'CHANGE STATUS';

  @override
  String get sectionHistory => 'CHANGE HISTORY';

  @override
  String get readOnlyNotice =>
      'Only the dispatcher can change the report status.';

  @override
  String get statusNew => 'New';

  @override
  String get statusArmaturaReview => 'At Armatura';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusReturnedToService => 'Returned to service';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get sectionClassify => 'ARMATURA CLASSIFICATION';

  @override
  String get classifyHelperNote =>
      'Armatura reviews the report and determines the actual defect category — electrical, mechanical or bravari (bodywork) — which sets the department it\'s routed to.';

  @override
  String get classifySave => 'Confirm classification';

  @override
  String get classifyUnchanged => 'This is already the current classification.';

  @override
  String get mapTitle => 'DEFECT MAP';

  @override
  String get mapNoLocation => 'No defects with a saved location.';

  @override
  String mapLegend(int count) {
    return '$count defects on the map · tap a marker for details';
  }

  @override
  String mapTooltip(String bus, String type) {
    return 'Bus #$bus · $type';
  }

  @override
  String get managementTitle => 'MANAGEMENT';

  @override
  String get mgmtStatusOverview => 'STATUS OVERVIEW';

  @override
  String get mgmtFleet => 'FLEET';

  @override
  String mgmtBuses(int count) {
    return '$count buses';
  }

  @override
  String get mgmtDepartments => 'DEPARTMENTS';

  @override
  String get mgmtTotalDefects => 'total defects';

  @override
  String mgmtBusTotal(int count) {
    return '$count defects total';
  }

  @override
  String mgmtBusActive(int count) {
    return '$count active';
  }

  @override
  String get mgmtBusOk => 'OK';

  @override
  String mgmtDeptActive(int count) {
    return '$count active defects';
  }

  @override
  String get mgmtDeptNone => 'No active defects';

  @override
  String get staffTitle => 'USERS';

  @override
  String get staffNewUser => 'NEW USER';

  @override
  String get staffEmpty => 'No users created.';

  @override
  String get staffGenericError => 'Something went wrong. Try again.';

  @override
  String get staffDeactivate => 'Deactivate';

  @override
  String get staffActivate => 'Activate';

  @override
  String get staffDelete => 'Delete';

  @override
  String get staffOptions => 'Options';

  @override
  String get staffInactive => 'INACTIVE';

  @override
  String get staffCreateTitle => 'New user';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get staffNameHint => 'e.g. Marko Markovski';

  @override
  String get validationNameRequired => 'Enter a name';

  @override
  String get staffEmailHint => 'name@jsp.mk';

  @override
  String get staffPasswordHint => 'at least 8 characters';

  @override
  String get validationPasswordMin8 => 'At least 8 characters';

  @override
  String get fieldBusOptional => 'Bus (optional)';

  @override
  String get fieldRouteOptional => 'Route (optional)';

  @override
  String get routeHint => 'e.g. 22';

  @override
  String get staffCreateButton => 'Create user';

  @override
  String get staffCreated => 'User created.';

  @override
  String get roleDriver => 'DRIVER';

  @override
  String get roleDispatcher => 'DISPATCHER';

  @override
  String get typeUnclassified => 'Not yet classified';

  @override
  String get typeElectrical => 'Electrical';

  @override
  String get typeMechanical => 'Mechanical';

  @override
  String get typeDoors => 'Doors';

  @override
  String get typeBrakes => 'Brakes';

  @override
  String get typeLights => 'Lights';

  @override
  String get typeClimate => 'Heating / air conditioning';

  @override
  String get typeBodywork => 'Bodywork';

  @override
  String get typeOther => 'Other';

  @override
  String get deptUnassigned => 'Pending Armatura review';

  @override
  String get deptElectrical => 'Electrical department';

  @override
  String get deptMechanical => 'Mechanical department';

  @override
  String get deptBodywork => 'Bodywork department';

  @override
  String get deptGeneral => 'General maintenance';

  @override
  String get reportPendingClassification =>
      'No need to pick a category — Armatura will review the description and classify the defect (electrical, mechanical, bravari/bodywork, etc.) once the report comes in.';
}
