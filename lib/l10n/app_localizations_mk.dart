// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Macedonian (`mk`).
class AppLocalizationsMk extends AppLocalizations {
  AppLocalizationsMk([String locale = 'mk']) : super(locale);

  @override
  String get appTitle => 'ЈСП Пријава на дефекти';

  @override
  String get brandCityTransit => 'ГРАДСКИ ПРЕВОЗ';

  @override
  String get brandDefectReporting => 'Пријава на дефекти';

  @override
  String get languageEnglish => 'Англиски';

  @override
  String get languageMacedonian => 'Македонски';

  @override
  String get actionBack => 'Назад';

  @override
  String get actionCancel => 'Откажи';

  @override
  String get actionRefresh => 'Освежи';

  @override
  String get actionReplace => 'Замени';

  @override
  String get actionRemove => 'Отстрани';

  @override
  String get actionClose => 'Затвори';

  @override
  String get splashInitializing => 'Се вчитува';

  @override
  String get loginTitle => 'Најави се.';

  @override
  String get loginSubtitle =>
      'Користете ги вашата е-пошта и лозинка издадени од диспечер за да поднесувате и следите пријави за дефекти.';

  @override
  String get fieldEmail => 'Е-пошта';

  @override
  String get loginEmailHint => 'ime@jsp.mk';

  @override
  String get validationEmailRequired => 'Е-поштата е задолжителна';

  @override
  String get validationEmailInvalid => 'Внесете валидна е-пошта';

  @override
  String get fieldPassword => 'Лозинка';

  @override
  String get loginPasswordHint => 'Внесете лозинка';

  @override
  String get validationPasswordRequired => 'Лозинката е задолжителна';

  @override
  String get validationPasswordMin6 =>
      'Лозинката мора да има најмалку 6 карактери';

  @override
  String get loginSignIn => 'Најави се';

  @override
  String get loginNoAccess => 'НЕМАТЕ ПРИСТАП?';

  @override
  String get loginContactDispatch =>
      'Контактирајте го диспечерот за да создадете или ресетирате сметка.';

  @override
  String get homeTitle => 'ГЛАВЕН ЕКРАН';

  @override
  String get greetingMorning => 'ДОБРО УТРО';

  @override
  String get greetingAfternoon => 'ДОБАР ДЕН';

  @override
  String get greetingEvening => 'ДОБРА ВЕЧЕР';

  @override
  String get homeSignOut => 'Одјави се';

  @override
  String get homeLoadDemo => 'Внеси демо податоци';

  @override
  String get homeBadgePrimary => 'ОСНОВНО';

  @override
  String get homeFooter => 'ДИСПЕЧЕР  ·  ГРАДСКИ ПРЕВОЗ';

  @override
  String get actionReportTitle => 'Пријави дефект';

  @override
  String get actionReportSubtitle => 'Поднеси нов извештај';

  @override
  String get actionMyDefectsTitle => 'Мои дефекти';

  @override
  String get actionMyDefectsSubtitle => 'Прегледај претходни извештаи';

  @override
  String get actionMapTitle => 'Мапа на дефекти';

  @override
  String get actionMapSubtitle => 'Прегледај дефекти на мапа';

  @override
  String get actionAllDefectsTitle => 'Сите дефекти';

  @override
  String get actionAllDefectsSubtitle => 'Прегледај ги сите пријавени дефекти';

  @override
  String get actionManageTitle => 'Управување';

  @override
  String get actionManageSubtitle => 'Статуси, возачи и линии';

  @override
  String get actionStaffTitle => 'Корисници';

  @override
  String get actionStaffSubtitle => 'Креирај и управувај со сметки';

  @override
  String seedSuccess(int count) {
    return 'Внесени се $count демо дефекти.';
  }

  @override
  String seedExisting(int count) {
    return 'Веќе имате $count пријавени дефекти.';
  }

  @override
  String get seedError => 'Не можеше да се внесат демо податоци.';

  @override
  String get reportTitle => 'ПРИЈАВИ ДЕФЕКТ';

  @override
  String get reportBadgeNew => 'НОВ ИЗВЕШТАЈ';

  @override
  String get reportFillForm => 'Пополнете го формуларот';

  @override
  String get reportFormIntro =>
      'Внесете ги основните податоци за возилото и опишете го дефектот за да биде препратен до сервисот.';

  @override
  String get sectionVehicle => 'Возило';

  @override
  String get fieldBusNumber => 'Број на автобус';

  @override
  String get reportBusHint => 'пр. 412 или АА-1234-БВ';

  @override
  String get validationBusRequired => 'Внесете го бројот на автобусот';

  @override
  String get validationBusShort => 'Бројот на автобусот е премногу краток';

  @override
  String get fieldDriverName => 'Возач';

