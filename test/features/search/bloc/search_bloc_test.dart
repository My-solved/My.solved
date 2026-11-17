import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:my_solved/features/search/bloc/search_bloc.dart';
import 'package:my_solved/features/search_filter/bloc/search_filter_bloc.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';

void main() {
  test('loads problem, user, and tag results concurrently', () async {
    final problemsCompleter = Completer<SearchObject<ProblemSearchItem>>();
    final usersCompleter = Completer<SearchObject<UserSearchItem>>();
    final tagsCompleter = Completer<SearchObject<TagSearchItem>>();
    final allRequestsStarted = Completer<void>();
    var startedRequestCount = 0;

    void markRequestStarted() {
      startedRequestCount++;
      if (startedRequestCount == 3) allRequestsStarted.complete();
    }

    final repository = _TestSearchRepository(
      onProblems: (query, page, sort, direction) {
        expect(query, 'alpha -s@w8385');
        expect(sort, 'id');
        expect(direction, 'asc');
        markRequestStarted();
        return problemsCompleter.future;
      },
      onUsers: (query, page) {
        expect(query, 'alpha');
        markRequestStarted();
        return usersCompleter.future;
      },
      onTags: (query, page) {
        expect(query, 'alpha');
        markRequestStarted();
        return tagsCompleter.future;
      },
    );
    final bloc = _createBloc(repository);
    addTearDown(bloc.close);

    bloc.add(SearchTextFieldOnSummited(text: 'alpha'));

    await allRequestsStarted.future.timeout(const Duration(seconds: 1));
    expect(bloc.state.status, SearchStatus.loading);

    const problems = SearchObject<ProblemSearchItem>(count: 1, items: []);
    const users = SearchObject<UserSearchItem>(count: 1, items: []);
    const tags = SearchObject<TagSearchItem>(count: 1, items: []);
    problemsCompleter.complete(problems);
    usersCompleter.complete(users);
    tagsCompleter.complete(tags);

    await _waitForState(bloc, (state) => state.status.isSuccess);
    expect(bloc.state.problems, same(problems));
    expect(bloc.state.users, same(users));
    expect(bloc.state.tags, same(tags));
  });

  test('emits failure when a full search request fails', () async {
    final pendingTags = Completer<SearchObject<TagSearchItem>>();
    final repository = _TestSearchRepository(
      onProblems: (_, __, ___, ____) async => throw StateError('offline'),
      onUsers: (_, __) async =>
          const SearchObject<UserSearchItem>(count: 0, items: []),
      onTags: (_, __) => pendingTags.future,
    );
    final bloc = _createBloc(repository);
    addTearDown(bloc.close);
    final statuses = <SearchStatus>[];
    final subscription = bloc.stream.listen(
      (state) => statuses.add(state.status),
    );
    addTearDown(subscription.cancel);

    bloc.add(SearchTextFieldOnSummited(text: 'alpha'));

    await _waitForState(bloc, (state) => state.status.isFailure);
    expect(
      statuses,
      containsAllInOrder([SearchStatus.loading, SearchStatus.failure]),
    );
  });

  test('does not add a solved filter without a saved handle', () async {
    final repository = _TestSearchRepository(
      onProblems: (query, page, sort, direction) async {
        expect(query, 'alpha');
        return const SearchObject<ProblemSearchItem>(count: 0, items: []);
      },
    );
    final bloc = _createBloc(repository, handle: null);
    addTearDown(bloc.close);

    bloc.add(SearchTextFieldOnSummited(text: 'alpha'));

    await _waitForState(bloc, (state) => state.status.isSuccess);
  });

  test('ignores a stale response from an older search', () async {
    final oldProblems = Completer<SearchObject<ProblemSearchItem>>();
    final oldUsers = Completer<SearchObject<UserSearchItem>>();
    final oldTags = Completer<SearchObject<TagSearchItem>>();
    final oldRequestsStarted = Completer<void>();
    var oldStartedCount = 0;

    void markOldRequestStarted() {
      oldStartedCount++;
      if (oldStartedCount == 3) oldRequestsStarted.complete();
    }

    const latestProblems = SearchObject<ProblemSearchItem>(
      count: 101,
      items: [],
    );
    const latestUsers = SearchObject<UserSearchItem>(count: 102, items: []);
    const latestTags = SearchObject<TagSearchItem>(count: 103, items: []);
    final repository = _TestSearchRepository(
      onProblems: (query, page, sort, direction) {
        if (query.startsWith('old ')) {
          markOldRequestStarted();
          return oldProblems.future;
        }
        return Future.value(latestProblems);
      },
      onUsers: (query, page) {
        if (query == 'old') {
          markOldRequestStarted();
          return oldUsers.future;
        }
        return Future.value(latestUsers);
      },
      onTags: (query, page) {
        if (query == 'old') {
          markOldRequestStarted();
          return oldTags.future;
        }
        return Future.value(latestTags);
      },
    );
    final bloc = _createBloc(repository);
    final successStates = <SearchState>[];
    final subscription = bloc.stream.listen((state) {
      if (state.status.isSuccess) successStates.add(state);
    });
    addTearDown(subscription.cancel);

    bloc.add(SearchTextFieldOnSummited(text: 'old'));
    await oldRequestsStarted.future.timeout(const Duration(seconds: 1));
    bloc.add(SearchTextFieldOnSummited(text: 'latest'));
    await _waitForState(
      bloc,
      (state) => state.status.isSuccess && state.text == 'latest',
    );

    oldProblems.complete(
      const SearchObject<ProblemSearchItem>(count: 201, items: []),
    );
    oldUsers.complete(
      const SearchObject<UserSearchItem>(count: 202, items: []),
    );
    oldTags.complete(const SearchObject<TagSearchItem>(count: 203, items: []));
    await bloc.close();

    expect(successStates, hasLength(1));
    expect(bloc.state.text, 'latest');
    expect(bloc.state.problems, same(latestProblems));
  });

  test('a full search commits the current optimistic filter values', () async {
    final pendingFilterResult = Completer<SearchObject<ProblemSearchItem>>();
    final pendingFilterStarted = Completer<void>();
    var failRequests = false;
    const fullSearchProblems = SearchObject<ProblemSearchItem>(
      count: 301,
      items: [],
    );
    final repository = _TestSearchRepository(
      onProblems: (query, page, sort, direction) {
        if (query.startsWith('alpha') && !pendingFilterStarted.isCompleted) {
          pendingFilterStarted.complete();
          return pendingFilterResult.future;
        }
        if (failRequests) return Future.error(StateError('offline'));
        expect(query, 'beta -s@w8385');
        expect(sort, SearchSortMethod.level.value);
        expect(direction, SearchDirection.asc.value);
        return Future.value(fullSearchProblems);
      },
    );
    final bloc = _createBloc(repository);
    addTearDown(bloc.close);
    bloc.add(SearchTextFieldOnChanged(text: 'alpha'));
    await _waitForState(bloc, (state) => state.text == 'alpha');

    bloc.add(SearchFilterSortMethodSelected(sort: SearchSortMethod.level));
    await pendingFilterStarted.future.timeout(const Duration(seconds: 1));
    bloc.add(SearchTextFieldOnSummited(text: 'beta'));
    await _waitForState(
      bloc,
      (state) => state.status.isSuccess && state.text == 'beta',
    );
    expect(bloc.state.sort, SearchSortMethod.level);

    pendingFilterResult.complete(
      const SearchObject<ProblemSearchItem>(count: 302, items: []),
    );
    failRequests = true;
    bloc.add(SearchFilterDirectionSelected(direction: SearchDirection.desc));
    await _waitForState(bloc, (state) => state.status.isFailure);

    expect(bloc.state.sort, SearchSortMethod.level);
    expect(bloc.state.direction, SearchDirection.asc);
    expect(bloc.state.problems, same(fullSearchProblems));
  });

  test('filter requests emit loading and failure consistently', () async {
    const committedProblems = SearchObject<ProblemSearchItem>(
      count: 1,
      items: [],
    );
    final repository = _TestSearchRepository(
      onProblems: (_, __, sort, ___) async {
        if (sort == SearchSortMethod.level.value) {
          throw StateError('offline');
        }
        return committedProblems;
      },
    );
    final bloc = _createBloc(repository);
    addTearDown(bloc.close);
    bloc.add(SearchTextFieldOnChanged(text: 'alpha'));
    await _waitForState(bloc, (state) => state.text == 'alpha');
    bloc.add(SearchFilterDirectionSelected(direction: SearchDirection.asc));
    await _waitForState(
      bloc,
      (state) => state.status.isSuccess && state.problems == committedProblems,
    );
    final statuses = <SearchStatus>[];
    final subscription = bloc.stream.listen(
      (state) => statuses.add(state.status),
    );
    addTearDown(subscription.cancel);

    bloc.add(SearchFilterSortMethodSelected(sort: SearchSortMethod.level));

    await _waitForState(bloc, (state) => state.status.isFailure);
    expect(
      statuses,
      containsAllInOrder([SearchStatus.loading, SearchStatus.failure]),
    );
    expect(bloc.state.sort, SearchSortMethod.id);
    expect(bloc.state.problems, same(committedProblems));

    bloc.add(SearchFilterShowProblemTagChanged(isOn: true));
    await _waitForState(
      bloc,
      (state) => state.status.isSuccess && state.showProblemTag,
    );
  });

  test(
    'a successful filter request updates the problem result and filter',
    () async {
      const filteredProblems = SearchObject<ProblemSearchItem>(
        count: 1,
        items: [],
      );
      final repository = _TestSearchRepository(
        onProblems: (query, page, sort, direction) async {
          expect(query, 'alpha -s@w8385');
          expect(sort, SearchSortMethod.id.value);
          expect(direction, SearchDirection.desc.value);
          return filteredProblems;
        },
      );
      final bloc = _createBloc(repository);
      addTearDown(bloc.close);
      bloc.add(SearchTextFieldOnChanged(text: 'alpha'));
      await _waitForState(bloc, (state) => state.text == 'alpha');

      bloc.add(SearchFilterDirectionSelected(direction: SearchDirection.desc));

      await _waitForState(
        bloc,
        (state) =>
            state.status.isSuccess && state.direction == SearchDirection.desc,
      );
      expect(bloc.state.problems, same(filteredProblems));
      expect(bloc.state.showSolvedProblem, isTrue);
    },
  );
}

