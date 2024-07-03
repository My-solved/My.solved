import 'package:boj_api/boj_api.dart' as boj_api;
import 'package:contest_repository/contest_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockBojApiClient extends Mock implements boj_api.BojApiClient {}

class MockContest extends Mock implements boj_api.Contest {}

void main() {
  group('ContestRepository', () {
    late boj_api.BojApiClient bojApiClient;
    late ContestRepository contestRepository;

    setUp(() {
      bojApiClient = MockBojApiClient();
      contestRepository = ContestRepository(bojApiClient: bojApiClient);
    });

    group('getContests', () {
      test('gets contests', () async {
        try {
          await contestRepository.getContests();
        } catch (_) {}
        verify(() => bojApiClient.contests()).called(1);
      });
    });
  });
}
