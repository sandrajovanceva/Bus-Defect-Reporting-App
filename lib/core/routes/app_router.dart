import 'package:go_router/go_router.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/defects/defect_details_screen.dart';
import '../../screens/defects/defect_report_screen.dart';
import '../../screens/defects/my_defects_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/management/management_screen.dart';
import '../../screens/management/staff_screen.dart';
import '../../screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.myDefects,
        builder: (_, __) => const MyDefectsScreen(),
      ),
      GoRoute(
        path: AppRoutes.defectReport,
        builder: (_, __) => const DefectReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.defectDetailsPattern,
        builder: (_, state) =>
            DefectDetailsScreen(defectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.management,
        builder: (_, __) => const ManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.staff,
        builder: (_, __) => const StaffScreen(),
      ),
    ],
  );
}
