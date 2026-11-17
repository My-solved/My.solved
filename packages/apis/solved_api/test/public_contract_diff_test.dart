import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/src/public_contract_diff.dart';

void main() {
  late Directory temporaryRoot;

  setUp(() {
    temporaryRoot = Directory.systemTemp.createTempSync('contract-diff-test-');
  });

  tearDown(() {
    if (temporaryRoot.existsSync()) {
      temporaryRoot.deleteSync(recursive: true);
    }
  });

  test(
    'reports deterministic request and response shape changes without values',
    () {
      final beforeDirectory = _writeCapture(temporaryRoot, 'before', [
        _exchange(
          id: 'user-show',
          path: '/api/v3/user/show',
          query: const {'handle': 1},
          response: {
            'handle': 'private-before-handle',
            'rating': 1234,
            'items': [
              {'id': 1, 'score': 100, 'nullable': null},
              {'id': 2, 'nullable': 'private-before-text'},
            ],
            'a/b': {'x~y': true},
            '*': 'private-star-value',
          },
        ),
        _exchange(
          id: 'same-shape',
          path: '/api/v3/same',
          response: {'value': 'private-old-value'},
        ),
        _exchange(
          id: 'removed-operation',
          path: '/api/v3/removed',
          response: {'legacy': true},
        ),
      ]);
      final afterDirectory = _writeCapture(temporaryRoot, 'after', [
        _exchange(
          id: 'added-operation',
          path: '/api/v4/added',
          response: {'new': true},
        ),
        _exchange(
          id: 'same-shape',
          path: '/api/v3/same',
          response: {'value': 'private-new-value'},
        ),
        _exchange(
          id: 'user-show',
          path: '/api/v4/user/show',
          query: const {'handle': 1},
          status: 201,
          response: {
            'handle': 'private-after-handle',
            'rating': '1234',
            'reputation': 900,
            'items': [
              {'id': 3, 'score': 200, 'helpful': true, 'nullable': null},
              {'id': 4, 'score': 300, 'helpful': false, 'nullable': null},
            ],
            'a/b': {'x~y': 1},
            '*': false,
          },
        ),
      ]);

      final diff = diffPublicContractCaptures(
        readPublicContractCapture(beforeDirectory),
        readPublicContractCapture(afterDirectory),
      );
      final json = diff.toJson();
      final summary = json['summary']! as Map<String, Object?>;
      final operations =
          (json['operations']! as List<Object?>).cast<Map<String, Object?>>();

      expect(summary, {
        'addedOperations': 1,
        'removedOperations': 1,
        'modifiedOperations': 1,
        'responsePathChanges': 11,
      });
      expect(operations.map((operation) => operation['id']), [
        'added-operation',
        'removed-operation',
        'user-show',
      ]);

      final userDiff = operations.singleWhere(
        (operation) => operation['id'] == 'user-show',
      );
      final request = userDiff['request']! as Map<String, Object?>;
      expect(request['changed'], isTrue);
      expect(
        (request['before']! as Map<String, Object?>)['path'],
        '/api/v3/user/show',
      );
      expect(
        (request['after']! as Map<String, Object?>)['path'],
        '/api/v4/user/show',
      );
      expect(
        ((request['after']! as Map<String, Object?>)['query']! as List<Object?>)
            .single,
        {'name': 'handle', 'valueCount': 1},
      );

      final response = userDiff['response']! as Map<String, Object?>;
      expect(response['status'], {
        'changed': true,
        'before': 200,
        'after': 201,
      });
      final changes =
          (response['changes']! as List<Object?>).cast<Map<String, Object?>>();
      final changesByPointer = {
        for (final change in changes) change['pointer']! as String: change,
      };
      expect(changesByPointer['/rating']!['change'], 'modified');
      expect(
        (changesByPointer['/rating']!['before']!
            as Map<String, Object?>)['types'],
        ['integer'],
      );
      expect(
        (changesByPointer['/rating']!['after']!
            as Map<String, Object?>)['types'],
        ['string'],
      );
      expect(changesByPointer['/reputation']!['change'], 'added');
      expect(changesByPointer['/items/*/helpful']!['change'], 'added');
      expect(
        (changesByPointer['/items/*/score']!['before']!
            as Map<String, Object?>)['presence'],
        'optional',
      );
      expect(
        (changesByPointer['/items/*/score']!['after']!
            as Map<String, Object?>)['presence'],
        'required',
      );
      expect(changesByPointer['/a~1b/x~0y']!['change'], 'modified');
      expect(changesByPointer['/~2']!['change'], 'modified');

      final encoded = prettyPublicContractDiff(diff);
      for (final privateValue in [
        'private-before-handle',
        'private-after-handle',
        'private-before-text',
        'private-star-value',
        'private-old-value',
        'private-new-value',
        '<redacted>',
        beforeDirectory.path,
        afterDirectory.path,
      ]) {
        expect(encoded, isNot(contains(privateValue)));
      }
    },
  );

  test('ignores response values and required array sample counts', () {
    final before = _writeCapture(temporaryRoot, 'before', [
      _exchange(
        response: {
          'items': [
            {'id': 1, 'name': 'private-a'},
          ],
        },
      ),
    ]);
    final after = _writeCapture(temporaryRoot, 'after', [
      _exchange(
        response: {
          'items': [
            {'id': 2, 'name': 'private-b'},
            {'id': 3, 'name': 'private-c'},
            {'id': 4, 'name': 'private-d'},
          ],
        },
      ),
    ]);

    final diff = diffPublicContractCaptures(
      readPublicContractCapture(before),
      readPublicContractCapture(after),
    );

    expect(diff.operations, isEmpty);
  });

  test('reports a response status change separately from the request', () {
    final before = _writeCapture(
      temporaryRoot,
      'before',
      [_exchange(status: 200)],
    );
    final after = _writeCapture(
      temporaryRoot,
      'after',
      [_exchange(status: 404)],
    );

    final operation = (diffPublicContractCaptures(
      readPublicContractCapture(before),
      readPublicContractCapture(after),
    ).toJson()['operations']! as List<Object?>)
        .single as Map<String, Object?>;
    final request = operation['request']! as Map<String, Object?>;
    final response = operation['response']! as Map<String, Object?>;

    expect(request['changed'], isFalse);
    expect(response['status'], {
      'changed': true,
      'before': 200,
      'after': 404,
    });
    expect(response['changes'], isEmpty);
  });

  test('normalizes heterogeneous array items and observes empty arrays safely',
      () {
    final before = _writeCapture(
      temporaryRoot,
      'before',
      [
        _exchange(
          response: {
            'items': [1, 'private-before', null, <String, Object?>{}],
            'empty': <Object?>[],
          },
        ),
      ],
    );
    final after = _writeCapture(
      temporaryRoot,
      'after',
      [
        _exchange(
          response: {
            'items': [1.5, 'private-after', null, <String, Object?>{}],
            'empty': <Object?>[],
          },
        ),
      ],
    );

    final operation = diffPublicContractCaptures(
      readPublicContractCapture(before),
      readPublicContractCapture(after),
    ).operations.single;
    final changes = operation.responseChanges;

    expect(changes, hasLength(1));
    expect(changes.single.pointer, '/items/*');
    expect(changes.single.before!.types, [
      'object',
      'string',
      'integer',
      'null',
    ]);
    expect(changes.single.after!.types, [
      'object',
      'string',
      'number',
      'null',
    ]);
    expect(
        prettyPublicContractDiff(
          diffPublicContractCaptures(
            readPublicContractCapture(before),
            readPublicContractCapture(after),
          ),
        ),
        isNot(contains('private-')));
  });

  test('reports nonempty and empty array transitions at the wildcard only', () {
    final nonempty = _writeCapture(
      temporaryRoot,
      'nonempty',
      [
        _exchange(
          response: {
            'items': [
              {
                'id': 1,
                'nested': {'value': true},
              },
            ],
          },
        ),
      ],
    );
    final empty = _writeCapture(
      temporaryRoot,
      'empty',
      [
        _exchange(response: {'items': <Object?>[]}),
      ],
    );

    final removedObservation = _responseChanges(nonempty, empty);
    final addedObservation = _responseChanges(empty, nonempty);

    for (final changes in [removedObservation, addedObservation]) {
      expect(changes, hasLength(1));
      expect(changes.single.pointer, '/items/*');
      expect(changes.single.change, 'modified');
    }
    expect(removedObservation.single.before!.types, ['object']);
    expect(removedObservation.single.before!.presence, 'required');
    expect(removedObservation.single.after!.types, isEmpty);
    expect(removedObservation.single.after!.presence, 'unobserved');
    expect(addedObservation.single.before!.types, isEmpty);
    expect(addedObservation.single.before!.presence, 'unobserved');
    expect(addedObservation.single.after!.types, ['object']);
    expect(addedObservation.single.after!.presence, 'required');
  });

  test('treats two empty array samples as the same observation', () {
    final before = _writeCapture(
      temporaryRoot,
      'before',
      [
        _exchange(response: {'items': <Object?>[]}),
      ],
    );
    final after = _writeCapture(
      temporaryRoot,
      'after',
      [
        _exchange(response: {'items': <Object?>[]}),
      ],
    );
    final beforeSnapshot = readPublicContractCapture(before);
    final emptyWildcard =
        beforeSnapshot.exchanges['scenario']!.responseSchema['/items/*']!;

    expect(emptyWildcard.types, isEmpty);
    expect(emptyWildcard.presence, 'unobserved');
    expect(
      diffPublicContractCaptures(
        beforeSnapshot,
        readPublicContractCapture(after),
      ).operations,
      isEmpty,
    );
  });

  test('uses the nearest unobserved wildcard for nested arrays', () {
    final allEmpty = _writeCapture(
      temporaryRoot,
      'all-empty',
      [
        _exchange(
          response: {
            'groups': [<Object?>[], <Object?>[]],
          },
        ),
      ],
    );
    final nestedItems = _writeCapture(
      temporaryRoot,
      'nested-items',
      [
        _exchange(
          response: {
            'groups': [
              [
                {
                  'id': 1,
                  'meta': {'score': 100},
                },
              ],
              <Object?>[],
            ],
          },
        ),
      ],
    );

    final changes = _responseChanges(allEmpty, nestedItems);

    expect(changes, hasLength(1));
    expect(changes.single.pointer, '/groups/*/*');
    expect(changes.single.before!.presence, 'unobserved');
    expect(changes.single.after!.types, ['object']);
  });

  test('suppresses every nested descendant below an empty root array', () {
    final emptyRoot = _writeCapture(
      temporaryRoot,
      'empty-root',
      [_exchange(response: <Object?>[])],
    );
    final nestedItems = _writeCapture(
      temporaryRoot,
      'nested-root-items',
      [
        _exchange(
          response: [
            [
              {'id': 1},
            ],
          ],
        ),
      ],
    );

    final changes = _responseChanges(emptyRoot, nestedItems);

    expect(changes, hasLength(1));
    expect(changes.single.pointer, '/*');
    expect(changes.single.before!.presence, 'unobserved');
    expect(changes.single.after!.types, ['array']);
  });

  test('CLI emits JSON without response values or local paths', () async {
    final before = _writeCapture(
      temporaryRoot,
      'before',
      [
        _exchange(
          response: {'rating': 1000, 'handle': 'cli-private-before'},
        ),
      ],
    );
    final after = _writeCapture(
      temporaryRoot,
      'after',
      [
        _exchange(
          path: '/api/v4/public',
          response: {
            'rating': '1000',
            'handle': 'cli-private-after',
          },
        ),
      ],
    );

    final process = await _runCli(before: before, after: after);

    expect(process.exitCode, 0, reason: process.stderr.toString());
    final output = process.stdout.toString();
    expect(jsonDecode(output), isA<Map<String, Object?>>());
    for (final privateValue in [
      'cli-private-before',
      'cli-private-after',
      before.path,
      after.path,
    ]) {
      expect(output, isNot(contains(privateValue)));
    }
  });

  test('CLI fails without echoing malformed capture contents', () async {
    final before = _writeCapture(
      temporaryRoot,
      'before',
      [_exchange()],
    );
    final after = _writeCapture(
      temporaryRoot,
      'after',
      [_exchange()],
    );
    File('${after.path}/manifest.json').writeAsStringSync(
      '{"secret":"cli-do-not-print",',
    );

    final process = await _runCli(before: before, after: after);

    expect(process.exitCode, 64);
    expect(process.stdout, isNot(contains('cli-do-not-print')));
    expect(process.stderr, isNot(contains('cli-do-not-print')));
  });

  test('CLI rejects duplicate options', () async {
    final before = _writeCapture(
      temporaryRoot,
      'before',
      [_exchange()],
    );
    final after = _writeCapture(
      temporaryRoot,
      'after',
      [_exchange()],
    );

    final process = await Process.run(
      Platform.resolvedExecutable,
      [
        'run',
        'tool/diff_public_contract.dart',
        '--before',
        before.path,
        '--before',
        before.path,
        '--after',
        after.path,
      ],
      workingDirectory: Directory.current.path,
    );

    expect(process.exitCode, 64);
  });

  group('strict capture loading', () {
    test('rejects unknown manifest fields and duplicate ids', () {
      final unknown = _writeCapture(
        temporaryRoot,
        'unknown',
        [_exchange()],
        mutateManifest: (manifest) => {...manifest, 'unknown': true},
      );
      final duplicate = _writeCapture(temporaryRoot, 'duplicate', [
        _exchange(),
        _exchange(),
      ]);

      expect(() => readPublicContractCapture(unknown), throwsFormatException);
      expect(() => readPublicContractCapture(duplicate), throwsFormatException);
    });

    test('rejects fixture traversal and unredacted query values', () {
      final traversal = _writeCapture(
        temporaryRoot,
        'traversal',
        [_exchange()],
        mutateManifest: (manifest) {
          final exchange = _firstExchange(manifest);
          final response = exchange['response']! as Map<String, Object?>;
          response['fixture'] = '../outside.json';
          return manifest;
        },
      );
      final unredacted = _writeCapture(
        temporaryRoot,
        'unredacted',
        [
          _exchange(query: const {'handle': 1}),
        ],
        mutateManifest: (manifest) {
          final exchange = _firstExchange(manifest);
          final request = exchange['request']! as Map<String, Object?>;
          final query = (request['query']! as List<Object?>).single
              as Map<String, Object?>;
          query['values'] = ['private-handle'];
          return manifest;
        },
      );
      final credentialNames = _writeCapture(
        temporaryRoot,
        'credential-names',
        [
          _exchange(
            path: '/api/token/show',
            query: const {'token': 1},
          ),
        ],
      );

      expect(() => readPublicContractCapture(traversal), throwsFormatException);
      expect(
        () => readPublicContractCapture(unredacted),
        throwsFormatException,
      );
      expect(
        () => readPublicContractCapture(credentialNames),
        throwsFormatException,
      );
    });

    test('rejects duplicate or unsorted query names', () {
      final duplicateQuery = _writeCapture(
        temporaryRoot,
        'duplicate-query',
        [
          _exchange(query: const {'handle': 1}),
        ],
        mutateManifest: (manifest) {
          final request =
              _firstExchange(manifest)['request']! as Map<String, Object?>;
          request['query'] = [
            {
              'name': 'handle',
              'values': ['<redacted>'],
            },
            {
              'name': 'handle',
              'values': ['<redacted>'],
            },
          ];
          return manifest;
        },
      );
      final unsortedQuery = _writeCapture(
        temporaryRoot,
        'unsorted-query',
        [
          _exchange(query: const {'a': 1, 'z': 1}),
        ],
        mutateManifest: (manifest) {
          final request =
              _firstExchange(manifest)['request']! as Map<String, Object?>;
          request['query'] =
              (request['query']! as List<Object?>).reversed.toList();
          return manifest;
        },
      );

      expect(
        () => readPublicContractCapture(duplicateQuery),
        throwsFormatException,
      );
      expect(
        () => readPublicContractCapture(unsortedQuery),
        throwsFormatException,
      );
    });

    test('rejects response type mismatch and malformed JSON', () {
      final mismatch = _writeCapture(
        temporaryRoot,
        'mismatch',
        [
          _exchange(response: {'value': true}),
        ],
        mutateManifest: (manifest) {
          final response =
              _firstExchange(manifest)['response']! as Map<String, Object?>;
          response['topLevelType'] = 'array';
          return manifest;
        },
      );
      final malformed = _writeCapture(temporaryRoot, 'malformed', [
        _exchange(),
      ]);
      File('${malformed.path}/scenario.response.json').writeAsStringSync('{');

      expect(() => readPublicContractCapture(mismatch), throwsFormatException);
      expect(() => readPublicContractCapture(malformed), throwsFormatException);
    });

    test('rejects extra files and fixture symlinks', () {
      final extra = _writeCapture(temporaryRoot, 'extra', [_exchange()]);
      File('${extra.path}/raw.har').writeAsStringSync('private');

      final linked = _writeCapture(temporaryRoot, 'linked', [_exchange()]);
      final fixture = File('${linked.path}/scenario.response.json');
      final outside = File('${temporaryRoot.path}/outside.json')
        ..writeAsStringSync('{}');
      fixture.deleteSync();
      Link(fixture.path).createSync(outside.path);

      expect(() => readPublicContractCapture(extra), throwsFormatException);
      expect(() => readPublicContractCapture(linked), throwsFormatException);
    });

    test('rejects capture directory and manifest symlinks', () {
      final target = _writeCapture(
        temporaryRoot,
        'target',
        [_exchange()],
      );
      final directoryLink = Link('${temporaryRoot.path}/directory-link')
        ..createSync(target.path);

      final linkedManifest = _writeCapture(
        temporaryRoot,
        'linked-manifest',
        [_exchange()],
      );
      final manifest = File('${linkedManifest.path}/manifest.json');
      final manifestTarget = File('${temporaryRoot.path}/manifest-target.json');
      manifest.renameSync(manifestTarget.path);
      Link(manifest.path).createSync(manifestTarget.path);

      expect(
        () => readPublicContractCapture(Directory(directoryLink.path)),
        throwsFormatException,
      );
      expect(
        () => readPublicContractCapture(linkedManifest),
        throwsFormatException,
      );
    });
  });
}

