import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/src/public_contract_capture.dart';

void main() {
  group('PublicHarInventory', () {
    test('deduplicates and sorts contract shapes without retaining values', () {
      final first = PublicHarInventory('solved.ac').inspect(
        _har([
          _entry(
            url: 'https://solved.ac/api/v4/z?query=private-z',
            body: '[{"private":"response-z"}]',
          ),
          _entry(
            url:
                'https://solved.ac/api/v4/user?sort=rank&handle=private-one&handle=private-two',
            body: '{"handle":"private-response-one"}',
          ),
          _entry(
            url:
                'https://solved.ac/api/v4/user?handle=private-three&handle=private-four&sort=solved',
            body: '{"handle":"private-response-two"}',
          ),
          _entry(
            url: 'https://solved.ac/api/v4/a',
            body: '42',
          ),
        ]),
      );
      final second = PublicHarInventory('solved.ac').inspect(
        _har([
          _entry(url: 'https://solved.ac/api/v4/a', body: '99'),
          _entry(
            url:
                'https://solved.ac/api/v4/user?handle=changed-a&handle=changed-b&sort=other',
            body: '{"handle":"changed-response-a"}',
          ),
          _entry(
            url: 'https://solved.ac/api/v4/z?query=changed-z',
            body: '[{"private":"changed-response-z"}]',
          ),
          _entry(
            url:
                'https://solved.ac/api/v4/user?sort=different&handle=changed-c&handle=changed-d',
            body: '{"handle":"changed-response-b"}',
          ),
        ]),
      );

      final firstJson = first.toJson();
      expect(firstJson, second.toJson());
      expect(
        const JsonEncoder.withIndent('  ').convert(firstJson),
        const JsonEncoder.withIndent('  ').convert(second.toJson()),
      );
      expect(firstJson['summary'], {
        'totalEntries': 4,
        'candidateOccurrences': 4,
        'candidateContracts': 3,
        'excludedEntries': {
          'invalidEntry': 0,
          'unsupportedMethod': 0,
          'unsupportedOrigin': 0,
          'unsafeRequest': 0,
          'unsupportedResponse': 0,
        },
      });

      final candidates = (firstJson['candidates']! as List<Object?>)
          .cast<Map<String, Object?>>();
      final paths = candidates.map((candidate) {
        final request = candidate['request']! as Map<String, Object?>;
        return request['path'];
      });
      expect(paths, ['/api/v4/a', '/api/v4/user', '/api/v4/z']);

      final user = candidates[1];
      expect(user['occurrences'], 2);
      expect(user['request'], {
        'method': 'GET',
        'scheme': 'https',
        'path': '/api/v4/user',
        'query': [
          {'name': 'handle', 'valueCount': 2},
          {'name': 'sort', 'valueCount': 1},
        ],
      });
      expect(user['response'], {
        'status': 200,
        'contentType': 'application/json',
        'topLevelType': 'object',
      });

      final encoded = jsonEncode(firstJson);
      for (final secret in [
        'private-one',
        'private-two',
        'private-three',
        'private-four',
        'private-z',
        'private-response-one',
        'private-response-two',
        'response-z',
        'timestamp-secret',
      ]) {
        expect(encoded, isNot(contains(secret)));
      }
    });

    test(
        'normalizes JSON media types and groups empty and heterogeneous arrays',
        () {
      final encoded = base64Encode(utf8.encode('[]'));
      final result = PublicHarInventory('solved.ac').inspect(
        _har([
          _entry(
            url: 'https://solved.ac/api/v4/problem',
            body: encoded,
            encoding: 'base64',
            mimeType: 'Application/Problem+JSON; Charset=UTF-8',
          ),
          _entry(
            url: 'https://solved.ac/api/v4/problem',
            body: '[{"private":"heterogeneous-secret"},1,null]',
            mimeType: 'application/problem+json',
          ),
        ]),
      );

      final candidate = result.candidates.single.toJson();
      expect(candidate['occurrences'], 2);
      expect(candidate['response'], {
        'status': 200,
        'contentType': 'application/problem+json',
        'topLevelType': 'array',
      });
      expect(
          jsonEncode(result.toJson()), isNot(contains('heterogeneous-secret')));
    });

    test('uses fixed counters for unsafe, malformed, and unsupported entries',
        () {
      final invalidUtf8 = base64Encode([0xff, 0xfe]);
      final entries = <Object?>[
        null,
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          method: 'POST',
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          method: 'get',
        ),
        _entry(
          url: 'https://example.com/api/v4/public',
          body: '{"irrelevant-host-response-secret":',
          mimeType: 'malformed-irrelevant-host-mime-secret',
          responseHeaders: 'malformed-irrelevant-host-header-secret',
        ),
        _entry(url: 'http://solved.ac/api/v4/public', body: '{}'),
        _entry(url: 'https://user@solved.ac/api/v4/public', body: '{}'),
        _entry(url: 'https://solved.ac:444/api/v4/public', body: '{}'),
        _entry(url: 'https://solved.ac/api/v4/public#fragment', body: '{}'),
        _entry(url: 'https://solved.ac/api/token/public', body: '{}'),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          postData: {'text': 'body-secret'},
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          cookies: const [
            {'name': 'session', 'value': 'cookie-secret'},
          ],
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          headers: const [
            {'name': 'Authorization', 'value': 'Bearer header-secret'},
          ],
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          headers: const [
            {'name': 'X-Unknown', 'value': 'unknown-header-secret'},
          ],
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public?access%5Ftoken=query-secret',
          body: '{}',
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public?handle=url-secret',
          body: '{}',
          queryString: const [
            {'name': 'handle', 'value': 'different-secret'},
          ],
        ),
        _entry(
          url:
              'https://solved.ac/api/v4/public?handle=first-order-secret&sort=middle-order-secret&handle=last-order-secret',
          body: '{}',
          queryString: const [
            {'name': 'handle', 'value': 'first-order-secret'},
            {'name': 'handle', 'value': 'last-order-secret'},
            {'name': 'sort', 'value': 'middle-order-secret'},
          ],
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '<html>response-secret</html>',
          mimeType: 'text/html',
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{"response-secret":',
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: 'not-base64-response-secret',
          encoding: 'base64',
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: invalidUtf8,
          encoding: 'base64',
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          mimeType: 'not a mime type',
        ),
        _entry(
          url: 'https://solved.ac/api/v4/public',
          body: '{}',
          responseHeaders: const [
            {'name': 'Content-Type', 'value': 'text/plain'},
          ],
        ),
      ];

      final result = PublicHarInventory('solved.ac').inspect(_har(entries));
      final summary = result.toJson()['summary']! as Map<String, Object?>;

      expect(result.candidates, isEmpty);
      expect(summary['totalEntries'], entries.length);
      expect(summary['excludedEntries'], {
        'invalidEntry': 3,
        'unsupportedMethod': 2,
        'unsupportedOrigin': 5,
        'unsafeRequest': 6,
        'unsupportedResponse': 6,
      });
      final encoded = jsonEncode(result.toJson());
      for (final secret in [
        'body-secret',
        'cookie-secret',
        'header-secret',
        'unknown-header-secret',
        'query-secret',
        'url-secret',
        'different-secret',
        'first-order-secret',
        'middle-order-secret',
        'last-order-secret',
        'response-secret',
        'irrelevant-host-response-secret',
        'malformed-irrelevant-host-mime-secret',
        'malformed-irrelevant-host-header-secret',
      ]) {
        expect(encoded, isNot(contains(secret)));
      }
    });

    test('rejects invalid hosts and malformed HAR roots', () {
      for (final host in [
        'Solved.AC',
        'solved.ac:443',
        'https://solved.ac',
        '',
      ]) {
        expect(() => PublicHarInventory(host), throwsFormatException);
      }
      for (final har in [
        null,
        {},
        {'log': null},
        {
          'log': {'entries': null},
        },
      ]) {
        expect(
          () => PublicHarInventory('solved.ac').inspect(har),
          throwsFormatException,
        );
      }
    });
  });

  group('inventory CLI', () {
    late Directory temporaryDirectory;

    setUp(() {
      temporaryDirectory =
          Directory.systemTemp.createTempSync('public-har-inventory-test-');
    });

    tearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });

    test('emits deterministic JSON without wire values or input path',
        () async {
      final input = File(
        '${temporaryDirectory.path}/local-path-secret.har',
      )..writeAsStringSync(
          jsonEncode(
            _har([
              _entry(
                url: 'https://solved.ac/api/v4/user?handle=cli-query-secret',
                body: '{"handle":"cli-response-secret"}',
                headers: const [
                  {'name': 'Accept', 'value': 'header-value-secret'},
                ],
                responseHeaders: const [
                  {'name': 'Content-Type', 'value': 'application/json'},
                  {'name': 'Set-Cookie', 'value': 'response-cookie-secret'},
                ],
              ),
            ]),
          ),
        );

      final process = await _runCli(input, ['--host', 'solved.ac']);

      expect(process.exitCode, 0, reason: process.stderr.toString());
      final output = process.stdout.toString();
      expect(jsonDecode(output), isA<Map<String, Object?>>());
      for (final secret in [
        input.path,
        'local-path-secret',
        'cli-query-secret',
        'cli-response-secret',
        'header-value-secret',
        'response-cookie-secret',
        'timestamp-secret',
      ]) {
        expect(output, isNot(contains(secret)));
      }
    });

    test('fails generically for malformed content and strict options',
        () async {
      final input = File(
        '${temporaryDirectory.path}/failure-local-path-secret.har',
      )..writeAsStringSync('{"malformed-secret":');

      final processes = [
        await _runCli(input, ['--host', 'solved.ac']),
        await _runCli(input, [
          '--host',
          'solved.ac',
          '--host',
          'solved.ac',
        ]),
        await _runCli(input, ['--host', 'Solved.AC']),
        await _runCli(input, ['--unknown', 'value']),
      ];

      for (final process in processes) {
        expect(process.exitCode, 64);
        final combined = '${process.stdout}${process.stderr}';
        expect(combined, isNot(contains(input.path)));
        expect(combined, isNot(contains('failure-local-path-secret')));
        expect(combined, isNot(contains('malformed-secret')));
      }
    });
  });
}

