import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:my_solved/app/bloc/app_bloc.dart';
import 'package:my_solved/features/login/screen/login_screen.dart';
import 'package:my_solved/features/root/screen/root_screen.dart';
import 'package:my_solved/features/splash/screen/splash_screen.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';
import 'package:upgrader/upgrader.dart';
import 'package:user_repository/user_repository.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key, this.httpClient});

  final http.Client? httpClient;

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  static final Uri _solvedApiBaseUri = Uri.https('solved.ac', '/api/v3/');
  static final Uri _solvedProxyBaseUri =
      Uri.https('codepoker.w8385.dev', '/solved/');

  late final http.Client _httpClient;
  late final bool _ownsHttpClient;
  late final SolvedApiClient _solvedApiClient;
  late final UserRepository _userRepository;
  late final SearchRepository _searchRepository;

  @override
  void initState() {
    super.initState();
    _ownsHttpClient = widget.httpClient == null;
    _httpClient = widget.httpClient ?? http.Client();
    _solvedApiClient = SolvedApiClient(
      httpClient: _httpClient,
      apiBaseUri: _solvedApiBaseUri,
      proxyBaseUri: _solvedProxyBaseUri,
    );
    _userRepository = UserRepository(solvedApiClient: _solvedApiClient);
    _searchRepository = SearchRepository(solvedApiClient: _solvedApiClient);
  }

  @override
  void dispose() {
    _solvedApiClient.close();
    if (_ownsHttpClient) _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _solvedApiClient),
        RepositoryProvider.value(value: _userRepository),
        RepositoryProvider.value(value: _searchRepository),
      ],
      child: BlocProvider(
        create: (context) =>
            AppBloc(sharedPreferencesRepository: SharedPreferencesRepository()),
        child: AppView(),
      ),
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
        home: UpgradeAlert(
      child: BlocBuilder<AppBloc, AppState>(
        bloc: BlocProvider.of<AppBloc>(context),
        builder: (context, state) {
          if (state is AppInitial) {
            return SplashScreen();
          } else if (state is AppLoggedIn) {
            return RootScreen(handle: state.handle);
          } else {
            return LoginScreen();
          }
        },
      ),
    ));
  }
}
