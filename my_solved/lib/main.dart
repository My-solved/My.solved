import 'package:flutter/cupertino.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/views/login_view.dart';
import 'package:my_solved/views/main_tab_view.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: PageRouter(),
    );
  }
}

class PageRouter extends StatefulWidget {
  const PageRouter({super.key});

  @override
  State<PageRouter> createState() => PageRouterState();
}

class PageRouterState extends State<PageRouter> {
  UserService userService = UserService();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserService(),
      child: CupertinoPageScaffold(
        child: Consumer<UserService>(
          builder: (context, provider, child) =>
              route(Provider.of<UserService>(context).state),
        ),
      ),
    );
  }

  Widget route(UserState state) {
    switch (state) {
      case UserState.unknown:
        return LoginView();
      case UserState.loggedIn:
        return MainTabView();
      default:
        return Center(child: Text('loading'));
    }
  }
}
