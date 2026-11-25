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
        'id',
        'tier',
        'profileImageUrl',
        'bio',
        'rating',
        'solvedCount',
        'classPlus',
        'currentStreak',
        'maxStreak',
        'streakVacation',
        'streakCountedToday',
        'streakFrozenYesterday',
        'streakTheme',
        'isRival',
        'isReverseRival',
        'ojAccounts',
        'linkedAccounts',
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
    expect(profileSchema.containsKey('additionalProperties'), isFalse);
    final profileProperties = _properties(profileSchema);
    expect(_map(profileProperties['id']), {'type': 'number'});
    expect(_map(profileProperties['voteCount']), {'type': 'integer'});
    expect(_map(profileProperties['tier']), {
      'type': ['integer', 'null'],
      'minimum': 0,
      'maximum': 31,
    });
    expect(_map(profileProperties['profileImageUrl'])['type'], [
      'string',
      'null',
    ]);
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
    final streakVacation = _map(profileProperties['streakVacation']);
    expect(streakVacation['type'], ['object', 'null']);
    expect(_required(streakVacation), ['fromDay', 'source']);
    expect(streakVacation.containsKey('additionalProperties'), isFalse);
    final streakVacationProperties = _properties(streakVacation);
    expect(_map(streakVacationProperties['fromDay']), {'type': 'string'});
    expect(_map(streakVacationProperties['source']), {
      'type': 'string',
      'enum': ['item', 'launch'],
    });
    for (final field in ['streakCountedToday', 'streakFrozenYesterday']) {
      expect(_map(profileProperties[field]), {'type': 'boolean'});
    }
    expect(_map(profileProperties['streakTheme']), {
      'type': ['string', 'null'],
    });
    expect(_map(profileProperties['isRival']), {'type': 'boolean'});
    expect(_map(profileProperties['isReverseRival']), {'type': 'boolean'});

    final ojAccounts = _map(profileProperties['ojAccounts']);
    expect(ojAccounts['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(ojAccounts.containsKey(constraint), isFalse);
    }
    final ojAccount = _map(ojAccounts['items']);
    expect(ojAccount['type'], 'object');
    expect(_required(ojAccount), [
      'ojId',
      'ojName',
      'handle',
      'profileUrl',
      'logoUrl',
      'verified',
    ]);
    expect(ojAccount.containsKey('additionalProperties'), isFalse);
    final ojAccountProperties = _properties(ojAccount);
    for (final field in ['ojId', 'ojName', 'handle']) {
      expect(_map(ojAccountProperties[field]), {'type': 'string'});
    }
    for (final field in ['profileUrl', 'logoUrl']) {
      expect(_map(ojAccountProperties[field]), {
        'type': ['string', 'null'],
        'format': 'uri',
      });
    }
    expect(_map(ojAccountProperties['verified']), {'type': 'boolean'});

    final linkedAccounts = _map(profileProperties['linkedAccounts']);
    expect(linkedAccounts['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(linkedAccounts.containsKey(constraint), isFalse);
    }
    final linkedAccount = _map(linkedAccounts['items']);
    expect(linkedAccount['type'], 'object');
    expect(_required(linkedAccount), ['provider', 'name', 'url']);
    expect(linkedAccount.containsKey('additionalProperties'), isFalse);
    final linkedAccountProperties = _properties(linkedAccount);
    expect(_map(linkedAccountProperties['provider']), {
      'type': 'string',
      'enum': ['discord', 'icpc'],
    });
    expect(_map(linkedAccountProperties['name']), {'type': 'string'});
    expect(_map(linkedAccountProperties['url']), {
      'type': 'string',
      'format': 'uri',
    });

    final background = _map(profileProperties['background']);
    expect(background['type'], ['object', 'null']);
    expect(_required(background), [
      'key',
      'backgroundImageUrl',
      'fallbackBackgroundImageUrl',
      'backgroundVideoUrl',
      'thumbnailPlaceholder',
      'isIllust',
      'displayName',
      'authors',
    ]);
    expect(background.containsKey('additionalProperties'), isFalse);
    final backgroundProperties = _properties(background);
    expect(_map(backgroundProperties['key']), {'type': 'string'});
    expect(_map(backgroundProperties['backgroundImageUrl']), {
      'type': 'string',
      'format': 'uri',
    });
    for (final field in [
      'fallbackBackgroundImageUrl',
      'backgroundVideoUrl',
    ]) {
      expect(_map(backgroundProperties[field]), {
        'type': ['string', 'null'],
        'format': 'uri',
      });
    }
    for (final field in ['thumbnailPlaceholder', 'displayName']) {
      expect(_map(backgroundProperties[field]), {
        'type': ['string', 'null'],
      });
    }
    expect(_map(backgroundProperties['isIllust']), {'type': 'boolean'});
    final authors = _map(backgroundProperties['authors']);
    expect(authors['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(authors.containsKey(constraint), isFalse);
    }
    final author = _map(authors['items']);
    expect(author['type'], 'object');
    expect(_required(author), [
      'key',
      'displayName',
      'role',
      'authorUrl',
      'handle',
      'twitter',
      'instagram',
    ]);
    expect(author.containsKey('additionalProperties'), isFalse);
    final authorProperties = _properties(author);
    for (final field in ['key', 'role']) {
      expect(_map(authorProperties[field]), {'type': 'string'});
    }
    for (final field in [
      'displayName',
      'authorUrl',
      'handle',
      'twitter',
      'instagram',
    ]) {
      expect(_map(authorProperties[field]), {
        'type': ['string', 'null'],
      });
    }

    final badge = _map(profileProperties['badge']);
    expect(badge['type'], ['object', 'null']);
    expect(_required(badge), ['key', 'name', 'imageUrl']);
    expect(badge.containsKey('additionalProperties'), isFalse);
    final badgeProperties = _properties(badge);
    for (final field in ['key', 'name', 'imageUrl']) {
      expect(_map(badgeProperties[field]), {'type': 'string'});
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
    expect(_required(activitySchema), [
      'from',
      'to',
      'days',
      'maxSolvedCount',
      'currentStreak',
      'maxStreak',
      'theme',
      'firstActiveDay',
      'vacation',
      'vacations',
      'countedToday',
      'frozenYesterday',
    ]);
    expect(activitySchema.containsKey('additionalProperties'), isFalse);
    final activityProperties = _properties(activitySchema);
    for (final field in ['from', 'to']) {
      expect(_map(activityProperties[field]), {'type': 'string'});
    }
    final days = _map(activityProperties['days']);
    expect(days['type'], 'array');
    for (final constraint in [
      'minItems',
      'maxItems',
      'uniqueItems',
      'additionalProperties',
    ]) {
      expect(days.containsKey(constraint), isFalse);
    }
    final dayItem = _map(days['items']);
    expect(dayItem['type'], 'object');
    expect(_required(dayItem), [
      'day',
      'solvedCount',
      'maxSolvedLevel',
      'ratingDelta',
      'freezeUsed',
      'streakRepaired',
    ]);
    expect(dayItem.containsKey('additionalProperties'), isFalse);
    final dayProperties = _properties(dayItem);
    expect(_map(dayProperties['day']), {
      'type': 'string',
      'pattern': r'^\d{4}-\d{2}-\d{2}$',
    });
    expect(_map(dayProperties['solvedCount']), {
      'type': 'integer',
      'minimum': 0,
    });
    expect(_map(dayProperties['maxSolvedLevel']), {
      'type': 'integer',
      'minimum': 0,
      'maximum': 30,
    });
    expect(_map(dayProperties['ratingDelta']), {'type': 'integer'});
    for (final field in ['freezeUsed', 'streakRepaired']) {
      expect(_map(dayProperties[field]), {'type': 'boolean'});
    }
    for (final field in ['maxSolvedCount', 'currentStreak', 'maxStreak']) {
      expect(_map(activityProperties[field]), {
        'type': 'integer',
        'minimum': 0,
      });
    }
    for (final field in ['theme', 'firstActiveDay']) {
      expect(_map(activityProperties[field]), {
        'type': ['string', 'null'],
      });
    }
    final vacation = _map(activityProperties['vacation']);
    expect(vacation['type'], ['object', 'null']);
    expect(_required(vacation), ['fromDay', 'source']);
    expect(vacation.containsKey('additionalProperties'), isFalse);
    final vacationProperties = _properties(vacation);
    expect(_map(vacationProperties['fromDay']), {'type': 'string'});
    expect(_map(vacationProperties['source']), {
      'type': 'string',
      'enum': ['item', 'launch'],
    });
    final vacations = _map(activityProperties['vacations']);
    expect(vacations['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(vacations.containsKey(constraint), isFalse);
    }
    final vacationItem = _map(vacations['items']);
    expect(_required(vacationItem), ['fromDay', 'untilDay']);
    expect(vacationItem.containsKey('additionalProperties'), isFalse);
    final vacationItemProperties = _properties(vacationItem);
    expect(_map(vacationItemProperties['fromDay']), {'type': 'string'});
    expect(_map(vacationItemProperties['untilDay']), {
      'type': ['string', 'null'],
    });
    for (final field in ['countedToday', 'frozenYesterday']) {
      expect(_map(activityProperties[field]), {'type': 'boolean'});
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
    final problemSchema = _responseSchema(problems);
    expect(_required(problemSchema), [
      'problems',
      'total',
      'page',
      'pageSize',
    ]);
    final problemResponseProperties = _properties(problemSchema);
    for (final field in ['total', 'page', 'pageSize']) {
      expect(_map(problemResponseProperties[field]), {'type': 'number'});
    }
    final diagnostics = _map(problemResponseProperties['diagnostics']);
    expect(diagnostics['type'], 'array');
    for (final constraint in [
      'minItems',
      'maxItems',
      'uniqueItems',
      'description',
    ]) {
      expect(diagnostics.containsKey(constraint), isFalse);
    }
    final diagnosticItem = _map(diagnostics['items']);
    expect(diagnosticItem['type'], 'object');
    expect(_required(diagnosticItem), [
      'start',
      'end',
      'severity',
      'code',
      'messageKey',
      'message',
    ]);
    expect(diagnosticItem.containsKey('additionalProperties'), isFalse);
    final diagnosticProperties = _properties(diagnosticItem);
    for (final field in ['start', 'end']) {
      expect(_map(diagnosticProperties[field]), {'type': 'number'});
    }
    expect(_map(diagnosticProperties['severity']), {
      'type': 'string',
      'enum': ['error', 'warning'],
    });
    expect(_map(diagnosticProperties['code']), {
      'type': 'string',
      'enum': [
        'unknown-filter',
        'unimplemented-filter',
        'empty-value',
        'invalid-value',
        'unknown-lang',
        'invalid-boolean',
        'unclosed-quote',
        'unmatched-paren',
        'dangling-operator',
        'ignored-input',
        'unknown-handle',
        'unknown-tag',
        'me-without-viewer',
      ],
    });
    for (final field in ['messageKey', 'message']) {
      expect(_map(diagnosticProperties[field]), {'type': 'string'});
    }
    final diagnosticData = _map(diagnosticProperties['data']);
    expect(diagnosticData['type'], 'object');
    expect(_map(diagnosticData['additionalProperties']), {'type': 'string'});
    expect(_map(problemResponseProperties['seed']), {'type': 'string'});
    final problemItem = _map(
      _map(problemResponseProperties['problems'])['items'],
    );
    expect(
      _required(problemItem),
      containsAll([
        'contests',
        'givesNoRating',
        'id',
        'isStandard',
        'effectiveVoteCount',
        'levelAverage',
        'levelStdev',
        'noRatingReasons',
        'noRatingWarnings',
        'userStatus',
        'votedUserCount',
        'solvedUserCount',
        'subId',
        'tags',
        'titles',
        'viewerFolders',
      ]),
    );
    final problemProperties = _properties(problemItem);
    expect(_map(problemProperties['id']), {'type': 'number'});
    expect(_map(problemProperties['subId']), {'type': 'string'});
    final titles = _map(problemProperties['titles']);
    expect(titles['type'], 'array');
    for (final constraint in [
      'minItems',
      'maxItems',
      'uniqueItems',
      'description',
    ]) {
      expect(titles.containsKey(constraint), isFalse);
    }
    final titleItem = _map(titles['items']);
    expect(titleItem['type'], 'object');
    expect(_required(titleItem), [
      'language',
      'title',
      'isOriginal',
      'latex',
      'html',
    ]);
    expect(titleItem.containsKey('additionalProperties'), isFalse);
    final titleProperties = _properties(titleItem);
    for (final field in ['language', 'title']) {
      expect(_map(titleProperties[field]), {'type': 'string'});
    }
    for (final field in ['isOriginal', 'latex', 'html']) {
      expect(_map(titleProperties[field]), {'type': 'boolean'});
    }
    final contests = _map(problemProperties['contests']);
    expect(contests['type'], 'array');
    for (final constraint in [
      'minItems',
      'maxItems',
      'uniqueItems',
      'description',
    ]) {
      expect(contests.containsKey(constraint), isFalse);
    }
    final contestItem = _map(contests['items']);
    expect(contestItem['type'], 'object');
    expect(_required(contestItem), [
      'id',
      'displayId',
      'name',
      'abbreviation',
    ]);
    expect(contestItem.containsKey('additionalProperties'), isFalse);
    final contestProperties = _properties(contestItem);
    expect(_map(contestProperties['id']), {'type': 'number'});
    for (final field in ['displayId', 'name']) {
      expect(_map(contestProperties[field]), {'type': 'string'});
    }
    expect(_map(contestProperties['abbreviation']), {
      'type': ['string', 'null'],
    });
    final tags = _map(problemProperties['tags']);
    expect(tags['type'], 'array');
    for (final constraint in [
      'minItems',
      'maxItems',
      'uniqueItems',
      'description',
    ]) {
      expect(tags.containsKey(constraint), isFalse);
    }
    final tagItem = _map(tags['items']);
    expect(tagItem['type'], 'object');
    expect(_required(tagItem), ['id', 'key', 'isMeta']);
    expect(tagItem.containsKey('additionalProperties'), isFalse);
    final tagProperties = _properties(tagItem);
    expect(_map(tagProperties['id']), {'type': 'number'});
    expect(_map(tagProperties['key']), {'type': 'string'});
    expect(_map(tagProperties['isMeta']), {'type': 'boolean'});
    final viewerFolders = _map(problemProperties['viewerFolders']);
    expect(viewerFolders['type'], 'array');
    for (final constraint in [
      'minItems',
      'maxItems',
      'uniqueItems',
      'description',
    ]) {
      expect(viewerFolders.containsKey(constraint), isFalse);
    }
    final viewerFolderItem = _map(viewerFolders['items']);
    expect(viewerFolderItem['type'], 'object');
    expect(_required(viewerFolderItem), ['slug', 'name', 'color']);
    expect(viewerFolderItem.containsKey('additionalProperties'), isFalse);
    final viewerFolderProperties = _properties(viewerFolderItem);
    for (final field in ['slug', 'name']) {
      expect(_map(viewerFolderProperties[field]), {'type': 'string'});
    }
    final viewerFolderColor = _map(viewerFolderProperties['color']);
    expect(viewerFolderColor['type'], ['string', 'null']);
    expect(viewerFolderColor['enum'], [
      'red',
      'violet',
      'blue',
      'teal',
      'lime',
      'yellow',
      'orange',
      null,
    ]);
    expect(_map(problemProperties['isStandard']), {'type': 'boolean'});
    final userStatus = _map(problemProperties['userStatus']);
    expect(userStatus['type'], ['string', 'null']);
    expect(userStatus['enum'], ['solved', 'partial', 'tried', null]);
    for (final field in ['levelAverage', 'levelStdev']) {
      final schema = _map(problemProperties[field]);
      expect(schema['type'], 'number');
      for (final constraint in [
        'minimum',
        'maximum',
        'multipleOf',
        'description',
      ]) {
        expect(schema.containsKey(constraint), isFalse);
      }
    }
    final votedUserCount = _map(problemProperties['votedUserCount']);
    expect(votedUserCount['type'], 'number');
    for (final constraint in [
      'minimum',
      'maximum',
      'multipleOf',
      'description',
    ]) {
      expect(votedUserCount.containsKey(constraint), isFalse);
    }
    final effectiveVoteCount = _map(problemProperties['effectiveVoteCount']);
    expect(effectiveVoteCount['type'], 'number');
    for (final constraint in [
      'minimum',
      'maximum',
      'multipleOf',
      'description',
    ]) {
      expect(effectiveVoteCount.containsKey(constraint), isFalse);
    }
    final solvedUserCount = _map(problemProperties['solvedUserCount']);
    expect(solvedUserCount['type'], 'number');
    for (final constraint in [
      'minimum',
      'maximum',
      'multipleOf',
      'description',
    ]) {
      expect(solvedUserCount.containsKey(constraint), isFalse);
    }
    expect(_map(problemProperties['givesNoRating'])['type'], 'boolean');
    final noRatingReasons = _map(problemProperties['noRatingReasons']);
    expect(noRatingReasons['type'], 'array');
    final noRatingReasonItem = _map(noRatingReasons['items']);
    expect(noRatingReasonItem['type'], 'string');
    expect(noRatingReasonItem['enum'], [
      'unofficial',
      'legacy',
      'staff',
      'unsettled',
    ]);
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(noRatingReasons.containsKey(constraint), isFalse);
    }
    final noRatingWarnings = _map(problemProperties['noRatingWarnings']);
    expect(noRatingWarnings['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(noRatingWarnings.containsKey(constraint), isFalse);
    }
    final noRatingWarning = _map(noRatingWarnings['items']);
    expect(noRatingWarning['type'], 'object');
    expect(_required(noRatingWarning), ['type', 'problem']);
    expect(noRatingWarning.containsKey('additionalProperties'), isFalse);
    final warningProperties = _properties(noRatingWarning);
    final warningType = _map(warningProperties['type']);
    expect(warningType['type'], 'string');
    expect(warningType['enum'], [
      'same',
      'searchable',
      'wrong-inputs',
      'insufficient-conditions',
      'no-special-judge',
      'wrong-conditions',
      'wrong-statement',
    ]);
    final warningProblem = _map(warningProperties['problem']);
    expect(warningProblem['type'], ['object', 'null']);
    expect(_required(warningProblem), [
      'problemId',
      'subId',
      'level',
      'effectiveVoteCount',
      'givesNoRating',
      'isStandard',
      'userStatus',
    ]);
    expect(warningProblem.containsKey('additionalProperties'), isFalse);
    final warningProblemProperties = _properties(warningProblem);
    for (final field in ['problemId', 'level', 'effectiveVoteCount']) {
      final property = _map(warningProblemProperties[field]);
      expect(property['type'], 'number');
      for (final constraint in ['minimum', 'maximum', 'multipleOf']) {
        expect(property.containsKey(constraint), isFalse);
      }
    }
    final warningSubId = _map(warningProblemProperties['subId']);
    expect(warningSubId['type'], 'string');
    for (final constraint in ['minLength', 'maxLength', 'pattern', 'format']) {
      expect(warningSubId.containsKey(constraint), isFalse);
    }
    for (final field in ['givesNoRating', 'isStandard']) {
      expect(_map(warningProblemProperties[field])['type'], 'boolean');
    }
    final warningUserStatus = _map(warningProblemProperties['userStatus']);
    expect(warningUserStatus['type'], ['string', 'null']);
    expect(warningUserStatus['enum'], ['solved', 'partial', 'tried', null]);

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
      expect(_required(userSchema), [
        'id',
        'handle',
        'tier',
        'profileImageUrl',
        'rank',
        'rating',
        'solvedCount',
        'voteCount',
        'reputation',
        'class',
        'classPlus',
        'tagRating',
        'globalRank',
        'page',
      ]);
      final properties = _properties(userSchema);
      expect(_map(properties['id']), {'type': 'number'});
      expect(_map(properties['tier']), {
        'type': ['integer', 'null'],
        'minimum': 0,
        'maximum': 31,
      });
      expect(_map(properties['profileImageUrl'])['type'], ['string', 'null']);
      for (final field in [
        'rank',
        'rating',
        'solvedCount',
        'voteCount',
        'reputation',
        'class',
        'page',
      ]) {
        expect(_map(properties[field]), {'type': 'integer'});
      }
      expect(_map(properties['classPlus'])['type'], 'boolean');
      for (final field in ['tagRating', 'globalRank']) {
        expect(_map(properties[field]), {
          'type': ['integer', 'null'],
        });
      }
    }
  });

  test('pins the tag catalog and standalone asset lookup limitations', () {
    final tags = _get(contract, '/api/v4/tags');
    expect(_parameterNames(tags), isEmpty);
    final tagsSchema = _responseSchema(tags);
    expect(_required(tagsSchema), ['tags']);
    final tagArray = _map(_properties(tagsSchema)['tags']);
    expect(tagArray['type'], 'array');
    for (final constraint in [
      'minItems',
      'maxItems',
      'uniqueItems',
      'description',
    ]) {
      expect(tagArray.containsKey(constraint), isFalse);
    }
    final tagItem = _map(tagArray['items']);
    expect(tagItem['type'], 'object');
    expect(_required(tagItem), [
      'id',
      'key',
      'isMeta',
      'parents',
      'names',
      'aliases',
      'rated',
    ]);
    expect(tagItem.containsKey('additionalProperties'), isFalse);
    final tagProperties = _properties(tagItem);
    expect(_map(tagProperties['id']), {'type': 'number'});
    expect(_map(tagProperties['key']), {'type': 'string'});
    for (final field in ['isMeta', 'rated']) {
      expect(_map(tagProperties[field]), {'type': 'boolean'});
    }
    for (final field in ['parents', 'aliases']) {
      final values = _map(tagProperties[field]);
      expect(values['type'], 'array');
      expect(_map(values['items']), {'type': 'string'});
    }
    final names = _map(tagProperties['names']);
    expect(names['type'], 'object');
    expect(_map(names['additionalProperties']), {'type': 'string'});
    expect(tagProperties.containsKey('problemCount'), isFalse);

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
