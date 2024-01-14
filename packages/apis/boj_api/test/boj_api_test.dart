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
                <div class="table-responsive">
                <table class="table table-bordered table-striped" style="width:100%;">
                <thead>
                <tr>
                  <th style="width: 34%;">대회 이름</th>
                  <th style="width: 10%;">우승</th>
                  <th style="width: 10%;">준우승</th>
                  <th style="width: 18%;">시작</th>
                  <th style="width: 18%;">종료</th>
                  <th style="width: 10%;">상태</th>
                </tr>
                </thead>
                <tbody>
                    <tr class="info">
                    <td>
                      <a href="/contest/view/1228">제3회 보라매컵 예선 Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1705827600" class="update-local-time" data-remove-second="true">2024년 1월 21일 18:00</span></td>
                    <td><span data-timestamp="1705838400" class="update-local-time" data-remove-second="true">2024년 1월 21일 21:00</span></td>
                            <td class="real-time-update" data-method="contest" data-timestamp-start="1705827600" data-timestamp="1705838400">시작까지 6일 23:58:40</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1225">Hello, BOJ 2024! Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1705206600" class="update-local-time" data-remove-second="true">2024년 1월 14일 13:30</span></td>
                    <td><span data-timestamp="1705217400" class="update-local-time" data-remove-second="true">2024년 1월 14일 16:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1223">2023 경인지역 6개 대학 연합 프로그래밍 경시대회 shake! Open Contest · Arena #17</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1705122000" class="update-local-time" data-remove-second="true">2024년 1월 13일 14:00</span></td>
                    <td><span data-timestamp="1705136400" class="update-local-time" data-remove-second="true">2024년 1월 13일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1220">제3회 흐즈로컵 (The 3rd Chromate Cup) Algorithm Division</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1704625200" class="update-local-time" data-remove-second="true">2024년 1월 7일 20:00</span></td>
                    <td><span data-timestamp="1704634200" class="update-local-time" data-remove-second="true">2024년 1월 7일 22:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1217">나는코더다 2023 송년대회 Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1704513600" class="update-local-time" data-remove-second="true">2024년 1월 6일 13:00</span></td>
                    <td><span data-timestamp="1704531600" class="update-local-time" data-remove-second="true">2024년 1월 6일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1221">Good Bye, BOJ 2023!</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1704018600" class="update-local-time" data-remove-second="true">2023년 12월 31일 19:30</span></td>
                    <td><span data-timestamp="1704029400" class="update-local-time" data-remove-second="true">2023년 12월 31일 22:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1214">SciOI 2023 Open Contest · Arena #16</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1703908800" class="update-local-time" data-remove-second="true">2023년 12월 30일 13:00</span></td>
                    <td><span data-timestamp="1703926800" class="update-local-time" data-remove-second="true">2023년 12월 30일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1219">월간 향유회 2023. 12. · Arena #15</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1703412000" class="update-local-time" data-remove-second="true">2023년 12월 24일 19:00</span></td>
                    <td><span data-timestamp="1703422800" class="update-local-time" data-remove-second="true">2023년 12월 24일 22:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1215">첫 번째 나들이</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1703325600" class="update-local-time" data-remove-second="true">2023년 12월 23일 19:00</span></td>
                    <td><span data-timestamp="1703340000" class="update-local-time" data-remove-second="true">2023년 12월 23일 23:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1218">2023 제2회 미적확통컵</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1703304000" class="update-local-time" data-remove-second="true">2023년 12월 23일 13:00</span></td>
                    <td><span data-timestamp="1703322000" class="update-local-time" data-remove-second="true">2023년 12월 23일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1208">파댕이컵</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1702803600" class="update-local-time" data-remove-second="true">2023년 12월 17일 18:00</span></td>
                    <td><span data-timestamp="1702818000" class="update-local-time" data-remove-second="true">2023년 12월 17일 22:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1199">2023 서울사이버대학교 프로그래밍 경진대회 (SCUPC)</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1702702800" class="update-local-time" data-remove-second="true">2023년 12월 16일 14:00</span></td>
                    <td><span data-timestamp="1702720800" class="update-local-time" data-remove-second="true">2023년 12월 16일 19:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1206">BOJ Bundle in Math. Vol 1</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701558000" class="update-local-time" data-remove-second="true">2023년 12월 3일 08:00</span></td>
                    <td><span data-timestamp="1702162800" class="update-local-time" data-remove-second="true">2023년 12월 10일 08:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1201">가희와 함께 하는 6회 코딩 테스트</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701597600" class="update-local-time" data-remove-second="true">2023년 12월 3일 19:00</span></td>
                    <td><span data-timestamp="1701612000" class="update-local-time" data-remove-second="true">2023년 12월 3일 23:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1202">제10회 한양대학교 프로그래밍 경시대회(HCPC) Beginner Division</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701577800" class="update-local-time" data-remove-second="true">2023년 12월 3일 13:30</span></td>
                    <td><span data-timestamp="1701588600" class="update-local-time" data-remove-second="true">2023년 12월 3일 16:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1203">제10회 한양대학교 프로그래밍 경시대회(HCPC) Advanced Division</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701577800" class="update-local-time" data-remove-second="true">2023년 12월 3일 13:30</span></td>
                    <td><span data-timestamp="1701588600" class="update-local-time" data-remove-second="true">2023년 12월 3일 16:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1204">제10회 한양대학교 프로그래밍 경시대회(HCPC) Beginner Division Open Contest · Arena #14</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701577800" class="update-local-time" data-remove-second="true">2023년 12월 3일 13:30</span></td>
                    <td><span data-timestamp="1701588600" class="update-local-time" data-remove-second="true">2023년 12월 3일 16:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1205">제10회 한양대학교 프로그래밍 경시대회(HCPC) Advanced Division Open Contest · Arena #14</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701577800" class="update-local-time" data-remove-second="true">2023년 12월 3일 13:30</span></td>
                    <td><span data-timestamp="1701588600" class="update-local-time" data-remove-second="true">2023년 12월 3일 16:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1209">제10회 한양대학교 프로그래밍 경시대회(HCPC) 예비소집</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701507600" class="update-local-time" data-remove-second="true">2023년 12월 2일 18:00</span></td>
                    <td><span data-timestamp="1701529200" class="update-local-time" data-remove-second="true">2023년 12월 3일 00:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1212">2023 서울시립대학교 프로그래밍 경진대회 (UOSPC) Open contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701507600" class="update-local-time" data-remove-second="true">2023년 12월 2일 18:00</span></td>
                    <td><span data-timestamp="1701518400" class="update-local-time" data-remove-second="true">2023년 12월 2일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1195">INU 코드페스티벌 2023</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701493200" class="update-local-time" data-remove-second="true">2023년 12월 2일 14:00</span></td>
                    <td><span data-timestamp="1701504000" class="update-local-time" data-remove-second="true">2023년 12월 2일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1196">INU 코드페스티벌 2023 Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1701493200" class="update-local-time" data-remove-second="true">2023년 12월 2일 14:00</span></td>
                    <td><span data-timestamp="1701504000" class="update-local-time" data-remove-second="true">2023년 12월 2일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1200">월간 향유회 2023. 11.</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700992800" class="update-local-time" data-remove-second="true">2023년 11월 26일 19:00</span></td>
                    <td><span data-timestamp="1701000000" class="update-local-time" data-remove-second="true">2023년 11월 26일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1197">solved.ac Grand Arena #3 — Division 1 · Arena #13</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700974800" class="update-local-time" data-remove-second="true">2023년 11월 26일 14:00</span></td>
                    <td><span data-timestamp="1700985600" class="update-local-time" data-remove-second="true">2023년 11월 26일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1198">solved.ac Grand Arena #3 — Division 2 · Arena #13</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700974800" class="update-local-time" data-remove-second="true">2023년 11월 26일 14:00</span></td>
                    <td><span data-timestamp="1700985600" class="update-local-time" data-remove-second="true">2023년 11월 26일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1207">솔브드 아레나로 대회를 열고 싶었으나 실패해서 그냥 여는 대회</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700492400" class="update-local-time" data-remove-second="true">2023년 11월 21일 00:00</span></td>
                    <td><span data-timestamp="1700751600" class="update-local-time" data-remove-second="true">2023년 11월 24일 00:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1189">2023 연세대학교 프로그래밍 경진대회 Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700366400" class="update-local-time" data-remove-second="true">2023년 11월 19일 13:00</span></td>
                    <td><span data-timestamp="1700380800" class="update-local-time" data-remove-second="true">2023년 11월 19일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1144">제1회 스타보우컵</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700298000" class="update-local-time" data-remove-second="true">2023년 11월 18일 18:00</span></td>
                    <td><span data-timestamp="1700308800" class="update-local-time" data-remove-second="true">2023년 11월 18일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1194">2023 고려대학교 프로그래밍 경시대회 (KCPC) - Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700283600" class="update-local-time" data-remove-second="true">2023년 11월 18일 14:00</span></td>
                    <td><span data-timestamp="1700298000" class="update-local-time" data-remove-second="true">2023년 11월 18일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1188">2023 연세대학교 프로그래밍 경진대회</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1700280000" class="update-local-time" data-remove-second="true">2023년 11월 18일 13:00</span></td>
                    <td><span data-timestamp="1700294400" class="update-local-time" data-remove-second="true">2023년 11월 18일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1159">2023 Sogang Programming Contest Open (Master) · Arena #12</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699765200" class="update-local-time" data-remove-second="true">2023년 11월 12일 14:00</span></td>
                    <td><span data-timestamp="1699776000" class="update-local-time" data-remove-second="true">2023년 11월 12일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1160">2023 Sogang Programming Contest Open (Champion) · Arena #12</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699765200" class="update-local-time" data-remove-second="true">2023년 11월 12일 14:00</span></td>
                    <td><span data-timestamp="1699776000" class="update-local-time" data-remove-second="true">2023년 11월 12일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1164">2023 IGRUS Newbie Programming Contest Open</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699693200" class="update-local-time" data-remove-second="true">2023년 11월 11일 18:00</span></td>
                    <td><span data-timestamp="1699704000" class="update-local-time" data-remove-second="true">2023년 11월 11일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1185">SASA Programming Contest 2023 Open Contest Div. 1 · Arena #11</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699682400" class="update-local-time" data-remove-second="true">2023년 11월 11일 15:00</span></td>
                    <td><span data-timestamp="1699693200" class="update-local-time" data-remove-second="true">2023년 11월 11일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1186">SASA Programming Contest 2023 Open Contest Div. 2</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699682400" class="update-local-time" data-remove-second="true">2023년 11월 11일 15:00</span></td>
                    <td><span data-timestamp="1699693200" class="update-local-time" data-remove-second="true">2023년 11월 11일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1177">2023 4분기 Small &amp; Large Lighter Cup</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699178400" class="update-local-time" data-remove-second="true">2023년 11월 5일 19:00</span></td>
                    <td><span data-timestamp="1699185600" class="update-local-time" data-remove-second="true">2023년 11월 5일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1173">2023 건국대학교 프로그래밍 경진대회 (KUPC) Open Contest · Arena #10</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699160400" class="update-local-time" data-remove-second="true">2023년 11월 5일 14:00</span></td>
                    <td><span data-timestamp="1699171200" class="update-local-time" data-remove-second="true">2023년 11월 5일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1148">2023 Goricon Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699084800" class="update-local-time" data-remove-second="true">2023년 11월 4일 17:00</span></td>
                    <td><span data-timestamp="1699095600" class="update-local-time" data-remove-second="true">2023년 11월 4일 20:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1147">2023 Goricon</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699074000" class="update-local-time" data-remove-second="true">2023년 11월 4일 14:00</span></td>
                    <td><span data-timestamp="1699084800" class="update-local-time" data-remove-second="true">2023년 11월 4일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1171">2023 건국대학교 프로그래밍 경진대회 (KUPC) - Division 2</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699072200" class="update-local-time" data-remove-second="true">2023년 11월 4일 13:30</span></td>
                    <td><span data-timestamp="1699083000" class="update-local-time" data-remove-second="true">2023년 11월 4일 16:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1172">2023 건국대학교 프로그래밍 경진대회 (KUPC) - Division 1</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699072200" class="update-local-time" data-remove-second="true">2023년 11월 4일 13:30</span></td>
                    <td><span data-timestamp="1699083000" class="update-local-time" data-remove-second="true">2023년 11월 4일 16:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1183">제 1회 DGUPC Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1699005600" class="update-local-time" data-remove-second="true">2023년 11월 3일 19:00</span></td>
                    <td><span data-timestamp="1699016400" class="update-local-time" data-remove-second="true">2023년 11월 3일 22:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1149">월간 향유회 2023. 10.</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1698573600" class="update-local-time" data-remove-second="true">2023년 10월 29일 19:00</span></td>
                    <td><span data-timestamp="1698580800" class="update-local-time" data-remove-second="true">2023년 10월 29일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1174">기1행</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1698555600" class="update-local-time" data-remove-second="true">2023년 10월 29일 14:00</span></td>
                    <td><span data-timestamp="1698566400" class="update-local-time" data-remove-second="true">2023년 10월 29일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1151">2023 제1회 춘배컵</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1698454800" class="update-local-time" data-remove-second="true">2023년 10월 28일 10:00</span></td>
                    <td><span data-timestamp="1698483600" class="update-local-time" data-remove-second="true">2023년 10월 28일 18:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1146">2023 KAIST 13th ICPC Mock Competition Open Contest</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1697252400" class="update-local-time" data-remove-second="true">2023년 10월 14일 12:00</span></td>
                    <td><span data-timestamp="1697270400" class="update-local-time" data-remove-second="true">2023년 10월 14일 17:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1117">제2회 보라매컵 본선 Open Contest · Arena #9</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1696669200" class="update-local-time" data-remove-second="true">2023년 10월 7일 18:00</span></td>
                    <td><span data-timestamp="1696680000" class="update-local-time" data-remove-second="true">2023년 10월 7일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1142">2023 서울대학교 프로그래밍 경시대회 Open Contest - Division 1</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1695558600" class="update-local-time" data-remove-second="true">2023년 9월 24일 21:30</span></td>
                    <td><span data-timestamp="1695573000" class="update-local-time" data-remove-second="true">2023년 9월 25일 01:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1143">2023 서울대학교 프로그래밍 경시대회 Open Contest - Division 2</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1695558600" class="update-local-time" data-remove-second="true">2023년 9월 24일 21:30</span></td>
                    <td><span data-timestamp="1695569400" class="update-local-time" data-remove-second="true">2023년 9월 25일 00:30</span></td>
                          <td>종료</td>
                        </tr>
                    <tr class="">
                    <td>
                      <a href="/contest/view/1128">월간 향유회 2023. 09.</a>
                                                                    </td>
                    <td class="break-all">
                            </td>
                    <td class="break-all">
                            </td>
                    <td><span data-timestamp="1695549600" class="update-local-time" data-remove-second="true">2023년 9월 24일 19:00</span></td>
                    <td><span data-timestamp="1695556800" class="update-local-time" data-remove-second="true">2023년 9월 24일 21:00</span></td>
                          <td>종료</td>
                        </tr>
                </tbody>
                </table>
                </div>
              </div>
            </body>
          </html>
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final contests = await apiClient.officialContestList();
        expect(contests, isA<List<Contest>>());
        expect(contests.length, 49);
        expect(contests[0].name, 'Hello, BOJ 2024! Open Contest');
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