class _ExchangeInput {
  const _ExchangeInput({
    required this.id,
    required this.path,
    required this.query,
    required this.status,
    required this.response,
  });

  final String id;
  final String path;
  final Map<String, int> query;
  final int status;
  final Object? response;
}

_ExchangeInput _exchange({
  String id = 'scenario',
  String path = '/api/v3/public',
  Map<String, int> query = const {},
  int status = 200,
  Object? response = const {'ok': true},
}) =>
    _ExchangeInput(
      id: id,
      path: path,
      query: query,
      status: status,
      response: response,
    );

Directory _writeCapture(
  Directory root,
  String name,
  List<_ExchangeInput> inputs, {
  Map<String, Object?> Function(Map<String, Object?> manifest)? mutateManifest,
}) {
  final directory = Directory('${root.path}/$name')..createSync();
  final exchanges = <Map<String, Object?>>[];
  for (final input in inputs) {
    final fixtureName = '${input.id}.response.json';
    File(
      '${directory.path}/$fixtureName',
    ).writeAsStringSync(jsonEncode(input.response));
    final queryNames = input.query.keys.toList()..sort();
    exchanges.add({
      'id': input.id,
      'request': {
        'method': 'GET',
        'scheme': 'https',
        'host': 'solved.ac',
        'path': input.path,
        'query': [
          for (final queryName in queryNames)
            {
              'name': queryName,
              'values': List.filled(input.query[queryName]!, '<redacted>'),
            },
        ],
      },
      'response': {
        'status': input.status,
        'fixture': fixtureName,
        'topLevelType': switch (input.response) {
          Map() => 'object',
          List() => 'array',
          _ => 'scalar',
        },
      },
    });
  }

  var manifest = <String, Object?>{
    'schemaVersion': 1,
    'source': 'sanitized-public-har',
    'host': 'solved.ac',
    'exchanges': exchanges,
  };
  manifest = mutateManifest?.call(manifest) ?? manifest;
  File(
    '${directory.path}/manifest.json',
  ).writeAsStringSync(jsonEncode(manifest));
  return directory;
}

Map<String, Object?> _firstExchange(Map<String, Object?> manifest) =>
    (manifest['exchanges']! as List<Object?>).first as Map<String, Object?>;

Future<ProcessResult> _runCli({
  required Directory before,
  required Directory after,
}) =>
    Process.run(
      Platform.resolvedExecutable,
      [
        'run',
        'tool/diff_public_contract.dart',
        '--before',
        before.path,
        '--after',
        after.path,
      ],
      workingDirectory: Directory.current.path,
    );

List<PublicContractResponsePathDiff> _responseChanges(
  Directory before,
  Directory after,
) =>
    diffPublicContractCaptures(
      readPublicContractCapture(before),
      readPublicContractCapture(after),
    ).operations.single.responseChanges;
