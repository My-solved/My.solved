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

    group('officialContestList', () {
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.officialContestList();
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'acmicpc.net',
              '/contest/official/list',
            ),
          ),
        ).called(1);
      });

      test('returns List<Contest> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
          <html>
            <body>
              <div class="col-md-12"></div>
              <div class="col-md-12">
                <table>
                  <tbody>
                    <tr>
                      <td>BOJ Open</td>
                      <td><a href="/contest/view/1084">제3회 고려대학교 MatKor Cup : 2023 Summer Open Contest - Phase 1 · Arena #3</a></td>
                      <td><span data-timestamp="1692082800" class="update-local-time" data-remove-second="true">2023년 8월 15일 16:00</span></td>
                      <td><span data-timestamp="1692097200" class="update-local-time" data-remove-second="true">2023년 8월 15일 20:00</span></td>
                      <td>종료</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </body>
          </html>
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final contests = await apiClient.officialContestList();
        expect(contests, isA<List<Contest>>());
        expect(contests.length, equals(1));
        expect(contests[0].venue, equals('BOJ Open'));
        expect(
            contests[0].name,
            equals(
                '제3회 고려대학교 MatKor Cup : 2023 Summer Open Contest - Phase 1 · Arena #3'));
        expect(
            contests[0].url, equals('https://acmicpc.net/contest/view/1084'));
        expect(
            contests[0].startTime,
            equals(DateTime.fromMillisecondsSinceEpoch(1692082800 * 1000,
                    isUtc: true)
                .toLocal()));
        expect(
            contests[0].endTime,
            equals(DateTime.fromMillisecondsSinceEpoch(1692097200 * 1000,
                    isUtc: true)
                .toLocal()));
      });
    });
  });
}
