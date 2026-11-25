import 'dart:convert';

import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

void main() {
  late SolvedApiV4Contract contract;

  setUp(() {
    contract = SolvedApiV4Contract(
      proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
    );
  });

  test('builds the public random-problem endpoint and preserves q', () {
    final omitted = contract.randomProblem();
    final empty = contract.randomProblem(query: '');
    final explicit = contract.randomProblem(query: 'A B&한');

    expect(omitted.direct.path, 'search/random-problem');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(empty.direct.queryParameters, {'q': ''});
    expect(explicit.direct.queryParameters, {'q': 'A B&한'});
    expect(explicit.proxy.queryParameters, explicit.direct.queryParameters);
  });

  test('validates q by Unicode code points with no minimum', () {
    final zero = contract.randomProblem(query: '');
    final boundary = List.filled(1000, '🧩').join();
    final over = '$boundary🧩';

    expect(zero.direct.queryParameters, {'q': ''});
    expect(contract.randomProblem(query: boundary).direct.queryParameters, {
      'q': boundary,
    });
    expect(
      () => contract.randomProblem(query: over),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'query')
            .having((error) => error.invalidValue, 'invalidValue', over),
      ),
    );
  });

  test('decodes the complete official random-problem fixture', () {
    final actual = contract.randomProblem().decode(
          jsonDecode(fixture('v4/random_problem.json')),
        );

    expect(actual, isA<RandomProblemResult>());
    expect(actual, isNot(isA<ProblemSearchItem>()));
    expect(actual.id, 42.0);
    expect(actual.id, isA<double>());
    expect(actual.problemId, 1000.5);
    expect(actual.problemId, isA<double>());
    expect(actual.subId, 'raw-sub');
    expect(actual.level, 12.5);
    expect(actual.level, isA<double>());
    expect(actual.levelAverage, -3);
    expect(actual.levelAverage, isA<int>());
    expect(actual.levelStdev, 0.0);
    expect(actual.levelStdev, isA<double>());
    expect(actual.isStandard, isTrue);
    expect(actual.votedUserCount, -6.5);
    expect(actual.votedUserCount, isA<double>());
    expect(actual.effectiveVoteCount, 7.0);
    expect(actual.effectiveVoteCount, isA<double>());
    expect(actual.solvedUserCount, 8);
    expect(actual.solvedUserCount, isA<int>());
    expect(actual.givesNoRating, isFalse);
    expect(actual.noRatingReasons, [
      ProblemNoRatingReason.unofficial,
      ProblemNoRatingReason.staff,
    ]);
    expect(actual.noRatingWarnings.map((warning) => warning.type), [
      ProblemNoRatingWarningType.same,
      ProblemNoRatingWarningType.wrongStatement,
    ]);
    expect(actual.noRatingWarnings.first.problem?.problemId, 1001.5);
    expect(
      actual.noRatingWarnings.first.problem?.userStatus,
      ProblemUserStatus.partial,
    );
    expect(actual.noRatingWarnings.last.problem, isNull);
    expect(actual.titles.map((title) => title.language), ['ko', 'en']);
    expect(actual.titles.last.latex, isTrue);
    expect(actual.titles.last.html, isTrue);
    expect(actual.userStatus, isNull);
    expect(actual.contests.single.id, 3.5);
    expect(actual.contests.single.abbreviation, isNull);
    expect(actual.tags.map((tag) => tag.id), [1.5, 2]);
    expect(actual.tags.last.isMeta, isTrue);
    expect(actual.viewerFolders.map((folder) => folder.slug), [
      'raw-folder',
      'red-folder',
    ]);
    expect(actual.viewerFolders.first.color, isNull);
    expect(actual.viewerFolders.last.color, ProblemSearchViewerFolderColor.red);
  });

  test('requires every top-level random-problem field', () {
    final endpoint = contract.randomProblem();
    for (final invalid in <Object?>[
      null,
      0,
      false,
      'problem',
      const <Object?>[],
    ]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in _topLevelFields) {
      expect(
        () => endpoint.decode(_source()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }
  });

  test('preserves finite raw response numbers and rejects non-numbers', () {
    final endpoint = contract.randomProblem();
    const numberFields = [
      'id',
      'problemId',
      'level',
      'levelAverage',
      'levelStdev',
      'votedUserCount',
      'effectiveVoteCount',
      'solvedUserCount',
    ];
    for (final field in numberFields) {
      for (final invalid in <Object?>[
        null,
        '1',
        false,
        const <Object?>[],
        const <String, Object?>{},
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => endpoint.decode(_source()..[field] = invalid),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }

    num decodedNumber(RandomProblemResult result, String field) =>
        switch (field) {
          'id' => result.id,
          'problemId' => result.problemId,
          'level' => result.level,
          'levelAverage' => result.levelAverage,
          'levelStdev' => result.levelStdev,
          'votedUserCount' => result.votedUserCount,
          'effectiveVoteCount' => result.effectiveVoteCount,
          'solvedUserCount' => result.solvedUserCount,
          _ => throw StateError('Unexpected number field: $field'),
        };

    const values = <num>[-17, 18.0, -19.25];
    for (final field in numberFields) {
      for (final value in values) {
        final actual = endpoint.decode(_source()..[field] = value);
        final decoded = decodedNumber(actual, field);
        expect(decoded, value, reason: '$field preserves $value');
        expect(
          decoded,
          value is int ? isA<int>() : isA<double>(),
          reason: '$field preserves ${value.runtimeType}',
        );
      }
    }
  });

  test('preserves every nested raw-number value and runtime type', () {
    final endpoint = contract.randomProblem();
    const values = <num>[20, 21.0, -22.5];

    for (final field in ['problemId', 'level', 'effectiveVoteCount']) {
      for (final value in values) {
        final warningProblem = _warningProblem()..[field] = value;
        final actual = endpoint.decode(
          _source()
            ..['noRatingWarnings'] = <Object?>[
              _warning(problem: warningProblem),
            ],
        );
        final related = actual.noRatingWarnings.single.problem!;
        final decoded = switch (field) {
          'problemId' => related.problemId,
          'level' => related.level,
          'effectiveVoteCount' => related.effectiveVoteCount,
          _ => throw StateError('Unexpected warning number field: $field'),
        };
        expect(decoded, value, reason: 'warning problem $field = $value');
        expect(
          decoded,
          value is int ? isA<int>() : isA<double>(),
          reason: 'warning problem $field preserves ${value.runtimeType}',
        );
      }
    }

    for (final value in values) {
      final contest = endpoint
          .decode(
            _source()..['contests'] = <Object?>[_contest()..['id'] = value],
          )
          .contests
          .single
          .id;
      expect(contest, value, reason: 'contest id = $value');
      expect(
        contest,
        value is int ? isA<int>() : isA<double>(),
        reason: 'contest id preserves ${value.runtimeType}',
      );

      final tag = endpoint
          .decode(
            _source()..['tags'] = <Object?>[_tag()..['id'] = value],
          )
          .tags
          .single
          .id;
      expect(tag, value, reason: 'tag id = $value');
      expect(
        tag,
        value is int ? isA<int>() : isA<double>(),
        reason: 'tag id preserves ${value.runtimeType}',
      );
    }
  });

  test('validates scalar and collection top-level types', () {
    final endpoint = contract.randomProblem();
    final invalidValues = <String, List<Object?>>{
      'subId': [null, 1, false, const <Object?>[], const <String, Object?>{}],
      'isStandard': [null, 1, 'true', const <Object?>[]],
      'givesNoRating': [null, 1, 'false', const <String, Object?>{}],
      for (final field in [
        'noRatingReasons',
        'noRatingWarnings',
        'titles',
        'contests',
        'tags',
        'viewerFolders',
      ])
        field: [null, 0, false, field, const <String, Object?>{}],
    };
    for (final entry in invalidValues.entries) {
      for (final invalid in entry.value) {
        expect(
          () => endpoint.decode(_source()..[entry.key] = invalid),
          throwsFormatException,
          reason: '${entry.key} = $invalid',
        );
      }
    }
  });

  test('preserves every supported top-level user status and null', () {
    final endpoint = contract.randomProblem();
    const statuses = <Object?, ProblemUserStatus?>{
      'solved': ProblemUserStatus.solved,
      'partial': ProblemUserStatus.partial,
      'tried': ProblemUserStatus.tried,
      null: null,
    };
    for (final entry in statuses.entries) {
      final actual = endpoint.decode(_source()..['userStatus'] = entry.key);
      expect(actual.userStatus, entry.value);
    }
    for (final invalid in <Object?>['unknown', 1, false, const <Object?>[]]) {
      expect(
        () => endpoint.decode(_source()..['userStatus'] = invalid),
        throwsFormatException,
      );
    }
  });

  test('validates all no-rating values and nullable warning problems', () {
    final endpoint = contract.randomProblem();
    for (final reason in ProblemNoRatingReason.values) {
      final actual = endpoint.decode(
        _source()..['noRatingReasons'] = <Object?>[reason.value],
      );
      expect(actual.noRatingReasons.single, reason);
    }
    for (final warningType in ProblemNoRatingWarningType.values) {
      final actual = endpoint.decode(
        _source()
          ..['noRatingWarnings'] = <Object?>[
            _warning(type: warningType.value, problem: null),
          ],
      );
      expect(actual.noRatingWarnings.single.type, warningType);
      expect(actual.noRatingWarnings.single.problem, isNull);
    }
    for (final invalid in <Object?>['unknown', 1, false, null]) {
      expect(
        () => endpoint.decode(
          _source()..['noRatingReasons'] = <Object?>[invalid],
        ),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(
          _source()
            ..['noRatingWarnings'] = <Object?>[
              _warning(type: invalid, problem: null),
            ],
        ),
        throwsFormatException,
      );
    }
  });

  test('preserves six empty arrays as isolated unmodifiable lists', () {
    final reasons = <Object?>[];
    final warnings = <Object?>[];
    final titles = <Object?>[];
    final contests = <Object?>[];
    final tags = <Object?>[];
    final viewerFolders = <Object?>[];
    final source = _source()
      ..['noRatingReasons'] = reasons
      ..['noRatingWarnings'] = warnings
      ..['titles'] = titles
      ..['contests'] = contests
      ..['tags'] = tags
      ..['viewerFolders'] = viewerFolders;

    final actual = contract.randomProblem().decode(source);
    reasons.add('staff');
    warnings.add(_warning());
    titles.add(_title());
    contests.add(_contest());
    tags.add(_tag());
    viewerFolders.add(_viewerFolder());

    expect(actual.noRatingReasons, isEmpty);
    expect(actual.noRatingWarnings, isEmpty);
    expect(actual.titles, isEmpty);
    expect(actual.contests, isEmpty);
    expect(actual.tags, isEmpty);
    expect(actual.viewerFolders, isEmpty);
    expect(
      () => actual.noRatingReasons.add(ProblemNoRatingReason.staff),
      throwsUnsupportedError,
    );
    expect(
      () => actual.noRatingWarnings.add(
        const ProblemNoRatingWarning(
          type: ProblemNoRatingWarningType.same,
          problem: null,
        ),
      ),
      throwsUnsupportedError,
    );
    expect(() => actual.titles.clear(), throwsUnsupportedError);
    expect(() => actual.contests.clear(), throwsUnsupportedError);
    expect(() => actual.tags.clear(), throwsUnsupportedError);
    expect(() => actual.viewerFolders.clear(), throwsUnsupportedError);
  });

  test('requires the complete nested warning problem shape', () {
    final endpoint = contract.randomProblem();
    const fields = [
      'problemId',
      'subId',
      'level',
      'effectiveVoteCount',
      'givesNoRating',
      'isStandard',
      'userStatus',
    ];
    for (final field in ['type', 'problem']) {
      expect(
        () => endpoint.decode(
          _source()
            ..['noRatingWarnings'] = <Object?>[_warning()..remove(field)],
        ),
        throwsFormatException,
        reason: 'warning.$field missing',
      );
    }
    for (final field in fields) {
      expect(
        () => endpoint.decode(
          _source()
            ..['noRatingWarnings'] = <Object?>[
              _warning(problem: _warningProblem()..remove(field)),
            ],
        ),
        throwsFormatException,
        reason: 'warning.problem.$field missing',
      );
    }
    for (final status in <Object?>['solved', 'partial', 'tried', null]) {
      final actual = endpoint.decode(
        _source()
          ..['noRatingWarnings'] = <Object?>[
            _warning(problem: _warningProblem()..['userStatus'] = status),
          ],
      );
      expect(actual.noRatingWarnings.single.problem?.userStatus?.value, status);
    }
  });

  test('requires every random-problem nested DTO field', () {
    final endpoint = contract.randomProblem();
    final cases = <String, (Map<String, Object?> Function(), List<String>)>{
      'titles': (_title, ['language', 'title', 'isOriginal', 'latex', 'html']),
      'contests': (_contest, ['id', 'displayId', 'name', 'abbreviation']),
      'tags': (_tag, ['id', 'key', 'isMeta']),
      'viewerFolders': (_viewerFolder, ['slug', 'name', 'color']),
    };
    for (final entry in cases.entries) {
      final factory = entry.value.$1;
      for (final field in entry.value.$2) {
        expect(
          () => endpoint.decode(
            _source()..[entry.key] = <Object?>[factory()..remove(field)],
          ),
          throwsFormatException,
          reason: '${entry.key}[].$field missing',
        );
      }
      expect(
        () => endpoint.decode(_source()..[entry.key] = <Object?>[0]),
        throwsFormatException,
      );
    }
  });

  test('validates nested DTO types and finite numbers', () {
    final endpoint = contract.randomProblem();

    void expectInvalid(String collection, Object? item, String reason) {
      expect(
        () => endpoint.decode(_source()..[collection] = <Object?>[item]),
        throwsFormatException,
        reason: reason,
      );
    }

    for (final invalid in <Object?>[0, false, 'problem', const <Object?>[]]) {
      expectInvalid(
        'noRatingWarnings',
        _warning(problem: invalid),
        'warning.problem = $invalid',
      );
    }
    for (final field in ['problemId', 'level', 'effectiveVoteCount']) {
      for (final invalid in <Object?>['1', false, double.nan]) {
        expectInvalid(
          'noRatingWarnings',
          _warning(problem: _warningProblem()..[field] = invalid),
          'warning.problem.$field = $invalid',
        );
      }
    }
    expectInvalid(
      'noRatingWarnings',
      _warning(problem: _warningProblem()..['subId'] = 1),
      'warning.problem.subId',
    );
    for (final field in ['givesNoRating', 'isStandard']) {
      expectInvalid(
        'noRatingWarnings',
        _warning(problem: _warningProblem()..[field] = 'true'),
        'warning.problem.$field',
      );
    }
    expectInvalid(
      'noRatingWarnings',
      _warning(problem: _warningProblem()..['userStatus'] = 'unknown'),
      'warning.problem.userStatus',
    );

    for (final field in ['language', 'title']) {
      expectInvalid('titles', _title()..[field] = 1, 'titles[].$field');
    }
    for (final field in ['isOriginal', 'latex', 'html']) {
      expectInvalid('titles', _title()..[field] = 1, 'titles[].$field');
    }

    expectInvalid(
      'contests',
      _contest()..['id'] = double.infinity,
      'contest.id',
    );
    for (final field in ['displayId', 'name']) {
      expectInvalid('contests', _contest()..[field] = 1, 'contest.$field');
    }
    expectInvalid(
      'contests',
      _contest()..['abbreviation'] = 1,
      'contest.abbreviation',
    );

    expectInvalid('tags', _tag()..['id'] = double.negativeInfinity, 'tag.id');
    expectInvalid('tags', _tag()..['key'] = 1, 'tag.key');
    expectInvalid('tags', _tag()..['isMeta'] = 1, 'tag.isMeta');

    for (final field in ['slug', 'name']) {
      expectInvalid(
        'viewerFolders',
        _viewerFolder()..[field] = 1,
        'viewerFolder.$field',
      );
    }
    expectInvalid(
      'viewerFolders',
      _viewerFolder()..['color'] = 1,
      'viewerFolder.color',
    );
  });

  test('preserves every viewer-folder color and required null', () {
    final endpoint = contract.randomProblem();
    for (final color in ProblemSearchViewerFolderColor.values) {
      final actual = endpoint.decode(
        _source()
          ..['viewerFolders'] = <Object?>[
            _viewerFolder()..['color'] = color.value,
          ],
      );
      expect(actual.viewerFolders.single.color, color);
    }
    expect(
      endpoint
          .decode(
            _source()
              ..['viewerFolders'] = <Object?>[
                _viewerFolder()..['color'] = null,
              ],
          )
          .viewerFolders
          .single
          .color,
      isNull,
    );
  });

  test('uses random-problem paths in nested decoder diagnostics', () {
    final endpoint = contract.randomProblem();

    expect(
      () => endpoint.decode(
        _source()..['titles'] = <Object?>[_title()..['language'] = 1],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Expected string for random problem.titles[].language',
        ),
      ),
    );
    expect(
      () => endpoint.decode(
        _source()..['contests'] = <Object?>[_contest()..remove('abbreviation')],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Missing required field random problem.contests[].abbreviation',
        ),
      ),
    );
    expect(
      () => endpoint.decode(
        _source()..['tags'] = <Object?>[_tag()..['key'] = 1],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Expected string for random problem.tags[].key',
        ),
      ),
    );
    expect(
      () => endpoint.decode(
        _source()
          ..['viewerFolders'] = <Object?>[_viewerFolder()..remove('color')],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Missing required field random problem.viewerFolders[].color',
        ),
      ),
    );
    expect(
      () => endpoint.decode(
        _source()
          ..['viewerFolders'] = <Object?>[
            _viewerFolder()..['color'] = 'future',
          ],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Unsupported random problem.viewerFolders[].color',
        ),
      ),
    );
  });

  test('eagerly validates trailing collection entries', () {
    final endpoint = contract.randomProblem();
    final invalidTrailingEntries = <String, Object?>{
      'noRatingReasons': 1,
      'noRatingWarnings': _warning()..remove('type'),
      'titles': _title()..remove('html'),
      'contests': _contest()..remove('abbreviation'),
      'tags': _tag()..remove('key'),
      'viewerFolders': _viewerFolder()..remove('color'),
    };
    for (final entry in invalidTrailingEntries.entries) {
      final first = switch (entry.key) {
        'noRatingReasons' => 'staff',
        'noRatingWarnings' => _warning(),
        'titles' => _title(),
        'contests' => _contest(),
        'tags' => _tag(),
        'viewerFolders' => _viewerFolder(),
        _ => throw StateError('Unexpected collection'),
      };
      expect(
        () => endpoint.decode(
          _source()..[entry.key] = <Object?>[first, entry.value],
        ),
        throwsFormatException,
        reason: '${entry.key} trailing item',
      );
    }
  });

  test('preserves raw values, order, duplicates, and immutable snapshots', () {
    final reasons = <Object?>['staff', 'unofficial', 'staff'];
    final warningProblem = _warningProblem()
      ..['problemId'] = -1.5
      ..['subId'] = ' raw '
      ..['level'] = -2.5
      ..['effectiveVoteCount'] = -3.5
      ..['futureProblemField'] = true;
    final warning = _warning(problem: warningProblem)
      ..['futureWarningField'] = true;
    final warnings = <Object?>[warning, warning];
    final title = _title()
      ..['language'] = ''
      ..['title'] = '  '
      ..['futureTitleField'] = true;
    final titles = <Object?>[title, title];
    final contest = _contest()
      ..['id'] = -4.5
      ..['displayId'] = ''
      ..['name'] = ' '
      ..['futureContestField'] = true;
    final contests = <Object?>[contest, contest];
    final tag = _tag()
      ..['id'] = -5.5
      ..['key'] = ''
      ..['futureTagField'] = true;
    final tags = <Object?>[tag, tag];
    final viewerFolder = _viewerFolder()
      ..['slug'] = ''
      ..['name'] = ' raw folder '
      ..['color'] = 'orange'
      ..['futureViewerFolderField'] = true;
    final viewerFolders = <Object?>[viewerFolder, viewerFolder];
    final source = _source()
      ..['id'] = -0.5
      ..['problemId'] = -1.5
      ..['subId'] = ' raw '
      ..['level'] = -2.5
      ..['levelAverage'] = -3.5
      ..['levelStdev'] = -4.5
      ..['votedUserCount'] = -5.5
      ..['effectiveVoteCount'] = -6.5
      ..['solvedUserCount'] = -7.5
      ..['noRatingReasons'] = reasons
      ..['noRatingWarnings'] = warnings
      ..['titles'] = titles
      ..['contests'] = contests
      ..['tags'] = tags
      ..['viewerFolders'] = viewerFolders
      ..['futureTopLevelField'] = true;

    final actual = contract.randomProblem().decode(source);
    expect(actual.id, -0.5);
    expect(actual.id, isA<double>());
    expect(actual.problemId, -1.5);
    expect(actual.subId, ' raw ');
    expect(actual.noRatingReasons, [
      ProblemNoRatingReason.staff,
      ProblemNoRatingReason.unofficial,
      ProblemNoRatingReason.staff,
    ]);
    expect(actual.noRatingWarnings, hasLength(2));
    expect(actual.noRatingWarnings.first.problem?.problemId, -1.5);
    expect(actual.titles.map((item) => item.title), ['  ', '  ']);
    expect(actual.contests.map((item) => item.id), [-4.5, -4.5]);
    expect(actual.tags.map((item) => item.key), ['', '']);
    expect(actual.viewerFolders.map((item) => item.slug), ['', '']);
    expect(actual.viewerFolders.map((item) => item.name), [
      ' raw folder ',
      ' raw folder ',
    ]);
    expect(actual.viewerFolders.map((item) => item.color), [
      ProblemSearchViewerFolderColor.orange,
      ProblemSearchViewerFolderColor.orange,
    ]);

    reasons.clear();
    warningProblem.clear();
    warning.clear();
    warnings.clear();
    title.clear();
    titles.clear();
    contest.clear();
    contests.clear();
    tag.clear();
    tags.clear();
    viewerFolder.clear();
    viewerFolders.clear();
    source.clear();
    expect(actual.noRatingReasons, hasLength(3));
    expect(actual.noRatingWarnings.first.problem?.subId, ' raw ');
    expect(actual.titles, hasLength(2));
    expect(actual.contests, hasLength(2));
    expect(actual.tags, hasLength(2));
    expect(actual.viewerFolders, hasLength(2));

    expect(
      () => actual.noRatingReasons.add(ProblemNoRatingReason.legacy),
      throwsUnsupportedError,
    );
    expect(() => actual.noRatingWarnings.clear(), throwsUnsupportedError);
    expect(() => actual.titles.clear(), throwsUnsupportedError);
    expect(() => actual.contests.clear(), throwsUnsupportedError);
    expect(() => actual.tags.clear(), throwsUnsupportedError);
    expect(() => actual.viewerFolders.clear(), throwsUnsupportedError);
  });
}

