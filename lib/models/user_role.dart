enum UserRole {
  driver,
  dispatcher;

  String get label {
    switch (this) {
      case UserRole.driver:
        return 'ВОЗАЧ';
      case UserRole.dispatcher:
        return 'ДИСПЕЧЕР';
    }
  }

  bool get isDriver => this == UserRole.driver;
  bool get isDispatcher => this == UserRole.dispatcher;
}
