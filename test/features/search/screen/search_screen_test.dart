import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:my_solved/features/search/bloc/search_bloc.dart';
import 'package:my_solved/features/search/screen/search_screen.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';

void main() {
  testWidgets(
    'renders exact users separately and preserves nullable v4 fields',
    (tester) async {
      const duplicate = UserSearchItem(
        handle: 'same-handle',
        profileImageUrl: null,
        tier: null,
      );
      final repository = _SearchScreenRepository(
        users: const UserSearchResult(
          exact: duplicate,
          items: [
            duplicate,
            UserSearchItem(
              handle: 'second-handle',
              profileImageUrl: null,
              tier: 10,
            ),
          ],
        ),
      );
      final bloc = SearchBloc(
        searchRepository: repository,
        sharedPreferencesRepository: _SearchScreenPreferences(),
      );
      addTearDown(bloc.close);

      bloc.add(SearchTextFieldOnSummited(text: 'same'));
      await _waitForState(bloc, (state) => state.status.isSuccess);
      bloc.add(SearchSegmentedControlTapped(index: 1));
      await _waitForState(bloc, (state) => state.currentIndex == 1);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SearchBloc>.value(
            value: bloc,
            child: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('user-search-exact-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('user-search-items-section')),
        findsOneWidget,
      );
      expect(find.text('정확히 일치'), findsOneWidget);
      expect(find.text('검색 결과'), findsOneWidget);
      expect(find.text('same-handle'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('user-search-exact-same-handle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-search-item-0-same-handle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-search-item-1-second-handle')),
        findsOneWidget,
      );

      bloc.add(SearchSegmentedControlTapped(index: 2));
      await _waitForState(bloc, (state) => state.currentIndex == 2);
      await tester.pump();

      expect(find.text('다이나믹 프로그래밍 (dynamic_programming)'), findsOneWidget);
      expect(find.text('number_theory:1314'), findsOneWidget);
      expect(find.text('same_key'), findsOneWidget);
      expect(find.text('same_key (same_key)'), findsNothing);
      expect(find.text('key_only:7'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    },
  );
}

Future<void> _waitForState(
  SearchBloc bloc,
  bool Function(SearchState state) predicate,
) async {
  if (predicate(bloc.state)) return;
  await bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 1));
}

final class _SearchScreenRepository extends SearchRepository {
  _SearchScreenRepository({required this.users})
    : super(
        solvedApiClient: SolvedApiClient(
          httpClient: _NoopHttpClient(),
          useProxy: false,
        ),
      );

  final UserSearchResult users;

  @override
  Future<SearchObject<ProblemSearchItem>> getProblems(
    String query, {
    int page = 1,
    required SolvedApiV4ProblemSort sort,
    required SolvedApiV4SearchDirection direction,
  }) async => const SearchObject(count: 0, items: []);

  @override
  Future<UserSearchResult> getUsers(String query, {int page = 1}) async =>
      users;

  @override
  Future<SearchObject<TagSearchItem>> getTags(
    String query, {
    int page = 1,
  }) async => const SearchObject(
    count: 4,
    items: [
      TagSearchItem(
        key: 'dynamic_programming',
        problemCount: null,
        displayName: '다이나믹 프로그래밍',
      ),
      TagSearchItem(key: 'number_theory', problemCount: 1314),
      TagSearchItem(
        key: 'same_key',
        problemCount: null,
        displayName: ' SAME_KEY ',
      ),
      TagSearchItem(key: 'key_only', problemCount: 7),
    ],
  );
}

final class _SearchScreenPreferences extends SharedPreferencesRepository {
  @override
  Future<String?> requestHandle() async => null;
}

final class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnsupportedError('No HTTP request expected in SearchScreen tests');
  }
}