const _topLevelFields = [
  'id',
  'problemId',
  'subId',
  'level',
  'levelAverage',
  'levelStdev',
  'isStandard',
  'votedUserCount',
  'effectiveVoteCount',
  'solvedUserCount',
  'givesNoRating',
  'noRatingReasons',
  'noRatingWarnings',
  'titles',
  'userStatus',
  'contests',
  'tags',
  'viewerFolders',
];

Map<String, Object?> _source() => <String, Object?>{
      'id': 1,
      'problemId': 1,
      'subId': '',
      'level': 1,
      'levelAverage': 1.5,
      'levelStdev': 0.5,
      'isStandard': true,
      'votedUserCount': 2,
      'effectiveVoteCount': 2,
      'solvedUserCount': 3,
      'givesNoRating': false,
      'noRatingReasons': <Object?>['staff'],
      'noRatingWarnings': <Object?>[_warning()],
      'titles': <Object?>[_title()],
      'userStatus': null,
      'contests': <Object?>[_contest()],
      'tags': <Object?>[_tag()],
      'viewerFolders': <Object?>[_viewerFolder()],
    };

Map<String, Object?> _warning({
  Object? type = 'same',
  Object? problem = const _DefaultWarningProblem(),
}) =>
    <String, Object?>{
      'type': type,
      'problem':
          problem is _DefaultWarningProblem ? _warningProblem() : problem,
    };

Map<String, Object?> _warningProblem() => <String, Object?>{
      'problemId': 2,
      'subId': '',
      'level': 2,
      'effectiveVoteCount': 3,
      'givesNoRating': false,
      'isStandard': true,
      'userStatus': null,
    };

Map<String, Object?> _title() => <String, Object?>{
      'language': 'en',
      'title': 'Title',
      'isOriginal': true,
      'latex': false,
      'html': false,
    };

Map<String, Object?> _contest() => <String, Object?>{
      'id': 1,
      'displayId': 'contest',
      'name': 'Contest',
      'abbreviation': null,
    };

Map<String, Object?> _tag() => <String, Object?>{
      'id': 1,
      'key': 'tag',
      'isMeta': false,
    };

Map<String, Object?> _viewerFolder() => <String, Object?>{
      'slug': 'folder',
      'name': 'Folder',
      'color': null,
    };

final class _DefaultWarningProblem {
  const _DefaultWarningProblem();
}
