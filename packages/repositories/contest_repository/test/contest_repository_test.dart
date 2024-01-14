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
      test('calls officialContestList and otherContestList', () async {
        try {
          await contestRepository.getContests();
        } catch (_) {}
        verify(() {
          bojApiClient.otherContestList();
          bojApiClient.officialContestList();
        }).called(1);
      });

      test('returns correct contests on success', () async {
        final otherContests = (
          [MockContest()],
          [MockContest()],
        );
        when(() => bojApiClient.otherContestList())
            .thenAnswer((_) async => otherContests);

        final officialContests = [MockContest()];
        when(() => bojApiClient.officialContestList())
            .thenAnswer((_) async => officialContests);

        expect(await contestRepository.getContests(), {
          ContestType.ended: officialContests,
          ContestType.upcoming: otherContests.$1,
          ContestType.ongoing: otherContests.$2,
        });
      });
    });
  });
}
