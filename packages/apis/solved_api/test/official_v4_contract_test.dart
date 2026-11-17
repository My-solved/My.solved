import 'dart:convert';

import 'package:test/test.dart';

import 'helpers/fixture.dart';

void main() {
  late Map<String, dynamic> contract;

  setUpAll(() {
    contract = Map<String, dynamic>.from(
      jsonDecode(fixture('v4/official_openapi_contract.json')) as Map,
    );
  });

  test('pins the official production document and credential boundary', () {
    expect(contract['source'], 'https://backstage.solved.ac/api/v4/openapi');
    expect(contract['openapi'], '3.1.0');
    expect(contract['servers'], [
      {'url': 'https://solved.ac'},
    ]);
    expect(contract['security'], isNull);
    expect(contract['securitySchemes'], isNull);

    final info = _map(contract['info']);
    final description = info['description'] as String;
    expect(description, contains('x-client-id'));
    expect(description, contains('x-client-secret'));
    expect(description, contains('authorization code grant with PKCE'));
    expect(description, contains('S256 only'));
    expect(description, contains('600 units'));
    expect(description, contains('refilled at 2 per second'));
    expect(description, contains('one 200 times that'));
    expect(description, contains('Retry-After'));
  });

  test('records the complete path inventory and removed v3 paths', () {
    final allPaths = List<String>.from(contract['allPaths'] as List);

    expect(allPaths, hasLength(79));
    expect(allPaths, contains('/api/v4/me'));
    expect(allPaths, contains('/api/v4/users/{handle}'));
    expect(allPaths, contains('/api/v4/problems'));
    expect(allPaths, isNot(contains('/api/v4/user/show')));
    expect(allPaths, isNot(contains('/api/v4/user/grass')));
    expect(allPaths, isNot(contains('/api/v4/user/problem_stats')));
    expect(allPaths, isNot(contains('/api/v4/user/tag_ratings')));
    expect(allPaths, isNot(contains('/api/v4/search/problem')));
    expect(allPaths, isNot(contains('/api/v4/search/user')));
    expect(allPaths, isNot(contains('/api/v4/search/tag')));
    expect(allPaths, isNot(contains('/api/v4/background/show')));
    expect(allPaths, isNot(contains('/api/v4/badge/show')));
  });

  test('pins the authenticated identity and profile scope', () {
    final me = _get(contract, '/api/v4/me');

    expect(_accessClass(me), 'user');
    expect(_accessScope(me), 'profile');
    expect(_parameterNames(me), isEmpty);
    expect(me['description'], contains('never changes'));
    expect(me['description'], contains('handle can'));
    expect(_map(me['responses']).keys, containsAll(['200', '401']));
    final schema = _responseSchema(me);
    expect(_required(schema), ['id', 'handle']);
    expect(_map(_properties(schema)['id'])['type'], 'number');
    expect(_map(_properties(schema)['handle'])['type'], 'string');
  });

  test('pins the integrated public profile and contribution schemas', () {
    final profile = _get(contract, '/api/v4/users/{handle}');
    expect(_accessClass(profile), 'public');
    expect(_parameterNames(profile), ['handle', 'lang']);

    final profileSchema = _responseSchema(profile);
    expect(
      _required(profileSchema),
      containsAll([
        'tier',
        'bio',
        'rating',
        'solvedCount',
        'classPlus',
        'currentStreak',
        'maxStreak',
        'voteCount',
        'reputation',
        'noRatingSolvedCount',
        'background',
        'badge',
        'ratingByProblemsSum',
        'ratingByClass',
        'ratingBySolvedCount',
        'ratingProblemsHistogram',
        'tagRatings',
      ]),
    );
    final profileProperties = _properties(profileSchema);
    expect(_map(profileProperties['tier'])['type'], ['integer', 'null']);
    final bio = _map(profileProperties['bio']);
    expect(bio['type'], ['string', 'null']);
    for (final constraint in ['format', 'minLength', 'maxLength', 'pattern']) {
      expect(bio.containsKey(constraint), isFalse);
    }
    expect(_map(profileProperties['classPlus'])['type'], 'boolean');
    for (final field in [
      'currentStreak',
      'maxStreak',
      'noRatingSolvedCount',
    ]) {
      final property = _map(profileProperties[field]);
      expect(property['type'], 'integer');
      expect(property.containsKey('minimum'), isFalse);
    }
    expect(profileProperties.containsKey('overRating'), isFalse);

    final reputation = _get(contract, '/api/v4/users/{handle}/reputation');
    expect(_accessClass(reputation), 'public');
    expect(_parameterNames(reputation), ['handle', 'range']);
    expect(
      _required(_responseSchema(reputation)),
      containsAll([
        'reputation',
        'scoringCount',
        'helpfulCount',
        'vouchedCount',
        'history',
        'today',
      ]),
    );
  });

  test('pins the required activity range and sparse-day response', () {
    final activity = _get(contract, '/api/v4/users/{handle}/activity/days');
    expect(_accessClass(activity), 'public');
    expect(_parameterNames(activity), ['handle', 'from', 'to']);
    expect(
      _parameters(activity)
          .where((parameter) => parameter['required'] == true)
          .map((parameter) => parameter['name']),
      ['handle', 'from', 'to'],
    );
    final activitySchema = _responseSchema(activity);
    expect(
      _required(activitySchema),
      containsAll([
        'from',
        'to',
        'days',
        'currentStreak',
        'maxStreak',
        'theme',
        'firstActiveDay',
      ]),
    );
    final activityProperties = _properties(activitySchema);
    for (final field in ['currentStreak', 'maxStreak']) {
      final property = _map(activityProperties[field]);
      expect(property['type'], 'integer');
      expect(property['minimum'], 0);
    }
  });

  test('pins v4 problem and user search shapes', () {
    final problems = _get(contract, '/api/v4/problems');
    expect(_parameterNames(problems), [
      'page',
      'q',
      'sort',
      'direction',
      'seed',
    ]);
    expect(_required(_responseSchema(problems)), [
      'problems',
      'total',
      'page',
      'pageSize',
    ]);

    final users = _get(contract, '/api/v4/rankings/users/search');
    expect(_parameterNames(users), ['q', 'sort']);
    expect(_parameterNames(users), isNot(contains('page')));
    final usersSchema = _responseSchema(users);
    expect(_required(usersSchema), ['exact', 'items']);
    final userSearchProperties = _properties(usersSchema);
    final exactUser = _map(userSearchProperties['exact']);
    final listedUser = _map(
      _map(userSearchProperties['items'])['items'],
    );
    for (final userSchema in [exactUser, listedUser]) {
      expect(
        _required(userSchema),
        containsAll(['rank', 'globalRank', 'reputation']),
      );
      final properties = _properties(userSchema);
      final rank = _map(properties['rank']);
      expect(rank['type'], 'integer');
      for (final constraint in ['minimum', 'maximum', 'description']) {
        expect(rank.containsKey(constraint), isFalse);
      }
      final globalRank = _map(properties['globalRank']);
      expect(globalRank['type'], ['integer', 'null']);
      final reputation = _map(properties['reputation']);
      expect(reputation['type'], 'integer');
      expect(reputation.containsKey('minimum'), isFalse);
    }
  });

  test('pins the tag catalog and standalone asset lookup limitations', () {
    final tags = _get(contract, '/api/v4/tags');
    expect(_parameterNames(tags), isEmpty);
    final tagsSchema = _responseSchema(tags);
    final tagItem = _map(_map(_properties(tagsSchema)['tags'])['items']);
    expect(_required(tagItem), [
      'id',
      'key',
      'isMeta',
      'parents',
      'names',
      'aliases',
      'rated',
    ]);
    expect(_properties(tagItem).containsKey('problemCount'), isFalse);

    final item = _get(contract, '/api/v4/achievements/items/{kind}/{key}');
    expect(_parameterNames(item), ['kind', 'key', 'lang']);
    final kind = _parameters(item).first;
    expect(_map(kind['schema'])['enum'], ['badge', 'background']);
    expect(
      _required(_responseSchema(item)),
      containsAll(['kind', 'key', 'imageUrl', 'background']),
    );
  });
}

Map<String, dynamic> _get(Map<String, dynamic> contract, String path) {
  final paths = _map(contract['paths']);
  return _map(_map(paths[path])['get']);
}

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);

String _accessClass(Map<String, dynamic> operation) =>
    _map(operation['x-access'])['class'] as String;

String _accessScope(Map<String, dynamic> operation) =>
    _map(operation['x-access'])['scope'] as String;

List<Map<String, dynamic>> _parameters(Map<String, dynamic> operation) =>
    List<dynamic>.from(
      operation['parameters'] as List? ?? const [],
    ).map(_map).toList(growable: false);

List<String> _parameterNames(Map<String, dynamic> operation) => _parameters(
      operation,
    ).map((parameter) => parameter['name'] as String).toList(growable: false);

Map<String, dynamic> _responseSchema(Map<String, dynamic> operation) => _map(
      _map(
        _map(
          _map(_map(operation['responses'])['200'])['content'],
        )['application/json'],
      )['schema'],
    );

List<String> _required(Map<String, dynamic> schema) =>
    List<String>.from(schema['required'] as List? ?? const []);

Map<String, dynamic> _properties(Map<String, dynamic> schema) =>
    _map(schema['properties']);
