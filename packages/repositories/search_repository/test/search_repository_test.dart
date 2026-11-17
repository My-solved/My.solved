import 'package:mocktail/mocktail.dart';
import 'package:search_repository/search_repository.dart';
import 'package:solved_api/solved_api.dart' as solved_api;
import 'package:test/test.dart';

class MockSolvedApiClient extends Mock implements solved_api.SolvedApiClient {}

void main() {
  group('SearchRepository', () {
    late solved_api.SolvedApiClient solvedApiClient;
    late SearchRepository searchRepository;

    setUp(() {
      solvedApiClient = MockSolvedApiClient();
      searchRepository = SearchRepository(solvedApiClient: solvedApiClient);
    });

    group('getProblems', () {
      const query = 'rsa';
      const page = 1;
      const sort = 'id';
      const direction = 'asc';

      test(
        'calls searchProblem with correct query, page, sort, direction',
        () async {
          try {
            await searchRepository.getProblems(query, page, sort, direction);
          } catch (_) {}
          verify(
            () => solvedApiClient.searchProblem(query, page, sort, direction),
          ).called(1);
        },
      );

      test('returns correct searchObject on success', () async {
        const searchObject =
            solved_api.SearchObject<solved_api.ProblemSearchItem>(
          count: 0,
          items: [],
        );
        when(
          () => solvedApiClient.searchProblem(query, page, sort, direction),
        ).thenAnswer((_) async => searchObject);

        expect(
          await searchRepository.getProblems(query, page, sort, direction),
          searchObject,
        );
      });
    });

    group('getUsers', () {
      const query = 'fdsa';
      const page = 1;

      test('calls searchUser with correct query, page', () async {
        try {
          await searchRepository.getUsers(query, page);
        } catch (_) {}
        verify(() => solvedApiClient.searchUser(query, page)).called(1);
      });

      test('returns correct searchObject on success', () async {
        const searchObject = solved_api.SearchObject<solved_api.UserSearchItem>(
          count: 0,
          items: [],
        );
        when(
          () => solvedApiClient.searchUser(query, page),
        ).thenAnswer((_) async => searchObject);

        expect(await searchRepository.getUsers(query, page), searchObject);
      });
    });

    group('getTags', () {
      const query = 'graph';
      const page = 1;

      test('calls searchTag with correct query, page', () async {
        try {
          await searchRepository.getTags(query, page);
        } catch (_) {}
        verify(() => solvedApiClient.searchTag(query, page)).called(1);
      });

      test('returns correct searchObject on success', () async {
        const searchObject = solved_api.SearchObject<solved_api.TagSearchItem>(
          count: 0,
          items: [],
        );
        when(
          () => solvedApiClient.searchTag(query, page),
        ).thenAnswer((_) async => searchObject);

        expect(await searchRepository.getTags(query, page), searchObject);
      });
    });
  });
}
