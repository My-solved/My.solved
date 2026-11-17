import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:my_solved/app/bloc/app_bloc.dart';
import 'package:my_solved/app/config/solved_api_gateway_config.dart';
import 'package:my_solved/app/config/solved_oauth_runtime_config.dart';
import 'package:my_solved/features/login/screen/login_screen.dart';
import 'package:my_solved/features/root/screen/root_screen.dart';
import 'package:my_solved/features/splash/screen/splash_screen.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';
import 'package:upgrader/upgrader.dart';
import 'package:user_repository/user_repository.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key, this.httpClient, this.solvedApiGatewayConfig});

  final http.Client? httpClient;
  final SolvedApiGatewayConfig? solvedApiGatewayConfig;

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  bool _resourcesInitialized = false;
  late final http.Client _httpClient;
  late final bool _ownsHttpClient;
  late final SolvedApiGatewayConfig _solvedApiGatewayConfig;
  late final SolvedApiClient _solvedApiClient;
  late final SolvedOAuthRuntimeConfig _solvedOAuthRuntimeConfig;
  late final SolvedOAuthClient? _solvedOAuthClient;
  late final UserRepository _userRepository;
  late final SearchRepository _searchRepository;

  @override
  void initState() {
    super.initState();
    _solvedApiGatewayConfig =
        widget.solvedApiGatewayConfig ??
        SolvedApiGatewayConfig.fromEnvironment();
    _solvedOAuthRuntimeConfig = SolvedOAuthRuntimeConfig.fromEnvironment(
      gatewayConfig: _solvedApiGatewayConfig,
    );
    _ownsHttpClient = widget.httpClient == null;
    _httpClient = widget.httpClient ?? http.Client();
    _solvedApiClient = _solvedApiGatewayConfig.createClient(
      httpClient: _httpClient,
    );
    _solvedOAuthClient =
        _solvedOAuthRuntimeConfig.isConfigured
            ? _solvedOAuthRuntimeConfig.createClient(httpClient: _httpClient)
            : null;
    _userRepository = UserRepository(solvedApiClient: _solvedApiClient);
    _searchRepository = SearchRepository(solvedApiClient: _solvedApiClient);
    _resourcesInitialized = true;
  }

  @override
  void dispose() {
    if (_resourcesInitialized) {
      _solvedOAuthClient?.close();
      _solvedApiClient.close();
      if (_ownsHttpClient) _httpClient.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _solvedApiClient),
        RepositoryProvider.value(value: _solvedOAuthRuntimeConfig),
        if (_solvedOAuthClient != null)
          RepositoryProvider<SolvedOAuthClient>.value(
            value: _solvedOAuthClient,
          ),
        RepositoryProvider.value(value: _userRepository),
        RepositoryProvider.value(value: _searchRepository),
      ],
      child: BlocProvider(
        create:
            (context) => AppBloc(
              sharedPreferencesRepository: SharedPreferencesRepository(),
            ),
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
      ),
    );
  }
}