SearchBloc _createBloc(
  _TestSearchRepository repository, {
  String? handle = 'w8385',
}) {
  return SearchBloc(
    searchRepository: repository,
    sharedPreferencesRepository: _TestSharedPreferencesRepository(handle),
  );
}

Future<void> _waitForState(
  SearchBloc bloc,
  bool Function(SearchState state) predicate,
) async {
  if (predicate(bloc.state)) return;
  await bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 1));
}

typedef _ProblemsHandler = Future<SearchObject<ProblemSearchItem>> Function(
  String query,
  int? page,
  String? sort,
  String? direction,
);
typedef _UsersHandler = Future<SearchObject<UserSearchItem>> Function(
    String query, int? page);
typedef _TagsHandler = Future<SearchObject<TagSearchItem>> Function(
    String query, int? page);

class _TestSearchRepository extends SearchRepository {
  _TestSearchRepository({
    _ProblemsHandler? onProblems,
    _UsersHandler? onUsers,
    _TagsHandler? onTags,
  })  : _onProblems = onProblems ?? _emptyProblems,
        _onUsers = onUsers ?? _emptyUsers,
        _onTags = onTags ?? _emptyTags,
        super(
          solvedApiClient: SolvedApiClient(
            httpClient: _NoopHttpClient(),
            useProxy: false,
          ),
        );

