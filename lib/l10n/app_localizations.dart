import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JSP Defect Reporting'**
  String get appTitle;

  /// No description provided for @brandCityTransit.
  ///
  /// In en, this message translates to:
  /// **'CITY TRANSIT'**
  String get brandCityTransit;

  /// No description provided for @brandDefectReporting.
  ///
  /// In en, this message translates to:
  /// **'Defect Reporting'**
  String get brandDefectReporting;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMacedonian.
  ///
  /// In en, this message translates to:
  /// **'Macedonian'**
  String get languageMacedonian;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get actionReplace;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing'**
  String get splashInitializing;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in.'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your dispatch-issued email and password to submit and track bus defect reports.'**
  String get loginSubtitle;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@jsp.mk'**
  String get loginEmailHint;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get loginPasswordHint;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordMin6;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginNoAccess.
  ///
  /// In en, this message translates to:
  /// **'NO ACCESS?'**
  String get loginNoAccess;

  /// No description provided for @loginContactDispatch.
  ///
  /// In en, this message translates to:
  /// **'Contact dispatch to create or reset your account.'**
  String get loginContactDispatch;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get homeTitle;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'GOOD MORNING'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'GOOD AFTERNOON'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'GOOD EVENING'**
  String get greetingEvening;

  /// No description provided for @homeSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeSignOut;

  /// No description provided for @homeLoadDemo.
  ///
  /// In en, this message translates to:
  /// **'Load demo data'**
  String get homeLoadDemo;

  /// No description provided for @homeBadgePrimary.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get homeBadgePrimary;

  /// No description provided for @homeFooter.
  ///
  /// In en, this message translates to:
  /// **'DISPATCH  ·  CITY TRANSIT'**
  String get homeFooter;

  /// No description provided for @actionReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a defect'**
  String get actionReportTitle;

  /// No description provided for @actionReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a new report'**
  String get actionReportSubtitle;

  /// No description provided for @actionMyDefectsTitle.
  ///
  /// In en, this message translates to:
  /// **'My defects'**
  String get actionMyDefectsTitle;

  /// No description provided for @actionMyDefectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View previous reports'**
  String get actionMyDefectsSubtitle;

  /// No description provided for @actionMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Defect map'**
  String get actionMapTitle;

  /// No description provided for @actionMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View defects on a map'**
  String get actionMapSubtitle;

  /// No description provided for @actionAllDefectsTitle.
  ///
  /// In en, this message translates to:
  /// **'All defects'**
  String get actionAllDefectsTitle;

  /// No description provided for @actionAllDefectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View every reported defect'**
  String get actionAllDefectsSubtitle;

  /// No description provided for @actionManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get actionManageTitle;

  /// No description provided for @actionManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Statuses, drivers and routes'**
  String get actionManageSubtitle;

  /// No description provided for @actionStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get actionStaffTitle;

  /// No description provided for @actionStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage accounts'**
  String get actionStaffSubtitle;

  /// No description provided for @seedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} demo defects.'**
  String seedSuccess(int count);

  /// No description provided for @seedExisting.
  ///
  /// In en, this message translates to:
  /// **'You already have {count} reported defects.'**
  String seedExisting(int count);

  /// No description provided for @seedError.
  ///
  /// In en, this message translates to:
  /// **'Could not load demo data.'**
  String get seedError;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'REPORT DEFECT'**
  String get reportTitle;

  /// No description provided for @reportBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'NEW REPORT'**
  String get reportBadgeNew;

  /// No description provided for @reportFillForm.
  ///
  /// In en, this message translates to:
  /// **'Fill out the form'**
  String get reportFillForm;

  /// No description provided for @reportFormIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the vehicle details and describe the defect so it can be forwarded to the service department.'**
  String get reportFormIntro;

  /// No description provided for @sectionVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get sectionVehicle;

  /// No description provided for @fieldBusNumber.
  ///
  /// In en, this message translates to:
  /// **'Bus number'**
  String get fieldBusNumber;

  /// No description provided for @reportBusHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 412 or AA-1234-BV'**
  String get reportBusHint;

  /// No description provided for @validationBusRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the bus number'**
  String get validationBusRequired;

  /// No description provided for @validationBusShort.
  ///
  /// In en, this message translates to:
  /// **'The bus number is too short'**
  String get validationBusShort;

  /// No description provided for @fieldDriverName.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get fieldDriverName;

  /// No description provided for @reportDriverHint.
  ///
  /// In en, this message translates to:
  /// **'Full name of the driver'**
  String get reportDriverHint;

  /// No description provided for @validationDriverRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the driver\'s name'**
  String get validationDriverRequired;

  /// No description provided for @validationDriverShort.
  ///
  /// In en, this message translates to:
  /// **'The driver\'s name is too short'**
  String get validationDriverShort;

  /// No description provided for @reportNoDrivers.
  ///
  /// In en, this message translates to:
  /// **'No drivers registered yet. Add one to select them here.'**
  String get reportNoDrivers;

  /// No description provided for @sectionDefect.
  ///
  /// In en, this message translates to:
  /// **'Defect'**
  String get sectionDefect;

  /// No description provided for @fieldDefectType.
  ///
  /// In en, this message translates to:
  /// **'Defect type'**
  String get fieldDefectType;

  /// No description provided for @reportTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get reportTypeHint;

  /// No description provided for @validationTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a defect type'**
  String get validationTypeRequired;

  /// No description provided for @assignedDepartment.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED DEPARTMENT'**
  String get assignedDepartment;

  /// No description provided for @fieldPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get fieldPriority;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the defect…'**
  String get reportDescriptionHint;

  /// No description provided for @validationDescRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a defect description'**
  String get validationDescRequired;

  /// No description provided for @validationDescShort.
  ///
  /// In en, this message translates to:
  /// **'The description is too short'**
  String get validationDescShort;

  /// No description provided for @sectionAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get sectionAttachment;

  /// No description provided for @attachmentAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD PHOTO'**
  String get attachmentAdd;

  /// No description provided for @attachmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional · from camera or gallery'**
  String get attachmentOptional;

  /// No description provided for @attachmentImageFallback.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get attachmentImageFallback;

  /// No description provided for @sectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sectionLocation;

  /// No description provided for @locationAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD LOCATION'**
  String get locationAdd;

  /// No description provided for @locationLocating.
  ///
  /// In en, this message translates to:
  /// **'LOCATING…'**
  String get locationLocating;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional · GPS coordinates of the defect'**
  String get locationOptional;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'LOCATION SAVED'**
  String get locationSaved;

  /// No description provided for @reportHelperNote.
  ///
  /// In en, this message translates to:
  /// **'The report will be forwarded to the dispatcher right after submission.'**
  String get reportHelperNote;

  /// No description provided for @sheetCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get sheetCamera;

  /// No description provided for @sheetGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get sheetGallery;

  /// No description provided for @reportErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT ERROR'**
  String get reportErrorTitle;

  /// No description provided for @reportImageOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the image: {error}'**
  String reportImageOpenError(String error);

  /// No description provided for @reportSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before submitting a report.'**
  String get reportSignInFirst;

  /// No description provided for @reportSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Unable to submit the report. Check your connection and try again.'**
  String get reportSubmitError;

  /// No description provided for @successSubmitted.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED'**
  String get successSubmitted;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get successTitle;

  /// No description provided for @successSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The dispatcher will review it and notify you of the status.'**
  String get successSubtitle;

  /// No description provided for @submitCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get submitCancel;

  /// No description provided for @submitSend.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitSend;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Turn them on and try again.'**
  String get locationServicesOff;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access was denied.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is permanently denied. Enable it in settings.'**
  String get locationDeniedForever;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Could not determine the location.'**
  String get locationError;

  /// No description provided for @myDefectsTitleAll.
  ///
  /// In en, this message translates to:
  /// **'ALL DEFECTS'**
  String get myDefectsTitleAll;

  /// No description provided for @myDefectsTitleMine.
  ///
  /// In en, this message translates to:
  /// **'MY DEFECTS'**
  String get myDefectsTitleMine;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get filterClear;

  /// No description provided for @searchBusHint.
  ///
  /// In en, this message translates to:
  /// **'Search by bus number…'**
  String get searchBusHint;

  /// No description provided for @emptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No defects for the selected filters'**
  String get emptyFiltered;

  /// No description provided for @emptyNoDefects.
  ///
  /// In en, this message translates to:
  /// **'No reported defects'**
  String get emptyNoDefects;

  /// No description provided for @busShort.
  ///
  /// In en, this message translates to:
  /// **'Bus #{bus}'**
  String busShort(String bus);

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get detailsTitle;

  /// No description provided for @detailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Defect not found.'**
  String get detailsNotFound;

  /// No description provided for @labelBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get labelBus;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @labelDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get labelDepartment;

  /// No description provided for @labelSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get labelSubmitted;

  /// No description provided for @labelDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get labelDriver;

  /// No description provided for @labelReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Logged by'**
  String get labelReportedBy;

  /// No description provided for @labelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get labelLocation;

  /// No description provided for @busNumbered.
  ///
  /// In en, this message translates to:
  /// **'Bus #{bus}'**
  String busNumbered(String bus);

  /// No description provided for @sectionDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get sectionDescription;

  /// No description provided for @sectionChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'CHANGE STATUS'**
  String get sectionChangeStatus;

  /// No description provided for @sectionHistory.
  ///
  /// In en, this message translates to:
  /// **'CHANGE HISTORY'**
  String get sectionHistory;

  /// No description provided for @readOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Only the dispatcher can change the report status.'**
  String get readOnlyNotice;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @statusArmaturaReview.
  ///
  /// In en, this message translates to:
  /// **'At Armatura'**
  String get statusArmaturaReview;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusReturnedToService.
  ///
  /// In en, this message translates to:
  /// **'Returned to service'**
  String get statusReturnedToService;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @sectionClassify.
  ///
  /// In en, this message translates to:
  /// **'ARMATURA CLASSIFICATION'**
  String get sectionClassify;

  /// No description provided for @classifyHelperNote.
  ///
  /// In en, this message translates to:
  /// **'Armatura reviews the report and determines the actual defect category — electrical, mechanical or bravari (bodywork) — which sets the department it\'s routed to.'**
  String get classifyHelperNote;

  /// No description provided for @classifySave.
  ///
  /// In en, this message translates to:
  /// **'Confirm classification'**
  String get classifySave;

  /// No description provided for @classifyUnchanged.
  ///
  /// In en, this message translates to:
  /// **'This is already the current classification.'**
  String get classifyUnchanged;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'DEFECT MAP'**
  String get mapTitle;

  /// No description provided for @mapNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No defects with a saved location.'**
  String get mapNoLocation;

  /// No description provided for @mapLegend.
  ///
  /// In en, this message translates to:
  /// **'{count} defects on the map · tap a marker for details'**
  String mapLegend(int count);

  /// No description provided for @mapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Bus #{bus} · {type}'**
  String mapTooltip(String bus, String type);

  /// No description provided for @managementTitle.
  ///
  /// In en, this message translates to:
  /// **'MANAGEMENT'**
  String get managementTitle;

  /// No description provided for @mgmtStatusOverview.
  ///
  /// In en, this message translates to:
  /// **'STATUS OVERVIEW'**
  String get mgmtStatusOverview;

  /// No description provided for @mgmtFleet.
  ///
  /// In en, this message translates to:
  /// **'FLEET'**
  String get mgmtFleet;

  /// No description provided for @mgmtBuses.
  ///
  /// In en, this message translates to:
  /// **'{count} buses'**
  String mgmtBuses(int count);

  /// No description provided for @mgmtDepartments.
  ///
  /// In en, this message translates to:
  /// **'DEPARTMENTS'**
  String get mgmtDepartments;

  /// No description provided for @mgmtTotalDefects.
  ///
  /// In en, this message translates to:
  /// **'total defects'**
  String get mgmtTotalDefects;

  /// No description provided for @mgmtBusTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} defects total'**
  String mgmtBusTotal(int count);

  /// No description provided for @mgmtBusActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String mgmtBusActive(int count);

  /// No description provided for @mgmtBusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get mgmtBusOk;

  /// No description provided for @mgmtDeptActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active defects'**
  String mgmtDeptActive(int count);

  /// No description provided for @mgmtDeptNone.
  ///
  /// In en, this message translates to:
  /// **'No active defects'**
  String get mgmtDeptNone;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'USERS'**
  String get staffTitle;

  /// No description provided for @staffNewUser.
  ///
  /// In en, this message translates to:
  /// **'NEW USER'**
  String get staffNewUser;

  /// No description provided for @staffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users created.'**
  String get staffEmpty;

  /// No description provided for @staffGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get staffGenericError;

  /// No description provided for @staffDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get staffDeactivate;

  /// No description provided for @staffActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get staffActivate;

  /// No description provided for @staffDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get staffDelete;

  /// No description provided for @staffOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get staffOptions;

  /// No description provided for @staffInactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get staffInactive;

  /// No description provided for @staffCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get staffCreateTitle;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @staffNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Marko Markovski'**
  String get staffNameHint;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get validationNameRequired;

  /// No description provided for @staffEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@jsp.mk'**
  String get staffEmailHint;

  /// No description provided for @staffPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'at least 8 characters'**
  String get staffPasswordHint;

  /// No description provided for @validationPasswordMin8.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get validationPasswordMin8;

  /// No description provided for @fieldBusOptional.
  ///
  /// In en, this message translates to:
  /// **'Bus (optional)'**
  String get fieldBusOptional;

  /// No description provided for @fieldRouteOptional.
  ///
  /// In en, this message translates to:
  /// **'Route (optional)'**
  String get fieldRouteOptional;

  /// No description provided for @routeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 22'**
  String get routeHint;

  /// No description provided for @staffCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get staffCreateButton;

  /// No description provided for @staffCreated.
  ///
  /// In en, this message translates to:
  /// **'User created.'**
  String get staffCreated;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get roleDriver;

  /// No description provided for @roleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'DISPATCHER'**
  String get roleDispatcher;

  /// No description provided for @typeUnclassified.
  ///
  /// In en, this message translates to:
  /// **'Not yet classified'**
  String get typeUnclassified;

  /// No description provided for @typeElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get typeElectrical;

  /// No description provided for @typeMechanical.
  ///
  /// In en, this message translates to:
  /// **'Mechanical'**
  String get typeMechanical;

  /// No description provided for @typeDoors.
  ///
  /// In en, this message translates to:
  /// **'Doors'**
  String get typeDoors;

  /// No description provided for @typeBrakes.
  ///
  /// In en, this message translates to:
  /// **'Brakes'**
  String get typeBrakes;

  /// No description provided for @typeLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get typeLights;

  /// No description provided for @typeClimate.
  ///
  /// In en, this message translates to:
  /// **'Heating / air conditioning'**
  String get typeClimate;

  /// No description provided for @typeBodywork.
  ///
  /// In en, this message translates to:
  /// **'Bodywork'**
  String get typeBodywork;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// No description provided for @deptUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Pending Armatura review'**
  String get deptUnassigned;

  /// No description provided for @deptElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical department'**
  String get deptElectrical;

  /// No description provided for @deptMechanical.
  ///
  /// In en, this message translates to:
  /// **'Mechanical department'**
  String get deptMechanical;

  /// No description provided for @deptBodywork.
  ///
  /// In en, this message translates to:
  /// **'Bodywork department'**
  String get deptBodywork;

  /// No description provided for @deptGeneral.
  ///
  /// In en, this message translates to:
  /// **'General maintenance'**
  String get deptGeneral;

  /// No description provided for @reportPendingClassification.
  ///
  /// In en, this message translates to:
  /// **'No need to pick a category — Armatura will review the description and classify the defect (electrical, mechanical, bravari/bodywork, etc.) once the report comes in.'**
  String get reportPendingClassification;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mk':
      return AppLocalizationsMk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
