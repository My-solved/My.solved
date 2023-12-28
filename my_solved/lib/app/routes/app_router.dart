import 'package:go_router/go_router.dart';
import 'package:my_solved/components/utils/routes.dart';
import 'package:my_solved/views/login_view.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash.path,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.splash.path,
        name: Routes.splash.name,
        builder: (context, state) => LoginView(),
      ),
      GoRoute(
        path: Routes.login.path,
        name: Routes.login.name,
        builder: (context, state) => LoginView(),
      ),
      GoRoute(
        path: Routes.root.path,
        name: Routes.root.name,
        builder: (context, state) => LoginView(),
      ),
    ],
  );
}
