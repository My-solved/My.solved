import 'dart:async';

import 'package:solved_api/solved_api.dart';

class UserRepository {
  UserRepository({SolvedApiClient? solvedApiClient})
      : _solvedApiClient = solvedApiClient ?? SolvedApiClient();

  final SolvedApiClient _solvedApiClient;

  Future<User> getUser(String handle) async {
    return await _solvedApiClient.userShow(handle);
  }

  Future<List<Organization>> getOrganizations(String handle) async {
    return await _solvedApiClient.userOrganizations(handle);
  }

  Future<List<Badge>> getBadges(String handle) async {
    return await _solvedApiClient.userAvailableBadges(handle);
  }

  Future<Streak> getStreak(String handle, String? topic) async {
    return await _solvedApiClient.userGrass(handle, topic);
  }

  Future<List<Problem>> getTopProblems(String handle) async {
    return await _solvedApiClient.userTop100(handle);
  }

  Future<List<TagRating>> getTagRatings(String handle) async {
    return await _solvedApiClient.userTagRatings(handle);
  }

  Future<Background> getBackground(String backgroundId) async {
    return await _solvedApiClient.backgroundShow(backgroundId);
  }

  Future<Badge> getBadge(String badgeId) async {
    return await _solvedApiClient.badgeShow(badgeId);
  }

  Future<SiteStats> getSiteStats() async {
    return await _solvedApiClient.siteStats();
  }
}
