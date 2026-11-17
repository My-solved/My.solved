import 'dart:async';

import 'package:solved_api/solved_api.dart';

class UserRepository {
  UserRepository({SolvedApiClient? solvedApiClient})
      : _solvedApiClient = solvedApiClient ?? SolvedApiClient();

  final SolvedApiClient _solvedApiClient;

  bool get supportsV4 => _solvedApiClient.supportsV4;

  Future<UserProfile> getUser(String handle) async {
    if (supportsV4) return await _solvedApiClient.v4UserProfile(handle);
    return await _solvedApiClient.userShow(handle);
  }

  Future<ProfileStreak> getStreak(
    String handle, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (supportsV4) {
      return await _solvedApiClient.v4UserActivity(
        handle,
        from: from,
        to: to,
      );
    }
    return await _solvedApiClient.userGrass(handle, 'default');
  }

  Future<List<ProfileTierStat>> getProblemStats(String handle) async {
    return await _solvedApiClient.userProblemStats(handle);
  }

  Future<List<ProfileTagRating>> getTagRatings(String handle) async {
    return await _solvedApiClient.userTagRatings(handle);
  }

  Future<ProfileBackgroundAsset> getBackground(String backgroundId) async {
    return await _solvedApiClient.backgroundShow(backgroundId);
  }

  Future<ProfileBadgeAsset> getBadge(String badgeId) async {
    return await _solvedApiClient.badgeShow(badgeId);
  }
}
