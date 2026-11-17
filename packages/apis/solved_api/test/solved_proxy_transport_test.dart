import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:solved_api/src/solved_proxy_transport.dart';
import 'package:test/test.dart';

typedef _RequestHandler = Future<http.StreamedResponse> Function(
  http.Request request,
);

final class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.handler);

  final _RequestHandler handler;
  final List<http.Request> requests = <http.Request>[];
  var closeCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is! http.Request) {
      throw StateError('Expected a buffered HTTP request');
    }
    requests.add(request);
    return handler(request);
  }

  @override
  void close() {
    closeCount += 1;
  }
}

void main() {
  group('SolvedProxyTransport configuration', () {
    test('requires the canonical proxy boundary and a positive timeout', () {
      final httpClient = _RecordingClient(_unusedHandler);
      for (final uri in <Uri>[
        Uri.parse('/solved/v4/'),
        Uri.parse('http://proxy.example/solved/v4/'),
        Uri.parse('https://solved.ac/solved/v4/'),
        Uri.parse('https://solved.ac./solved/v4/'),
        Uri.parse('https://api.solved.ac/solved/v4/'),
        Uri.parse('https://api.solved.ac./solved/v4/'),
        Uri.parse('https://proxy.example/api/v4/'),
        Uri.parse('https://proxy.example/solved/v4'),
        Uri.parse('https://user@proxy.example/solved/v4/'),
        Uri.parse('https://proxy.example/solved/v4/?query=yes'),
        Uri.parse('https://proxy.example/solved/v4/#fragment'),
      ]) {
        expect(
          () => SolvedProxyTransport(
            proxyBaseUri: uri,
            httpClient: httpClient,
          ),
          throwsArgumentError,
          reason: uri.toString(),
        );
      }
      for (final timeout in <Duration>[
        Duration.zero,
        const Duration(microseconds: -1),
      ]) {
        expect(
          () => SolvedProxyTransport(
            proxyBaseUri: Uri.parse(
              'https://proxy.example/solved/v4/',
            ),
            httpClient: httpClient,
            requestTimeout: timeout,
          ),
          throwsArgumentError,
          reason: timeout.toString(),
        );
      }
    });

    test('requires an explicit opt-in for HTTP loopback', () {
      final httpClient = _RecordingClient(_unusedHandler);
      for (final value in <String>[
        'http://localhost:8080/solved/v4/',
        'http://127.0.0.1:8080/solved/v4/',
        'http://[::1]:8080/solved/v4/',
      ]) {
        final uri = Uri.parse(value);
        expect(
          () => SolvedProxyTransport(
            proxyBaseUri: uri,
            httpClient: httpClient,
          ),
          throwsArgumentError,
        );
        final transport = SolvedProxyTransport(
          proxyBaseUri: uri,
          httpClient: httpClient,
          allowInsecureLoopback: true,
        );
        expect(transport.proxyBaseUri, uri);
        transport.close();
      }
      expect(httpClient.closeCount, 0);
    });
  });

  group('SolvedProxyTransport request boundary', () {
    test('sends one bounded form request and returns the raw response',
        () async {
      final httpClient = _RecordingClient(
        (_) async => _response(
          <int>[1, 2, 3],
          statusCode: 599,
          headers: const <String, String>{'content-type': 'text/plain'},
        ),
      );
      final transport = _transport(httpClient);

      final response = await transport.postForm(
        relativePath: 'oauth/token',
        fields: const <String, String>{'grant_type': 'refresh_token'},
      );

      expect(httpClient.requests, hasLength(1));
      final request = httpClient.requests.single;
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('https://proxy.example/solved/v4/oauth/token'),
      );
      expect(request.followRedirects, isFalse);
      expect(request.maxRedirects, 0);
      expect(request.headers['accept'], 'application/json');
      expect(
        request.headers['content-type'],
        'application/x-www-form-urlencoded',
      );
      expect(request.body, 'grant_type=refresh_token');
      expect(response.uri, request.url);
      expect(response.statusCode, 599);
      expect(response.headers['content-type'], 'text/plain');
      expect(response.bodyBytes, <int>[1, 2, 3]);
    });

    test('rejects relative paths that can escape or change the request target',
        () {
      final httpClient = _RecordingClient(_unusedHandler);
      final transport = _transport(httpClient);

      for (final relativePath in <String>[
        '',
        '/',
        '//elsewhere.example/path',
        'https://elsewhere.example/path',
        'oauth/token?query=yes',
        'oauth/token#fragment',
        r'oauth\token',
        '.',
        '..',
        'oauth/./token',
        'oauth/../token',
        'oauth//token',
        'oauth/%2e/token',
        'oauth/%2E%2E/token',
        'oauth/%2f/token',
        'oauth/%5c/token',
      ]) {
        expect(
          () => transport.postForm(
            relativePath: relativePath,
            fields: const <String, String>{},
          ),
          throwsArgumentError,
          reason: relativePath,
        );
      }
      expect(httpClient.requests, isEmpty);
    });

    test('accepts exactly 64 KiB and rejects the next request byte', () async {
      final httpClient = _RecordingClient(
        (_) async => _response(const <int>[]),
      );
      final transport = _transport(httpClient);
      final exactValue = List<String>.filled(
        SolvedProxyTransport.maximumPayloadBytes - 2,
        'a',
      ).join();

      await transport.postForm(
        relativePath: 'oauth/token',
        fields: <String, String>{'x': exactValue},
      );
      expect(httpClient.requests.single.bodyBytes, hasLength(64 * 1024));

      expect(
        () => transport.postForm(
          relativePath: 'oauth/token',
          fields: <String, String>{'x': '${exactValue}a'},
        ),
        throwsA(isA<SolvedProxyRequestTooLarge>()),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('accepts exactly 64 KiB and rejects the next response byte', () async {
      late int responseSize;
      final httpClient = _RecordingClient(
        (_) async => _response(
          List<int>.filled(responseSize, 0x20),
          statusCode: 302,
        ),
      );
      final transport = _transport(httpClient);

      responseSize = SolvedProxyTransport.maximumPayloadBytes;
      final response = await transport.postForm(
        relativePath: 'oauth/token',
        fields: const <String, String>{},
      );
      expect(response.statusCode, 302);
      expect(response.bodyBytes, hasLength(64 * 1024));

      responseSize = SolvedProxyTransport.maximumPayloadBytes + 1;
      await expectLater(
        transport.postForm(
          relativePath: 'oauth/token',
          fields: const <String, String>{},
        ),
        throwsA(
          isA<SolvedProxyResponseTooLarge>().having(
            (error) => error.statusCode,
            'statusCode',
            302,
          ),
        ),
      );
      expect(httpClient.requests, hasLength(2));
    });
  });

  group('SolvedProxyTransport deadline and ownership', () {
    test('aborts a request that times out before response headers', () async {
      final wasAborted = Completer<void>();
      final neverResponds = Completer<http.StreamedResponse>();
      final httpClient = _RecordingClient((request) {
        final abortTrigger = (request as http.AbortableRequest).abortTrigger!;
        unawaited(abortTrigger.then((_) => wasAborted.complete()));
        return neverResponds.future;
      });
      final transport = _transport(
        httpClient,
        requestTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        transport.postForm(
          relativePath: 'oauth/token',
          fields: const <String, String>{},
        ),
        throwsA(isA<SolvedProxyDeadlineExceeded>()),
      );
      await wasAborted.future.timeout(const Duration(seconds: 1));
      expect(httpClient.requests, hasLength(1));
    });

    test('aborts a request that times out while reading the response',
        () async {
      final wasAborted = Completer<void>();
      final responseController = StreamController<List<int>>();
      final httpClient = _RecordingClient((request) async {
        final abortTrigger = (request as http.AbortableRequest).abortTrigger!;
        unawaited(
          abortTrigger.then((_) async {
            wasAborted.complete();
            await responseController.close();
          }),
        );
        return http.StreamedResponse(responseController.stream, 200);
      });
      final transport = _transport(
        httpClient,
        requestTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        transport.postForm(
          relativePath: 'oauth/token',
          fields: const <String, String>{},
        ),
        throwsA(isA<SolvedProxyDeadlineExceeded>()),
      );
      await wasAborted.future.timeout(const Duration(seconds: 1));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves an injected client timeout and its stack', () async {
      final injectedTimeout = TimeoutException('injected timeout');
      final injectedStack = StackTrace.current;
      final httpClient = _RecordingClient(
        (_) => Future<http.StreamedResponse>.error(
          injectedTimeout,
          injectedStack,
        ),
      );
      final transport = _transport(httpClient);

      try {
        await transport.postForm(
          relativePath: 'oauth/token',
          fields: const <String, String>{},
        );
        fail('Expected the injected timeout');
      } on Object catch (error, stackTrace) {
        expect(error, same(injectedTimeout));
        expect(stackTrace, same(injectedStack));
      }
    });

    test('does not close an injected client and rejects use after close', () {
      final httpClient = _RecordingClient(_unusedHandler);
      final transport = _transport(httpClient);

      transport.close();
      transport.close();

      expect(httpClient.closeCount, 0);
      expect(
        () => transport.postForm(
          relativePath: 'oauth/token',
          fields: const <String, String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'SolvedProxyTransport is closed',
          ),
        ),
      );
      expect(httpClient.requests, isEmpty);
    });
  });
}

SolvedProxyTransport _transport(
  http.Client httpClient, {
  Duration requestTimeout = const Duration(seconds: 10),
}) =>
    SolvedProxyTransport(
      proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
      httpClient: httpClient,
      requestTimeout: requestTimeout,
    );

Future<http.StreamedResponse> _unusedHandler(http.Request request) async =>
    throw StateError('Unexpected request: ${request.url}');

http.StreamedResponse _response(
  List<int> bytes, {
  int statusCode = 200,
  Map<String, String> headers = const <String, String>{},
}) =>
    http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      statusCode,
      headers: headers,
    );
