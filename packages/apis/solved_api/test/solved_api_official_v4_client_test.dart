import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

typedef _RequestHandler = Future<http.StreamedResponse> Function(
  http.Request request,
);

final class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.handler);

  _RequestHandler handler;
  final List<http.Request> requests = <http.Request>[];
  bool wasClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (wasClosed) throw StateError('Recording client is closed');
    if (request is! http.Request) {
      throw StateError('Expected a buffered HTTP request');
    }
    requests.add(request);
    return handler(request);
  }

  @override
  void close() {
    wasClosed = true;
  }
}

void main() {
  group('SolvedApiClient.officialV4', () {
    late _RequestHandler handler;
    late _RecordingClient httpClient;
    late SolvedApiClient client;

    setUp(() {
      handler = (_) async => _jsonResponse(fixture('v4/badge_item.json'));
      httpClient = _RecordingClient((request) => handler(request));
      client = _client(httpClient);
    });

    tearDown(() => client.close());

    test(
      'sends exact bodyless bounded GETs and decodes all public operations',
      () async {
        handler = (request) async {
          final fixturePath = switch (request.url.path) {
            '/solved/v4/users/index' => 'v4/user_profile.json',
            '/solved/v4/users/index/activity/days' =>
              'v4/user_activity_days.json',
            '/solved/v4/users/index/reputation' => 'v4/user_reputation.json',
            '/solved/v4/achievements/items/background/anniversary_1st' =>
              'v4/background_item.json',
            '/solved/v4/achievements/items/badge/boardgame' =>
              'v4/badge_item.json',
            '/solved/v4/problems' => 'v4/search_problems.json',
            '/solved/v4/rankings/users/search' => 'v4/search_users.json',
            '/solved/v4/tags' => 'v4/tags.json',
            _ => throw StateError('Unexpected request: ${request.url}'),
          };
          return _jsonResponse(_paddedFixture(fixturePath));
        };

        final OfficialUserProfile profile = await client.v4UserProfile('index');
        final ProfileActivityResult activity = await client.v4UserActivity(
          'index',
          from: DateTime.utc(2026, 11),
          to: DateTime.utc(2026, 11, 17),
        );
        final reputation = await client.v4UserReputation(
          'index',
          range: SolvedApiV4ReputationRange.year,
        );
        final background = await client.v4BackgroundShow('anniversary_1st');
        final badge = await client.v4BadgeShow('boardgame');
        final ProblemSearchResult problems = await client.v4SearchProblems(
          'number',
          page: 2,
          sort: SolvedApiV4ProblemSort.level,
          direction: SolvedApiV4SearchDirection.desc,
          seed: 'stable-seed',
        );
        final users = await client.v4SearchUsers(
          'index',
          sort: SolvedApiV4UserSort.contribution,
        );
        final tags = await client.v4SearchTags('NUMBER');

        expect(profile.handle, 'index');
        expect(profile.id, 1);
        expect(profile.voteCount, 37);
        expect(profile.solvedCount, 2048);
        expect(profile.streakVacation, isNull);
        expect(profile.streakCountedToday, isTrue);
        expect(profile.streakFrozenYesterday, isFalse);
        expect(profile.streakTheme, isNull);
        expect(profile.isRival, isFalse);
        expect(profile.isReverseRival, isFalse);
        expect(profile.ojAccounts, hasLength(2));
        expect(profile.ojAccounts.first.ojId, 'boj');
        expect(profile.ojAccounts.first.handle, 'index');
        expect(profile.ojAccounts.first.logoUrl, isNull);
        expect(profile.ojAccounts.first.verified, isTrue);
        expect(profile.ojAccounts.last.ojId, 'codeforces');
        expect(profile.ojAccounts.last.profileUrl, isNull);
        expect(profile.ojAccounts.last.verified, isFalse);
        expect(profile.linkedAccounts, hasLength(2));
        expect(
          profile.linkedAccounts.first.provider,
          OfficialUserProfileLinkedAccountProvider.discord,
        );
        expect(profile.linkedAccounts.first.name, 'index');
        expect(
          profile.linkedAccounts.last.provider,
          OfficialUserProfileLinkedAccountProvider.icpc,
        );
        expect(profile.linkedAccounts.last.name, 'Index Team');
        expect(profile.backgroundId, 'anniversary_1st');
        expect(profile.background, isA<OfficialUserProfileBackground>());
        expect(profile.background?.backgroundVideoUrl, isNull);
        expect(profile.background?.isIllust, isTrue);
        expect(profile.background?.displayName, 'First Anniversary');
        expect(profile.background?.authors, isEmpty);
        expect(profile.badgeId, 'boardgame');
        expect(profile.badge, isA<OfficialUserProfileBadge>());
        expect(profile.badge?.name, 'Board Game');
        expect(activity.from, '2026-11-01');
        expect(activity.to, '2026-11-17');
        expect(activity.maxSolvedCount, 4);
        expect(activity.currentStreak, 12);
        final int maxStreak = activity.maxStreak;
        expect(maxStreak, 365);
        expect(activity.vacation, isNull);
        expect(activity.vacations, isEmpty);
        expect(activity.countedToday, isTrue);
        expect(activity.frozenYesterday, isFalse);
        expect(activity.days, hasLength(2));
        expect(reputation.reputation, 314);
        expect(background?.key, 'anniversary_1st');
        expect(badge.key, 'boardgame');
        expect(problems.count, 4);
        expect(problems.page, 1);
        expect(problems.pageSize, 50);
        expect(problems.diagnostics, isNull);
        expect(problems.seed, isNull);
        expect(users.exact?.handle, 'index');
        expect(tags.items.single.key, 'number_theory');

        expect(
          httpClient.requests.map((request) => request.url),
          <Uri>[
            _uri('users/index', <String, String>{'lang': 'ko'}),
            _uri('users/index/activity/days', <String, String>{
              'from': '2026-11-01',
              'to': '2026-11-17',
            }),
            _uri('users/index/reputation', <String, String>{'range': '1y'}),
            _uri(
              'achievements/items/background/anniversary_1st',
              <String, String>{'lang': 'ko'},
            ),
            _uri(
              'achievements/items/badge/boardgame',
              <String, String>{'lang': 'ko'},
            ),
            _uri('problems', <String, String>{
              'q': 'number',
              'page': '2',
              'sort': 'level',
              'direction': 'desc',
              'seed': 'stable-seed',
            }),
            _uri('rankings/users/search', <String, String>{
              'q': 'index',
              'sort': 'contribution',
            }),
            _uri('tags'),
          ],
        );
        expect(httpClient.requests, hasLength(8));
        for (final request in httpClient.requests) {
          expect(request, isA<http.AbortableRequest>());
          expect(request.method, 'GET');
          expect(request.followRedirects, isFalse);
          expect(request.maxRedirects, 0);
          expect(request.headers, const <String, String>{
            'accept': 'application/json',
          });
          expect(request.bodyBytes, isEmpty);
        }
      },
    );

    test('accepts exactly 5 MiB and cancels a larger response', () async {
      final fixtureBytes = utf8.encode(fixture('v4/tags.json'));
      final exactBody = List<int>.of(fixtureBytes, growable: true)
        ..addAll(
          List<int>.filled(
            _maximumPublicResponseBytes - fixtureBytes.length,
            0x20,
          ),
        );
      handler = (_) async => _bytesResponse(
            exactBody,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );

      final tags = await client.v4SearchTags('NUMBER');
      expect(tags.items.single.key, 'number_theory');

      final streamCancelled = Completer<void>();
      late StreamController<List<int>> responseController;
      responseController = StreamController<List<int>>(
        onListen: () {
          responseController.add(
            List<int>.filled(_maximumPublicResponseBytes + 1, 0x20),
          );
        },
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      handler = (_) async => http.StreamedResponse(
            responseController.stream,
            503,
          );

      final error = await _captureFailure(client.v4SearchTags('dp'));
      await streamCancelled.future.timeout(const Duration(seconds: 1));
      await responseController.close();

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 503);
      expect(error.cause, isA<SolvedApiResponseTooLarge>());
      expect(error.responseBody, isNull);
      expect(error.isRetryable, isFalse);
      expect(httpClient.requests, hasLength(2));
    });

    test('aborts a timed-out body read without retrying', () async {
      client.close();
      client = _client(
        httpClient,
        requestTimeout: const Duration(milliseconds: 1),
      );
      final wasAborted = Completer<void>();
      final streamCancelled = Completer<void>();
      late StreamController<List<int>> responseController;
      responseController = StreamController<List<int>>(
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      handler = (request) async {
        final abortTrigger = (request as http.AbortableRequest).abortTrigger!;
        unawaited(
          abortTrigger.then((_) async {
            if (!wasAborted.isCompleted) wasAborted.complete();
            responseController.addError(
              http.RequestAbortedException(request.url),
            );
            await responseController.close();
          }),
        );
        return http.StreamedResponse(responseController.stream, 200);
      };

      final error = await _captureFailure(client.v4SearchTags('dp'));
      await wasAborted.future.timeout(const Duration(seconds: 1));
      await streamCancelled.future.timeout(const Duration(seconds: 1));

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, isNull);
      expect(error.cause, isA<TimeoutException>());
      expect(error.isTimeout, isTrue);
      expect(error.isRetryable, isTrue);
      expect(httpClient.requests, hasLength(1));
    });

    test('classifies status before interpreting an untrusted body', () async {
      final cases = <(int, bool)>[
        (201, false),
        (204, false),
        (302, false),
        (400, false),
        (401, false),
        (403, false),
        (404, false),
        (408, true),
        (429, true),
        (500, true),
        (599, true),
        (600, false),
      ];

      for (final entry in cases) {
        handler = (_) async => _bytesResponse(
              const <int>[0xff],
              statusCode: entry.$1,
              headers: <String, String>{
                'content-type': 'text/plain',
                if (entry.$1 == 429) 'retry-after': '12',
              },
            );

        final error = await _captureFailure(client.v4BadgeShow('boardgame'));

        expect(error, isA<BadgeRequestFailed>());
        expect(error.statusCode, entry.$1);
        expect(error.cause, isNull);
        expect(error.responseBody, isNull);
        expect(error.isRetryable, entry.$2, reason: '${entry.$1}');
        expect(
          error.retryAfter,
          entry.$1 == 429 ? const Duration(seconds: 12) : isNull,
        );
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('preserves the public failure type for every operation family',
        () async {
      handler = (_) async => _bytesResponse(const <int>[], statusCode: 404);

      expect(
        await _captureFailure(client.v4UserProfile('index')),
        isA<UserRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4BackgroundShow('anniversary_1st')),
        isA<BackgroundRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4BadgeShow('boardgame')),
        isA<BadgeRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4SearchTags('dp')),
        isA<SearchRequestFailed>(),
      );
      expect(httpClient.requests, hasLength(4));
    });

    test('preserves only valid Retry-After metadata on retryable 429s',
        () async {
      final cases = <(String?, Duration?, bool)>[
        ('12', const Duration(seconds: 12), true),
        (null, null, true),
        ('', null, true),
        ('invalid', null, true),
        ('-1', null, true),
        ('+1', null, true),
        ('1.0', null, true),
      ];

      for (final entry in cases) {
        handler = (_) async => _bytesResponse(
              utf8.encode('do-not-interpret'),
              statusCode: 429,
              headers: <String, String>{
                if (entry.$1 != null) 'Retry-After': entry.$1!,
              },
            );

        final error = await _captureFailure(client.v4UserProfile('index'));

        expect(error, isA<UserRequestFailed>());
        expect(error.statusCode, 429);
        expect(error.retryAfter, entry.$2);
        expect(error.isRetryable, entry.$3);
        expect(error.responseBody, isNull);
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('requires JSON metadata, fatal UTF-8, JSON, and the DTO shape',
        () async {
      final cases = <(List<int>, Map<String, String>)>[
        (
          utf8.encode('{"secret":"missing-content-type"}'),
          const <String, String>{},
        ),
        (
          utf8.encode('{"secret":"wrong-content-type"}'),
          const <String, String>{'content-type': 'text/plain'},
        ),
        (
          utf8.encode('{"secret":"malformed-content-type"}'),
          const <String, String>{'content-type': 'application/json,'},
        ),
        (
          const <int>[0xff],
          const <String, String>{'content-type': 'application/json'},
        ),
        (
          utf8.encode('{"secret":"invalid-json"'),
          const <String, String>{'content-type': 'application/json'},
        ),
        (
          utf8.encode('{"kind":"badge","key":"secret-dto"}'),
          const <String, String>{'content-type': 'application/json'},
        ),
      ];

      for (final entry in cases) {
        handler = (_) async => _bytesResponse(
              entry.$1,
              headers: entry.$2,
            );

        final error = await _captureFailure(client.v4BadgeShow('boardgame'));

        expect(error, isA<BadgeRequestFailed>());
        expect(error.statusCode, 200);
        expect(error.cause, isA<FormatException>());
        expect(error.responseBody, isNull);
        expect(error.isRetryable, isFalse);
        expect(error.toString(), isNot(contains('secret')));
        expect(error.cause.toString(), isNot(contains('secret')));
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('preserves and classifies injected transport failures', () async {
      final cases = <(Object, bool, bool)>[
        (TimeoutException('injected timeout'), true, true),
        (http.ClientException('offline'), true, false),
        (StateError('offline'), false, false),
      ];

      for (final entry in cases) {
        handler = (_) => Future<http.StreamedResponse>.error(entry.$1);

        final error = await _captureFailure(client.v4UserProfile('index'));

        expect(error, isA<UserRequestFailed>());
        expect(error.statusCode, isNull);
        expect(error.cause, same(entry.$1));
        expect(error.isRetryable, entry.$2);
        expect(error.isTimeout, entry.$3);
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('keeps the shared client caller-owned across close and validation',
        () async {
      client.close();
      client.close();

      expect(httpClient.wasClosed, isFalse);
      expect(httpClient.requests, isEmpty);
      await expectLater(
        client.v4SearchTags('dp'),
        throwsA(isA<StateError>()),
      );

      expect(
        () => SolvedApiClient.officialV4(
          proxyBaseUri: Uri.parse('https://solved.ac/solved/v4/'),
          httpClient: httpClient,
        ),
        throwsArgumentError,
      );
      expect(httpClient.wasClosed, isFalse);

      expect(
        () => SolvedApiClient.officialV4(
          proxyBaseUri: Uri.parse('http://localhost:3000/solved/v4/'),
          httpClient: httpClient,
        ),
        throwsArgumentError,
      );
      final loopbackClient = SolvedApiClient.officialV4(
        proxyBaseUri: Uri.parse('http://localhost:3000/solved/v4/'),
        httpClient: httpClient,
        allowInsecureLoopback: true,
      );
      loopbackClient.close();

      expect(httpClient.wasClosed, isFalse);
      expect(httpClient.requests, isEmpty);
    });
  });
}

const int _legacyResponseLimitBytes = 64 * 1024;
const int _maximumPublicResponseBytes = 5 * 1024 * 1024;
final Uri _proxyBaseUri = Uri.parse('https://proxy.example/solved/v4/');

SolvedApiClient _client(
  http.Client httpClient, {
  Duration requestTimeout = const Duration(seconds: 10),
}) =>
    SolvedApiClient.officialV4(
      proxyBaseUri: _proxyBaseUri,
      httpClient: httpClient,
      requestTimeout: requestTimeout,
    );

Uri _uri(
  String relativePath, [
  Map<String, String> queryParameters = const <String, String>{},
]) {
  final resolved = _proxyBaseUri.resolve(relativePath);
  return queryParameters.isEmpty
      ? resolved
      : resolved.replace(queryParameters: queryParameters);
}

String _paddedFixture(String path) =>
    '${fixture(path)}${List<String>.filled(_legacyResponseLimitBytes, ' ').join()}';

http.StreamedResponse _jsonResponse(
  String body, {
  int statusCode = 200,
  Map<String, String>? headers,
}) =>
    _bytesResponse(
      utf8.encode(body),
      statusCode: statusCode,
      headers: headers ??
          const <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
    );

http.StreamedResponse _bytesResponse(
  List<int> bytes, {
  int statusCode = 200,
  Map<String, String> headers = const <String, String>{},
}) =>
    http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      statusCode,
      headers: headers,
    );

Future<SolvedApiException> _captureFailure(Future<Object?> future) async {
  try {
    await future;
  } on SolvedApiException catch (error) {
    return error;
  }
  throw StateError('Expected a solved API request failure');
}
