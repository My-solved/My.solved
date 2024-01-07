import 'dart:async';

import 'package:boj_api/boj_api.dart';

enum ContestType { ongoing, upcoming, ended }

class ContestRepository {
  ContestRepository({BojApiClient? bojApiClient})
      : _bojApiClient = bojApiClient ?? BojApiClient();

  final BojApiClient _bojApiClient;

  Future<Map<ContestType, List<Contest>>> getContests() async {
    final otherContests = await _bojApiClient.otherContestList();
    final endedContests = await _bojApiClient.officialContestList();

    return {
      ContestType.ongoing: otherContests.$1,
      ContestType.upcoming: otherContests.$2,
      ContestType.ended: endedContests,
    };
  }
}
