import 'package:boj_api/boj_api.dart';

class ContestRepository {
  ContestRepository({BojApiClient? bojApiClient})
      : _bojApiClient = bojApiClient ?? BojApiClient();

  final BojApiClient _bojApiClient;

  Future<Map<ContestType, List<Contest>>> getContests() async {
    return await _bojApiClient.contests();
  }
}
