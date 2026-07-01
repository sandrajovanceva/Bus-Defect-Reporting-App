import '../l10n/app_localizations.dart';

enum UserRole {
  driver,
  dispatcher;

  String label(AppLocalizations t) {
    switch (this) {
      case UserRole.driver:
        return t.roleDriver;
      case UserRole.dispatcher:
        return t.roleDispatcher;
    }
  }

  bool get isDriver => this == UserRole.driver;
  bool get isDispatcher => this == UserRole.dispatcher;
}
