import 'package:go_router/go_router.dart';
import 'package:my_solved/components/utils/routes.dart';
import 'package:my_solved/features/login/login_screen.dart';
import 'package:my_solved/features/splash/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash.path,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.splash.path,
        name: Routes.splash.name,
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
        path: Routes.login.path,
        name: Routes.login.name,
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: Routes.root.path,
        name: Routes.root.name,
        builder: (context, state) => LoginScreen(),
      ),
    ],
  );
}
