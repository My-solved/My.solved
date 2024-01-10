import 'package:mocktail/mocktail.dart';
import 'package:search_repository/search_repository.dart';
import 'package:solved_api/solved_api.dart' as solved_api;
import 'package:test/test.dart';

class MockSolvedApiClient extends Mock implements solved_api.SolvedApiClient {}

class MockSearchSuggestion extends Mock
    implements solved_api.SearchSuggestion {}

class MockSearchObject extends Mock implements solved_api.SearchObject {}

void main() {
  group('SearchRepository', () {
    late solved_api.SolvedApiClient solvedApiClient;
    late SearchRepository searchRepository;

    setUp(() {
      solvedApiClient = MockSolvedApiClient();
      searchRepository = SearchRepository(solvedApiClient: solvedApiClient);
    });

    group('getSuggestions', () {
      const query = 'rsa';

      test('calls searchSuggestion with correct query', () async {
        try {
          await searchRepository.getSuggestions(query);
        } catch (_) {}
        verify(() => solvedApiClient.searchSuggestion(query)).called(1);
      });

      test('returns correct searchSuggestion on success', () async {
        final searchSuggestion = MockSearchSuggestion();
        when(() => solvedApiClient.searchSuggestion(query))
            .thenAnswer((_) async => searchSuggestion);

        expect(await searchRepository.getSuggestions(query), searchSuggestion);
      });
    });

    group('getProblems', () {
      const query = 'rsa';
      const page = 1;
      const sort = 'id';
      const direction = 'asc';

      test('calls searchProblem with correct query, page, sort, direction',
          () async {
        try {
          await searchRepository.getProblems(query, page, sort, direction);
        } catch (_) {}
        verify(() =>
                solvedApiClient.searchProblem(query, page, sort, direction))
            .called(1);
      });

      test('returns correct searchObject on success', () async {
        final searchObject = MockSearchObject();
        when(() => solvedApiClient.searchProblem(query, page, sort, direction))
            .thenAnswer((_) async => searchObject);

        expect(await searchRepository.getProblems(query, page, sort, direction),
            searchObject);
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
        final searchObject = MockSearchObject();
        when(() => solvedApiClient.searchTag(query, page))
            .thenAnswer((_) async => searchObject);

        expect(await searchRepository.getTags(query, page), searchObject);
      });
    });
  });
}
