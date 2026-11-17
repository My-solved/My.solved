import 'dart:async';

import 'package:solved_api/solved_api.dart';

class SearchRepository {
  SearchRepository({SolvedApiClient? solvedApiClient})
      : _solvedApiClient = solvedApiClient ?? SolvedApiClient();

  final SolvedApiClient _solvedApiClient;

  Future<SearchObject<ProblemSearchItem>> getProblems(
    String query, {
    int page = 1,
    required SolvedApiV4ProblemSort sort,
    required SolvedApiV4SearchDirection direction,
  }) async {
    if (_solvedApiClient.supportsV4) {
      return _solvedApiClient.v4SearchProblems(
        query,
        page: page,
        sort: sort,
        direction: direction,
      );
    }
    return _solvedApiClient.searchProblem(
      query,
      page,
      sort.value,
      direction.value,
    );
  }

  Future<UserSearchResult> getUsers(String query, {int page = 1}) async {
    if (_solvedApiClient.supportsV4) {
      return _solvedApiClient.v4SearchUsers(query);
    }
    final legacy = await _solvedApiClient.searchUser(query, page);
    return UserSearchResult(exact: null, items: legacy.items);
  }

  Future<SearchObject<TagSearchItem>> getTags(
    String query, {
    int page = 1,
  }) async {
    if (_solvedApiClient.supportsV4) {
      return _solvedApiClient.v4SearchTags(query, page: page);
    }
    return _solvedApiClient.searchTag(query, page);
  }
}