  @override
  String get reportDriverHint => 'Име и презиме на возачот';

  @override
  String get validationDriverRequired => 'Внесете го името на возачот';

  @override
  String get validationDriverShort => 'Името на возачот е премногу кратко';

  @override
  String get reportNoDrivers =>
      'Нема регистрирани возачи. Прво додади еден за да може да се избере тука.';

  @override
  String get sectionDefect => 'Дефект';

  @override
  String get fieldDefectType => 'Тип на дефект';

  @override
  String get reportTypeHint => 'Изберете категорија';

  @override
  String get validationTypeRequired => 'Изберете тип на дефект';

  @override
  String get assignedDepartment => 'ДОДЕЛЕН ОДДЕЛ';

  @override
  String get fieldPriority => 'Приоритет';

  @override
  String get fieldDescription => 'Опис';

  @override
  String get reportDescriptionHint => 'Опишете го дефектот накратко…';

  @override
  String get validationDescRequired => 'Внесете опис на дефектот';

  @override
  String get validationDescShort => 'Описот е премногу краток';

  @override
  String get sectionAttachment => 'Прилог';

  @override
  String get attachmentAdd => 'ДОДАДИ СЛИКА';

  @override
  String get attachmentOptional => 'Опционално · од камера или галерија';

  @override
  String get attachmentImageFallback => 'Слика';

  @override
  String get sectionLocation => 'Локација';

  @override
  String get locationAdd => 'ПРИКАЧИ ЛОКАЦИЈА';

  @override
  String get locationLocating => 'СЕ ОДРЕДУВА…';

  @override
  String get locationOptional => 'Опционално · GPS координати на дефектот';

  @override
  String get locationSaved => 'ЛОКАЦИЈАТА Е ЗАЧУВАНА';

  @override
  String get reportHelperNote =>
      'Извештајот ќе биде препратен до диспечерот веднаш по поднесувањето.';

  @override
  String get sheetCamera => 'Сликај со камера';

  @override
  String get sheetGallery => 'Избери од галерија';

  @override
  String get reportErrorTitle => 'ГРЕШКА ПРИ ИСПРАЌАЊЕ';

  @override
  String reportImageOpenError(String error) {
    return 'Не можеше да се отвори сликата: $error';
  }

  @override
  String get reportSignInFirst => 'Најавете се пред да поднесете извештај.';

  @override
  String get reportSubmitError =>
      'Извештајот не може да се поднесе. Проверете ја врската и обидете се повторно.';

  @override
  String get successSubmitted => 'ПОДНЕСЕНО';

  @override
  String get successTitle => 'Извештајот е испратен';

  @override
  String get successSubtitle =>
      'Диспечерот ќе го прегледа и ќе ве извести за статусот.';

  @override
  String get submitCancel => 'Откажи';

  @override
  String get submitSend => 'Поднеси';

  @override
  String get locationServicesOff =>
      'Локациските услуги се исклучени. Вклучете ги и обидете се повторно.';

  @override
  String get locationDenied => 'Пристапот до локацијата е одбиен.';

  @override
  String get locationDeniedForever =>
      'Пристапот до локацијата е трајно одбиен. Овозможете го од подесувањата.';

  @override
  String get locationError => 'Не можеше да се одреди локацијата.';

  @override
  String get myDefectsTitleAll => 'СИТЕ ДЕФЕКТИ';

  @override
  String get myDefectsTitleMine => 'МОИ ДЕФЕКТИ';

  @override
  String get filterClear => 'ИСЧИСТИ';

  @override
  String get searchBusHint => 'Пребарај по број на автобус…';

  @override
  String get emptyFiltered => 'Нема дефекти за избраните филтри';

  @override
  String get emptyNoDefects => 'Нема пријавени дефекти';

  @override
  String busShort(String bus) {
    return 'Автобус #$bus';
  }

  @override
  String get detailsTitle => 'ДЕТАЛИ';

  @override
  String get detailsNotFound => 'Дефектот не е пронајден.';

  @override
  String get labelBus => 'Автобус';

  @override
  String get labelType => 'Тип';

  @override
  String get labelDepartment => 'Оддел';

  @override
  String get labelSubmitted => 'Поднесено';

  @override
  String get labelDriver => 'Возач';

  @override
  String get labelReportedBy => 'Внесено од';

  @override
  String get labelLocation => 'Локација';

  @override
  String busNumbered(String bus) {
    return 'Автобус #$bus';
  }

  @override
  String get sectionDescription => 'ОПИС';

  @override
  String get sectionChangeStatus => 'ПРОМЕНИ СТАТУС';

  @override
  String get sectionHistory => 'ИСТОРИЈА НА ПРОМЕНИ';

  @override
  String get readOnlyNotice =>
      'Само диспечерот може да го менува статусот на извештајот.';

