import 'dart:convert';

import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

void main() {
  late SolvedApiV4Contract contract;

  setUp(() {
    contract = SolvedApiV4Contract(
      proxyBaseUri: Uri.parse('https://proxy.example.com/solved/v4/'),
    );
  });

  group('problem search', () {
    test('exposes the official no-rating reason codes', () {
      expect(ProblemNoRatingReason.values.map((reason) => reason.value), [
        'unofficial',
        'legacy',
        'staff',
        'unsettled',
      ]);
    });

    test('exposes the official no-rating warning and user-status codes', () {
      expect(
        ProblemNoRatingWarningType.values.map((warning) => warning.value),
        [
          'same',
          'searchable',
          'wrong-inputs',
          'insufficient-conditions',
          'no-special-judge',
          'wrong-conditions',
          'wrong-statement',
        ],
      );
      expect(ProblemUserStatus.values.map((status) => status.value), [
        'solved',
        'partial',
        'tried',
      ]);
    });

    test('uses the official path, parameters, and defaults', () {
      final defaults = contract.searchProblems('tag:dp');
      final configured = contract.searchProblems(
        'tag:dp',
        page: 3,
        sort: SolvedApiV4ProblemSort.averageTry,
        direction: SolvedApiV4SearchDirection.desc,
        seed: 'reroll-1',
      );

      expect(defaults.direct.path, 'problems');
      expect(defaults.direct.queryParameters, {
        'q': 'tag:dp',
        'page': '1',
        'sort': 'id',
        'direction': 'asc',
      });
      expect(configured.direct.queryParameters, {
        'q': 'tag:dp',
        'page': '3',
        'sort': 'average_try',
        'direction': 'desc',
        'seed': 'reroll-1',
      });
      expect(configured.proxy.path, 'problems');
      expect(
        configured.proxy.queryParameters,
        configured.direct.queryParameters,
      );
    });

    test('does not represent the unsupported v3 title sort', () {
      expect(SolvedApiV4ProblemSort.values.map((sort) => sort.value), [
        'id',
        'level',
        'solved',
        'average_try',
        'random',
      ]);
      expect(
        SolvedApiV4ProblemSort.values.map((sort) => sort.value),
        isNot(contains('title')),
      );
    });

    test('validates page and seed before creating a request', () {
      expect(() => contract.searchProblems('dp', page: 0), throwsArgumentError);
      expect(
        () => contract.searchProblems('dp', seed: ''),
        throwsArgumentError,
      );
      expect(
        () => contract.searchProblems('dp', seed: List.filled(65, 'a').join()),
        throwsArgumentError,
      );
    });

    test('normalizes total, title fallbacks, levels, and tag keys', () {
      final actual = contract
          .searchProblems('sample')
          .decode(jsonDecode(fixture('v4/search_problems.json')));

      expect(actual.count, 4);
      expect(actual.items, hasLength(4));
      expect(actual.items[0].problemId, 1001);
      expect(actual.items[0].title, '한국어 제목');
      expect(actual.items[0].level, 10);
      expect(actual.items[0].votedUserCount, 42);
      expect(actual.items[0].solvedUserCount, 1234);
      expect(actual.items[0].givesNoRating, isFalse);
      expect(actual.items[0].noRatingReasons, isEmpty);
      expect(actual.items[0].noRatingWarnings, isEmpty);
      expect(actual.items[0].tagNames, ['math', 'number_theory']);
      expect(actual.items[1].title, 'Original title');
      expect(actual.items[2].title, 'First fallback');
      expect(actual.items[3].title, isNull);
      expect(actual.items[3].votedUserCount, 0);
      expect(actual.items[3].solvedUserCount, 0);
      expect(actual.items[3].givesNoRating, isTrue);
      expect(actual.items[3].noRatingReasons, [
        ProblemNoRatingReason.unofficial,
      ]);
      expect(actual.items[3].noRatingWarnings, isEmpty);
    });

    test('requires a finite voted-user count without inventing bounds', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      final missing = source();
      firstProblem(missing).remove('votedUserCount');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        '1',
        true,
        const <String, Object?>{},
        const <Object>[],
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final malformed = source();
        firstProblem(malformed)['votedUserCount'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'votedUserCount = $invalid',
        );
      }

      final unbounded = source();
      firstProblem(unbounded)['votedUserCount'] = -1.5;
      final lastProblem =
          (unbounded['problems'] as List).last as Map<String, dynamic>;
      lastProblem['votedUserCount'] = 0.25;
      final actual = endpoint.decode(unbounded);
      expect(actual.items.first.votedUserCount, -1.5);
      expect(actual.items.last.votedUserCount, 0.25);
    });

    test('requires a finite solved-user count without inventing bounds', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      final missing = source();
      firstProblem(missing).remove('solvedUserCount');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        '1',
        true,
        const <String, Object?>{},
        const <Object>[],
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final malformed = source();
        firstProblem(malformed)['solvedUserCount'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'solvedUserCount = $invalid',
        );
      }

      final unbounded = source();
      firstProblem(unbounded)['solvedUserCount'] = -1.5;
      final lastProblem =
          (unbounded['problems'] as List).last as Map<String, dynamic>;
      lastProblem['solvedUserCount'] = 0.25;
      final actual = endpoint.decode(unbounded);
      expect(actual.items.first.solvedUserCount, -1.5);
      expect(actual.items.last.solvedUserCount, 0.25);
    });

    test('requires a boolean no-rating marker in every v4 problem', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      final missing = source();
      firstProblem(missing).remove('givesNoRating');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        0,
        1,
        'false',
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['givesNoRating'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'givesNoRating = $invalid',
        );
      }
    });

    test('requires the documented no-rating reason array and values', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      final missing = source();
      firstProblem(missing).remove('noRatingReasons');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        0,
        false,
        'unofficial',
        const <String, Object?>{},
      ]) {
        final malformed = source();
        firstProblem(malformed)['noRatingReasons'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'noRatingReasons = $invalid',
        );
      }

      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
        'future-reason',
      ]) {
        final malformed = source();
        firstProblem(malformed)['noRatingReasons'] = [invalid];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'noRatingReasons[] = $invalid',
        );
      }
    });

    test(
      'preserves reason order and duplicates without inferring the marker',
      () {
        final body =
            jsonDecode(fixture('v4/search_problems.json'))
                as Map<String, dynamic>;
        final problems = body['problems'] as List;
        final rated = problems.first as Map<String, dynamic>;
        rated['givesNoRating'] = false;
        rated['noRatingReasons'] = [
          'staff',
          'unofficial',
          'staff',
          'legacy',
          'unsettled',
        ];
        final unrated = problems.last as Map<String, dynamic>;
        unrated['givesNoRating'] = true;
        unrated['noRatingReasons'] = <Object>[];

        final actual = contract.searchProblems('sample').decode(body);
        expect(actual.items.first.givesNoRating, isFalse);
        expect(actual.items.first.noRatingReasons, [
          ProblemNoRatingReason.staff,
          ProblemNoRatingReason.unofficial,
          ProblemNoRatingReason.staff,
          ProblemNoRatingReason.legacy,
          ProblemNoRatingReason.unsettled,
        ]);
        expect(actual.items.last.givesNoRating, isTrue);
        expect(actual.items.last.noRatingReasons, isEmpty);
        expect(
          () => actual.items.first.noRatingReasons!.add(
            ProblemNoRatingReason.legacy,
          ),
          throwsUnsupportedError,
        );
        expect(
          () =>
              actual.items.first.noRatingReasons![0] =
                  ProblemNoRatingReason.legacy,
          throwsUnsupportedError,
        );
      },
    );

    test('requires the documented no-rating warning array and keys', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> relatedProblem() => {
        'problemId': 1000,
        'subId': 'A',
        'level': 10,
        'effectiveVoteCount': 5,
        'givesNoRating': false,
        'isStandard': true,
        'userStatus': null,
      };
      Map<String, dynamic> warning() => {
        'type': 'same',
        'problem': relatedProblem(),
      };
      SearchObject<ProblemSearchItem> decodeWarnings(Object? warnings) {
        final body = source();
        firstProblem(body)['noRatingWarnings'] = warnings;
        return endpoint.decode(body);
      }

      final missing = source();
      firstProblem(missing).remove('noRatingWarnings');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        0,
        false,
        'same',
        const <String, Object?>{},
      ]) {
        expect(
          () => decodeWarnings(invalid),
          throwsFormatException,
          reason: 'noRatingWarnings = $invalid',
        );
      }

      for (final invalid in <Object?>[
        null,
        0,
        false,
        'same',
        const <Object>[],
      ]) {
        expect(
          () => decodeWarnings([invalid]),
          throwsFormatException,
          reason: 'noRatingWarnings[] = $invalid',
        );
      }

      for (final field in ['type', 'problem']) {
        final malformed = warning()..remove(field);
        expect(
          () => decodeWarnings([malformed]),
          throwsFormatException,
          reason: 'noRatingWarnings[].$field missing',
        );
      }

      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
        'future-warning',
      ]) {
        final malformed = warning()..['type'] = invalid;
        expect(
          () => decodeWarnings([malformed]),
          throwsFormatException,
          reason: 'noRatingWarnings[].type = $invalid',
        );
      }

      for (final invalid in <Object?>[
        0,
        false,
        'problem',
        const <Object>[],
        const <String, Object?>{},
      ]) {
        final malformed = warning()..['problem'] = invalid;
        expect(
          () => decodeWarnings([malformed]),
          throwsFormatException,
          reason: 'noRatingWarnings[].problem = $invalid',
        );
      }

      final actual = decodeWarnings([
        {'type': 'same', 'problem': null},
      ]);
      expect(
        actual.items.first.noRatingWarnings!.single.type,
        ProblemNoRatingWarningType.same,
      );
      expect(actual.items.first.noRatingWarnings!.single.problem, isNull);
    });

    test('strictly validates every nested warning problem field', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> relatedProblem() => {
        'problemId': 1000,
        'subId': 'A',
        'level': 10,
        'effectiveVoteCount': 5,
        'givesNoRating': false,
        'isStandard': true,
        'userStatus': null,
      };
      void decodeProblem(Object? problem) {
        final body = source();
        final firstProblem =
            (body['problems'] as List).first as Map<String, dynamic>;
        firstProblem['noRatingWarnings'] = [
          {'type': 'same', 'problem': problem},
        ];
        endpoint.decode(body);
      }

      for (final field in [
        'problemId',
        'subId',
        'level',
        'effectiveVoteCount',
        'givesNoRating',
        'isStandard',
        'userStatus',
      ]) {
        final malformed = relatedProblem()..remove(field);
        expect(
          () => decodeProblem(malformed),
          throwsFormatException,
          reason: 'warning problem $field missing',
        );
      }

      for (final field in ['problemId', 'level', 'effectiveVoteCount']) {
        for (final invalid in <Object?>[
          null,
          '1',
          true,
          const <String, Object?>{},
          const <Object>[],
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          final malformed = relatedProblem()..[field] = invalid;
          expect(
            () => decodeProblem(malformed),
            throwsFormatException,
            reason: 'warning problem $field = $invalid',
          );
        }
      }

      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = relatedProblem()..['subId'] = invalid;
        expect(
          () => decodeProblem(malformed),
          throwsFormatException,
          reason: 'warning problem subId = $invalid',
        );
      }

      for (final field in ['givesNoRating', 'isStandard']) {
        for (final invalid in <Object?>[
          null,
          0,
          'true',
          const <String, Object?>{},
          const <Object>[],
        ]) {
          final malformed = relatedProblem()..[field] = invalid;
          expect(
            () => decodeProblem(malformed),
            throwsFormatException,
            reason: 'warning problem $field = $invalid',
          );
        }
      }

      for (final invalid in <Object?>[
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
        'future-status',
      ]) {
        final malformed = relatedProblem()..['userStatus'] = invalid;
        expect(
          () => decodeProblem(malformed),
          throwsFormatException,
          reason: 'warning problem userStatus = $invalid',
        );
      }
    });

    test(
      'preserves warning order, duplicates, nullable problems, and numbers',
      () {
        final body =
            jsonDecode(fixture('v4/search_problems.json'))
                as Map<String, dynamic>;
        final firstProblem =
            (body['problems'] as List).first as Map<String, dynamic>;
        firstProblem['givesNoRating'] = false;
        Map<String, dynamic> relatedProblem({
          required Object? userStatus,
          num problemId = 1000,
          num level = 10,
          num effectiveVoteCount = 5,
        }) => {
          'problemId': problemId,
          'subId': '',
          'level': level,
          'effectiveVoteCount': effectiveVoteCount,
          'givesNoRating': false,
          'isStandard': true,
          'userStatus': userStatus,
          'futureProblemField': true,
        };
        Map<String, dynamic> duplicateWarning() => {
          'type': 'wrong-statement',
          'problem': relatedProblem(
            userStatus: 'solved',
            problemId: -1.5,
            level: 0.25,
            effectiveVoteCount: -2.5,
          ),
          'futureWarningField': true,
        };
        firstProblem['noRatingWarnings'] = [
          duplicateWarning(),
          {'type': 'same', 'problem': relatedProblem(userStatus: 'partial')},
          duplicateWarning(),
          {
            'type': 'searchable',
            'problem': relatedProblem(userStatus: 'tried'),
          },
          {'type': 'wrong-inputs', 'problem': relatedProblem(userStatus: null)},
          {'type': 'insufficient-conditions', 'problem': null},
          {'type': 'no-special-judge', 'problem': null},
          {'type': 'wrong-conditions', 'problem': null},
        ];

        final actual = contract.searchProblems('sample').decode(body);
        final warnings = actual.items.first.noRatingWarnings!;
        expect(actual.items.first.givesNoRating, isFalse);
        expect(warnings.map((warning) => warning.type), [
          ProblemNoRatingWarningType.wrongStatement,
          ProblemNoRatingWarningType.same,
          ProblemNoRatingWarningType.wrongStatement,
          ProblemNoRatingWarningType.searchable,
          ProblemNoRatingWarningType.wrongInputs,
          ProblemNoRatingWarningType.insufficientConditions,
          ProblemNoRatingWarningType.noSpecialJudge,
          ProblemNoRatingWarningType.wrongConditions,
        ]);
        expect(warnings[0].problem!.problemId, -1.5);
        expect(warnings[0].problem!.subId, '');
        expect(warnings[0].problem!.level, 0.25);
        expect(warnings[0].problem!.effectiveVoteCount, -2.5);
        expect(warnings[0].problem!.givesNoRating, isFalse);
        expect(warnings[0].problem!.isStandard, isTrue);
        expect(warnings[0].problem!.userStatus, ProblemUserStatus.solved);
        expect(warnings[1].problem!.userStatus, ProblemUserStatus.partial);
        expect(warnings[2].problem!.problemId, -1.5);
        expect(warnings[2].problem!.userStatus, ProblemUserStatus.solved);
        expect(warnings[3].problem!.userStatus, ProblemUserStatus.tried);
        expect(warnings[4].problem!.userStatus, isNull);
        expect(warnings[5].problem, isNull);
        expect(
          () => warnings.add(
            const ProblemNoRatingWarning(
              type: ProblemNoRatingWarningType.same,
              problem: null,
            ),
          ),
          throwsUnsupportedError,
        );
        expect(
          () =>
              warnings[0] = const ProblemNoRatingWarning(
                type: ProblemNoRatingWarningType.same,
                problem: null,
              ),
          throwsUnsupportedError,
        );
      },
    );

    test(
      'accepts integral JSON numbers but rejects fractional model values',
      () {
        final endpoint = contract.searchProblems('number');
        final actual = endpoint.decode({
          'problems': [
            {
              'problemId': 1001.0,
              'level': 12.0,
              'votedUserCount': 0,
              'solvedUserCount': 0,
              'givesNoRating': false,
              'noRatingReasons': <Object>[],
              'noRatingWarnings': <Object>[],
              'titles': <Object>[],
              'tags': <Object>[],
            },
          ],
          'total': 1.0,
        });

        expect(actual.count, 1);
        expect(actual.items.single.problemId, 1001);
        expect(actual.items.single.level, 12);
        expect(
          () => endpoint.decode({
            'problems': [
              {
                'problemId': 1001.5,
                'level': 12,
                'votedUserCount': 0,
                'solvedUserCount': 0,
                'givesNoRating': false,
                'noRatingReasons': <Object>[],
                'noRatingWarnings': <Object>[],
                'titles': <Object>[],
                'tags': <Object>[],
              },
            ],
            'total': 1,
          }),
          throwsFormatException,
        );
      },
    );
  });

  group('user search', () {
    test('uses q and sort without inventing a page parameter', () {
      final endpoint = contract.searchUsers(
        'index',
        sort: SolvedApiV4UserSort.contribution,
      );

      expect(endpoint.direct.path, 'rankings/users/search');
      expect(endpoint.direct.queryParameters, {
        'q': 'index',
        'sort': 'contribution',
      });
      expect(endpoint.direct.queryParameters, isNot(containsPair('page', '1')));
    });

    test('enforces only the documented maximum query length', () {
      expect(() => contract.searchUsers(''), returnsNormally);
      expect(() => contract.searchUsers('a'), returnsNormally);
      expect(
        () => contract.searchUsers(List.filled(65, 'a').join()),
        throwsArgumentError,
      );
    });

    test('preserves nullable tier and keeps exact separate from items', () {
      final actual = contract
          .searchUsers('index')
          .decode(jsonDecode(fixture('v4/search_users.json')));

      expect(actual.exact?.handle, 'index');
      expect(actual.exact?.tier, isNull);
      expect(actual.exact?.rank, 1);
      expect(actual.exact?.userClass, 10);
      expect(actual.exact?.classPlus, isTrue);
      expect(actual.exact?.rating, 3000);
      expect(actual.exact?.solvedCount, 5000);
      expect(actual.exact?.reputation, 500);
      expect(actual.items, hasLength(2));
      expect(actual.items.first.handle, 'index');
      expect(actual.items.first.tier, isNull);
      expect(actual.items.first.rank, 1);
      expect(actual.items.first.userClass, 10);
      expect(actual.items.first.classPlus, isTrue);
      expect(actual.items.first.rating, 3000);
      expect(actual.items.first.solvedCount, 5000);
      expect(actual.items.first.reputation, 500);
      expect(actual.items.last.handle, 'index2');
      expect(actual.items.last.tier, 20);
      expect(actual.items.last.rank, 2);
      expect(actual.items.last.userClass, 8);
      expect(actual.items.last.classPlus, isFalse);
      expect(actual.items.last.rating, 2500);
      expect(actual.items.last.solvedCount, 2500);
      expect(actual.items.last.reputation, 250);
    });

    test('requires integer summaries in every v4 user item', () {
      final endpoint = contract.searchUsers('index');
      Map<String, dynamic> source() => Map<String, dynamic>.from(
            jsonDecode(fixture('v4/search_users.json')) as Map,
          );
      Map<String, dynamic> item(
        Map<String, dynamic> body,
        String location,
      ) => location == 'exact'
          ? body['exact'] as Map<String, dynamic>
          : (body['items'] as List).first as Map<String, dynamic>;

      for (final field in [
        'rank',
        'class',
        'rating',
        'solvedCount',
        'reputation',
      ]) {
        for (final location in ['exact', 'items']) {
          final missing = source();
          item(missing, location).remove(field);
          expect(
            () => endpoint.decode(missing),
            throwsFormatException,
            reason: '$location.$field missing',
          );

          for (final invalid in <Object?>[null, '1', 1.5]) {
            final malformed = source();
            item(malformed, location)[field] = invalid;
            expect(
              () => endpoint.decode(malformed),
              throwsFormatException,
              reason: '$location.$field = $invalid',
            );
          }
        }
      }

      final unbounded = source();
      item(unbounded, 'exact')['rank'] = -1;
      item(unbounded, 'items')['rank'] = 0;
      item(unbounded, 'exact')['class'] = -1;
      item(unbounded, 'items')['class'] = 0;
      item(unbounded, 'exact')['reputation'] = -1;
      final actual = endpoint.decode(unbounded);
      expect(actual.exact?.rank, -1);
      expect(actual.items.first.rank, 0);
      expect(actual.exact?.userClass, -1);
      expect(actual.items.first.userClass, 0);
      expect(actual.exact?.reputation, -1);
    });

    test('requires the CLASS+ marker in every v4 user item', () {
      final endpoint = contract.searchUsers('index');
      Map<String, dynamic> source() => Map<String, dynamic>.from(
            jsonDecode(fixture('v4/search_users.json')) as Map,
          );
      Map<String, dynamic> item(
        Map<String, dynamic> body,
        String location,
      ) =>
          location == 'exact'
              ? body['exact'] as Map<String, dynamic>
              : (body['items'] as List).first as Map<String, dynamic>;

      for (final location in ['exact', 'items']) {
        final missing = source();
        item(missing, location).remove('classPlus');
        expect(
          () => endpoint.decode(missing),
          throwsFormatException,
          reason: '$location.classPlus missing',
        );

        for (final invalid in <Object?>[null, 0, 'true']) {
          final malformed = source();
          item(malformed, location)['classPlus'] = invalid;
          expect(
            () => endpoint.decode(malformed),
            throwsFormatException,
            reason: '$location.classPlus = $invalid',
          );
        }
      }
    });

    test('preserves zero public summaries', () {
      final actual = contract.searchUsers('zero').decode({
        'exact': {
          'handle': 'zero',
          'tier': 0,
          'profileImageUrl': null,
          'rank': 0,
          'class': 0,
          'classPlus': false,
          'rating': 0,
          'solvedCount': 0,
          'reputation': 0,
        },
        'items': <Object>[],
      });

      expect(actual.exact?.rank, 0);
      expect(actual.exact?.userClass, 0);
      expect(actual.exact?.classPlus, isFalse);
      expect(actual.exact?.rating, 0);
      expect(actual.exact?.solvedCount, 0);
      expect(actual.exact?.reputation, 0);
    });

    test('requires the exact key while preserving an explicit null match', () {
      expect(
        () => contract.searchUsers('missing').decode({
          'items': <Object>[],
        }),
        throwsFormatException,
      );

      final actual = contract.searchUsers('missing').decode({
        'exact': null,
        'items': <Object>[],
      });

      expect(actual.exact, isNull);
      expect(actual.items, isEmpty);
    });
  });

  group('tag search', () {
    test('requests the parameterless catalog', () {
      final endpoint = contract.searchTags('graph', page: 2);

      expect(endpoint.direct.path, 'tags');
      expect(endpoint.direct.queryParameters, isEmpty);
      expect(endpoint.proxy.path, 'tags');
      expect(endpoint.proxy.queryParameters, isEmpty);
      expect(() => contract.searchTags('graph', page: 0), throwsArgumentError);
    });

    test('matches key, localized names, and aliases case-insensitively', () {
      final source = jsonDecode(fixture('v4/tags.json'));
      final keyMatch = contract.searchTags('NUMBER_THEORY').decode(source);
      final nameMatch = contract.searchTags('union FIND').decode(source);
      final aliasMatch = contract.searchTags('DIJKSTRA').decode(source);

      expect(keyMatch.items.single.key, 'number_theory');
      expect(keyMatch.items.single.displayName, '정수론');
      expect(nameMatch.items.single.key, 'disjoint_set');
      expect(nameMatch.items.single.displayName, '분리 집합');
      expect(aliasMatch.items.single.key, 'shortest_path');
      expect(aliasMatch.items.single.displayName, '최단 경로');
      expect(aliasMatch.items.single.problemCount, isNull);
    });

    test('selects Korean, English, deterministic fallback, then none', () {
      final actual = contract.searchTags('fallback').decode({
        'tags': [
          {
            'key': 'fallback_korean',
            'names': {'ja': '日本語', 'en': 'English', 'ko': ' 한국어 '},
            'aliases': <String>[],
          },
          {
            'key': 'fallback_english',
            'names': {'ja': '日本語', 'ko': '', 'en': 'English'},
            'aliases': <String>[],
          },
          {
            'key': 'fallback_first',
            'names': {'zh': '中文', 'ja': '最初'},
            'aliases': <String>[],
          },
          {
            'key': 'fallback_key_only',
            'names': {'ko': '', 'en': '   '},
            'aliases': <String>[],
          },
        ],
      });

      expect(
        actual.items.map((item) => (item.key, item.displayName)),
        [
          ('fallback_korean', '한국어'),
          ('fallback_english', 'English'),
          ('fallback_first', '最初'),
          ('fallback_key_only', null),
        ],
      );
      expect(actual.items.every((item) => item.problemCount == null), isTrue);
    });

    test('keeps strict validation for every localized name value', () {
      final endpoint = contract.searchTags('invalid');

      expect(
        () => endpoint.decode({
          'tags': [
            {
              'key': 'invalid_missing',
              'aliases': <String>[],
            },
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode({
          'tags': [
            {
              'key': 'invalid_shape',
              'names': <String>[],
              'aliases': <String>[],
            },
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode({
          'tags': [
            {
              'key': 'invalid_value',
              'names': {'ko': '정상', 'later': 42},
              'aliases': <String>[],
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('paginates filtered catalog results locally', () {
      final source = {
        'tags': List.generate(
          51,
          (index) => {
            'key': 'tag_$index',
            'names': {'en': 'Tag $index'},
            'aliases': <String>[],
          },
        ),
      };

      final first = contract.searchTags('TAG').decode(source);
      final second = contract.searchTags('TAG', page: 2).decode(source);

      expect(first.count, 51);
      expect(first.items, hasLength(SolvedApiV4Contract.tagSearchPageSize));
      expect(first.items.first.key, 'tag_0');
      expect(first.items.last.key, 'tag_49');
      expect(second.count, 51);
      expect(second.items.single.key, 'tag_50');
      expect(second.items.single.displayName, 'Tag 50');
      expect(second.items.single.problemCount, isNull);
    });
  });
}
