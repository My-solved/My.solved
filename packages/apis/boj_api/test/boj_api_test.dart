import 'package:boj_api/boj_api.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class FakeUri extends Fake implements Uri {}

void main() {
  group('BojApiClient', () {
    late http.Client httpClient;
    late BojApiClient apiClient;

    setUpAll(() {
      registerFallbackValue(FakeUri());
    });

    setUp(() {
      httpClient = MockHttpClient();
      apiClient = BojApiClient(httpClient: httpClient);
    });

    group('contests', () {
      test('returns contests', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body)
            .thenReturn('{"ongoing":[],"upcoming":[],"ended":[]}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final contests = await apiClient.contests();

        expect(contests, {
          ContestType.ongoing: [],
          ContestType.upcoming: [],
          ContestType.ended: [],
        });
      });
    });
  });
}
