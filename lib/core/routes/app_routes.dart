class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String myDefects = '/defects';
  static const String defectReport = '/defects/new';
  static const String defectDetailsPattern = '/defects/:id';

  static String defectDetails(String id) => '/defects/$id';
}
