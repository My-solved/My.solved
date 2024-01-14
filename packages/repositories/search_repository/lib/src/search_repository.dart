import 'dart:async';

import 'package:solved_api/solved_api.dart';

class SearchRepository {
  SearchRepository({SolvedApiClient? solvedApiClient})
      : _solvedApiClient = solvedApiClient ?? SolvedApiClient();

  final SolvedApiClient _solvedApiClient;

  Future<SearchSuggestion> getSuggestions(String query) async {
    return await _solvedApiClient.searchSuggestion(query);
  }

  Future<SearchObject> getProblems(
      String query, int? page, String? sort, String? direction) async {
    return await _solvedApiClient.searchProblem(query, page, sort, direction);
  }

  Future<SearchObject> getUsers(String query, int? page) async {
    return await _solvedApiClient.searchUser(query, page);
  }

  Future<SearchObject> getTags(String query, int? page) async {
    return await _solvedApiClient.searchTag(query, page);
  }
}
