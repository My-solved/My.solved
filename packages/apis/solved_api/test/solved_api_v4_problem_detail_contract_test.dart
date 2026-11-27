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

  test('builds the public problem-detail endpoint and preserves sub', () {
    final omitted = contract.problemDetail(1);
    final empty = contract.problemDetail(2, sub: '');
    final explicit = contract.problemDetail(3, sub: 'A B&한');

    expect(omitted.direct.path, 'problems/1');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(empty.direct.queryParameters, {'sub': ''});
    expect(explicit.direct.queryParameters, {'sub': 'A B&한'});
    expect(explicit.proxy.queryParameters, explicit.direct.queryParameters);
    for (final invalid in [0, -1]) {
      expect(
        () => contract.problemDetail(invalid),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'problemId')
              .having((error) => error.invalidValue, 'invalidValue', invalid),
        ),
      );
    }
  });

  test('decodes the complete official problem-detail fixture', () {
    final actual = contract
        .problemDetail(1000)
        .decode(jsonDecode(fixture('v4/problem_detail.json')));

    expect(actual.id, 1000.5);
    expect(actual.problemId, 1000);
    expect(actual.subId, 'A');
    expect(actual.level, 12.5);
    expect(actual.levelAverage, 13.25);
    expect(actual.levelStdev, 0.75);
    expect(actual.isStandard, isTrue);
    expect(actual.votedUserCount, 42.5);
    expect(actual.effectiveVoteCount, 40);
    expect(actual.solvedUserCount, 1234.5);
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
    expect(actual.contests.single.id, 7.5);
    expect(actual.contests.single.abbreviation, isNull);
    expect(actual.tags.map((tag) => tag.id), [1.5, 2]);
    expect(actual.tags.last.isMeta, isTrue);
    expect(actual.ojLinks.map((link) => link.ojId), ['boj', 'example']);
    expect(actual.ojLinks.first.logoUrl, isNull);
    expect(actual.ojLinks.last.url, 'not a normalized URI');
    expect(actual.ojLinks.last.logoUrl, 'raw logo value');
  });

  test('requires every top-level problem-detail field', () {
    final endpoint = contract.problemDetail(1);
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
    final endpoint = contract.problemDetail(1);
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

    final source = _source()
      ..['id'] = -1
      ..['problemId'] = -2.0
      ..['level'] = -3
      ..['levelAverage'] = -4.0
      ..['levelStdev'] = -5
      ..['votedUserCount'] = -6.0
      ..['effectiveVoteCount'] = -7
      ..['solvedUserCount'] = -8.0;
    final actual = endpoint.decode(source);
    expect(actual.id, -1);
    expect(actual.id, isA<int>());
    expect(actual.problemId, -2.0);
    expect(actual.problemId, isA<double>());
    expect(actual.level, -3);
    expect(actual.level, isA<int>());
    expect(actual.levelAverage, -4.0);
    expect(actual.levelAverage, isA<double>());
    expect(actual.levelStdev, -5);
    expect(actual.levelStdev, isA<int>());
    expect(actual.votedUserCount, -6.0);
    expect(actual.votedUserCount, isA<double>());
    expect(actual.effectiveVoteCount, -7);
    expect(actual.effectiveVoteCount, isA<int>());
    expect(actual.solvedUserCount, -8.0);
    expect(actual.solvedUserCount, isA<double>());
  });

  test('preserves nested integer and integral-double runtime types', () {
    final warningProblem = _warningProblem()
      ..['problemId'] = 20.0
      ..['level'] = 21
      ..['effectiveVoteCount'] = 22.0;
    final source = _source()
      ..['noRatingWarnings'] = <Object?>[
        _warning(problem: warningProblem),
      ]
      ..['contests'] = <Object?>[
        _contest()..['id'] = 30,
        _contest()..['id'] = 31.0,
      ]
      ..['tags'] = <Object?>[
        _tag()..['id'] = 40,
        _tag()..['id'] = 41.0,
      ];

    final actual = contract.problemDetail(1).decode(source);
    final related = actual.noRatingWarnings.single.problem!;
    expect(related.problemId, 20.0);
    expect(related.problemId, isA<double>());
    expect(related.level, 21);
    expect(related.level, isA<int>());
    expect(related.effectiveVoteCount, 22.0);
    expect(related.effectiveVoteCount, isA<double>());
    expect(actual.contests.map((item) => item.id), [30, 31.0]);
    expect(actual.contests.first.id, isA<int>());
    expect(actual.contests.last.id, isA<double>());
    expect(actual.tags.map((item) => item.id), [40, 41.0]);
    expect(actual.tags.first.id, isA<int>());
    expect(actual.tags.last.id, isA<double>());
  });

  test('validates scalar and collection top-level types', () {
    final endpoint = contract.problemDetail(1);
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
        'ojLinks',
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
    final endpoint = contract.problemDetail(1);
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
    final endpoint = contract.problemDetail(1);
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
    final ojLinks = <Object?>[];
    final source = _source()
      ..['noRatingReasons'] = reasons
      ..['noRatingWarnings'] = warnings
      ..['titles'] = titles
      ..['contests'] = contests
      ..['tags'] = tags
      ..['ojLinks'] = ojLinks;

    final actual = contract.problemDetail(1).decode(source);
    reasons.add('staff');
    warnings.add(_warning());
    titles.add(_title());
    contests.add(_contest());
    tags.add(_tag());
    ojLinks.add(_ojLink());

    expect(actual.noRatingReasons, isEmpty);
    expect(actual.noRatingWarnings, isEmpty);
    expect(actual.titles, isEmpty);
    expect(actual.contests, isEmpty);
    expect(actual.tags, isEmpty);
    expect(actual.ojLinks, isEmpty);
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
    expect(() => actual.ojLinks.clear(), throwsUnsupportedError);
  });

  test('requires the complete nested warning problem shape', () {
    final endpoint = contract.problemDetail(1);
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

  test('requires every detail-specific nested DTO field', () {
    final endpoint = contract.problemDetail(1);
    final cases = <String, (Map<String, Object?> Function(), List<String>)>{
      'titles': (_title, ['language', 'title', 'isOriginal', 'latex', 'html']),
      'contests': (_contest, ['id', 'displayId', 'name', 'abbreviation']),
      'tags': (_tag, ['id', 'key', 'isMeta']),
      'ojLinks': (
        _ojLink,
        ['ojId', 'ojName', 'nativeProblemId', 'url', 'logoUrl'],
      ),
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
    final endpoint = contract.problemDetail(1);

    void expectInvalid(String collection, Object? item, String reason) {
      expect(
        () => endpoint.decode(
          _source()..[collection] = <Object?>[item],
        ),
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
    for (final field in [
      'problemId',
      'level',
      'effectiveVoteCount',
    ]) {
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
        'contests', _contest()..['id'] = double.infinity, 'contest.id');
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

    for (final field in ['ojId', 'ojName', 'nativeProblemId', 'url']) {
      expectInvalid('ojLinks', _ojLink()..[field] = 1, 'ojLink.$field');
    }
    expectInvalid('ojLinks', _ojLink()..['logoUrl'] = 1, 'ojLink.logoUrl');
  });

  test('eagerly validates trailing collection entries', () {
    final endpoint = contract.problemDetail(1);
    final invalidTrailingEntries = <String, Object?>{
      'noRatingReasons': 1,
      'noRatingWarnings': _warning()..remove('type'),
      'titles': _title()..remove('html'),
      'contests': _contest()..remove('abbreviation'),
      'tags': _tag()..remove('key'),
      'ojLinks': _ojLink()..remove('logoUrl'),
    };
    for (final entry in invalidTrailingEntries.entries) {
      final first = switch (entry.key) {
        'noRatingReasons' => 'staff',
        'noRatingWarnings' => _warning(),
        'titles' => _title(),
        'contests' => _contest(),
        'tags' => _tag(),
        'ojLinks' => _ojLink(),
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
    final ojLink = _ojLink()
      ..['ojId'] = ''
      ..['url'] = ' not a URI '
      ..['logoUrl'] = ''
      ..['futureOjLinkField'] = true;
    final ojLinks = <Object?>[ojLink, ojLink];
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
      ..['ojLinks'] = ojLinks
      ..['futureTopLevelField'] = true;

    final actual = contract.problemDetail(1).decode(source);
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
    expect(actual.ojLinks.map((item) => item.url), [
      ' not a URI ',
      ' not a URI ',
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
    ojLink.clear();
    ojLinks.clear();
    source.clear();
    expect(actual.noRatingReasons, hasLength(3));
    expect(actual.noRatingWarnings.first.problem?.subId, ' raw ');
    expect(actual.titles, hasLength(2));
    expect(actual.contests, hasLength(2));
    expect(actual.tags, hasLength(2));
    expect(actual.ojLinks, hasLength(2));

    expect(
      () => actual.noRatingReasons.add(ProblemNoRatingReason.legacy),
      throwsUnsupportedError,
    );
    expect(() => actual.noRatingWarnings.clear(), throwsUnsupportedError);
    expect(() => actual.titles.clear(), throwsUnsupportedError);
    expect(() => actual.contests.clear(), throwsUnsupportedError);
    expect(() => actual.tags.clear(), throwsUnsupportedError);
    expect(() => actual.ojLinks.clear(), throwsUnsupportedError);
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
  'ojLinks',
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
      'ojLinks': <Object?>[_ojLink()],
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

Map<String, Object?> _ojLink() => <String, Object?>{
      'ojId': 'boj',
      'ojName': 'Baekjoon Online Judge',
      'nativeProblemId': '1',
      'url': 'raw url',
      'logoUrl': null,
    };

final class _DefaultWarningProblem {
  const _DefaultWarningProblem();
}
