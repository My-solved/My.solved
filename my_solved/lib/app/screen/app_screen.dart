import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/app/bloc/app_bloc.dart';
import 'package:my_solved/features/login/screen/login_screen.dart';
import 'package:my_solved/features/root/screen/root_screen.dart';
import 'package:my_solved/features/splash/screen/splash_screen.dart';
import 'package:my_solved/packages/user_repository/lib/user_repository.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc(userRepository: UserRepository()),
      child: AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocBuilder<AppBloc, AppState>(
        bloc: context.read<AppBloc>(),
        builder: (context, state) {
          switch (state.runtimeType) {
            case AppInitial:
              return SplashScreen();
            case AppLoggedOut:
              return LoginScreen();
            default:
              return RootScreen();
          }
        },
      ),
    );
  }
}
