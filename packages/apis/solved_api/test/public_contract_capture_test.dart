import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/src/public_contract_capture.dart';

void main() {
  group('PublicContractCapturePlan', () {
    test('accepts explicit unique public operations', () {
      final plan = _plan([
        _operation(
          id: 'users-by-rank',
          path: '/public/users',
          query: {
            'sort': ['rank'],
          },
        ),
      ]);

      expect(plan.host, 'solved.ac');
      expect(plan.operations.single.id, 'users-by-rank');
    });

    test('rejects unknown fields, invalid hosts, ids, paths, and statuses', () {
      final invalidPlans = <Object?>[
        null,
        {'schemaVersion': 1, 'host': 'solved.ac', 'operations': [], 'extra': 1},
        {'schemaVersion': 2, 'host': 'solved.ac', 'operations': []},
        {'schemaVersion': 1, 'host': 'Solved.AC', 'operations': []},
        {'schemaVersion': 1, 'host': 'solved.ac:443', 'operations': []},
        _planJson([_operation(id: '../escape')]),
        _planJson([_operation(path: 'relative/path')]),
        _planJson([_operation(path: '/public/token/value')]),
        _planJson([_operation(status: 99)]),
        _planJson([_operation(status: 600)]),
        _planJson([
          {..._operation(), 'unknown': true},
        ]),
      ];

      for (final invalid in invalidPlans) {
        expect(
          () => PublicContractCapturePlan.fromJson(invalid),
          throwsFormatException,
          reason: jsonEncode(invalid),
        );
      }
    });

    test('rejects duplicate ids and exact selectors', () {
      expect(
        () => _plan([
          _operation(id: 'same', query: const {}),
          _operation(id: 'same', path: '/other', query: const {}),
        ]),
        throwsFormatException,
      );
      expect(
        () => _plan([
          _operation(id: 'first'),
          _operation(id: 'second'),
        ]),
        throwsFormatException,
      );
    });

    test('rejects malformed and credential-like query definitions', () {
      for (final name in [
        'access_token',
        'accessKey',
        'apiKey',
        'auth_key',
        'X-CSRF-Token',
        'X-Auth-Key',
        'hmac',
        'key',
        'authtoken',
        'csrftoken',
        'oauthcode',
        'passwordhash',
        'secretkey',
        'sessionid',
        'session_id',
        'sig',
        'private-key',
      ]) {
        expect(
          () => _plan([
            _operation(query: {
              name: ['secret'],
            }),
          ]),
          throwsFormatException,
        );
      }

      expect(
        () => PublicContractCapturePlan.fromJson(
          _planJson([
            {
              'id': 'scenario',
              'path': '/public/data',
              'query': {'page': '1'},
              'status': 200,
            },
          ]),
        ),
        throwsFormatException,
      );
      expect(
        () => _plan([
          _operation(query: const {'page': []}),
        ]),
        throwsFormatException,
      );
    });
  });

  group('PublicContractCapture', () {
    test('uses plan ids and order for same-path scenarios', () {
      final plan = _plan([
        _operation(
          id: 'users-rank-success',
          query: const {
            'handle': ['index'],
            'sort': ['rank'],
          },
        ),
        _operation(
          id: 'users-solved-success',
          query: const {
            'handle': ['index'],
            'sort': ['solved'],
          },
        ),
        _operation(
          id: 'users-missing',
          query: const {
            'handle': ['missing'],
            'sort': ['rank'],
          },
          status: 404,
        ),
      ]);
      final result = PublicContractCapture(plan).extract(
        _har([
          _entry(
            url: 'https://solved.ac/public/data?sort=rank&handle=missing',
            body: '{"error":"not-found"}',
            status: 404,
          ),
          _entry(
            url: 'https://solved.ac/public/data?sort=solved&handle=index',
            body: '{"sort":"solved"}',
          ),
          _entry(
            url: 'https://solved.ac/public/data?handle=index&sort=rank',
            body: '{"sort":"rank"}',
          ),
        ]),
      );

      expect(result.exchanges.map((exchange) => exchange.id), [
        'users-rank-success',
        'users-solved-success',
        'users-missing',
      ]);
      expect(result.exchanges.map((exchange) => exchange.responseJson), [
        {'sort': 'rank'},
        {'sort': 'solved'},
        {'error': 'not-found'},
      ]);
      expect(result.exchanges.first.queryParameters, {
        'handle': ['<redacted>'],
        'sort': ['<redacted>'],
      });
      final manifest = jsonEncode(result.toManifestJson());
      expect(manifest, isNot(contains('index')));
      final manifestJson = result.toManifestJson();
      final exchanges = manifestJson['exchanges']! as List<Object?>;
      for (final rawExchange in exchanges) {
        final exchange = rawExchange! as Map<String, Object?>;
        final request = exchange['request']! as Map<String, Object?>;
        final query = request['query']! as List<Object?>;
        for (final rawParameter in query) {
          final parameter = rawParameter! as Map<String, Object?>;
          expect(
            parameter['values'],
            everyElement(equals('<redacted>')),
          );
        }
      }
    });

    test('redacts direct and tuple-shaped sensitive response values', () {
      final result = PublicContractCapture(_plan([_operation()])).extract(
        _har([
          _entry(
            url: 'https://solved.ac/public/data',
            body: jsonEncode({
              'apiKey': 'secret-1',
              'private_key': 'secret-2',
              'csrfToken': 'secret-3',
              'authKey': 'secret-4',
              'accessKey': 'secret-5',
              'hmacKey': 'secret-6',
              'sessionid': 'secret-7',
              'csrftoken': 'secret-8',
              'authtoken': 'secret-9',
              'secretkey': 'secret-10',
              'passwordhash': 'secret-11',
              'oauthcode': 'secret-12',
              'code': 'NOT_FOUND',
              'errorCode': 'NOT_FOUND',
              'key': 'rating',
              'sortKey': 'rating',
              'author': 'public-author',
              'nested': [
                {'name': 'Authorization', 'value': 'Bearer secret-13'},
                {
                  'key': 'X-XSRF-Token',
                  'values': ['secret-14'],
                },
                {'name': 'rating', 'value': 2635},
                {'key': 'rating', 'value': 2635},
              ],
            }),
          ),
        ]),
      );

      expect(result.exchanges.single.responseJson, {
        'apiKey': '<redacted>',
        'private_key': '<redacted>',
        'csrfToken': '<redacted>',
        'authKey': '<redacted>',
        'accessKey': '<redacted>',
        'hmacKey': '<redacted>',
        'sessionid': '<redacted>',
        'csrftoken': '<redacted>',
        'authtoken': '<redacted>',
        'secretkey': '<redacted>',
        'passwordhash': '<redacted>',
        'oauthcode': '<redacted>',
        'code': 'NOT_FOUND',
        'errorCode': 'NOT_FOUND',
        'key': 'rating',
        'sortKey': 'rating',
        'author': 'public-author',
        'nested': [
          {'name': 'Authorization', 'value': '<redacted>'},
          {'key': 'X-XSRF-Token', 'values': '<redacted>'},
          {'name': 'rating', 'value': 2635},
          {'key': 'rating', 'value': 2635},
        ],
      });
      final encoded = jsonEncode(result.exchanges.single.responseJson);
      for (var index = 1; index <= 14; index++) {
        expect(encoded, isNot(contains('secret-$index')));
      }
    });

    test('decodes base64 JSON responses', () {
      final encoded = base64Encode(utf8.encode('[{"ok":true}]'));
      final result = PublicContractCapture(_plan([_operation()])).extract(
        _har([
          _entry(
            url: 'https://solved.ac/public/data',
            body: encoded,
            encoding: 'base64',
          ),
        ]),
      );

      expect(result.exchanges.single.responseJson, [
        {'ok': true},
      ]);
    });

    test('requires every selector exactly once', () {
      final capture = PublicContractCapture(_plan([_operation()]));
      expect(
        () => capture.extract(_har([])),
        throwsStateError,
      );
      expect(
        () => capture.extract(
          _har([
            _entry(url: 'https://solved.ac/public/data', body: '{}'),
            _entry(url: 'https://solved.ac/public/data', body: '{}'),
          ]),
        ),
        throwsStateError,
      );
    });

    test('matches repeated query values in exact order', () {
      final capture = PublicContractCapture(
        _plan([
          _operation(query: const {
            'tag': ['dp', 'math'],
          }),
        ]),
      );

      expect(
        () => capture.extract(
          _har([
            _entry(
              url: 'https://solved.ac/public/data?tag=math&tag=dp',
              body: '{}',
            ),
          ]),
        ),
        throwsStateError,
      );
    });

    test('ignores unplanned bodies and records only deterministic exchanges',
        () {
      final result = PublicContractCapture(_plan([_operation()])).extract(
        _har([
          {
            'request': {
              'method': 'GET',
              'url': 'https://solved.ac/private/data',
            },
            'response': {
              'status': 200,
              'content': {'text': 'not json: secret-do-not-read'},
            },
          },
          _entry(url: 'https://solved.ac/public/data', body: '{"ok":true}'),
        ]),
      );

      expect(result.exchanges, hasLength(1));
      expect(result.skipped, {CaptureSkipReason.unplannedRequest: 1});
      expect(
        jsonEncode(result.toManifestJson()),
        isNot(contains('secret-do-not-read')),
      );
      expect(result.toManifestJson(), isNot(containsPair('skipped', anything)));
    });

    test('skips wrong methods and origins without treating them as evidence',
        () {
      final result = PublicContractCapture(_plan([_operation()])).extract(
        _har([
          _entry(
            url: 'https://solved.ac/public/data',
            body: '{}',
            method: 'POST',
          ),
          _entry(url: 'http://solved.ac/public/data', body: '{}'),
          _entry(url: 'https://example.com/public/data', body: '{}'),
          _entry(url: 'https://solved.ac:8443/public/data', body: '{}'),
          _entry(url: 'https://user@solved.ac/public/data', body: '{}'),
          _entry(url: 'https://solved.ac/public/data#fragment', body: '{}'),
          _entry(url: 'https://solved.ac/public/data', body: '{"ok":true}'),
        ]),
      );

      expect(result.exchanges, hasLength(1));
      expect(result.skipped, {
        CaptureSkipReason.unsupportedMethod: 1,
        CaptureSkipReason.unsupportedOrigin: 5,
      });
    });

    test('accepts innocuous request metadata', () {
      final result = PublicContractCapture(_plan([_operation()])).extract(
        _har([
          _entry(
            url: 'https://solved.ac/public/data',
            body: '{}',
            headers: const [
              {'name': 'Accept', 'value': 'application/json'},
              {'name': 'Host', 'value': 'solved.ac:443'},
              {'name': 'User-Agent', 'value': 'Browser'},
            ],
          ),
        ]),
      );

      expect(result.exchanges, hasLength(1));
    });

    for (final headerName in [
      'Authorization',
      'Proxy-Authorization',
      'Cookie',
      'X-API-Key',
      'Api_Key',
      'X-Auth-Key',
      'X-Access-Key',
      'X-HMAC',
      'Key',
      'X-Sig',
      'X-CSRF-Token',
      'X-Solvedac-Token',
      'Session-Id',
      'Credential',
      'X-Custom-Metadata',
      'Content-Length',
      'Content-Type',
      'Host',
    ]) {
      test('rejects planned request header $headerName', () {
        final entry = _entry(
          url: 'https://solved.ac/public/data',
          body: '{}',
          headers: [
            {'name': headerName, 'value': 'secret'},
          ],
        );
        expect(
          () => PublicContractCapture(_plan([_operation()])).extract(
            _har([entry]),
          ),
          throwsStateError,
        );
      });
    }

    test('rejects cookies and any postData field for planned requests', () {
      final cookieEntry = _entry(
        url: 'https://solved.ac/public/data',
        body: '{}',
        cookies: const [
          {'name': 'theme', 'value': 'dark'},
        ],
      );
      final postDataEntry = _entry(
        url: 'https://solved.ac/public/data',
        body: '{}',
      );
      _request(postDataEntry)['postData'] = null;

      final capture = PublicContractCapture(_plan([_operation()]));
      expect(() => capture.extract(_har([cookieEntry])), throwsStateError);
      expect(() => capture.extract(_har([postDataEntry])), throwsStateError);
    });

    test('fails closed on missing or malformed headers and cookies', () {
      final mutations = <void Function(Map<String, Object?>)>[
        (request) => request.remove('headers'),
        (request) => request['headers'] = null,
        (request) => request['headers'] = {'name': 'Accept', 'value': '*/*'},
        (request) => request['headers'] = [42],
        (request) => request['headers'] = [
              {'name': 'Accept'},
            ],
        (request) => request.remove('cookies'),
        (request) => request['cookies'] = null,
        (request) => request['cookies'] = {},
        (request) => request['cookies'] = [42],
        (request) => request['cookies'] = [
              {'name': 'theme'},
            ],
      ];

      for (final mutate in mutations) {
        final entry = _entry(
          url: 'https://solved.ac/public/data',
          body: '{}',
        );
        mutate(_request(entry));
        expect(
          () => PublicContractCapture(_plan([_operation()])).extract(
            _har([entry]),
          ),
          throwsFormatException,
        );
      }
    });

    test('fails closed on missing, malformed, or inconsistent query metadata',
        () {
      final entries = [
        _entry(
          url: 'https://solved.ac/public/data?page=1',
          body: '{}',
        ),
        _entry(
          url: 'https://solved.ac/public/data?page=1',
          body: '{}',
        ),
        _entry(
          url: 'https://solved.ac/public/data?page=1',
          body: '{}',
        ),
      ];
      _request(entries[0]).remove('queryString');
      _request(entries[1])['queryString'] = [42];
      _request(entries[2])['queryString'] = [
        {'name': 'page', 'value': '2'},
      ];
      final capture = PublicContractCapture(
        _plan([
          _operation(query: const {
            'page': ['1'],
          }),
        ]),
      );

      for (final entry in entries) {
        expect(() => capture.extract(_har([entry])), throwsFormatException);
      }
    });

    test('rejects invalid response bodies and encodings', () {
      final invalidEntries = [
        _entry(url: 'https://solved.ac/public/data', body: null),
        _entry(url: 'https://solved.ac/public/data', body: ''),
        _entry(url: 'https://solved.ac/public/data', body: 'not json'),
        _entry(
          url: 'https://solved.ac/public/data',
          body: 'not base64',
          encoding: 'base64',
        ),
        _entry(
          url: 'https://solved.ac/public/data',
          body: '{}',
          encoding: 'binary',
        ),
      ];
      final capture = PublicContractCapture(_plan([_operation()]));

      for (final entry in invalidEntries) {
        expect(() => capture.extract(_har([entry])), throwsFormatException);
      }
    });

    test('rejects malformed HAR roots', () {
      expect(
        () => PublicContractCapture(_plan([_operation()])).extract(
          {'log': {}},
        ),
        throwsFormatException,
      );
    });
  });

  group('writeCapture', () {
    late Directory temporaryDirectory;
    late PublicContractCaptureResult capture;

    setUp(() {
      temporaryDirectory = Directory.systemTemp.createTempSync(
        'solved-contract-capture-',
      );
      capture = PublicContractCapture(_plan([_operation()])).extract(
        _har([
          _entry(
            url: 'https://solved.ac/public/data',
            body: '{"handle":"index"}',
          ),
        ]),
      );
    });

    tearDown(() {
      temporaryDirectory.deleteSync(recursive: true);
    });

    test('atomically writes only the manifest and planned fixtures', () {
      final output = Directory('${temporaryDirectory.path}/capture');

      writeCapture(capture, output);

      expect(
        output.listSync().map((entity) => entity.uri.pathSegments.last).toSet(),
        {'manifest.json', 'scenario.response.json'},
      );
      final manifest =
          jsonDecode(File('${output.path}/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(manifest['schemaVersion'], 1);
      expect(manifest['source'], 'sanitized-public-har');
      expect(manifest['host'], 'solved.ac');
      expect(manifest['exchanges'], hasLength(1));
      expect(manifest, isNot(containsPair('skipped', anything)));
      expect(
        File('${output.path}/scenario.response.json').readAsStringSync(),
        '{\n  "handle": "index"\n}\n',
      );
      expect(
        temporaryDirectory
            .listSync()
            .where((entity) => entity.path.contains('.capture.capture-')),
        isEmpty,
      );
    });

    test('rejects an existing empty or stale output directory', () {
      final empty = Directory('${temporaryDirectory.path}/empty')..createSync();
      final stale = Directory('${temporaryDirectory.path}/stale')..createSync();
      File('${stale.path}/old.response.json').writeAsStringSync('{}');

      expect(() => writeCapture(capture, empty), throwsStateError);
      expect(() => writeCapture(capture, stale), throwsStateError);
      expect(File('${stale.path}/old.response.json').existsSync(), isTrue);
    });

    test('rejects existing files and links as output', () {
      final file = File('${temporaryDirectory.path}/file')
        ..writeAsStringSync('x');
      final target = Directory('${temporaryDirectory.path}/target')
        ..createSync();
      final link = Link('${temporaryDirectory.path}/link')
        ..createSync(target.path);
      final broken = Link('${temporaryDirectory.path}/broken')
        ..createSync('${temporaryDirectory.path}/missing');

      expect(
          () => writeCapture(capture, Directory(file.path)), throwsStateError);
      expect(
          () => writeCapture(capture, Directory(link.path)), throwsStateError);
      expect(
        () => writeCapture(capture, Directory(broken.path)),
        throwsStateError,
      );
    });
  });

  group('capture CLI', () {
    late Directory temporaryDirectory;

    setUp(() {
      temporaryDirectory = Directory.systemTemp.createTempSync(
        'solved-contract-cli-',
      );
    });

    tearDown(() {
      temporaryDirectory.deleteSync(recursive: true);
    });

    test('writes a plan-named sanitized capture', () async {
      final input = File('${temporaryDirectory.path}/public.har')
        ..writeAsStringSync(
          jsonEncode(
            _har([
              _entry(
                url: 'https://solved.ac/public/data?handle=index',
                body: '{"handle":"index","token":"secret"}',
              ),
            ]),
          ),
        );
      final plan = File('${temporaryDirectory.path}/plan.json')
        ..writeAsStringSync(
          jsonEncode(
            _planJson([
              _operation(
                id: 'public-user-success',
                query: const {
                  'handle': ['index'],
                },
              ),
            ]),
          ),
        );
      final output = Directory('${temporaryDirectory.path}/capture');

      final process = await _runCli(
        input: input,
        plan: plan,
        output: output,
      );

      expect(process.exitCode, 0, reason: process.stderr.toString());
      expect(process.stdout, isNot(contains('handle=index')));
      expect(process.stdout, isNot(contains('secret')));
      expect(
        File('${output.path}/public-user-success.response.json')
            .readAsStringSync(),
        '{\n  "handle": "index",\n  "token": "<redacted>"\n}\n',
      );
      final manifest = File('${output.path}/manifest.json').readAsStringSync();
      expect(manifest, isNot(contains('index')));
      expect(manifest, isNot(contains('secret')));
    });

    test('requires a reviewed plan', () async {
      final input = File('${temporaryDirectory.path}/public.har')
        ..writeAsStringSync(jsonEncode(_har([])));
      final process = await Process.run(
        Platform.resolvedExecutable,
        [
          'run',
          'tool/capture_public_contract.dart',
          '--input',
          input.path,
          '--output',
          '${temporaryDirectory.path}/capture',
        ],
        workingDirectory: Directory.current.path,
      );

      expect(process.exitCode, 64);
      expect(process.stderr, contains('--plan'));
    });

    test('does not echo malformed HAR or plan contents', () async {
      final malformedHar = File('${temporaryDirectory.path}/malformed.har')
        ..writeAsStringSync('{"secret":"har-do-not-print",');
      final malformedPlan =
          File('${temporaryDirectory.path}/malformed-plan.json')
            ..writeAsStringSync('{"secret":"plan-do-not-print",');
      final validHar = File('${temporaryDirectory.path}/valid.har')
        ..writeAsStringSync(jsonEncode(_har([])));
      final validPlan = File('${temporaryDirectory.path}/valid-plan.json')
        ..writeAsStringSync(jsonEncode(_planJson([_operation()])));

      final harFailure = await _runCli(
        input: malformedHar,
        plan: validPlan,
        output: Directory('${temporaryDirectory.path}/har-output'),
      );
      final planFailure = await _runCli(
        input: validHar,
        plan: malformedPlan,
        output: Directory('${temporaryDirectory.path}/plan-output'),
      );

      for (final process in [harFailure, planFailure]) {
        expect(process.exitCode, 64);
        expect(process.stdout, isNot(contains('do-not-print')));
        expect(process.stderr, isNot(contains('do-not-print')));
      }
    });

    test('does not echo credentials from a rejected planned request', () async {
      final input = File('${temporaryDirectory.path}/credential.har')
        ..writeAsStringSync(
          jsonEncode(
            _har([
              _entry(
                url: 'https://solved.ac/public/data',
                body: '{}',
                headers: const [
                  {
                    'name': 'X-API-Key',
                    'value': 'credential-do-not-print',
                  },
                ],
              ),
            ]),
          ),
        );
      final plan = File('${temporaryDirectory.path}/plan.json')
        ..writeAsStringSync(jsonEncode(_planJson([_operation()])));

      final process = await _runCli(
        input: input,
        plan: plan,
        output: Directory('${temporaryDirectory.path}/capture'),
      );

      expect(process.exitCode, 64);
      expect(process.stdout, isNot(contains('credential-do-not-print')));
      expect(process.stderr, isNot(contains('credential-do-not-print')));
    });
  });
}

PublicContractCapturePlan _plan(List<Map<String, Object?>> operations) =>
    PublicContractCapturePlan.fromJson(_planJson(operations));

Map<String, Object?> _planJson(List<Map<String, Object?>> operations) => {
      'schemaVersion': 1,
      'host': 'solved.ac',
      'operations': operations,
    };

Map<String, Object?> _operation({
  String id = 'scenario',
  String path = '/public/data',
  Map<String, List<String>> query = const {},
  int status = 200,
}) =>
    {'id': id, 'path': path, 'query': query, 'status': status};

Map<String, Object?> _har(List<Object?> entries) => {
      'log': {'entries': entries},
    };

Map<String, Object?> _entry({
  required String url,
  required String? body,
  String method = 'GET',
  int status = 200,
  String? encoding,
  Object headers = const <Map<String, String>>[],
  Object cookies = const <Map<String, String>>[],
}) {
  final uri = Uri.parse(url);
  return {
    'request': <String, Object?>{
      'method': method,
      'url': url,
      'headers': headers,
      'cookies': cookies,
      'queryString': [
        for (final entry in uri.queryParametersAll.entries)
          for (final value in entry.value) {'name': entry.key, 'value': value},
      ],
    },
    'response': <String, Object?>{
      'status': status,
      'content': <String, Object?>{
        'text': body,
        if (encoding != null) 'encoding': encoding,
      },
    },
  };
}

Map<String, Object?> _request(Map<String, Object?> entry) =>
    entry['request']! as Map<String, Object?>;

Future<ProcessResult> _runCli({
  required File input,
  required File plan,
  required Directory output,
}) =>
    Process.run(
      Platform.resolvedExecutable,
      [
        'run',
        'tool/capture_public_contract.dart',
        '--input',
        input.path,
        '--plan',
        plan.path,
        '--output',
        output.path,
      ],
      workingDirectory: Directory.current.path,
    );