  final _ProblemsHandler _onProblems;
  final _UsersHandler _onUsers;
  final _TagsHandler _onTags;

  static Future<SearchObject<ProblemSearchItem>> _emptyProblems(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) async {
    return const SearchObject<ProblemSearchItem>(count: 0, items: []);
  }

  static Future<SearchObject<UserSearchItem>> _emptyUsers(
    String query,
    int? page,
  ) async {
    return const SearchObject<UserSearchItem>(count: 0, items: []);
  }

  static Future<SearchObject<TagSearchItem>> _emptyTags(
    String query,
    int? page,
  ) async {
    return const SearchObject<TagSearchItem>(count: 0, items: []);
  }

  @override
  Future<SearchObject<ProblemSearchItem>> getProblems(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) {
    return _onProblems(query, page, sort, direction);
  }

  @override
  Future<SearchObject<UserSearchItem>> getUsers(String query, int? page) {
    return _onUsers(query, page);
  }

  @override
  Future<SearchObject<TagSearchItem>> getTags(String query, int? page) {
    return _onTags(query, page);
  }
}

class _TestSharedPreferencesRepository extends SharedPreferencesRepository {
  _TestSharedPreferencesRepository(this.handle);

  final String? handle;

  @override
  Future<String?> requestHandle() async => handle;
}

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnsupportedError('No HTTP request expected in SearchBloc tests');
  }
}
