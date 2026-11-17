import 'dart:async';

import 'package:solved_api/solved_api.dart';

class SearchRepository {
  SearchRepository({SolvedApiClient? solvedApiClient})
      : _solvedApiClient = solvedApiClient ?? SolvedApiClient();

  final SolvedApiClient _solvedApiClient;

  Future<SearchObject<ProblemSearchItem>> getProblems(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) async {
    return await _solvedApiClient.searchProblem(query, page, sort, direction);
  }

  Future<SearchObject<UserSearchItem>> getUsers(String query, int? page) async {
    return await _solvedApiClient.searchUser(query, page);
  }

  Future<SearchObject<TagSearchItem>> getTags(String query, int? page) async {
    return await _solvedApiClient.searchTag(query, page);
  }
}
