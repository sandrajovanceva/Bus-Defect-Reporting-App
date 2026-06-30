class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String myDefects = '/defects';
  static const String defectReport = '/defects/new';
  static const String defectDetailsPattern = '/defects/:id';

  static const String management = '/management';
  static const String defectMap = '/map';

  static String defectDetails(String id) => '/defects/$id';
}