Map<String, Object?> _har(List<Object?> entries) => {
      'log': {'entries': entries},
    };

Map<String, Object?> _entry({
  required String url,
  required String? body,
  String method = 'GET',
  int status = 200,
  String mimeType = 'application/json; charset=utf-8',
  String? encoding,
  Object headers = const <Map<String, String>>[],
  Object cookies = const <Map<String, String>>[],
  Object? queryString,
  Object? postData,
  Object? responseHeaders,
}) {
  final uri = Uri.parse(url);
  return {
    'startedDateTime': 'timestamp-secret',
    'request': <String, Object?>{
      'method': method,
      'url': url,
      'headers': headers,
      'cookies': cookies,
      'queryString': queryString ??
          [
            for (final entry in uri.queryParametersAll.entries)
              for (final value in entry.value)
                {'name': entry.key, 'value': value},
          ],
      if (postData != null) 'postData': postData,
    },
    'response': <String, Object?>{
      'status': status,
      'headers': responseHeaders ??
          [
            {'name': 'Content-Type', 'value': mimeType},
          ],
      'content': <String, Object?>{
        'mimeType': mimeType,
        'text': body,
        if (encoding != null) 'encoding': encoding,
      },
    },
  };
}

Future<ProcessResult> _runCli(File input, List<String> arguments) =>
    Process.run(
      Platform.resolvedExecutable,
      [
        'run',
        'tool/inventory_public_har.dart',
        '--input',
        input.path,
        ...arguments,
      ],
      workingDirectory: Directory.current.path,
    );
