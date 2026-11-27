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
  group('SolvedAuthenticatedApiClient transport', () {
    late _RequestHandler handler;
    late _RecordingClient httpClient;
    late SolvedAuthenticatedApiClient client;

    setUp(() {
      handler = (_) async => _jsonResponse('{"id":123456789,"handle":"index"}');
      httpClient = _RecordingClient((request) => handler(request));
      client = _client(httpClient);
    });

    tearDown(() => client.close());

    test('sends exactly one token-bound GET and decodes stable identity',
        () async {
      final identity = await client.currentUser();

      expect(identity.id, 123456789);
      expect(identity.handle, 'index');
      expect(httpClient.requests, hasLength(1));
      final request = httpClient.requests.single;
      expect(request.method, 'GET');
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/me'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.maxRedirects, 0);
      expect(request.headers['accept'], 'application/json');
      expect(request.headers['authorization'], 'Bearer access-token');
      expect(request.headers.containsKey('x-client-id'), isFalse);
      expect(request.headers.containsKey('x-client-secret'), isFalse);
      expect(request.bodyBytes, isEmpty);
      expect(request.body, isNot(contains('do-not-send-refresh')));
      expect(
        client.toString(),
        'SolvedAuthenticatedApiClient(<redacted>)',
      );
      expect(client.toString(), isNot(contains('access-token')));
      expect(client.toString(), isNot(contains('do-not-send-refresh')));
    });

    test('classifies status before interpreting an untrusted body', () async {
      for (final entry in <(int, SolvedAuthenticatedFailureKind, bool)>[
        (302, SolvedAuthenticatedFailureKind.redirect, false),
        (400, SolvedAuthenticatedFailureKind.unexpectedStatus, false),
        (401, SolvedAuthenticatedFailureKind.unauthorized, false),
        (403, SolvedAuthenticatedFailureKind.forbidden, false),
        (408, SolvedAuthenticatedFailureKind.unexpectedStatus, true),
        (500, SolvedAuthenticatedFailureKind.unexpectedStatus, true),
        (599, SolvedAuthenticatedFailureKind.unexpectedStatus, true),
        (600, SolvedAuthenticatedFailureKind.unexpectedStatus, false),
      ]) {
        handler = (_) async => _bytesResponse(
              utf8.encode('do-not-log-response'),
              statusCode: entry.$1,
              headers: const <String, String>{'content-type': 'text/plain'},
            );

        final error = await _captureFailure(client.currentUser());

        expect(error.operation, SolvedAuthenticatedOperation.currentUser);
        expect(error.kind, entry.$2);
        expect(error.statusCode, entry.$1);
        expect(error.isRetryable, entry.$3);
        expect(error.toString(), isNot(contains('do-not-log-response')));
        expect(error.toString(), isNot(contains('access-token')));
      }
      expect(httpClient.requests, hasLength(8));
    });

    test('requires a valid Retry-After before exposing rate-limit retry',
        () async {
      final cases = <(String?, Duration?, bool)>[
        ('120', const Duration(seconds: 120), true),
        ('Sun, 06 Nov 2094 08:49:37 GMT', null, true),
        (null, null, false),
        ('', null, false),
        ('invalid', null, false),
        ('-1', null, false),
        ('+1', null, false),
      ];

      for (final entry in cases) {
        handler = (_) async => _bytesResponse(
              utf8.encode('ignored'),
              statusCode: 429,
              headers: <String, String>{
                if (entry.$1 != null) 'Retry-After': entry.$1!,
              },
            );

        final error = await _captureFailure(client.currentUser());

        expect(error.kind, SolvedAuthenticatedFailureKind.rateLimited);
        expect(error.statusCode, 429);
        expect(error.isRetryable, entry.$3);
        if (entry.$1?.startsWith('Sun') ?? false) {
          expect(error.retryAfter, isNotNull);
          expect(error.retryAfter, isNot(Duration.zero));
        } else {
          expect(error.retryAfter, entry.$2);
        }
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('sanitizes malformed 200 metadata, JSON, and identity', () async {
      final cases = <http.StreamedResponse>[
        _bytesResponse(utf8.encode('{"id":1,"handle":"secret-handle"}')),
        _bytesResponse(
          utf8.encode('{"id":1,"handle":"secret-handle"}'),
          headers: const <String, String>{'content-type': 'text/plain'},
        ),
        _bytesResponse(
          const <int>[0xff],
          headers: const <String, String>{'content-type': 'application/json'},
        ),
        _jsonResponse('{'),
        _jsonResponse('{"id":"secret-id","handle":"secret-handle"}'),
      ];

      for (final response in cases) {
        handler = (_) async => response;
        final error = await _captureFailure(client.currentUser());

        expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
        expect(error.statusCode, 200);
        expect(error.isRetryable, isFalse);
        expect(error.cause, isA<FormatException>());
        expect(error.toString(), isNot(contains('secret')));
        expect(error.cause.toString(), isNot(contains('secret')));
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('bounds the full response before status interpretation', () async {
      handler = (_) async => _bytesResponse(
            List<int>.filled(64 * 1024, 0x20),
            statusCode: 401,
          );
      var error = await _captureFailure(client.currentUser());
      expect(error.kind, SolvedAuthenticatedFailureKind.unauthorized);

      handler = (_) async => _bytesResponse(
            List<int>.filled(64 * 1024 + 1, 0x20),
            statusCode: 401,
          );
      error = await _captureFailure(client.currentUser());
      expect(error.kind, SolvedAuthenticatedFailureKind.responseTooLarge);
      expect(error.statusCode, 401);
      expect(error.cause, isNull);
      expect(error.isRetryable, isFalse);
      expect(httpClient.requests, hasLength(2));
    });

    test('aborts a timed-out body read without retrying', () async {
      client = _client(
        httpClient,
        requestTimeout: const Duration(milliseconds: 1),
      );
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
            responseController.addError(
              http.RequestAbortedException(request.url),
            );
            await responseController.close();
          }),
        );
        return http.StreamedResponse(responseController.stream, 200);
      };

      final error = await _captureFailure(client.currentUser());
      await streamCancelled.future.timeout(const Duration(seconds: 1));

      expect(error.kind, SolvedAuthenticatedFailureKind.timeout);
      expect(error.isTimeout, isTrue);
      expect(error.isRetryable, isTrue);
      expect(error.cause, isA<TimeoutException>());
      expect(
        (error.cause as TimeoutException).message,
        'Authenticated request timed out',
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves injected failures but redacts their string form', () async {
      final injectedTimeout = TimeoutException('access-token');
      final injectedStack = StackTrace.current;
      handler = (_) => Future<http.StreamedResponse>.error(
            injectedTimeout,
            injectedStack,
          );

      var error = await _captureFailure(client.currentUser());
      expect(error.kind, SolvedAuthenticatedFailureKind.timeout);
      expect(error.cause, same(injectedTimeout));
      expect(error.stackTrace, same(injectedStack));
      expect(error.toString(), isNot(contains('access-token')));

      final injectedTransport = http.ClientException('access-token');
      handler = (_) async => throw injectedTransport;
      error = await _captureFailure(client.currentUser());
      expect(error.kind, SolvedAuthenticatedFailureKind.transport);
      expect(error.isRetryable, isTrue);
      expect(error.cause, same(injectedTransport));
      expect(error.toString(), isNot(contains('access-token')));
      expect(httpClient.requests, hasLength(2));
    });

    test('sends one token-bound rivals GET and decodes the board', () async {
      handler =
          (_) async => _jsonResponse(fixture('v4/rival_leaderboard.json'));

      final omitted = await client.rivals();
      final explicit = await client.rivals(page: 1);

      expect(omitted.rivalCount, -1);
      expect(explicit.items.first.isRival, isTrue);
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/rankings/rivals',
        'https://proxy.example/solved/v4/rankings/rivals?page=1',
      ]);
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(request.maxRedirects, 0);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.url.toString(), isNot(contains('do-not-send-refresh')));
        expect(request.bodyBytes, isEmpty);
      }
    });

    test('sends one token-bound reverse-rivals GET', () async {
      handler =
          (_) async => _jsonResponse(fixture('v4/rival_leaderboard.json'));

      final omitted = await client.reverseRivals();
      final explicit = await client.reverseRivals(page: 2);

      expect(omitted.reverseRivalCount, 0);
      expect(explicit.items[1].isReverseRival, isTrue);
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/rankings/reverse-rivals',
        'https://proxy.example/solved/v4/rankings/reverse-rivals?page=2',
      ]);
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(request.maxRedirects, 0);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.bodyBytes, isEmpty);
      }

      await expectLater(
        client.reverseRivals(page: 0),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
        ),
      );
      expect(httpClient.requests, hasLength(2));

      handler = (_) async => _bytesResponse(
            const <int>[],
            statusCode: 401,
            headers: const <String, String>{'content-type': 'text/plain'},
          );
      final error = await _captureFailure(client.reverseRivals());
      expect(error.operation, SolvedAuthenticatedOperation.reverseRivals);
      expect(error.kind, SolvedAuthenticatedFailureKind.unauthorized);
      expect(
        error.uri,
        Uri.parse('https://proxy.example/solved/v4/rankings/reverse-rivals'),
      );
    });

    test('sends one token-bound bookmark-favorites GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/bookmark_folders.json'));

      final omitted = await client.bookmarkFavorites();
      await client.bookmarkFavorites(page: 10000);

      expect(omitted.folders.first.slug, 'dp_set');
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/account/bookmark-favorites',
        'https://proxy.example/solved/v4/account/bookmark-favorites?'
            'page=10000',
      ]);
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.bodyBytes, isEmpty);
      }

      for (final page in [0, 10001]) {
        await expectLater(
          client.bookmarkFavorites(page: page),
          throwsA(
            isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
          ),
        );
      }
      expect(httpClient.requests, hasLength(2));

      handler = (_) async => _jsonResponse('{"folders":null}');
      final error = await _captureFailure(client.bookmarkFavorites());
      expect(error.operation, SolvedAuthenticatedOperation.bookmarkFavorites);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound collection GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/user_collection.json'));

      final omitted = await client.collection();
      await client.collection(
        kind: OfficialAchievementItemKind.badge,
        query: 'a b',
        offset: 0,
      );

      expect(omitted.counts.background, -2);
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/account/collection',
        'https://proxy.example/solved/v4/account/collection?'
            'kind=badge&q=a+b&offset=0',
      ]);
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.bodyBytes, isEmpty);
      }

      await expectLater(
        client.collection(offset: -1),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'offset'),
        ),
      );
      expect(httpClient.requests, hasLength(2));

      handler = (_) async => _jsonResponse('{"items":null}');
      final error = await _captureFailure(client.collection());
      expect(error.operation, SolvedAuthenticatedOperation.collection);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound viewer-vote GET', () async {
      handler = (_) async => _jsonResponse('{"vote":null}');

      final none = await client.myProblemVote(1000);
      await client.myProblemVote(1000, sub: 'a&b');

      expect(none.vote, isNull);
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/problems/1000/votes/me',
        'https://proxy.example/solved/v4/problems/1000/votes/me?sub=a%26b',
      ]);
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.bodyBytes, isEmpty);
      }

      await expectLater(
        client.myProblemVote(0),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'problemId'),
        ),
      );
      expect(httpClient.requests, hasLength(2));

      handler = (_) async => _bytesResponse(
            const <int>[],
            statusCode: 403,
            headers: const <String, String>{'content-type': 'text/plain'},
          );
      final error = await _captureFailure(client.myProblemVote(1000));
      expect(error.operation, SolvedAuthenticatedOperation.myProblemVote);
      expect(error.kind, SolvedAuthenticatedFailureKind.forbidden);
      expect(error.statusCode, 403);
    });

    test('sends one token-bound tag-progress GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/tag_progress.json'));

      final actual = await client.tagProgress();

      expect(actual.ratings.single.rating, -50);
      final request = httpClient.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/me/tag-progress'),
      );
      expect(request.method, 'GET');
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"counts":[]}');
      final error = await _captureFailure(client.tagProgress());
      expect(error.operation, SolvedAuthenticatedOperation.tagProgress);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound consents GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_consents.json'));

      final actual = await client.accountConsents();

      expect(actual.pending, hasLength(3));
      final request = httpClient.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/account/consents'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _bytesResponse(
            const <int>[],
            statusCode: 401,
            headers: const <String, String>{'content-type': 'text/plain'},
          );
      final error = await _captureFailure(client.accountConsents());
      expect(error.operation, SolvedAuthenticatedOperation.accountConsents);
      expect(error.kind, SolvedAuthenticatedFailureKind.unauthorized);
    });

    test('sends one token-bound wallet GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_wallet.json'));

      final actual = await client.accountWallet();

      expect(actual.stardusts, -5);
      final request = httpClient.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/account/wallet'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"stardusts":1}');
      final error = await _captureFailure(client.accountWallet());
      expect(error.operation, SolvedAuthenticatedOperation.accountWallet);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound emoticons GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/emoticon_catalog.json'));

      final actual = await client.emoticons();

      expect(actual.items, hasLength(3));
      final request = httpClient.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/me/emoticons'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"items":[{}]}');
      final error = await _captureFailure(client.emoticons());
      expect(error.operation, SolvedAuthenticatedOperation.emoticons);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound backgrounds GET', () async {
      handler =
          (_) async => _jsonResponse(fixture('v4/account_backgrounds.json'));

      final actual = await client.accountBackgrounds();

      expect(actual.backgrounds, hasLength(3));
      final request = httpClient.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/account/backgrounds'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"backgrounds":[{}]}');
      final error = await _captureFailure(client.accountBackgrounds());
      expect(error.operation, SolvedAuthenticatedOperation.accountBackgrounds);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound bans GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_bans.json'));

      final actual = await client.accountBans();

      expect(actual.items, hasLength(3));
      final request = httpClient.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/account/bans'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"items":[{}]}');
      final error = await _captureFailure(client.accountBans());
      expect(error.operation, SolvedAuthenticatedOperation.accountBans);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound standing GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_standing.json'));

      final actual = await client.accountStanding();

      expect(actual.strikes, hasLength(3));
      final request = httpClient.requests.single;
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/account/standing'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"strikes":[]}');
      final error = await _captureFailure(client.accountStanding());
      expect(error.operation, SolvedAuthenticatedOperation.accountStanding);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound viewer-folders GET', () async {
      handler = (_) async =>
          _jsonResponse(fixture('v4/account_bookmark_folders.json'));

      final omitted = await client.accountBookmarks();
      await client.accountBookmarks(problemId: 1000);

      expect(omitted.folders.first.containsProblem, isTrue);
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/account/bookmarks',
        'https://proxy.example/solved/v4/account/bookmarks?problemId=1000',
      ]);
      for (final request in httpClient.requests) {
        expect(request.followRedirects, isFalse);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.bodyBytes, isEmpty);
      }

      await expectLater(
        client.accountBookmarks(problemId: 0),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'problemId'),
        ),
      );
      expect(httpClient.requests, hasLength(2));

      handler = (_) async => _jsonResponse('{"folders":[{}]}');
      final error = await _captureFailure(client.accountBookmarks());
      expect(error.operation, SolvedAuthenticatedOperation.accountBookmarks);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound wallet-history GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/wallet_history.json'));

      final omitted = await client.walletHistory();
      await client.walletHistory(month: '2026-11', language: 'ko');

      expect(omitted.moves, hasLength(3));
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/account/wallet/history',
        'https://proxy.example/solved/v4/account/wallet/history?'
            'month=2026-11&lang=ko',
      ]);
      for (final request in httpClient.requests) {
        expect(request.followRedirects, isFalse);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.bodyBytes, isEmpty);
      }

      await expectLater(
        client.walletHistory(month: '2026-13'),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'month'),
        ),
      );
      expect(httpClient.requests, hasLength(2));

      handler = (_) async => _jsonResponse('{"month":"x"}');
      final error = await _captureFailure(client.walletHistory());
      expect(error.operation, SolvedAuthenticatedOperation.walletHistory);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound items GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_items.json'));

      final omitted = await client.accountItems();
      await client.accountItems(language: 'en');

      expect(omitted.items, hasLength(3));
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/account/items',
        'https://proxy.example/solved/v4/account/items?lang=en',
      ]);
      for (final request in httpClient.requests) {
        expect(request.followRedirects, isFalse);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer access-token',
        });
        expect(request.bodyBytes, isEmpty);
      }

      handler = (_) async => _jsonResponse('{"items":[]}');
      final error = await _captureFailure(client.accountItems());
      expect(error.operation, SolvedAuthenticatedOperation.accountItems);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound profile GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_profile.json'));

      final actual = await client.accountProfile();

      expect(actual.profile.gender, 9);
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/account/profile',
      ]);
      final request = httpClient.requests.single;
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"profile":{}}');
      final error = await _captureFailure(client.accountProfile());
      expect(error.operation, SolvedAuthenticatedOperation.accountProfile);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound settings GET', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_settings.json'));

      final actual = await client.accountSettings();

      expect(actual.settings.theme, AccountSettingTheme.dark);
      expect(httpClient.requests.map((request) => request.url.toString()), [
        'https://proxy.example/solved/v4/account/settings',
      ]);
      final request = httpClient.requests.single;
      expect(request.method, 'GET');
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      handler = (_) async => _jsonResponse('{"settings":{}}');
      final error = await _captureFailure(client.accountSettings());
      expect(error.operation, SolvedAuthenticatedOperation.accountSettings);
      expect(error.kind, SolvedAuthenticatedFailureKind.invalidResponse);
    });

    test('sends one token-bound settings PATCH and never retries', () async {
      handler = (_) async => _jsonResponse(fixture('v4/account_settings.json'));

      final actual = await client.updateAccountSettings(
        const AccountSettingsPatch(
          theme: NullablePatch.value(AccountSettingTheme.light),
          iconTheme: NullablePatch.toNull(),
        ),
      );

      expect(actual.settings.theme, AccountSettingTheme.dark);
      final request = httpClient.requests.single;
      expect(request.method, 'PATCH');
      expect(
        request.url.toString(),
        'https://proxy.example/solved/v4/account/settings',
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
        'content-type': 'application/json',
      });
      expect(
        utf8.decode(request.bodyBytes),
        '{"theme":"light","iconTheme":null}',
      );

      await expectLater(
        client.updateAccountSettings(
          const AccountSettingsPatch(iconWarnAbsolute: NullablePatch.value(31)),
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'iconWarnAbsolute'),
        ),
      );
      expect(httpClient.requests, hasLength(1));

      handler = (_) async => _jsonResponse('{}', statusCode: 503);
      final error = await _captureFailure(
        client.updateAccountSettings(const AccountSettingsPatch()),
      );
      expect(
          error.operation, SolvedAuthenticatedOperation.updateAccountSettings);
      expect(error.kind, SolvedAuthenticatedFailureKind.unexpectedStatus);
      expect(error.statusCode, 503);
      expect(httpClient.requests, hasLength(2));
      expect(httpClient.requests.last.bodyBytes, utf8.encode('{}'));
    });

    test('sends one bodyless favorite POST and never retries', () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/bookmark_favorite_state.json'),
          );

      final actual = await client.addBookmarkFavorite('a b', 'z_9');

      expect(actual.isFavorite, isFalse);
      final request = httpClient.requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://proxy.example/solved/v4/account/bookmark-favorites/a%20b/z_9',
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      await expectLater(
        client.addBookmarkFavorite('a', 'A'),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'slug'),
        ),
      );
      expect(httpClient.requests, hasLength(1));

      handler = (_) async => _jsonResponse('{}', statusCode: 404);
      final error = await _captureFailure(client.addBookmarkFavorite('a', 'b'));
      expect(error.operation, SolvedAuthenticatedOperation.addBookmarkFavorite);
      expect(error.kind, SolvedAuthenticatedFailureKind.unexpectedStatus);
      expect(error.statusCode, 404);
      expect(httpClient.requests, hasLength(2));
    });

    test('sends one bodyless favorite DELETE and never retries', () async {
      handler = (_) async => _jsonResponse(
            '{"isFavorite":false,"favoriteCount":0}',
          );

      final actual = await client.removeBookmarkFavorite('a b', 'z_9');

      expect(actual.isFavorite, isFalse);
      expect(actual.favoriteCount, 0);
      final request = httpClient.requests.single;
      expect(request.method, 'DELETE');
      expect(
        request.url.toString(),
        'https://proxy.example/solved/v4/account/bookmark-favorites/a%20b/z_9',
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      await expectLater(
        client.removeBookmarkFavorite('', 'b'),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'handle'),
        ),
      );
      expect(httpClient.requests, hasLength(1));

      handler = (_) async => _jsonResponse('{}', statusCode: 401);
      final error = await _captureFailure(
        client.removeBookmarkFavorite('a', 'b'),
      );
      expect(
        error.operation,
        SolvedAuthenticatedOperation.removeBookmarkFavorite,
      );
      expect(error.kind, SolvedAuthenticatedFailureKind.unauthorized);
      expect(httpClient.requests, hasLength(2));
    });

    test('sends one folder DELETE and requires exactly no content', () async {
      handler = (_) async => _bytesResponse(const <int>[], statusCode: 204);

      await client.deleteBookmarkFolder('z_9');

      final request = httpClient.requests.single;
      expect(request.method, 'DELETE');
      expect(
        request.url.toString(),
        'https://proxy.example/solved/v4/account/bookmarks/z_9',
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
      });
      expect(request.bodyBytes, isEmpty);

      await expectLater(
        client.deleteBookmarkFolder('Z'),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'slug'),
        ),
      );
      expect(httpClient.requests, hasLength(1));

      for (final (response, kind) in [
        (
          () => _bytesResponse(const <int>[0x7b, 0x7d], statusCode: 204),
          SolvedAuthenticatedFailureKind.invalidResponse,
        ),
        (
          () => _bytesResponse(
                const <int>[],
                statusCode: 204,
                headers: const <String, String>{
                  'Content-Type': 'application/json',
                },
              ),
          SolvedAuthenticatedFailureKind.invalidResponse,
        ),
        (
          () => _jsonResponse('{}'),
          SolvedAuthenticatedFailureKind.unexpectedStatus,
        ),
        (
          () => _jsonResponse('{}', statusCode: 404),
          SolvedAuthenticatedFailureKind.unexpectedStatus,
        ),
      ]) {
        handler = (_) async => response();
        final error = await _captureFailure(client.deleteBookmarkFolder('a'));
        expect(
          error.operation,
          SolvedAuthenticatedOperation.deleteBookmarkFolder,
        );
        expect(error.kind, kind);
      }
      expect(httpClient.requests, hasLength(5));
    });

    test('sends one folder-order POST with a JSON body', () async {
      handler = (_) async => _bytesResponse(const <int>[], statusCode: 204);

      await client.reorderBookmarkFolders(['b', 'a']);

      final request = httpClient.requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://proxy.example/solved/v4/account/bookmarks/order',
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
        'content-type': 'application/json',
      });
      expect(utf8.decode(request.bodyBytes), '{"slugs":["b","a"]}');

      await expectLater(
        client.reorderBookmarkFolders(const []),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'slugs'),
        ),
      );
      expect(httpClient.requests, hasLength(1));

      handler = (_) async => _jsonResponse('{}', statusCode: 409);
      final error = await _captureFailure(client.reorderBookmarkFolders(['a']));
      expect(
        error.operation,
        SolvedAuthenticatedOperation.reorderBookmarkFolders,
      );
      expect(error.kind, SolvedAuthenticatedFailureKind.unexpectedStatus);
      expect(error.statusCode, 409);
      expect(httpClient.requests, hasLength(2));
    });

    test('sends one folder-create POST and requires exactly 201', () async {
      final folder = ((jsonDecode(fixture('v4/bookmark_folders.json'))
              as Map<String, dynamic>)['folders'] as List<dynamic>)
          .first;
      handler = (_) async => _jsonResponse(jsonEncode(folder), statusCode: 201);

      final actual = await client.createBookmarkFolder(
        const NewBookmarkFolder(
          slug: 'z_9',
          name: 'n',
          visibility: BookmarkFolderVisibility.public,
        ),
      );

      expect(actual.slug, (folder as Map<String, dynamic>)['slug']);
      final request = httpClient.requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://proxy.example/solved/v4/account/bookmarks',
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer access-token',
        'content-type': 'application/json',
      });
      expect(
        utf8.decode(request.bodyBytes),
        '{"slug":"z_9","name":"n","visibility":"public"}',
      );

      await expectLater(
        client
            .createBookmarkFolder(const NewBookmarkFolder(slug: 'a', name: '')),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'name'),
        ),
      );
      expect(httpClient.requests, hasLength(1));

      for (final status in [200, 409, 422]) {
        handler =
            (_) async => _jsonResponse(jsonEncode(folder), statusCode: status);
        final error = await _captureFailure(
          client.createBookmarkFolder(
            const NewBookmarkFolder(slug: 'a', name: 'b'),
          ),
        );
        expect(
          error.operation,
          SolvedAuthenticatedOperation.createBookmarkFolder,
        );
        expect(error.kind, SolvedAuthenticatedFailureKind.unexpectedStatus);
        expect(error.statusCode, status);
      }
      expect(httpClient.requests, hasLength(4));
    });

    test('keeps GET success at exactly 200', () async {
      handler = (_) async => _bytesResponse(const <int>[], statusCode: 204);

      final error = await _captureFailure(client.accountSettings());

      expect(error.kind, SolvedAuthenticatedFailureKind.unexpectedStatus);
      expect(error.statusCode, 204);
    });

    test('rejects an invalid rivals page before any request', () async {
      await expectLater(
        client.rivals(page: 0),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
        ),
      );
      expect(httpClient.requests, isEmpty);
    });

    test('classifies rivals failures with the rivals operation', () async {
      handler = (_) async => _bytesResponse(
            utf8.encode('do-not-log-response'),
            statusCode: 401,
            headers: const <String, String>{'content-type': 'text/plain'},
          );
      final unauthorized = await _captureFailure(client.rivals(page: 3));
      expect(unauthorized.operation, SolvedAuthenticatedOperation.rivals);
      expect(unauthorized.kind, SolvedAuthenticatedFailureKind.unauthorized);
      expect(
        unauthorized.uri,
        Uri.parse('https://proxy.example/solved/v4/rankings/rivals?page=3'),
      );
      expect(unauthorized.toString(), isNot(contains('access-token')));

      handler = (_) async => _jsonResponse('{"items":[]}');
      final invalid = await _captureFailure(client.rivals());
      expect(invalid.kind, SolvedAuthenticatedFailureKind.invalidResponse);
      expect(invalid.statusCode, 200);
      expect(
        invalid.uri,
        Uri.parse('https://proxy.example/solved/v4/rankings/rivals'),
      );

      handler = (_) async => _bytesResponse(
            const <int>[],
            statusCode: 429,
            headers: const <String, String>{'retry-after': '7'},
          );
      final limited = await _captureFailure(client.rivals());
      expect(limited.kind, SolvedAuthenticatedFailureKind.rateLimited);
      expect(limited.retryAfter, const Duration(seconds: 7));
      expect(httpClient.requests, hasLength(3));
    });

    test('does not close an injected client and rejects use after close',
        () async {
      client.close();
      client.close();

      expect(httpClient.wasClosed, isFalse);
      await expectLater(
        client.currentUser(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'SolvedAuthenticatedApiClient is closed',
          ),
        ),
      );
      await expectLater(client.rivals(), throwsStateError);
      await expectLater(client.reverseRivals(), throwsStateError);
      await expectLater(client.bookmarkFavorites(), throwsStateError);
      await expectLater(client.collection(), throwsStateError);
      await expectLater(client.myProblemVote(1), throwsStateError);
      await expectLater(client.tagProgress(), throwsStateError);
      await expectLater(client.accountConsents(), throwsStateError);
      await expectLater(client.accountWallet(), throwsStateError);
      await expectLater(client.emoticons(), throwsStateError);
      await expectLater(client.accountBackgrounds(), throwsStateError);
      await expectLater(client.accountBans(), throwsStateError);
      await expectLater(client.accountStanding(), throwsStateError);
      await expectLater(client.accountBookmarks(), throwsStateError);
      await expectLater(client.walletHistory(), throwsStateError);
      await expectLater(client.accountItems(), throwsStateError);
      await expectLater(client.accountProfile(), throwsStateError);
      await expectLater(client.accountSettings(), throwsStateError);
      await expectLater(
        client.updateAccountSettings(const AccountSettingsPatch()),
        throwsStateError,
      );
      await expectLater(client.addBookmarkFavorite('a', 'b'), throwsStateError);
      await expectLater(
        client.removeBookmarkFavorite('a', 'b'),
        throwsStateError,
      );
      await expectLater(client.deleteBookmarkFolder('a'), throwsStateError);
      await expectLater(client.reorderBookmarkFolders(['a']), throwsStateError);
      await expectLater(
        client.createBookmarkFolder(
          const NewBookmarkFolder(slug: 'a', name: 'b'),
        ),
        throwsStateError,
      );
      expect(httpClient.requests, isEmpty);
    });
  });
}

SolvedAuthenticatedApiClient _client(
  http.Client httpClient, {
  Duration requestTimeout = const Duration(seconds: 10),
}) =>
    SolvedAuthenticatedApiClient(
      proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
      token: _tokenResponse(),
      httpClient: httpClient,
      requestTimeout: requestTimeout,
    );

SolvedOAuthTokenResponse _tokenResponse() =>
    SolvedOAuthTokenResponse.fromJson(<String, Object?>{
      'access_token': 'access-token',
      'token_type': 'Bearer',
      'expires_in': 3600,
      'refresh_token': 'do-not-send-refresh',
      'scope': 'profile offline.access',
    });

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

Future<SolvedAuthenticatedRequestFailed> _captureFailure(
  Future<Object?> future,
) async {
  try {
    await future;
  } on SolvedAuthenticatedRequestFailed catch (error) {
    return error;
  }
  throw StateError('Expected an authenticated request failure');
}
