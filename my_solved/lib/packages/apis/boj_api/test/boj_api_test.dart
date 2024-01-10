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

    group('otherContestList', () {
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.otherContestList();
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'acmicpc.net',
              '/contest/other/list',
            ),
          ),
        ).called(1);
      });

      test('returns (List<Contest>, List<Contest>) on valid response',
          () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
<html>
  <body>
    <div class="row" style="height: auto !important;">
      <div class="col-md-12">
      </div>
      <div class="col-md-12">
          <div class="headline">
              <h2>예정</h2>
          </div>
      </div>
      <div class="col-md-12">
          <div class="table-responsive">
              <table class="table table-bordered contest-other-list td-middle" style="width:100%;">
                  <thead>
                      <tr>
                          <th style="width: 10%;">대회</th>
                          <th style="width: 44%;">대회 이름</th>
                          <th style="width: 18%;">시작</th>
                          <th style="width: 18%;">종료</th>
                          <th style="width: 10%;">상태</th>
                      </tr>
                  </thead>
                  <tbody>
                      <tr class="striped" data-contest="Codeforces">
                          <td>Codeforces</td>
                          <td>Codeforces Round (Div. 2)</td>
                          <td><span data-timestamp="1704888300" class="update-local-time" data-remove-second="true">2024년 1월 10일 21:05</span></td>
                          <td><span data-timestamp="1704895500" class="update-local-time" data-remove-second="true">2024년 1월 10일 23:05</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1704888300" data-timestamp="1704895500">시작까지 2일 17:26:06</td>
                      </tr>
                      <tr data-contest="CodeChef">
                          <td>CodeChef</td>
                          <td><a href="https://www.codechef.com/START116" target="_blank">Starters 116</a></td>
                          <td><span data-timestamp="1704897000" class="update-local-time" data-remove-second="true">2024년 1월 10일 23:30</span></td>
                          <td><span data-timestamp="1704904200" class="update-local-time" data-remove-second="true">2024년 1월 11일 01:30</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1704897000" data-timestamp="1704904200">시작까지 2일 19:51:06</td>
                      </tr>
                      <tr class="striped" data-contest="Codeforces">
                          <td>Codeforces</td>
                          <td><a href="https://codeforces.com/contestRegistration/1908" target="_blank">2024 New Year ICPC Challenge powered by Huawei</a></td>
                          <td><span data-timestamp="1705042800" class="update-local-time" data-remove-second="true">2024년 1월 12일 16:00</span></td>
                          <td><span data-timestamp="1706252400" class="update-local-time" data-remove-second="true">2024년 1월 26일 16:00</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705042800" data-timestamp="1706252400">시작까지 4일 12:21:06</td>
                      </tr>
                      <tr data-contest="BOJ Open">
                          <td>BOJ Open</td>
                          <td><a href="https://www.acmicpc.net/contest/view/1223" target="_blank">2023 경인지역 6개 대학 연합 프로그래밍 경시대회 shake! Open Contest · Arena #17</a></td>
                          <td><span data-timestamp="1705122000" class="update-local-time" data-remove-second="true">2024년 1월 13일 14:00</span></td>
                          <td><span data-timestamp="1705136400" class="update-local-time" data-remove-second="true">2024년 1월 13일 18:00</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705122000" data-timestamp="1705136400">시작까지 5일 10:21:06</td>
                      </tr>
                      <tr class="striped" data-contest="AtCoder">
                          <td>AtCoder</td>
                          <td><a href="https://atcoder.jp/contests/ahc028" target="_blank">ALGO ARTIS Programming Contest 2023 Winter（AtCoder Heuristic Contest 028）</a></td>
                          <td><span data-timestamp="1705125600" class="update-local-time" data-remove-second="true">2024년 1월 13일 15:00</span></td>
                          <td><span data-timestamp="1705140000" class="update-local-time" data-remove-second="true">2024년 1월 13일 19:00</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705125600" data-timestamp="1705140000">시작까지 5일 11:21:06</td>
                      </tr>
                      <tr data-contest="Codeforces">
                          <td>Codeforces</td>
                          <td>Codeforces Round (Div. 2)</td>
                          <td><span data-timestamp="1705156500" class="update-local-time" data-remove-second="true">2024년 1월 13일 23:35</span></td>
                          <td><span data-timestamp="1705163700" class="update-local-time" data-remove-second="true">2024년 1월 14일 01:35</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705156500" data-timestamp="1705163700">시작까지 5일 19:56:06</td>
                      </tr>
                      <tr class="striped" data-contest="AtCoder">
                          <td>AtCoder</td>
                          <td><a href="https://atcoder.jp/contests/abc336" target="_blank">AtCoder Beginner Contest 336</a></td>
                          <td><span data-timestamp="1705233600" class="update-local-time" data-remove-second="true">2024년 1월 14일 21:00</span></td>
                          <td><span data-timestamp="1705239600" class="update-local-time" data-remove-second="true">2024년 1월 14일 22:40</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705233600" data-timestamp="1705239600">시작까지 6일 17:21:06</td>
                      </tr>
                      <tr data-contest="Codeforces">
                          <td>Codeforces</td>
                          <td>Codeforces Round (Div. 3)</td>
                          <td><span data-timestamp="1705415700" class="update-local-time" data-remove-second="true">2024년 1월 16일 23:35</span></td>
                          <td><span data-timestamp="1705423800" class="update-local-time" data-remove-second="true">2024년 1월 17일 01:50</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705415700" data-timestamp="1705423800">시작까지 8일 19:56:06</td>
                      </tr>
                      <tr class="striped" data-contest="CodeChef">
                          <td>CodeChef</td>
                          <td><a href="https://www.codechef.com/START117" target="_blank">Starters 117</a></td>
                          <td><span data-timestamp="1705501800" class="update-local-time" data-remove-second="true">2024년 1월 17일 23:30</span></td>
                          <td><span data-timestamp="1705509000" class="update-local-time" data-remove-second="true">2024년 1월 18일 01:30</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705501800" data-timestamp="1705509000">시작까지 9일 19:51:06</td>
                      </tr>
                      <tr data-contest="CodeChef">
                          <td>CodeChef</td>
                          <td><a href="https://www.codechef.com/START117B" target="_blank">Starters 117 Division 2</a></td>
                          <td><span data-timestamp="1705501800" class="update-local-time" data-remove-second="true">2024년 1월 17일 23:30</span></td>
                          <td><span data-timestamp="1705509000" class="update-local-time" data-remove-second="true">2024년 1월 18일 01:30</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705501800" data-timestamp="1705509000">시작까지 9일 19:51:06</td>
                      </tr>
                      <tr class="striped" data-contest="AtCoder">
                          <td>AtCoder</td>
                          <td><a href="https://atcoder.jp/contests/arc170" target="_blank">AtCoder Regular Contest 170</a></td>
                          <td><span data-timestamp="1705838400" class="update-local-time" data-remove-second="true">2024년 1월 21일 21:00</span></td>
                          <td><span data-timestamp="1705845600" class="update-local-time" data-remove-second="true">2024년 1월 21일 23:00</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1705838400" data-timestamp="1705845600">시작까지 13일 17:21:06</td>
                      </tr>
                      <tr data-contest="CodeChef">
                          <td>CodeChef</td>
                          <td><a href="https://www.codechef.com/START118" target="_blank">Starters 118</a></td>
                          <td><span data-timestamp="1706106600" class="update-local-time" data-remove-second="true">2024년 1월 24일 23:30</span></td>
                          <td><span data-timestamp="1706113800" class="update-local-time" data-remove-second="true">2024년 1월 25일 01:30</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1706106600" data-timestamp="1706113800">시작까지 16일 19:51:06</td>
                      </tr>
                      <tr class="striped" data-contest="AtCoder">
                          <td>AtCoder</td>
                          <td><a href="https://atcoder.jp/contests/abc338" target="_blank">AtCoder Beginner Contest 338</a></td>
                          <td><span data-timestamp="1706356800" class="update-local-time" data-remove-second="true">2024년 1월 27일 21:00</span></td>
                          <td><span data-timestamp="1706362800" class="update-local-time" data-remove-second="true">2024년 1월 27일 22:40</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1706356800" data-timestamp="1706362800">시작까지 19일 17:21:06</td>
                      </tr>
                      <tr data-contest="CodeChef">
                          <td>CodeChef</td>
                          <td><a href="https://www.codechef.com/START119" target="_blank">Starters 119</a></td>
                          <td><span data-timestamp="1706711400" class="update-local-time" data-remove-second="true">2024년 1월 31일 23:30</span></td>
                          <td><span data-timestamp="1706718600" class="update-local-time" data-remove-second="true">2024년 2월 1일 01:30</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1706711400" data-timestamp="1706718600">시작까지 23일 19:51:06</td>
                      </tr>
                      <tr class="striped" data-contest="AtCoder">
                          <td>AtCoder</td>
                          <td><a href="https://atcoder.jp/contests/masters-qual" target="_blank">The 1st Masters Championship-qual-</a></td>
                          <td><span data-timestamp="1709438400" class="update-local-time" data-remove-second="true">2024년 3월 3일 13:00</span></td>
                          <td><span data-timestamp="1709460000" class="update-local-time" data-remove-second="true">2024년 3월 3일 19:00</span></td>
                          <td class="real-time-update" data-method="contest" data-timestamp-start="1709438400" data-timestamp="1709460000">시작까지 55일 09:21:06</td>
                      </tr>
                  </tbody>
              </table>
          </div>
      </div>
    </div>
  </body>
</html>
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final contests = await apiClient.otherContestList();
        expect(contests, isA<(List<Contest>, List<Contest>)>());
      });
    });
  });
}
