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
      when(() => solvedApiClient.supportsV4).thenReturn(false);
      searchRepository = SearchRepository(solvedApiClient: solvedApiClient);
    });

    group('getProblems', () {
      const query = 'rsa';
      const page = 1;
      const sort = solved_api.SolvedApiV4ProblemSort.level;
      const direction = solved_api.SolvedApiV4SearchDirection.desc;
      const result = solved_api.SearchObject<solved_api.ProblemSearchItem>(
        count: 0,
        items: [],
      );

      test('maps typed options to the legacy v3 request', () async {
        when(
          () => solvedApiClient.searchProblem(
            query,
            page,
            sort.value,
            direction.value,
          ),
        ).thenAnswer((_) async => result);

        expect(
          await searchRepository.getProblems(
            query,
            page: page,
            sort: sort,
            direction: direction,
          ),
          same(result),
        );
        verify(
          () => solvedApiClient.searchProblem(
            query,
            page,
            sort.value,
            direction.value,
          ),
        ).called(1);
        verifyNever(
          () => solvedApiClient.v4SearchProblems(
            query,
            page: page,
            sort: sort,
            direction: direction,
          ),
        );
      });

      test('uses the v4 problem endpoint when configured', () async {
        when(() => solvedApiClient.supportsV4).thenReturn(true);
        when(
          () => solvedApiClient.v4SearchProblems(
            query,
            page: page,
            sort: sort,
            direction: direction,
          ),
        ).thenAnswer((_) async => result);

        expect(
          await searchRepository.getProblems(
            query,
            page: page,
            sort: sort,
            direction: direction,
          ),
          same(result),
        );
        verify(
          () => solvedApiClient.v4SearchProblems(
            query,
            page: page,
            sort: sort,
            direction: direction,
          ),
        ).called(1);
        verifyNever(
          () => solvedApiClient.searchProblem(
            any(),
            any(),
            any(),
            any(),
          ),
        );
      });
    });

    group('getUsers', () {
      const query = 'fdsa';
      const page = 1;
      const item = solved_api.UserSearchItem(
        handle: 'fdsa',
        profileImageUrl: null,
        tier: null,
      );

      test('normalizes v3 items without inventing an exact match', () async {
        final items = <solved_api.UserSearchItem>[item];
        when(
          () => solvedApiClient.searchUser(query, page),
        ).thenAnswer(
          (_) async => solved_api.SearchObject(
            count: 1,
            items: items,
          ),
        );

        final actual = await searchRepository.getUsers(query, page: page);

        expect(actual.exact, isNull);
        expect(actual.items, same(items));
        verify(() => solvedApiClient.searchUser(query, page)).called(1);
        verifyNever(() => solvedApiClient.v4SearchUsers(any()));
      });

      test('preserves the separate v4 exact and item results', () async {
        when(() => solvedApiClient.supportsV4).thenReturn(true);
        const result = solved_api.UserSearchResult(
          exact: item,
          items: [item],
        );
        when(
          () => solvedApiClient.v4SearchUsers(query),
        ).thenAnswer((_) async => result);

        expect(
          await searchRepository.getUsers(query, page: page),
          same(result),
        );
        verify(() => solvedApiClient.v4SearchUsers(query)).called(1);
        verifyNever(() => solvedApiClient.searchUser(any(), any()));
      });
    });

    group('getTags', () {
      const query = 'graph';
      const page = 1;
      const result = solved_api.SearchObject<solved_api.TagSearchItem>(
        count: 0,
        items: [],
      );

      test('uses the v3 tag endpoint when v4 is unavailable', () async {
        when(
          () => solvedApiClient.searchTag(query, page),
        ).thenAnswer((_) async => result);

        expect(
          await searchRepository.getTags(query, page: page),
          same(result),
        );
        verify(() => solvedApiClient.searchTag(query, page)).called(1);
        verifyNever(
          () => solvedApiClient.v4SearchTags(query, page: page),
        );
      });

      test('uses the v4 tag endpoint with explicit page one', () async {
        when(() => solvedApiClient.supportsV4).thenReturn(true);
        when(
          () => solvedApiClient.v4SearchTags(query, page: page),
        ).thenAnswer((_) async => result);

        expect(
          await searchRepository.getTags(query, page: page),
          same(result),
        );
        verify(
          () => solvedApiClient.v4SearchTags(query, page: page),
        ).called(1);
        verifyNever(() => solvedApiClient.searchTag(any(), any()));
      });
    });
  });
}
