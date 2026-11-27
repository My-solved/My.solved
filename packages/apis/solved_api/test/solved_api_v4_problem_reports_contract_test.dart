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

  test('builds problem reports with omitted and explicit queries', () {
    final omitted = contract.problemReports(1000);
    final explicit = contract.problemReports(1, sub: '', page: 1);
    final raw = contract.problemReports(9007199254740991, sub: 'a b', page: 9);

    expect(omitted.direct.path, 'problems/1000/reports');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {'sub': '', 'page': '1'});
    expect(raw.direct.path, 'problems/9007199254740991/reports');
    expect(raw.direct.queryParameters, {'sub': 'a b', 'page': '9'});
    expect(raw.proxy.queryParameters, raw.direct.queryParameters);
  });

  test('rejects problem ids and pages below one', () {
    for (final id in [0, -1]) {
      expect(
        () => contract.problemReports(id),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'problemId')
              .having((error) => error.invalidValue, 'invalidValue', id),
        ),
      );
    }
    for (final page in [0, -1]) {
      expect(
        () => contract.problemReports(1, page: page),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
        ),
      );
    }
  });

  test('decodes the complete fixture with every reason variant', () {
    final actual = contract.problemReports(1).decode(
          jsonDecode(fixture('v4/problem_reports.json')),
        );

    expect(actual.total, -3);
    expect(actual.page, 2.0);
    expect(actual.pageSize, 10);
    expect(actual.items, hasLength(3));

    final first = actual.items[0];
    expect(first.id, 10);
    expect(first.user!.id, 1.5);
    expect(first.user!.handle, 'reporter');
    expect(first.user!.tier, 0);
    expect(first.user!.profileImageUrl, 'not necessarily a URI');
    expect(
      (first.reason as ProblemReportSameProblemReason).problemIds,
      [1, 1, 9007199254740991],
    );
    expect(first.sameProblems, hasLength(2));
    expect(first.sameProblems.first.problemId, 1000.5);
    expect(first.sameProblems.first.subId, '');
    expect(first.sameProblems.first.level, -1);
    expect(first.sameProblems.first.givesNoRating, isTrue);
    expect(first.sameProblems.first.isStandard, isFalse);
    expect(first.sameProblems.first.userStatus, isNull);
    expect(first.sameProblems.last.userStatus, ProblemUserStatus.tried);
    expect(first.comment, '');
    expect(first.status, ProblemReportStatus.accepted);
    expect(first.statusChange!.by!.tier, isNull);
    expect(first.statusChange!.by!.profileImageUrl, isNull);
    expect(first.statusChange!.at, 'not a date');
    expect(first.statusChange!.comment, isNull);
    expect(first.createdAt, 'not a date');

    final second = actual.items[1];
    expect(second.id, -1.25);
    expect(second.user, isNull);
    expect((second.reason as ProblemReportIssueReason).url, 'not a URI');
    expect(second.sameProblems, isEmpty);
    expect(second.comment, 'raw / 한 글');
    expect(second.status, ProblemReportStatus.pending);
    expect(second.statusChange, isNull);

    final third = actual.items[2];
    expect(
      (third.reason as ProblemReportIssueResolvedReason).problemReportId,
      10,
    );
    expect(third.status, ProblemReportStatus.resolved);
    expect(third.statusChange!.by, isNull);
    expect(third.statusChange!.comment, 'done');
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.problemReports(1);
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['items', 'total', 'page', 'pageSize']) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(_response()..[field] = null),
        throwsFormatException,
      );
    }
    for (final field in _reportFields) {
      final missing = _response();
      _item(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _item(nulled)[field] = null;
      if (field == 'user' || field == 'statusChange') {
        final report = endpoint.decode(nulled).items.first;
        expect(field == 'user' ? report.user : report.statusChange, isNull);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final field in ['by', 'at', 'comment']) {
      final missing = _response();
      (_item(missing)['statusChange'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    final atNull = _response();
    (_item(atNull)['statusChange'] as Map<String, dynamic>)['at'] = null;
    expect(() => endpoint.decode(atNull), throwsFormatException);
    for (final field in ['id', 'handle', 'tier', 'profileImageUrl']) {
      final missing = _response();
      (_item(missing)['user'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final field in _sameProblemFields) {
      final missing = _response();
      _sameProblem(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'sameProblems[].$field missing',
      );
      if (field != 'userStatus') {
        final nulled = _response();
        _sameProblem(nulled)[field] = null;
        expect(() => endpoint.decode(nulled), throwsFormatException);
      }
    }
  });

  test('discriminates reasons exactly and enforces documented bounds', () {
    final endpoint = contract.problemReports(1);
    for (final reason in <Map<String, Object?>>[
      {
        'problemIds': <Object?>[1]
      },
      {
        'type': 'Same-Problem',
        'problemIds': <Object?>[1]
      },
      {'type': 'unknown'},
      {'type': 'same-problem'},
      {'type': 'same-problem', 'problemIds': <Object?>[]},
      {'type': 'same-problem', 'problemIds': List<Object?>.filled(21, 1)},
      {
        'type': 'same-problem',
        'problemIds': <Object?>[0],
      },
      {
        'type': 'same-problem',
        'problemIds': <Object?>[1.0],
      },
      {'type': 'issue'},
      {'type': 'issue', 'url': null},
      {'type': 'issue', 'url': List.filled(513, 'a').join()},
      {'type': 'issue-resolved'},
      {'type': 'issue-resolved', 'problemReportId': 0},
      {'type': 'issue-resolved', 'problemReportId': 1.0},
    ]) {
      final body = _response();
      _item(body)['reason'] = reason;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: '$reason',
      );
    }
    ProblemReportReason decodeReason(Map<String, Object?> reason) {
      final body = _response();
      _item(body)['reason'] = reason;
      return endpoint.decode(body).items.first.reason;
    }

    for (final count in [1, 20]) {
      final reason = decodeReason({
        'type': 'same-problem',
        'problemIds': List<Object?>.filled(count, 7),
      });
      expect(
        (reason as ProblemReportSameProblemReason).problemIds,
        List.filled(count, 7),
      );
    }
    for (final url in ['', List.filled(512, '🌏').join()]) {
      final reason = decodeReason({'type': 'issue', 'url': url});
      expect((reason as ProblemReportIssueReason).url, url);
    }
    final resolved = decodeReason({
      'type': 'issue-resolved',
      'problemReportId': 1,
      'extra': true,
    });
    expect(
      (resolved as ProblemReportIssueResolvedReason).problemReportId,
      1,
    );
    for (final status in ProblemReportStatus.values) {
      final body = _response();
      _item(body)['status'] = status.value;
      expect(endpoint.decode(body).items.first.status, status);
    }
    for (final invalid in <Object?>['Pending', 'open', 0]) {
      final body = _response();
      _item(body)['status'] = invalid;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final tier in <Object?>[-1, 32, 1.0]) {
      final body = _response();
      (_item(body)['user'] as Map<String, dynamic>)['tier'] = tier;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final field in ['problemId', 'level', 'effectiveVoteCount']) {
      final body = _response();
      _sameProblem(body)[field] = double.nan;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    final status = _response();
    _sameProblem(status)['userStatus'] = 'Solved';
    expect(() => endpoint.decode(status), throwsFormatException);
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.problemReports(1);
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final problemIds = (_item(body)['reason'] as Map)['problemIds'] as List;
    final sameProblems = _item(body)['sameProblems'] as List<dynamic>;
    final actual = endpoint.decode(body);
    problemIds.clear();
    sameProblems.clear();
    items.clear();

    final reason = actual.items.first.reason as ProblemReportSameProblemReason;
    expect(actual.items, hasLength(3));
    expect(reason.problemIds, [1, 1, 9007199254740991]);
    expect(actual.items.first.sameProblems, hasLength(2));
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(() => reason.problemIds.clear(), throwsUnsupportedError);
    expect(
      () => actual.items.first.sameProblems.clear(),
      throwsUnsupportedError,
    );
    expect(
      endpoint
          .decode(_response()
            ..['items'] = <Object?>[]
            ..['future'] = true)
          .items,
      isEmpty,
    );
  });
}

const _reportFields = [
  'id',
  'user',
  'reason',
  'sameProblems',
  'comment',
  'status',
  'statusChange',
  'createdAt',
];

const _sameProblemFields = [
  'problemId',
  'subId',
  'level',
  'effectiveVoteCount',
  'givesNoRating',
  'isStandard',
  'userStatus',
];

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/problem_reports.json')) as Map<String, dynamic>;

Map<String, dynamic> _item(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;

Map<String, dynamic> _sameProblem(Map<String, dynamic> body) =>
    (_item(body)['sameProblems'] as List<dynamic>).first
        as Map<String, dynamic>;