  @override
  String get statusNew => 'Нов';

  @override
  String get statusArmaturaReview => 'На Арматура';

  @override
  String get statusInProgress => 'Во тек';

  @override
  String get statusResolved => 'Решено';

  @override
  String get statusReturnedToService => 'Вратен во сообраќај';

  @override
  String get statusRejected => 'Одбиено';

  @override
  String get sectionClassify => 'КЛАСИФИКАЦИЈА ОД АРМАТУРА';

  @override
  String get classifyHelperNote =>
      'Арматура го прегледува пријавениот дефект и го утврдува вистинскиот тип — електрика, механика или бравари (каросерија) — со што се определува одделот каде се препраќа.';

  @override
  String get classifySave => 'Потврди класификација';

  @override
  String get classifyUnchanged => 'Ова е веќе тековната класификација.';

  @override
  String get mapTitle => 'МАПА НА ДЕФЕКТИ';

  @override
  String get mapNoLocation => 'Нема дефекти со зачувана локација.';

  @override
  String mapLegend(int count) {
    return '$count дефекти на мапата · допрете маркер за детали';
  }

  @override
  String mapTooltip(String bus, String type) {
    return 'Автобус #$bus · $type';
  }

  @override
  String get managementTitle => 'УПРАВУВАЊЕ';

  @override
  String get mgmtStatusOverview => 'СТАТУС ПРЕГЛЕД';

  @override
  String get mgmtFleet => 'ФЛОТА';

  @override
  String mgmtBuses(int count) {
    return '$count автобуси';
  }

  @override
  String get mgmtDepartments => 'ОДДЕЛИ';

  @override
  String get mgmtTotalDefects => 'вкупно дефекти';

  @override
  String mgmtBusTotal(int count) {
    return '$count дефекти вкупно';
  }

  @override
  String mgmtBusActive(int count) {
    return '$count активни';
  }

  @override
  String get mgmtBusOk => 'Уредно';

  @override
  String mgmtDeptActive(int count) {
    return '$count активни дефекти';
  }

  @override
  String get mgmtDeptNone => 'Нема активни дефекти';

  @override
  String get staffTitle => 'КОРИСНИЦИ';

  @override
  String get staffNewUser => 'НОВ КОРИСНИК';

  @override
  String get staffEmpty => 'Нема креирани корисници.';

  @override
  String get staffGenericError => 'Настана грешка. Обидете се повторно.';

  @override
  String get staffDeactivate => 'Деактивирај';

  @override
  String get staffActivate => 'Активирај';

  @override
  String get staffDelete => 'Избриши';

  @override
  String get staffOptions => 'Опции';

  @override
  String get staffInactive => 'НЕАКТИВЕН';

  @override
  String get staffCreateTitle => 'Нов корисник';

  @override
  String get fieldFullName => 'Име и презиме';

  @override
  String get staffNameHint => 'пр. Марко Марковски';

  @override
  String get validationNameRequired => 'Внесете име';

  @override
  String get staffEmailHint => 'ime@jsp.mk';

  @override
  String get staffPasswordHint => 'најмалку 8 карактери';

  @override
  String get validationPasswordMin8 => 'Најмалку 8 карактери';

  @override
  String get fieldBusOptional => 'Автобус (опционално)';

  @override
  String get fieldRouteOptional => 'Линија (опционално)';

  @override
  String get routeHint => 'пр. 22';

  @override
  String get staffCreateButton => 'Креирај корисник';

  @override
  String get staffCreated => 'Корисникот е креиран.';

  @override
  String get roleDriver => 'ВОЗАЧ';

  @override
  String get roleDispatcher => 'ДИСПЕЧЕР';

  @override
  String get typeUnclassified => 'Сеуште неутврдено';

  @override
  String get typeElectrical => 'Електрика';

  @override
  String get typeMechanical => 'Механика';

  @override
  String get typeDoors => 'Врати';

  @override
  String get typeBrakes => 'Кочници';

  @override
  String get typeLights => 'Светла';

  @override
  String get typeClimate => 'Греење / климатизација';

  @override
  String get typeBodywork => 'Каросерија';

  @override
  String get typeOther => 'Друго';

  @override
  String get deptUnassigned => 'Чека преглед од Арматура';

  @override
  String get deptElectrical => 'Електро оддел';

  @override
  String get deptMechanical => 'Механички оддел';

  @override
  String get deptBodywork => 'Каросериски оддел';

  @override
  String get deptGeneral => 'Општо одржување';

  @override
  String get reportPendingClassification =>
      'Не треба да се избира категорија — Арматура ќе го прегледа описот и ќе го класифицира дефектот (електрика, механика, бравари/каросерија, итн.) штом пристигне пријавата.';
}
