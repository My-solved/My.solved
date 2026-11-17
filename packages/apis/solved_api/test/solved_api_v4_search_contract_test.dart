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

    test('exposes the official viewer-folder colors', () {
      expect(
        ProblemSearchViewerFolderColor.values.map((color) => color.value),
        ['red', 'violet', 'blue', 'teal', 'lime', 'yellow', 'orange'],
      );
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
      expect(actual.items[0].id, 1001);
      expect(actual.items[0].subId, '');
      expect(actual.items[0].title, '한국어 제목');
      expect(actual.items[0].titles, hasLength(2));
      expect(actual.items[0].titles![0].language, 'en');
      expect(actual.items[0].titles![0].title, 'English original');
      expect(actual.items[0].titles![0].isOriginal, isTrue);
      expect(actual.items[0].titles![0].latex, isFalse);
      expect(actual.items[0].titles![0].html, isFalse);
      expect(actual.items[0].titles![1].language, 'ko');
      expect(actual.items[0].titles![1].title, '한국어 제목');
      expect(actual.items[0].level, 10);
      expect(actual.items[0].levelAverage, 10.25);
      expect(actual.items[0].levelStdev, 0.5);
      expect(actual.items[0].isStandard, isTrue);
      expect(actual.items[0].userStatus, isNull);
      expect(actual.items[0].votedUserCount, 42);
      expect(actual.items[0].effectiveVoteCount, 40);
      expect(actual.items[0].solvedUserCount, 1234);
      expect(actual.items[0].givesNoRating, isFalse);
      expect(actual.items[0].noRatingReasons, isEmpty);
      expect(actual.items[0].noRatingWarnings, isEmpty);
      expect(
        actual.items.map((item) => item.contests!.length),
        [0, 0, 0, 0],
      );
      expect(actual.items.map((item) => item.tags!.length), [2, 0, 0, 0]);
      expect(
        actual.items.map((item) => item.viewerFolders!.length),
        [0, 0, 0, 0],
      );
      expect(actual.items[0].tags![0].id, 1);
      expect(actual.items[0].tags![0].key, 'math');
      expect(actual.items[0].tags![0].isMeta, isFalse);
      expect(actual.items[0].tags![1].id, 2);
      expect(actual.items[0].tags![1].key, 'number_theory');
      expect(actual.items[0].tags![1].isMeta, isFalse);
      expect(actual.items[0].tagNames, ['math', 'number_theory']);
      expect(actual.items[1].title, 'Original title');
      expect(actual.items[1].userStatus, ProblemUserStatus.solved);
      expect(actual.items[2].title, 'First fallback');
      expect(actual.items[2].userStatus, ProblemUserStatus.tried);
      expect(actual.items[3].title, isNull);
      expect(actual.items[3].titles, isEmpty);
      expect(actual.items[3].id, 1004);
      expect(actual.items[3].subId, '');
      expect(actual.items[3].levelAverage, 0);
      expect(actual.items[3].levelStdev, 0);
      expect(actual.items[3].isStandard, isFalse);
      expect(actual.items[3].userStatus, isNull);
      expect(actual.items[3].votedUserCount, 0);
      expect(actual.items[3].effectiveVoteCount, 0);
      expect(actual.items[3].solvedUserCount, 0);
      expect(actual.items[3].givesNoRating, isTrue);
      expect(actual.items[3].noRatingReasons, [
        ProblemNoRatingReason.unofficial,
      ]);
      expect(actual.items[3].noRatingWarnings, isEmpty);
    });

    test('requires the documented full title array and fields', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> title() => {
        'language': 'ko',
        'title': '제목',
        'isOriginal': false,
        'latex': false,
        'html': false,
      };

      final missing = source();
      firstProblem(missing).remove('titles');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        0,
        false,
        'title',
        const <String, Object?>{},
      ]) {
        final malformed = source();
        firstProblem(malformed)['titles'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'titles = $invalid',
        );
      }

      final invalidItem = source();
      firstProblem(invalidItem)['titles'] = [0];
      expect(() => endpoint.decode(invalidItem), throwsFormatException);

      for (final field in [
        'language',
        'title',
        'isOriginal',
        'latex',
        'html',
      ]) {
        final malformed = source();
        firstProblem(malformed)['titles'] = [title()..remove(field)];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'title $field missing',
        );
      }

      for (final field in ['language', 'title']) {
        for (final invalid in <Object?>[
          null,
          0,
          false,
          const <String, Object?>{},
          const <Object>[],
        ]) {
          final malformed = source();
          firstProblem(malformed)['titles'] = [title()..[field] = invalid];
          expect(
            () => endpoint.decode(malformed),
            throwsFormatException,
            reason: 'title $field = $invalid',
          );
        }
      }

      for (final field in ['isOriginal', 'latex', 'html']) {
        for (final invalid in <Object?>[
          null,
          0,
          'false',
          const <String, Object?>{},
          const <Object>[],
        ]) {
          final malformed = source();
          firstProblem(malformed)['titles'] = [title()..[field] = invalid];
          expect(
            () => endpoint.decode(malformed),
            throwsFormatException,
            reason: 'title $field = $invalid',
          );
        }
      }

      final malformedAfterKorean = source();
      firstProblem(malformedAfterKorean)['titles'] = [
        title(),
        title()..['html'] = 'false',
      ];
      expect(
        () => endpoint.decode(malformedAfterKorean),
        throwsFormatException,
      );
    });

    test('preserves full title order, duplicates, flags, and raw strings', () {
      final body =
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      final firstProblem =
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> firstTitle() => {
        'language': ' ',
        'title': ' 첫째 ',
        'isOriginal': true,
        'latex': true,
        'html': false,
        'futureTitleField': true,
      };
      firstProblem['titles'] = [
        firstTitle(),
        {
          'language': 'ko',
          'title': '',
          'isOriginal': false,
          'latex': false,
          'html': true,
          'futureTitleField': true,
        },
        firstTitle(),
      ];

      final item = contract.searchProblems('sample').decode(body).items.first;
      final titles = item.titles!;
      expect(item.title, '');
      expect(titles.map((title) => title.title), [' 첫째 ', '', ' 첫째 ']);
      expect(titles.map((title) => title.language), [' ', 'ko', ' ']);
      expect(titles[0].isOriginal, isTrue);
      expect(titles[0].latex, isTrue);
      expect(titles[0].html, isFalse);
      expect(titles[1].latex, isFalse);
      expect(titles[1].html, isTrue);
      expect(
        () => titles.add(titles.first),
        throwsUnsupportedError,
      );
      expect(
        () => titles[0] = titles[1],
        throwsUnsupportedError,
      );
    });

    test('requires the documented contest array and fields', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> contest() => {
        'id': 1,
        'displayId': 'contest',
        'name': 'Contest',
        'abbreviation': null,
      };

      final missing = source();
      firstProblem(missing).remove('contests');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        0,
        false,
        'contest',
        const <String, Object?>{},
      ]) {
        final malformed = source();
        firstProblem(malformed)['contests'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'contests = $invalid',
        );
      }

      final invalidItem = source();
      firstProblem(invalidItem)['contests'] = [0];
      expect(() => endpoint.decode(invalidItem), throwsFormatException);

      for (final field in ['id', 'displayId', 'name', 'abbreviation']) {
        final malformed = source();
        firstProblem(malformed)['contests'] = [contest()..remove(field)];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'contest $field missing',
        );
      }

      for (final invalid in <Object?>[
        null,
        '1',
        false,
        const <String, Object?>{},
        const <Object>[],
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final malformed = source();
        firstProblem(malformed)['contests'] = [contest()..['id'] = invalid];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'contest id = $invalid',
        );
      }

      for (final field in ['displayId', 'name']) {
        for (final invalid in <Object?>[
          null,
          0,
          false,
          const <String, Object?>{},
          const <Object>[],
        ]) {
          final malformed = source();
          firstProblem(malformed)['contests'] = [contest()..[field] = invalid];
          expect(
            () => endpoint.decode(malformed),
            throwsFormatException,
            reason: 'contest $field = $invalid',
          );
        }
      }

      for (final invalid in <Object?>[
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['contests'] = [
          contest()..['abbreviation'] = invalid,
        ];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'contest abbreviation = $invalid',
        );
      }

      final malformedAfterValid = source();
      firstProblem(malformedAfterValid)['contests'] = [
        contest(),
        contest()..['name'] = false,
      ];
      expect(() => endpoint.decode(malformedAfterValid), throwsFormatException);
    });

    test('preserves contest order, duplicates, nullable and raw values', () {
      final body =
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      final firstProblem =
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> firstContest() => {
        'id': -1.5,
        'displayId': ' 대회-α ',
        'name': ' 첫째 ',
        'abbreviation': ' 약칭 ',
        'futureContestField': true,
      };
      final sourceContests = <Map<String, dynamic>>[
        firstContest(),
        {'id': 0, 'displayId': '', 'name': '', 'abbreviation': null},
        firstContest(),
        {'id': 0.25, 'displayId': 'β', 'name': '마지막', 'abbreviation': ''},
      ];
      firstProblem['contests'] = sourceContests;

      final item = contract.searchProblems('sample').decode(body).items.first;
      final contests = item.contests!;
      expect(contests.map((contest) => contest.id), [-1.5, 0, -1.5, 0.25]);
      expect(contests.map((contest) => contest.displayId), [
        ' 대회-α ',
        '',
        ' 대회-α ',
        'β',
      ]);
      expect(contests.map((contest) => contest.name), [
        ' 첫째 ',
        '',
        ' 첫째 ',
        '마지막',
      ]);
      expect(contests.map((contest) => contest.abbreviation), [
        ' 약칭 ',
        null,
        ' 약칭 ',
        '',
      ]);

      sourceContests[0]['name'] = 'mutated';
      sourceContests.add({
        'id': 2,
        'displayId': 'later',
        'name': 'later',
        'abbreviation': null,
      });
      expect(contests.first.name, ' 첫째 ');
      expect(contests, hasLength(4));
      expect(() => contests.add(contests.first), throwsUnsupportedError);
      expect(() => contests[0] = contests[1], throwsUnsupportedError);
    });

    test('requires the documented full tag array and fields', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> tag() => {'id': 1, 'key': 'math', 'isMeta': false};

      final missing = source();
      firstProblem(missing).remove('tags');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        0,
        false,
        'tag',
        const <String, Object?>{},
      ]) {
        final malformed = source();
        firstProblem(malformed)['tags'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'tags = $invalid',
        );
      }

      final invalidItem = source();
      firstProblem(invalidItem)['tags'] = [0];
      expect(() => endpoint.decode(invalidItem), throwsFormatException);

      for (final field in ['id', 'key', 'isMeta']) {
        final malformed = source();
        firstProblem(malformed)['tags'] = [tag()..remove(field)];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'tag $field missing',
        );
      }

      for (final invalid in <Object?>[
        null,
        '1',
        false,
        const <String, Object?>{},
        const <Object>[],
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final malformed = source();
        firstProblem(malformed)['tags'] = [tag()..['id'] = invalid];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'tag id = $invalid',
        );
      }

      for (final invalid in <Object?>[
        null,
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['tags'] = [tag()..['key'] = invalid];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'tag key = $invalid',
        );
      }

      for (final invalid in <Object?>[
        null,
        0,
        'false',
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['tags'] = [tag()..['isMeta'] = invalid];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'tag isMeta = $invalid',
        );
      }

      final malformedAfterValid = source();
      firstProblem(malformedAfterValid)['tags'] = [
        tag(),
        tag()..['isMeta'] = 'false',
      ];
      expect(() => endpoint.decode(malformedAfterValid), throwsFormatException);
    });

    test('preserves full tag order, duplicates, flags, and raw values', () {
      final body =
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      final firstProblem =
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> firstTag() => {
        'id': -1.5,
        'key': ' 첫째 ',
        'isMeta': true,
        'futureTagField': true,
      };
      final sourceTags = <Map<String, dynamic>>[
        firstTag(),
        {'id': 0, 'key': '', 'isMeta': false},
        firstTag(),
      ];
      firstProblem['tags'] = sourceTags;

      final item = contract.searchProblems('sample').decode(body).items.first;
      final tags = item.tags!;
      expect(tags.map((tag) => tag.id), [-1.5, 0, -1.5]);
      expect(tags.map((tag) => tag.key), [' 첫째 ', '', ' 첫째 ']);
      expect(tags.map((tag) => tag.isMeta), [true, false, true]);
      expect(item.tagNames, [' 첫째 ', '', ' 첫째 ']);

      sourceTags[0]['key'] = 'mutated';
      sourceTags.add({'id': 2, 'key': 'later', 'isMeta': false});
      expect(tags.first.key, ' 첫째 ');
      expect(tags, hasLength(3));
      expect(() => tags.add(tags.first), throwsUnsupportedError);
      expect(() => tags[0] = tags[1], throwsUnsupportedError);
    });

    test('requires the documented viewer-folder array and fields', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> folder() => {
        'slug': 'folder',
        'name': 'Folder',
        'color': 'red',
      };

      final missing = source();
      firstProblem(missing).remove('viewerFolders');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        0,
        false,
        'folder',
        const <String, Object?>{},
      ]) {
        final malformed = source();
        firstProblem(malformed)['viewerFolders'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'viewerFolders = $invalid',
        );
      }

      final invalidItem = source();
      firstProblem(invalidItem)['viewerFolders'] = [0];
      expect(() => endpoint.decode(invalidItem), throwsFormatException);

      for (final field in ['slug', 'name', 'color']) {
        final malformed = source();
        firstProblem(malformed)['viewerFolders'] = [folder()..remove(field)];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'viewer folder $field missing',
        );
      }

      for (final field in ['slug', 'name']) {
        for (final invalid in <Object?>[
          null,
          0,
          false,
          const <String, Object?>{},
          const <Object>[],
        ]) {
          final malformed = source();
          firstProblem(malformed)['viewerFolders'] = [
            folder()..[field] = invalid,
          ];
          expect(
            () => endpoint.decode(malformed),
            throwsFormatException,
            reason: 'viewer folder $field = $invalid',
          );
        }
      }

      for (final invalid in <Object?>[
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
        '',
        ' ',
        'green',
        'Red',
        ' red ',
      ]) {
        final malformed = source();
        firstProblem(malformed)['viewerFolders'] = [
          folder()..['color'] = invalid,
        ];
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'viewer folder color = $invalid',
        );
      }

      final malformedAfterValid = source();
      firstProblem(malformedAfterValid)['viewerFolders'] = [
        folder(),
        folder()..['color'] = 'green',
      ];
      expect(() => endpoint.decode(malformedAfterValid), throwsFormatException);
    });

    test('preserves viewer-folder order, colors, and duplicates', () {
      final body =
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      final firstProblem =
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> firstFolder() => {
        'slug': ' 폴더-α ',
        'name': ' 첫째 ',
        'color': 'red',
        'futureFolderField': true,
      };
      final sourceFolders = <Map<String, dynamic>>[
        firstFolder(),
        {'slug': '', 'name': '', 'color': null},
        for (final color in [
          'violet',
          'blue',
          'teal',
          'lime',
          'yellow',
          'orange',
        ])
          {'slug': color, 'name': '이름-$color', 'color': color},
        firstFolder(),
      ];
      firstProblem['viewerFolders'] = sourceFolders;

      final item = contract.searchProblems('sample').decode(body).items.first;
      final folders = item.viewerFolders!;
      expect(folders.map((folder) => folder.slug), [
        ' 폴더-α ',
        '',
        'violet',
        'blue',
        'teal',
        'lime',
        'yellow',
        'orange',
        ' 폴더-α ',
      ]);
      expect(folders.first.name, ' 첫째 ');
      expect(folders[1].name, '');
      expect(folders.map((folder) => folder.color), [
        ProblemSearchViewerFolderColor.red,
        null,
        ProblemSearchViewerFolderColor.violet,
        ProblemSearchViewerFolderColor.blue,
        ProblemSearchViewerFolderColor.teal,
        ProblemSearchViewerFolderColor.lime,
        ProblemSearchViewerFolderColor.yellow,
        ProblemSearchViewerFolderColor.orange,
        ProblemSearchViewerFolderColor.red,
      ]);

      sourceFolders[0]['slug'] = 'mutated';
      sourceFolders.add({'slug': 'later', 'name': 'later', 'color': null});
      expect(folders.first.slug, ' 폴더-α ');
      expect(folders, hasLength(9));
      expect(() => folders.add(folders.first), throwsUnsupportedError);
      expect(() => folders[0] = folders[1], throwsUnsupportedError);
    });

    test('requires and preserves independent wire identifiers', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      for (final field in ['id', 'subId']) {
        final missing = source();
        firstProblem(missing).remove(field);
        expect(
          () => endpoint.decode(missing),
          throwsFormatException,
          reason: '$field missing',
        );
      }

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
        firstProblem(malformed)['id'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'id = $invalid',
        );
      }

      for (final invalid in <Object?>[
        null,
        0,
        true,
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['subId'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'subId = $invalid',
        );
      }

      final independent = source();
      firstProblem(independent)
        ..['id'] = -1.5
        ..['subId'] = ' 부분 식별자 ';
      final actual = endpoint.decode(independent).items.first;
      expect(actual.problemId, 1001);
      expect(actual.id, -1.5);
      expect(actual.subId, ' 부분 식별자 ');
    });

    test('requires the documented nullable user status in every problem', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      final missing = source();
      firstProblem(missing).remove('userStatus');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final entry
          in <String, ProblemUserStatus>{
            'solved': ProblemUserStatus.solved,
            'partial': ProblemUserStatus.partial,
            'tried': ProblemUserStatus.tried,
          }.entries) {
        final body = source();
        firstProblem(body)['userStatus'] = entry.key;
        expect(endpoint.decode(body).items.first.userStatus, entry.value);
      }

      for (final invalid in <Object>[
        '',
        'unknown',
        0,
        false,
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['userStatus'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'userStatus = $invalid',
        );
      }
    });

    test('requires finite level statistics without inventing bounds', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;
      Map<String, dynamic> lastProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).last as Map<String, dynamic>;

      for (final field in ['levelAverage', 'levelStdev']) {
        final missing = source();
        firstProblem(missing).remove(field);
        expect(
          () => endpoint.decode(missing),
          throwsFormatException,
          reason: '$field missing',
        );

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
          firstProblem(malformed)[field] = invalid;
          expect(
            () => endpoint.decode(malformed),
            throwsFormatException,
            reason: '$field = $invalid',
          );
        }

        final unbounded = source();
        firstProblem(unbounded)[field] = -1.5;
        lastProblem(unbounded)[field] = 0.25;
        final actual = endpoint.decode(unbounded);
        final firstValue =
            field == 'levelAverage'
                ? actual.items.first.levelAverage
                : actual.items.first.levelStdev;
        final lastValue =
            field == 'levelAverage'
                ? actual.items.last.levelAverage
                : actual.items.last.levelStdev;
        expect(firstValue, -1.5);
        expect(lastValue, 0.25);
      }
    });

    test('requires a boolean standard marker in every v4 problem', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      final missing = source();
      firstProblem(missing).remove('isStandard');
      expect(() => endpoint.decode(missing), throwsFormatException);

      for (final invalid in <Object?>[
        null,
        'true',
        1,
        const <String, Object?>{},
        const <Object>[],
      ]) {
        final malformed = source();
        firstProblem(malformed)['isStandard'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'isStandard = $invalid',
        );
      }
    });

    test('requires a finite effective-vote count without inventing bounds', () {
      final endpoint = contract.searchProblems('sample');
      Map<String, dynamic> source() =>
          jsonDecode(fixture('v4/search_problems.json'))
              as Map<String, dynamic>;
      Map<String, dynamic> firstProblem(Map<String, dynamic> body) =>
          (body['problems'] as List).first as Map<String, dynamic>;

      final missing = source();
      firstProblem(missing).remove('effectiveVoteCount');
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
        firstProblem(malformed)['effectiveVoteCount'] = invalid;
        expect(
          () => endpoint.decode(malformed),
          throwsFormatException,
          reason: 'effectiveVoteCount = $invalid',
        );
      }

      final unbounded = source();
      firstProblem(unbounded)['effectiveVoteCount'] = -1.5;
      final lastProblem =
          (unbounded['problems'] as List).last as Map<String, dynamic>;
      lastProblem['effectiveVoteCount'] = 0.25;
      final actual = endpoint.decode(unbounded);
      expect(actual.items.first.effectiveVoteCount, -1.5);
      expect(actual.items.last.effectiveVoteCount, 0.25);
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
              'id': 1001,
              'problemId': 1001.0,
              'subId': '',
              'level': 12.0,
              'levelAverage': 12,
              'levelStdev': 0,
              'isStandard': true,
              'userStatus': null,
              'votedUserCount': 0,
              'effectiveVoteCount': 0,
              'solvedUserCount': 0,
              'givesNoRating': false,
              'noRatingReasons': <Object>[],
              'noRatingWarnings': <Object>[],
              'titles': <Object>[],
              'contests': <Object>[],
              'tags': <Object>[],
              'viewerFolders': <Object>[],
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
                'id': 1001,
                'problemId': 1001.5,
                'subId': '',
                'level': 12,
                'levelAverage': 12,
                'levelStdev': 0,
                'isStandard': true,
                'userStatus': null,
                'votedUserCount': 0,
                'effectiveVoteCount': 0,
                'solvedUserCount': 0,
                'givesNoRating': false,
                'noRatingReasons': <Object>[],
                'noRatingWarnings': <Object>[],
                'titles': <Object>[],
                'contests': <Object>[],
                'tags': <Object>[],
                'viewerFolders': <Object>[],
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
    test('requires the documented catalog envelope', () {
      final endpoint = contract.searchTags('tag');

      expect(() => endpoint.decode(<String, dynamic>{}), throwsFormatException);
      for (final invalid in <Object?>[null, 0, 'tags', const <Object>{}]) {
        expect(
          () => endpoint.decode({'tags': invalid}),
          throwsFormatException,
          reason: 'tags = $invalid',
        );
      }
    });

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
      expect(keyMatch.items.single.id, 1);
      expect(keyMatch.items.single.isMeta, isFalse);
      expect(keyMatch.items.single.parents, ['math']);
      expect(keyMatch.items.single.names, {'ko': '정수론', 'en': 'Number Theory'});
      expect(keyMatch.items.single.aliases, ['NT']);
      expect(keyMatch.items.single.rated, isTrue);
    });

    test('selects Korean, English, deterministic fallback, then none', () {
      final actual = contract.searchTags('fallback').decode({
        'tags': [
          _v4CatalogTag(
            id: 1,
            key: 'fallback_korean',
            names: {'ja': '日本語', 'en': 'English', 'ko': ' 한국어 '},
          ),
          _v4CatalogTag(
            id: 2,
            key: 'fallback_english',
            names: {'ja': '日本語', 'ko': '', 'en': 'English'},
          ),
          _v4CatalogTag(
            id: 3,
            key: 'fallback_first',
            names: {'zh': '中文', 'ja': '最初'},
          ),
          _v4CatalogTag(
            id: 4,
            key: 'fallback_key_only',
            names: {'ko': '', 'en': '   '},
          ),
        ],
      });

      expect(actual.items.map((item) => (item.key, item.displayName)), [
        ('fallback_korean', '한국어'),
        ('fallback_english', 'English'),
        ('fallback_first', '最初'),
        ('fallback_key_only', null),
      ]);
      expect(actual.items.every((item) => item.problemCount == null), isTrue);
    });

    test('requires every documented catalog field and exact value shape', () {
      final endpoint = contract.searchTags('invalid');
      Map<String, dynamic> valid() => _v4CatalogTag(
        id: 1,
        key: 'invalid',
        parents: ['root'],
        names: {'ko': '정상'},
        aliases: ['alias'],
      );

      for (final field in [
        'id',
        'key',
        'isMeta',
        'parents',
        'names',
        'aliases',
        'rated',
      ]) {
        final tag = valid()..remove(field);
        expect(
          () => endpoint.decode({
            'tags': [tag],
          }),
          throwsFormatException,
          reason: 'missing $field',
        );
      }

      final invalidValues = <String, Object?>{
        'id': '1',
        'key': 1,
        'isMeta': 0,
        'parents': 'root',
        'names': <String>[],
        'aliases': {'alias': true},
        'rated': 'true',
      };
      for (final entry in invalidValues.entries) {
        final tag = valid()..[entry.key] = entry.value;
        expect(
          () => endpoint.decode({
            'tags': [tag],
          }),
          throwsFormatException,
          reason: '${entry.key} = ${entry.value}',
        );
      }

      for (final id in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          () => endpoint.decode({
            'tags': [valid()..['id'] = id],
          }),
          throwsFormatException,
          reason: 'id = $id',
        );
      }

      expect(
        () => endpoint.decode({
          'tags': [
            valid()..['parents'] = [1],
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode({
          'tags': [
            valid()..['aliases'] = [1],
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode({
          'tags': [
            valid()..['names'] = {'ko': '정상', 'later': 42},
          ],
        }),
        throwsFormatException,
      );
    });

    test(
      'validates unmatched and trailing catalog entries before filtering',
      () {
        final validMatch = _v4CatalogTag(
          id: 1,
          key: 'wanted',
          names: {'en': 'Wanted'},
        );
        final invalidUnmatched = _v4CatalogTag(
          id: 2,
          key: 'other',
          names: {'en': 'Other'},
        )..remove('rated');

        expect(
          () => contract.searchTags('wanted').decode({
            'tags': [validMatch, invalidUnmatched],
          }),
          throwsFormatException,
        );
      },
    );

    test(
      'preserves raw metadata and isolates immutable decoded collections',
      () {
        final parents = <String>[' parent ', '부모', ' parent '];
        final names = <String, String>{'ko': ' 한국어 ', ' x-custom ': ''};
        final aliases = <String>['', ' 별칭 ', ' 별칭 '];
        final sourceTag = _v4CatalogTag(
          id: -1.5,
          key: ' 태그 ',
          isMeta: true,
          parents: parents,
          names: names,
          aliases: aliases,
          rated: false,
        )..['future'] = {'kept': 'out of the model'};
        final duplicateTag = Map<String, dynamic>.from(sourceTag);
        final actual = contract.searchTags('').decode({
          'tags': [
            _v4CatalogTag(id: 2, key: '먼저', names: const {}),
            sourceTag,
            duplicateTag,
          ],
        });
        final item = actual.items[1];

        parents[0] = 'changed';
        names['ko'] = 'changed';
        aliases[0] = 'changed';
        sourceTag['parents'] = <String>[];
        sourceTag['names'] = <String, String>{};
        sourceTag['aliases'] = <String>[];

        expect(actual.items.map((item) => item.id), [2, -1.5, -1.5]);
        expect(actual.items.map((item) => item.key), ['먼저', ' 태그 ', ' 태그 ']);
        expect(actual.items.first.parents, isEmpty);
        expect(actual.items.first.names, isEmpty);
        expect(actual.items.first.aliases, isEmpty);
        expect(item.id, -1.5);
        expect(item.key, ' 태그 ');
        expect(item.isMeta, isTrue);
        expect(item.parents, [' parent ', '부모', ' parent ']);
        expect(item.names, {'ko': ' 한국어 ', ' x-custom ': ''});
        expect(item.aliases, ['', ' 별칭 ', ' 별칭 ']);
        expect(item.rated, isFalse);
        expect(item.displayName, '한국어');
        expect(() => item.parents!.add('blocked'), throwsUnsupportedError);
        expect(() => item.parents![0] = 'blocked', throwsUnsupportedError);
        expect(() => item.names!['ko'] = 'blocked', throwsUnsupportedError);
        expect(() => item.aliases!.add('blocked'), throwsUnsupportedError);
        expect(() => item.aliases![0] = 'blocked', throwsUnsupportedError);
      },
    );

    test('paginates filtered catalog results locally', () {
      final source = {
        'tags': List.generate(
          51,
          (index) => _v4CatalogTag(
            id: index,
            key: 'tag_$index',
            names: {'en': 'Tag $index'},
          ),
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

Map<String, dynamic> _v4CatalogTag({
  required num id,
  required String key,
  bool isMeta = false,
  List<String> parents = const [],
  required Map<String, String> names,
  List<String> aliases = const [],
  bool rated = true,
}) => {
  'id': id,
  'key': key,
  'isMeta': isMeta,
  'parents': parents,
  'names': names,
  'aliases': aliases,
  'rated': rated,
};
