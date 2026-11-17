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

  /// Returns the legacy tier distribution when using the v3 fallback.
  ///
  /// Official solved.ac v4 does not expose an equivalent distribution. In
  /// particular, its rating histogram must not be reinterpreted as tier data.
  Future<List<ProfileTierStat>> getProblemStats(String handle) async {
    if (supportsV4) {
      throw UnsupportedError(
        'Official solved.ac v4 does not expose a tier distribution',
      );
    }
    return _solvedApiClient.userProblemStats(handle);
  }

  Future<List<ProfileTagRating>> getTagRatings(String handle) async {
    if (supportsV4) {
      return (await _solvedApiClient.v4UserProfile(handle)).tagRatings;
    }
    return _solvedApiClient.userTagRatings(handle);
  }

  Future<ProfileBackgroundAsset?> getBackground(String backgroundId) {
    if (supportsV4) return _solvedApiClient.v4BackgroundShow(backgroundId);
    return _solvedApiClient.backgroundShow(backgroundId);
  }

  Future<ProfileBadgeAsset> getBadge(String badgeId) {
    if (supportsV4) return _solvedApiClient.v4BadgeShow(badgeId);
    return _solvedApiClient.badgeShow(badgeId);
  }
}
