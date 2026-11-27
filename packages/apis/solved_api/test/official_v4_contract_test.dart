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
    expect(allPaths, contains('/api/v4/users/{handle}/badge-stand'));
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

    const profileFields = [
      'id',
      'handle',
      'tier',
      'profileImageUrl',
      'bio',
      'rating',
      'solvedCount',
      'voteCount',
      'reputation',
      'maxStreak',
      'currentStreak',
      'streakVacation',
      'streakCountedToday',
      'streakFrozenYesterday',
      'noRatingSolvedCount',
      'streakTheme',
      'background',
      'isRival',
      'isReverseRival',
      'ojAccounts',
      'linkedAccounts',
      'affiliations',
      'class',
      'classPlus',
      'badge',
      'ratingByProblemsSum',
      'ratingByClass',
      'ratingBySolvedCount',
      'ratingProblemsCutoff',
      'ratingProblemsHistogram',
      'bans',
      'tagRatings',
      'metadata',
    ];
    expect(profileFields, hasLength(33));
    final profileSchema = _responseSchema(profile);
    expect(_required(profileSchema), profileFields);
    expect(profileSchema.containsKey('additionalProperties'), isFalse);
    final profileProperties = _properties(profileSchema);
    expect(profileProperties.keys.toList(growable: false), profileFields);
    expect(_map(profileProperties['id']), {'type': 'number'});
    expect(_map(profileProperties['handle']), {'type': 'string'});
    expect(_map(profileProperties['tier']), {
      'type': ['integer', 'null'],
      'minimum': 0,
      'maximum': 31,
    });
    expect(_map(profileProperties['profileImageUrl']), {
      'type': ['string', 'null'],
      'format': 'uri',
    });
    final bio = _map(profileProperties['bio']);
    expect(bio['type'], ['string', 'null']);
    for (final constraint in ['format', 'minLength', 'maxLength', 'pattern']) {
      expect(bio.containsKey(constraint), isFalse);
    }
    expect(_map(profileProperties['classPlus'])['type'], 'boolean');
    expect(_map(profileProperties['class']), {
      'type': 'integer',
      'minimum': 0,
      'maximum': 10,
    });
    for (final field in [
      'rating',
      'solvedCount',
      'voteCount',
      'reputation',
      'maxStreak',
      'currentStreak',
      'noRatingSolvedCount',
      'ratingByProblemsSum',
      'ratingByClass',
      'ratingBySolvedCount',
      'ratingProblemsCutoff',
    ]) {
      expect(_map(profileProperties[field]), {'type': 'integer'});
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

    final affiliations = _map(profileProperties['affiliations']);
    expect(affiliations['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(affiliations.containsKey(constraint), isFalse);
    }
    final affiliation = _map(affiliations['items']);
    expect(affiliation['type'], 'object');
    expect(_required(affiliation), [
      'id',
      'affiliationId',
      'name',
      'type',
      'logoThumbnailUrl',
      'color',
    ]);
    expect(affiliation.containsKey('additionalProperties'), isFalse);
    final affiliationProperties = _properties(affiliation);
    for (final field in ['id', 'affiliationId']) {
      expect(_map(affiliationProperties[field]), {'type': 'number'});
    }
    expect(_map(affiliationProperties['name']), {'type': 'string'});
    expect(_map(affiliationProperties['type']), {
      'type': 'string',
      'enum': [
        'undefined',
        'university',
        'high_school',
        'middle_school',
        'elementary_school',
        'company',
        'community',
      ],
    });
    for (final field in ['logoThumbnailUrl', 'color']) {
      expect(_map(affiliationProperties[field]), {
        'type': ['string', 'null'],
      });
    }

    final bans = _map(profileProperties['bans']);
    expect(bans['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(bans.containsKey(constraint), isFalse);
    }
    final ban = _map(bans['items']);
    expect(ban['type'], 'object');
    expect(_required(ban), ['banType', 'banReason', 'reason', 'until']);
    expect(ban.containsKey('additionalProperties'), isFalse);
    final banProperties = _properties(ban);
    expect(_map(banProperties['banType']), {
      'type': 'string',
      'enum': ['rating', 'vote'],
    });
    expect(_map(banProperties['banReason']), {
      'type': ['string', 'null'],
      'enum': [
        'vote_troll_level',
        'vote_hate_speech',
        'vote_disparagement',
        'vote_profanity',
        'vote_multi_account',
        'vote_repeat_offence',
        'rating_copied_code',
        'other',
        'rating_auto_pace',
        'vote_automated',
        'vote_comment_strikes',
        'vote_mark_abuse',
        null,
      ],
    });
    for (final field in ['reason', 'until']) {
      expect(_map(banProperties[field]), {'type': 'string'});
    }

    final metadata = _map(profileProperties['metadata']);
    expect(metadata['type'], 'object');
    expect(_required(metadata), [
      'countryCode',
      'pronouns',
      'name',
      'nameNative',
      'birthday',
    ]);
    expect(metadata.containsKey('additionalProperties'), isFalse);
    final metadataProperties = _properties(metadata);
    for (final field in ['countryCode', 'pronouns', 'name', 'nameNative']) {
      expect(_map(metadataProperties[field]), {
        'type': ['string', 'null'],
      });
    }
    final birthday = _map(metadataProperties['birthday']);
    expect(birthday['type'], ['object', 'null']);
    expect(_required(birthday), ['year', 'month', 'day']);
    expect(birthday.containsKey('additionalProperties'), isFalse);
    final birthdayProperties = _properties(birthday);
    for (final field in ['year', 'month', 'day']) {
      expect(_map(birthdayProperties[field]), {
        'type': ['integer', 'null'],
      });
    }

    final ratingProblemsHistogram =
        _map(profileProperties['ratingProblemsHistogram']);
    expect(ratingProblemsHistogram['type'], 'array');
    expect(_map(ratingProblemsHistogram['items']), {'type': 'integer'});
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(ratingProblemsHistogram.containsKey(constraint), isFalse);
    }

    final tagRatings = _map(profileProperties['tagRatings']);
    expect(tagRatings['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(tagRatings.containsKey(constraint), isFalse);
    }
    final tagRating = _map(tagRatings['items']);
    expect(tagRating['type'], 'object');
    const tagRatingFields = [
      'key',
      'rating',
      'solvedCount',
      'ratingByProblemsSum',
      'ratingBySolvedCount',
      'ratingProblemsCutoff',
    ];
    expect(_required(tagRating), tagRatingFields);
    expect(tagRating.containsKey('additionalProperties'), isFalse);
    final tagRatingProperties = _properties(tagRating);
    expect(
      tagRatingProperties.keys.toList(growable: false),
      tagRatingFields,
    );
    expect(_map(tagRatingProperties['key']), {'type': 'string'});
    for (final field in tagRatingFields.skip(1)) {
      expect(_map(tagRatingProperties[field]), {'type': 'integer'});
    }

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
    final range = _parameters(reputation).singleWhere(
      (parameter) => parameter['name'] == 'range',
    );
    expect(range['in'], 'query');
    expect(range['required'], isFalse);
    expect(_map(range['schema']), {
      'type': 'string',
      'enum': ['90d', '1y', 'all'],
    });

    final reputationSchema = _responseSchema(reputation);
    expect(_required(reputationSchema), [
      'reputation',
      'scoringCount',
      'helpfulCount',
      'vouchedCount',
      'history',
      'today',
    ]);
    expect(reputationSchema.containsKey('additionalProperties'), isFalse);
    final reputationProperties = _properties(reputationSchema);
    for (final field in [
      'reputation',
      'scoringCount',
      'helpfulCount',
      'vouchedCount',
    ]) {
      expect(_map(reputationProperties[field]), {'type': 'integer'});
    }

    final history = _map(reputationProperties['history']);
    expect(history['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(history.containsKey(constraint), isFalse);
    }
    final historyItem = _map(history['items']);
    expect(historyItem['type'], 'object');
    expect(_required(historyItem), ['day', 'value']);
    expect(historyItem.containsKey('additionalProperties'), isFalse);
    final historyProperties = _properties(historyItem);
    expect(_map(historyProperties['day']), {
      'type': 'string',
      'pattern': r'^\d{4}-\d{2}-\d{2}$',
    });
    expect(_map(historyProperties['value']), {'type': 'integer'});

    final today = _map(reputationProperties['today']);
    expect(today['type'], 'object');
    expect(_required(today), ['contributions', 'helpful']);
    expect(today.containsKey('additionalProperties'), isFalse);
    final todayProperties = _properties(today);
    final contributions = _map(todayProperties['contributions']);
    expect(contributions['type'], 'object');
    expect(_required(contributions), ['count', 'max']);
    expect(contributions.containsKey('additionalProperties'), isFalse);
    final contributionProperties = _properties(contributions);
    expect(_map(contributionProperties['count']), {'type': 'integer'});
    expect(_map(contributionProperties['max']), {'type': 'integer'});
    final helpful = _map(todayProperties['helpful']);
    expect(helpful['type'], 'object');
    expect(_required(helpful), ['earned', 'cap']);
    expect(helpful.containsKey('additionalProperties'), isFalse);
    final helpfulProperties = _properties(helpful);
    expect(_map(helpfulProperties['earned']), {'type': 'integer'});
    expect(_map(helpfulProperties['cap']), {'type': 'integer'});

    final ratingHistory =
        _get(contract, '/api/v4/users/{handle}/rating/history');
    expect(_accessClass(ratingHistory), 'public');
    expect(_parameterNames(ratingHistory), ['handle', 'range']);
    final ratingHistoryParameters = _parameters(ratingHistory);
    expect(_map(ratingHistoryParameters.first['schema']), {
      'type': 'string',
      'minLength': 1,
      'maxLength': 64,
    });
    expect(ratingHistoryParameters.first['required'], isTrue);
    final ratingHistoryRange = ratingHistoryParameters.last;
    expect(ratingHistoryRange['in'], 'query');
    expect(ratingHistoryRange['required'], isFalse);
    expect(_map(ratingHistoryRange['schema']), {
      'type': 'string',
      'enum': ['90d', '1y', 'all'],
    });
    expect(_map(ratingHistoryRange['schema']).containsKey('default'), isFalse);

    final ratingHistorySchema = _responseSchema(ratingHistory);
    expect(_required(ratingHistorySchema), ['history']);
    expect(ratingHistorySchema.containsKey('additionalProperties'), isFalse);
    final ratingHistoryProperties = _properties(ratingHistorySchema);
    final ratingHistoryItems = _map(ratingHistoryProperties['history']);
    expect(ratingHistoryItems['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(ratingHistoryItems.containsKey(constraint), isFalse);
    }
    final ratingHistoryItem = _map(ratingHistoryItems['items']);
    expect(ratingHistoryItem['type'], 'object');
    expect(_required(ratingHistoryItem), ['day', 'value']);
    expect(ratingHistoryItem.containsKey('additionalProperties'), isFalse);
    final ratingHistoryItemProperties = _properties(ratingHistoryItem);
    expect(_map(ratingHistoryItemProperties['day']), {
      'type': 'string',
      'pattern': r'^\d{4}-\d{2}-\d{2}$',
    });
    expect(_map(ratingHistoryItemProperties['value']), {'type': 'integer'});
  });

  test('pins the public user-tag level histogram without inference', () {
    final histogram =
        _get(contract, '/api/v4/users/{handle}/tags/{key}/histogram');

    expect(_map(histogram['x-access']), {'class': 'public'});
    expect(_parameterNames(histogram), ['handle', 'key']);
    final parameters = _parameters(histogram);
    for (final parameter in parameters) {
      expect(parameter['in'], 'path');
      expect(parameter['required'], isTrue);
      expect(_map(parameter['schema']), {
        'type': 'string',
        'minLength': 1,
        'maxLength': 64,
      });
    }
    expect(
      _map(histogram['responses']).keys,
      unorderedEquals(['200', '404']),
    );

    final schema = _responseSchema(histogram);
    expect(_required(schema), ['key', 'histogram']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys, unorderedEquals(['key', 'histogram']));
    expect(_map(properties['key']), {'type': 'string'});
    final buckets = _map(properties['histogram']);
    expect(buckets['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(buckets.containsKey(constraint), isFalse);
    }
    final bucket = _map(buckets['items']);
    expect(bucket, {'type': 'integer'});
    for (final constraint in ['minimum', 'maximum', 'multipleOf']) {
      expect(bucket.containsKey(constraint), isFalse);
    }
  });

  test('pins the public achievement catalog and shared reward shape', () {
    final catalog = _get(contract, '/api/v4/achievements');

    expect(_accessClass(catalog), 'public');
    expect(catalog.containsKey('requestBody'), isFalse);
    expect(_parameterNames(catalog), ['lang']);
    final language = _parameters(catalog).single;
    expect(language['in'], 'query');
    expect(language['required'], isFalse);
    expect(_map(language['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });
    expect(_map(catalog['responses']).keys.toList(), ['200']);
    expect(
      _map(_map(catalog['responses'])['200'])['description'],
      'The catalog.',
    );

    final schema = _responseSchema(catalog);
    expect(schema['type'], 'object');
    expect(_required(schema), ['items', 'userCount']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys.toList(growable: false), ['items', 'userCount']);
    expect(_map(properties['userCount']), {
      'minimum': 0,
      'type': 'integer',
    });

    final items = _map(properties['items']);
    expect(items['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(items.containsKey(constraint), isFalse);
    }
    final item = _map(items['items']);
    const itemFields = [
      'id',
      'key',
      'series',
      'seriesOrder',
      'historic',
      'hidden',
      'name',
      'condition',
      'searchQuery',
      'shopKey',
      'rewards',
      'holderCount',
      'earnedAt',
      'progress',
    ];
    expect(item['type'], 'object');
    expect(_required(item), itemFields);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(itemProperties.keys.toList(growable: false), [
      'condition',
      'earnedAt',
      'hidden',
      'historic',
      'holderCount',
      'id',
      'key',
      'name',
      'progress',
      'rewards',
      'searchQuery',
      'series',
      'seriesOrder',
      'shopKey',
    ]);
    for (final field in ['id', 'seriesOrder', 'holderCount']) {
      expect(_map(itemProperties[field]), {'type': 'integer'});
    }
    for (final field in ['key', 'series', 'name']) {
      expect(_map(itemProperties[field]), {'type': 'string'});
    }
    for (final field in ['historic', 'hidden']) {
      expect(_map(itemProperties[field]), {'type': 'boolean'});
    }
    for (final field in [
      'condition',
      'searchQuery',
      'shopKey',
      'earnedAt',
    ]) {
      expect(_map(itemProperties[field]), {
        'type': ['string', 'null'],
      });
    }

    final progress = _map(itemProperties['progress']);
    expect(progress['type'], ['object', 'null']);
    expect(_required(progress), ['current', 'target']);
    expect(progress.containsKey('additionalProperties'), isFalse);
    final progressProperties = _properties(progress);
    expect(progressProperties.keys.toList(growable: false), [
      'current',
      'target',
    ]);
    for (final field in ['current', 'target']) {
      expect(_map(progressProperties[field]), {'type': 'integer'});
    }

    final rewards = _map(itemProperties['rewards']);
    expect(rewards['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(rewards.containsKey(constraint), isFalse);
    }
    final reward = _map(rewards['items']);
    const rewardFields = [
      'kind',
      'id',
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
    ];
    expect(reward['type'], 'object');
    expect(_required(reward), rewardFields);
    expect(reward.containsKey('additionalProperties'), isFalse);
    final rewardProperties = _properties(reward);
    expect(rewardProperties.keys.toList(growable: false), [
      'addedAt',
      'category',
      'id',
      'imageUrl',
      'key',
      'kind',
      'name',
    ]);
    expect(_map(rewardProperties['kind']), {
      'enum': ['badge', 'background'],
      'type': 'string',
    });
    expect(_map(rewardProperties['id']), {'type': 'integer'});
    for (final field in ['key', 'name', 'imageUrl', 'category', 'addedAt']) {
      expect(_map(rewardProperties[field]), {'type': 'string'});
    }
  });

  test('pins problem achievements and their exact shared reward shape', () {
    final operation =
        _get(contract, '/api/v4/achievements/for-problem/{problemId}');

    expect(_accessClass(operation), 'public');
    expect(operation.containsKey('requestBody'), isFalse);
    expect(
      operation['summary'],
      'What solving a problem earns or counts toward',
    );
    expect(_parameterNames(operation), ['problemId', 'lang']);
    final parameters = _parameters(operation);
    expect(parameters.first['in'], 'path');
    expect(parameters.first['required'], isTrue);
    expect(_map(parameters.first['schema']), {
      'exclusiveMinimum': 0,
      'type': 'integer',
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });
    expect(_map(operation['responses']).keys.toList(), ['200']);
    expect(
      _map(_map(operation['responses'])['200'])['description'],
      'Open, unhidden achievements; what it earns first.',
    );

    final schema = _responseSchema(operation);
    expect(schema['type'], 'object');
    expect(_required(schema), ['items']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys.toList(growable: false), ['items']);

    final items = _map(properties['items']);
    expect(items['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(items.containsKey(constraint), isFalse);
    }
    final item = _map(items['items']);
    const itemFields = [
      'key',
      'name',
      'condition',
      'rewards',
      'holderCount',
      'earnedAt',
      'relation',
      'byLevel',
    ];
    expect(item['type'], 'object');
    expect(_required(item), itemFields);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(itemProperties.keys.toList(growable: false), [
      'byLevel',
      'condition',
      'earnedAt',
      'holderCount',
      'key',
      'name',
      'relation',
      'rewards',
    ]);
    for (final field in ['key', 'name']) {
      expect(_map(itemProperties[field]), {'type': 'string'});
    }
    for (final field in ['condition', 'earnedAt']) {
      expect(_map(itemProperties[field]), {
        'type': ['string', 'null'],
      });
    }
    expect(_map(itemProperties['holderCount']), {'type': 'integer'});
    expect(_map(itemProperties['byLevel']), {'type': 'boolean'});
    expect(_map(itemProperties['relation']), {
      'enum': ['unlocks', 'counts'],
      'type': 'string',
    });

    final rewards = _map(itemProperties['rewards']);
    expect(rewards['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(rewards.containsKey(constraint), isFalse);
    }
    final reward = _map(rewards['items']);
    const rewardFields = [
      'kind',
      'id',
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
    ];
    expect(reward['type'], 'object');
    expect(_required(reward), rewardFields);
    expect(reward.containsKey('additionalProperties'), isFalse);
    final rewardProperties = _properties(reward);
    expect(rewardProperties.keys.toList(growable: false), [
      'addedAt',
      'category',
      'id',
      'imageUrl',
      'key',
      'kind',
      'name',
    ]);
    expect(_map(rewardProperties['kind']), {
      'enum': ['badge', 'background'],
      'type': 'string',
    });
    expect(_map(rewardProperties['id']), {'type': 'integer'});
    for (final field in ['key', 'name', 'imageUrl', 'category', 'addedAt']) {
      expect(_map(rewardProperties[field]), {'type': 'string'});
    }
  });

  test('pins user achievements as the catalog base plus required vs', () {
    final operation =
        _get(contract, '/api/v4/users/{handle}/achievements');

    expect(_accessClass(operation), 'public');
    expect(operation.containsKey('requestBody'), isFalse);
    expect(
      operation['summary'],
      "Every achievement with a user's standing, or two users'",
    );
    expect(_parameterNames(operation), ['handle', 'lang', 'vs']);
    final parameters = _parameters(operation);
    expect(parameters.first['in'], 'path');
    expect(parameters.first['required'], isTrue);
    expect(_map(parameters.first['schema']), {
      'maxLength': 64,
      'minLength': 1,
      'type': 'string',
    });
    expect(parameters[1]['in'], 'query');
    expect(parameters[1]['required'], isFalse);
    expect(_map(parameters[1]['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'maxLength': 64,
      'minLength': 1,
      'type': 'string',
    });

    final responses = _map(operation['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(
      _map(responses['200'])['description'],
      'The catalog, as the user (and `vs`) stand on it.',
    );
    expect(_map(responses['404'])['description'], 'No such user.');

    final schema = _responseSchema(operation);
    expect(schema['type'], 'object');
    expect(_required(schema), ['handle', 'vsHandle', 'items', 'userCount']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys.toList(growable: false), [
      'handle',
      'items',
      'userCount',
      'vsHandle',
    ]);
    expect(_map(properties['handle']), {'type': 'string'});
    expect(_map(properties['vsHandle']), {
      'type': ['string', 'null'],
    });
    expect(_map(properties['userCount']), {
      'minimum': 0,
      'type': 'integer',
    });

    final items = _map(properties['items']);
    expect(items['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(items.containsKey(constraint), isFalse);
    }
    final item = _map(items['items']);
    const itemFields = [
      'id',
      'key',
      'series',
      'seriesOrder',
      'historic',
      'hidden',
      'name',
      'condition',
      'searchQuery',
      'shopKey',
      'rewards',
      'holderCount',
      'earnedAt',
      'progress',
      'vs',
    ];
    expect(item['type'], 'object');
    expect(_required(item), itemFields);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(itemProperties.keys.toList(growable: false), [
      'condition',
      'earnedAt',
      'hidden',
      'historic',
      'holderCount',
      'id',
      'key',
      'name',
      'progress',
      'rewards',
      'searchQuery',
      'series',
      'seriesOrder',
      'shopKey',
      'vs',
    ]);

    final catalog = _get(contract, '/api/v4/achievements');
    final catalogItems = _map(_properties(_responseSchema(catalog))['items']);
    final catalogItem = _map(catalogItems['items']);
    final userBaseProperties = Map<String, dynamic>.from(itemProperties)
      ..remove('vs');
    expect(userBaseProperties, _properties(catalogItem));
    expect(
      _required(item).where((field) => field != 'vs').toList(),
      _required(catalogItem),
    );

    final versus = _map(itemProperties['vs']);
    expect(versus['type'], ['object', 'null']);
    expect(_required(versus), ['earnedAt']);
    expect(versus.containsKey('additionalProperties'), isFalse);
    final versusProperties = _properties(versus);
    expect(versusProperties.keys.toList(growable: false), ['earnedAt']);
    expect(_map(versusProperties['earnedAt']), {
      'type': ['string', 'null'],
    });

    final notFound = _map(responses['404']);
    final notFoundContent = _map(notFound['content']);
    expect(notFoundContent.keys.toList(growable: false), [
      'application/json',
    ]);
    final notFoundSchema = _map(
      _map(notFoundContent['application/json'])['schema'],
    );
    expect(notFoundSchema['type'], 'object');
    expect(_required(notFoundSchema), ['error']);
    expect(notFoundSchema.containsKey('additionalProperties'), isFalse);
    final error = _map(_properties(notFoundSchema)['error']);
    expect(error['type'], 'object');
    expect(_required(error), ['code', 'message']);
    expect(error.containsKey('additionalProperties'), isFalse);
    final errorProperties = _properties(error);
    expect(errorProperties.keys.toList(growable: false), [
      'code',
      'details',
      'message',
    ]);
    expect(_map(errorProperties['code']), {'type': 'string'});
    expect(_map(errorProperties['message']), {'type': 'string'});
    final details = _map(errorProperties['details']);
    expect(details['type'], 'object');
    expect(details.containsKey('required'), isFalse);
    expect(_map(details['additionalProperties']), {
      'anyOf': [
        {'type': 'string'},
        {'type': 'number'},
        {'type': 'boolean'},
      ],
    });
  });

  test('pins the public achievement summary schema without inference', () {
    final summary =
        _get(contract, '/api/v4/users/{handle}/achievements/summary');

    expect(_accessClass(summary), 'public');
    expect(_parameterNames(summary), ['handle', 'lang']);
    final parameters = _parameters(summary);
    expect(parameters.first['in'], 'path');
    expect(parameters.first['required'], isTrue);
    expect(_map(parameters.first['schema']), {
      'maxLength': 64,
      'minLength': 1,
      'type': 'string',
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });
    expect(_map(summary['responses']).keys, containsAll(['200', '404']));

    final schema = _responseSchema(summary);
    expect(_required(schema), [
      'earned',
      'total',
      'past',
      'badges',
      'backgrounds',
      'recent',
    ]);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(
        properties.keys,
        unorderedEquals([
          'backgrounds',
          'badges',
          'earned',
          'past',
          'recent',
          'total',
        ]));
    for (final field in [
      'earned',
      'total',
      'past',
      'badges',
      'backgrounds',
    ]) {
      expect(_map(properties[field]), {'type': 'integer'});
    }

    final recent = _map(properties['recent']);
    expect(recent['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(recent.containsKey(constraint), isFalse);
    }
    final item = _map(recent['items']);
    expect(item['type'], 'object');
    expect(_required(item), [
      'kind',
      'id',
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
      'acquiredAt',
    ]);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(
        itemProperties.keys,
        unorderedEquals([
          'acquiredAt',
          'addedAt',
          'category',
          'id',
          'imageUrl',
          'key',
          'kind',
          'name',
        ]));
    expect(_map(itemProperties['kind']), {
      'enum': ['badge', 'background'],
      'type': 'string',
    });
    expect(_map(itemProperties['id']), {'type': 'integer'});
    for (final field in [
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
      'acquiredAt',
    ]) {
      expect(_map(itemProperties[field]), {'type': 'string'});
    }
  });

  test('pins the public badge stand schema without inference', () {
    final badgeStand = _get(contract, '/api/v4/users/{handle}/badge-stand');

    expect(_accessClass(badgeStand), 'public');
    expect(_parameterNames(badgeStand), ['handle', 'lang']);
    final parameters = _parameters(badgeStand);
    expect(parameters.first['in'], 'path');
    expect(parameters.first['required'], isTrue);
    expect(_map(parameters.first['schema']), {
      'maxLength': 64,
      'minLength': 1,
      'type': 'string',
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });
    expect(_map(badgeStand['responses']).keys, containsAll(['200', '404']));

    final schema = _responseSchema(badgeStand);
    expect(_required(schema), ['chosen', 'badges']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys, unorderedEquals(['badges', 'chosen']));
    expect(_map(properties['chosen']), {'type': 'boolean'});

    final badges = _map(properties['badges']);
    expect(badges['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(badges.containsKey(constraint), isFalse);
    }
    final item = _map(badges['items']);
    expect(item['type'], 'object');
    expect(_required(item), [
      'kind',
      'id',
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
      'holderCount',
    ]);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(
      itemProperties.keys,
      unorderedEquals([
        'addedAt',
        'category',
        'holderCount',
        'id',
        'imageUrl',
        'key',
        'kind',
        'name',
      ]),
    );
    expect(_map(itemProperties['kind']), {
      'enum': ['badge', 'background'],
      'type': 'string',
    });
    for (final field in ['id', 'holderCount']) {
      expect(_map(itemProperties[field]), {'type': 'integer'});
    }
    for (final field in [
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
    ]) {
      expect(_map(itemProperties[field]), {'type': 'string'});
    }
  });

  test('pins the public problem detail schema without inference', () {
    final problemDetail = _get(contract, '/api/v4/problems/{problemId}');

    expect(_accessClass(problemDetail), 'public');
    expect(_accessScope(problemDetail), 'solves');
    expect(_parameterNames(problemDetail), ['problemId', 'sub']);
    final parameters = _parameters(problemDetail);
    expect(parameters.first['in'], 'path');
    expect(parameters.first['required'], isTrue);
    expect(_map(parameters.first['schema']), {
      'minimum': 1,
      'type': 'integer',
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'default': '',
      'type': 'string',
    });
    expect(
      _map(problemDetail['responses']).keys,
      unorderedEquals(['200', '404']),
    );

    const fields = [
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
    final schema = _responseSchema(problemDetail);
    expect(_required(schema), fields);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys, unorderedEquals(fields));
    for (final field in [
      'id',
      'problemId',
      'level',
      'levelAverage',
      'levelStdev',
      'votedUserCount',
      'effectiveVoteCount',
      'solvedUserCount',
    ]) {
      expect(_map(properties[field]), {'type': 'number'});
    }
    expect(_map(properties['subId']), {'type': 'string'});
    for (final field in ['isStandard', 'givesNoRating']) {
      expect(_map(properties[field]), {'type': 'boolean'});
    }
    expect(_map(properties['userStatus']), {
      'enum': ['solved', 'partial', 'tried', null],
      'type': ['string', 'null'],
    });

    Map<String, dynamic> arrayItem(String field) {
      final array = _map(properties[field]);
      expect(array['type'], 'array');
      for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
        expect(array.containsKey(constraint), isFalse);
      }
      return _map(array['items']);
    }

    expect(arrayItem('noRatingReasons'), {
      'enum': ['unofficial', 'legacy', 'staff', 'unsettled'],
      'type': 'string',
    });

    final warning = arrayItem('noRatingWarnings');
    expect(warning['type'], 'object');
    expect(_required(warning), ['type', 'problem']);
    expect(warning.containsKey('additionalProperties'), isFalse);
    final warningProperties = _properties(warning);
    expect(_map(warningProperties['type']), {
      'enum': [
        'same',
        'searchable',
        'wrong-inputs',
        'insufficient-conditions',
        'no-special-judge',
        'wrong-conditions',
        'wrong-statement',
      ],
      'type': 'string',
    });
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
    for (final field in [
      'problemId',
      'level',
      'effectiveVoteCount',
    ]) {
      expect(_map(warningProblemProperties[field]), {'type': 'number'});
    }
    expect(_map(warningProblemProperties['subId']), {'type': 'string'});
    for (final field in ['givesNoRating', 'isStandard']) {
      expect(_map(warningProblemProperties[field]), {'type': 'boolean'});
    }
    expect(_map(warningProblemProperties['userStatus']), {
      'enum': ['solved', 'partial', 'tried', null],
      'type': ['string', 'null'],
    });

    final title = arrayItem('titles');
    expect(title['type'], 'object');
    expect(_required(title), [
      'language',
      'title',
      'isOriginal',
      'latex',
      'html',
    ]);
    expect(title.containsKey('additionalProperties'), isFalse);
    final titleProperties = _properties(title);
    for (final field in ['language', 'title']) {
      expect(_map(titleProperties[field]), {'type': 'string'});
    }
    for (final field in ['isOriginal', 'latex', 'html']) {
      expect(_map(titleProperties[field]), {'type': 'boolean'});
    }

    final contest = arrayItem('contests');
    expect(contest['type'], 'object');
    expect(_required(contest), ['id', 'displayId', 'name', 'abbreviation']);
    expect(contest.containsKey('additionalProperties'), isFalse);
    final contestProperties = _properties(contest);
    expect(_map(contestProperties['id']), {'type': 'number'});
    for (final field in ['displayId', 'name']) {
      expect(_map(contestProperties[field]), {'type': 'string'});
    }
    expect(_map(contestProperties['abbreviation']), {
      'type': ['string', 'null'],
    });

    final tag = arrayItem('tags');
    expect(tag['type'], 'object');
    expect(_required(tag), ['id', 'key', 'isMeta']);
    expect(tag.containsKey('additionalProperties'), isFalse);
    final tagProperties = _properties(tag);
    expect(_map(tagProperties['id']), {'type': 'number'});
    expect(_map(tagProperties['key']), {'type': 'string'});
    expect(_map(tagProperties['isMeta']), {'type': 'boolean'});

    final ojLink = arrayItem('ojLinks');
    expect(ojLink['type'], 'object');
    expect(_required(ojLink), [
      'ojId',
      'ojName',
      'nativeProblemId',
      'url',
      'logoUrl',
    ]);
    expect(ojLink.containsKey('additionalProperties'), isFalse);
    final ojLinkProperties = _properties(ojLink);
    for (final field in ['ojId', 'ojName', 'nativeProblemId', 'url']) {
      expect(_map(ojLinkProperties[field]), {'type': 'string'});
    }
    expect(_map(ojLinkProperties['logoUrl']), {
      'type': ['string', 'null'],
    });
    for (final field in ['url', 'logoUrl']) {
      expect(_map(ojLinkProperties[field]).containsKey('format'), isFalse);
    }
  });

  test('pins public problem reports and their reason union', () {
    final reports = _get(contract, '/api/v4/problems/{problemId}/reports');

    expect(_accessClass(reports), 'public');
    expect(_map(reports['x-access']).containsKey('scope'), isFalse);
    expect(reports.containsKey('security'), isFalse);
    expect(reports.containsKey('requestBody'), isFalse);
    expect(
      reports['summary'],
      "A problem's reports, newest first (page size 10)",
    );
    expect(_parameters(reports), [
      {
        'in': 'path',
        'name': 'problemId',
        'required': true,
        'schema': {'minimum': 1, 'type': 'integer'},
      },
      {
        'in': 'query',
        'name': 'sub',
        'required': false,
        'schema': {'default': '', 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'page',
        'required': false,
        'schema': {'default': 1, 'minimum': 1, 'type': 'integer'},
      },
    ]);
    final responses = _map(reports['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(
      _map(responses['200'])['description'],
      'One page of reports, with the staff decision on each.',
    );
    expect(_map(responses['404'])['description'], 'Problem not found.');
    expect(
      _jsonResponseSchema(reports, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    final schema = _responseSchema(reports);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), ['items', 'total', 'page', 'pageSize']);
    final properties = _properties(schema);
    expect(properties.keys.length, 4);
    for (final field in ['total', 'page', 'pageSize']) {
      expect(_map(properties[field]), {'type': 'number'});
    }
    final item = _map(_map(properties['items'])['items']);
    expect(item['type'], 'object');
    expect(item.containsKey('additionalProperties'), isFalse);
    expect(_required(item), [
      'id',
      'user',
      'reason',
      'sameProblems',
      'comment',
      'status',
      'statusChange',
      'createdAt',
    ]);
    final itemProperties = _properties(item);
    expect(itemProperties.keys.length, 8);
    expect(_map(itemProperties['id']), {'type': 'number'});
    expect(_map(itemProperties['comment']), {'type': 'string'});
    expect(_map(itemProperties['createdAt']), {'type': 'string'});
    expect(_map(itemProperties['status']), {
      'enum': ['pending', 'accepted', 'rejected', 'resolved'],
      'type': 'string',
    });

    final owner = _map(
      _properties(_map(_map(_properties(_responseSchema(
        _get(contract, '/api/v4/bookmarks'),
      ))['folders'])['items']))['owner'],
    );
    final nullableUser = {
      ...owner,
      'type': ['object', 'null'],
    };
    expect(_map(itemProperties['user']), nullableUser);
    expect(_map(itemProperties['statusChange']), {
      'properties': {
        'at': {'type': 'string'},
        'by': nullableUser,
        'comment': {
          'type': ['string', 'null'],
        },
      },
      'required': ['by', 'at', 'comment'],
      'type': ['object', 'null'],
    });
    expect(_map(itemProperties['reason']), {
      'oneOf': [
        {
          'properties': {
            'problemIds': {
              'items': {'exclusiveMinimum': 0, 'type': 'integer'},
              'maxItems': 20,
              'minItems': 1,
              'type': 'array',
            },
            'type': {
              'enum': ['same-problem'],
              'type': 'string',
            },
          },
          'required': ['type', 'problemIds'],
          'type': 'object',
        },
        {
          'properties': {
            'type': {
              'enum': ['issue'],
              'type': 'string',
            },
            'url': {'format': 'uri', 'maxLength': 512, 'type': 'string'},
          },
          'required': ['type', 'url'],
          'type': 'object',
        },
        {
          'properties': {
            'problemReportId': {'exclusiveMinimum': 0, 'type': 'integer'},
            'type': {
              'enum': ['issue-resolved'],
              'type': 'string',
            },
          },
          'required': ['type', 'problemReportId'],
          'type': 'object',
        },
      ],
    });
    expect(_map(itemProperties['sameProblems']), {
      'items': {
        'properties': {
          'effectiveVoteCount': {'type': 'number'},
          'givesNoRating': {'type': 'boolean'},
          'isStandard': {'type': 'boolean'},
          'level': {'type': 'number'},
          'problemId': {'type': 'number'},
          'subId': {'type': 'string'},
          'userStatus': {
            'enum': ['solved', 'partial', 'tried', null],
            'type': ['string', 'null'],
          },
        },
        'required': [
          'problemId',
          'subId',
          'level',
          'effectiveVoteCount',
          'givesNoRating',
          'isStandard',
          'userStatus',
        ],
        'type': 'object',
      },
      'type': 'array',
    });
  });

  test('pins public problem votes and their official auth failures', () {
    final votes = _get(contract, '/api/v4/problems/{problemId}/votes');
    final reports = _get(contract, '/api/v4/problems/{problemId}/reports');

    expect(_accessClass(votes), 'public');
    expect(_map(votes['x-access']).containsKey('scope'), isFalse);
    expect(votes.containsKey('security'), isFalse);
    expect(votes.containsKey('requestBody'), isFalse);
    expect(votes['summary'], 'Paginated votes (page size fixed at 30)');
    expect(_parameters(votes), [
      ..._parameters(reports),
      {
        'in': 'query',
        'name': 'sort',
        'required': false,
        'schema': {
          'default': 'recent',
          'enum': ['recent', 'level', 'weight'],
          'type': 'string',
        },
      },
    ]);
    final responses = _map(votes['responses']);
    expect(responses.keys.toList(growable: false), [
      '200',
      '401',
      '403',
      '404',
    ]);
    expect(_map(responses['200'])['description'], 'One page of votes.');
    expect(_map(responses['401'])['description'], 'Sign in required.');
    expect(
      _map(responses['403'])['description'],
      "Viewer hasn't solved this problem.",
    );
    expect(_map(responses['404'])['description'], 'Problem not found.');
    for (final status in ['401', '403', '404']) {
      expect(
        _jsonResponseSchema(votes, status),
        _jsonResponseSchema(reports, '404'),
        reason: status,
      );
    }

    final schema = _responseSchema(votes);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'items',
      'total',
      'page',
      'pageSize',
      'sort',
      'markRefusal',
      'unhelpfulLocked',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 7);
    for (final field in ['total', 'page', 'pageSize']) {
      expect(_map(properties[field]), {'type': 'number'});
    }
    expect(_map(properties['sort']), {
      'enum': ['recent', 'level', 'weight'],
      'type': 'string',
    });
    expect(_map(properties['markRefusal']), {
      'enum': [
        'UNAUTHENTICATED',
        'REPUTATION_TOO_LOW',
        'TIER_TOO_LOW',
        'ACCOUNT_TOO_NEW',
        'NOT_SOLVED',
        'BANNED',
        null,
      ],
      'type': ['string', 'null'],
    });
    expect(_map(properties['unhelpfulLocked']), {'type': 'boolean'});

    final vote = _map(_map(properties['items'])['items']);
    expect(vote['type'], 'object');
    expect(vote.containsKey('additionalProperties'), isFalse);
    expect(_required(vote), [
      'id',
      'user',
      'votedAt',
      'level',
      'weight',
      'invalidated',
      'notInCalculation',
      'banned',
      'superseded',
      'cutoff',
      'comment',
      'commentLanguage',
      'emoticonId',
      'emoticon',
      'source',
      'tags',
      'isStandard',
      'marks',
    ]);
    final voteProperties = _properties(vote);
    expect(voteProperties.keys.length, 18);
    final reportItem = _map(
      _map(_properties(_responseSchema(reports))['items'])['items'],
    );
    expect(voteProperties['user'], _properties(reportItem)['user']);
    expect(_map(voteProperties['id']), {'type': 'number'});
    expect(_map(voteProperties['weight']), {'type': 'number'});
    expect(_map(voteProperties['level']), {
      'type': ['number', 'null'],
    });
    for (final field in ['votedAt', 'source']) {
      expect(_map(voteProperties[field]), {'type': 'string'});
    }
    for (final field in [
      'invalidated',
      'notInCalculation',
      'banned',
      'superseded',
      'cutoff',
      'isStandard',
    ]) {
      expect(_map(voteProperties[field]), {'type': 'boolean'});
    }
    for (final field in ['comment', 'commentLanguage', 'emoticonId']) {
      expect(_map(voteProperties[field]), {
        'type': ['string', 'null'],
      });
    }
    expect(_map(voteProperties['emoticon']), {
      'properties': {
        'key': {'type': 'string'},
        'url': {'type': 'string'},
      },
      'required': ['key', 'url'],
      'type': ['object', 'null'],
    });
    final searchTag = _map(_map(_properties(_map(_map(_properties(
      _responseSchema(_get(contract, '/api/v4/problems')),
    )['problems'])['items']))['tags'])['items']);
    expect(_map(voteProperties['tags']), {
      'items': {
        'properties': {
          'legacyKey': {
            'type': ['string', 'null'],
          },
          'tag': {
            ...searchTag,
            'type': ['object', 'null'],
          },
        },
        'required': ['tag', 'legacyKey'],
        'type': 'object',
      },
      'type': 'array',
    });
    expect(_map(voteProperties['marks']), {
      'properties': {
        'counts': {
          'properties': {
            'helpful': {'type': 'integer'},
            'unhelpful': {'type': 'integer'},
          },
          'required': ['helpful', 'unhelpful'],
          'type': ['object', 'null'],
        },
        'mine': {
          'enum': ['helpful', 'unhelpful', null],
          'type': ['string', 'null'],
        },
        'own': {'type': 'boolean'},
        'score': {'type': 'integer'},
      },
      'required': ['score', 'counts', 'mine', 'own'],
      'type': ['object', 'null'],
    });
  });

  test('pins the viewer vote to the shared vote item shape', () {
    final mine = _get(contract, '/api/v4/problems/{problemId}/votes/me');
    final votes = _get(contract, '/api/v4/problems/{problemId}/votes');

    expect(_accessClass(mine), 'user');
    expect(_accessScope(mine), 'votes');
    expect(mine.containsKey('security'), isFalse);
    expect(mine.containsKey('requestBody'), isFalse);
    expect(
      mine['summary'],
      "Viewer's own vote on this problem (null if none)",
    );
    expect(_parameters(mine), _parameters(votes).take(2).toList());
    final responses = _map(mine['responses']);
    expect(responses.keys.toList(growable: false), [
      '200',
      '401',
      '403',
      '404',
    ]);
    expect(_map(responses['200'])['description'], "Viewer's vote.");
    for (final status in ['401', '403', '404']) {
      expect(
        _map(responses[status]),
        _map(_map(votes['responses'])[status]),
        reason: status,
      );
    }

    final schema = _responseSchema(mine);
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), ['vote']);
    expect(_properties(schema).keys.toList(growable: false), ['vote']);
    final vote = _map(_properties(schema)['vote']);
    final item =
        _map(_map(_properties(_responseSchema(votes))['items'])['items']);
    expect(vote, {
      ...item,
      'type': ['object', 'null'],
    });
  });

  test('pins the public vote summary and its shared shapes', () {
    final summary = _get(
      contract,
      '/api/v4/problems/{problemId}/votes/summary',
    );
    final votes = _get(contract, '/api/v4/problems/{problemId}/votes');

    expect(_accessClass(summary), 'public');
    expect(_map(summary['x-access']).containsKey('scope'), isFalse);
    expect(summary.containsKey('security'), isFalse);
    expect(summary.containsKey('requestBody'), isFalse);
    expect(
      summary['summary'],
      'Per-problem vote summary (time-series points + aggregate stats)',
    );
    expect(_parameters(summary), _parameters(votes).take(2).toList());
    final responses = _map(summary['responses']);
    expect(responses.keys.toList(growable: false), [
      '200',
      '401',
      '403',
      '404',
    ]);
    expect(
      _map(responses['200'])['description'],
      'Points and aggregate figures for the vote graph.',
    );
    for (final status in ['401', '403', '404']) {
      expect(
        _map(responses[status]),
        _map(_map(votes['responses'])[status]),
        reason: status,
      );
    }

    final schema = _responseSchema(summary);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), ['items', 'tagDistribution']);
    final properties = _properties(schema);
    expect(properties.keys.length, 2);
    final voteProperties = _properties(
      _map(_map(_properties(_responseSchema(votes))['items'])['items']),
    );
    const pointFields = [
      'votedAt',
      'level',
      'weight',
      'invalidated',
      'notInCalculation',
      'banned',
      'cutoff',
    ];
    expect(_map(properties['items']), {
      'items': {
        'properties': {
          for (final field in [...pointFields]..sort())
            field: voteProperties[field],
        },
        'required': pointFields,
        'type': 'object',
      },
      'type': 'array',
    });
    final searchTag = _map(_map(_properties(_map(_map(_properties(
      _responseSchema(_get(contract, '/api/v4/problems')),
    )['problems'])['items']))['tags'])['items']);
    expect(_map(properties['tagDistribution']), {
      'items': {
        'properties': {
          'count': {'type': 'number'},
          'denominator': {'type': 'number'},
          'tag': searchTag,
        },
        'required': ['tag', 'count', 'denominator'],
        'type': 'object',
      },
      'type': 'array',
    });
  });

  test('pins the public random-problem operation and complete schema', () {
    final randomProblem = _get(
      contract,
      '/api/v4/search/random-problem',
    );

    expect(_map(randomProblem['x-access']), {'class': 'public'});
    expect(_parameterNames(randomProblem), ['q']);
    final parameter = _parameters(randomProblem).single;
    expect(parameter['in'], 'query');
    expect(parameter['required'], isFalse);
    expect(_map(parameter['schema']), {
      'maxLength': 1000,
      'type': 'string',
    });
    expect(
      _map(randomProblem['responses']).keys,
      unorderedEquals(['200', '404']),
    );

    const fields = [
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
    final schema = _responseSchema(randomProblem);
    expect(schema['type'], 'object');
    expect(_required(schema), fields);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys, unorderedEquals(fields));

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
      expect(_map(properties[field]), {'type': 'number'});
    }
    expect(_map(properties['subId']), {'type': 'string'});
    for (final field in ['isStandard', 'givesNoRating']) {
      expect(_map(properties[field]), {'type': 'boolean'});
    }
    expect(_map(properties['userStatus']), {
      'enum': ['solved', 'partial', 'tried', null],
      'type': ['string', 'null'],
    });

    const arrayFields = [
      'noRatingReasons',
      'noRatingWarnings',
      'titles',
      'contests',
      'tags',
      'viewerFolders',
    ];
    for (final field in arrayFields) {
      final array = _map(properties[field]);
      expect(array['type'], 'array');
      for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
        expect(array.containsKey(constraint), isFalse);
      }
    }

    final warning = _map(_map(properties['noRatingWarnings'])['items']);
    final warningProblem = _map(_properties(warning)['problem']);
    expect(warningProblem['type'], ['object', 'null']);
    expect(_map(_properties(warningProblem)['userStatus']), {
      'enum': ['solved', 'partial', 'tried', null],
      'type': ['string', 'null'],
    });
    final contest = _map(_map(properties['contests'])['items']);
    expect(_map(_properties(contest)['abbreviation']), {
      'type': ['string', 'null'],
    });
    final viewerFolder = _map(_map(properties['viewerFolders'])['items']);
    expect(_map(_properties(viewerFolder)['color']), {
      'enum': [
        'red',
        'violet',
        'blue',
        'teal',
        'lime',
        'yellow',
        'orange',
        null,
      ],
      'type': ['string', 'null'],
    });

    final problemSearch = _responseSchema(
      _get(contract, '/api/v4/problems'),
    );
    final problemItem = _map(
      _map(_properties(problemSearch)['problems'])['items'],
    );
    expect(schema, problemItem);
  });

  test('pins the public affiliation detail without inferred relations', () {
    final affiliation = _get(contract, '/api/v4/affiliations/{id}');

    expect(_map(affiliation['x-access']), {'class': 'public'});
    expect(affiliation.containsKey('security'), isFalse);
    expect(affiliation.containsKey('requestBody'), isFalse);
    expect(affiliation['summary'], 'Public affiliation detail');
    expect(_parameterNames(affiliation), ['id', 'lang']);

    final parameters = _parameters(affiliation);
    final id = parameters.first;
    expect(id['in'], 'path');
    expect(id['required'], isTrue);
    expect(_map(id['schema']), {
      'exclusiveMinimum': 0,
      'type': 'integer',
    });
    final language = parameters.last;
    expect(language['in'], 'query');
    expect(language['required'], isFalse);
    expect(_map(language['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });

    final responses = _map(affiliation['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'Affiliation.');
    expect(_map(responses['404'])['description'], 'Affiliation not found.');

    const fields = [
      'id',
      'affiliationId',
      'name',
      'type',
      'countryCode',
      'logoImageUrl',
      'logoThumbnailUrl',
      'color',
      'website',
      'rating',
      'userCount',
      'solvedCount',
      'voteCount',
      'displayName',
      'rank',
      'rankedOf',
      'typeRank',
      'typeRankedOf',
      'tierCounts',
      'ratingByProblemsSum',
      'ratingByClass',
      'ratingBySolvedCount',
      'ratingProblemsHistogram',
      'ratingClass',
      'ratingClassPlus',
    ];
    expect(fields, hasLength(25));
    final schema = _responseSchema(affiliation);
    expect(schema['type'], 'object');
    expect(_required(schema), fields);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys.toList(growable: false), [
      'affiliationId',
      'color',
      'countryCode',
      'displayName',
      'id',
      'logoImageUrl',
      'logoThumbnailUrl',
      'name',
      'rank',
      'rankedOf',
      'rating',
      'ratingByClass',
      'ratingByProblemsSum',
      'ratingBySolvedCount',
      'ratingClass',
      'ratingClassPlus',
      'ratingProblemsHistogram',
      'solvedCount',
      'tierCounts',
      'type',
      'typeRank',
      'typeRankedOf',
      'userCount',
      'voteCount',
      'website',
    ]);

    expect(_map(properties['id']), {'type': 'number'});
    const integerFields = [
      'affiliationId',
      'rating',
      'userCount',
      'solvedCount',
      'voteCount',
      'rank',
      'rankedOf',
      'typeRank',
      'typeRankedOf',
      'ratingByProblemsSum',
      'ratingByClass',
      'ratingBySolvedCount',
      'ratingClass',
    ];
    for (final field in integerFields) {
      expect(_map(properties[field]), {'type': 'integer'});
    }
    for (final field in ['name', 'displayName']) {
      expect(_map(properties[field]), {'type': 'string'});
    }
    expect(_map(properties['type']), {
      'enum': [
        'undefined',
        'university',
        'high_school',
        'middle_school',
        'elementary_school',
        'company',
        'community',
      ],
      'type': 'string',
    });
    for (final field in [
      'countryCode',
      'logoImageUrl',
      'logoThumbnailUrl',
      'color',
      'website',
    ]) {
      expect(_map(properties[field]), {
        'type': ['string', 'null'],
      });
    }
    for (final field in ['tierCounts', 'ratingProblemsHistogram']) {
      final array = _map(properties[field]);
      expect(array['type'], 'array');
      expect(_map(array['items']), {'type': 'integer'});
      for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
        expect(array.containsKey(constraint), isFalse);
      }
    }
    expect(_map(properties['ratingClassPlus']), {'type': 'boolean'});

    final notFound = _map(responses['404']);
    final notFoundContent = _map(notFound['content']);
    expect(notFoundContent.keys.toList(growable: false), [
      'application/json',
    ]);
    final notFoundSchema = _jsonResponseSchema(affiliation, '404');
    expect(notFoundSchema['type'], 'object');
    expect(_required(notFoundSchema), ['error']);
    expect(notFoundSchema.containsKey('additionalProperties'), isFalse);
    final notFoundProperties = _properties(notFoundSchema);
    expect(notFoundProperties.keys.toList(growable: false), ['error']);
    final error = _map(notFoundProperties['error']);
    expect(error['type'], 'object');
    expect(_required(error), ['code', 'message']);
    expect(error.containsKey('additionalProperties'), isFalse);
    final errorProperties = _properties(error);
    expect(errorProperties.keys.toList(growable: false), [
      'code',
      'details',
      'message',
    ]);
    expect(_map(errorProperties['code']), {'type': 'string'});
    expect(_map(errorProperties['message']), {'type': 'string'});
    expect(_map(errorProperties['details']), {
      'additionalProperties': {
        'anyOf': [
          {'type': 'string'},
          {'type': 'number'},
          {'type': 'boolean'},
        ],
      },
      'type': 'object',
    });
    for (final path in [
      '/api/v4/achievements/items/{kind}/{key}/holders',
      '/api/v4/users/{handle}/achievements',
      '/api/v4/sources/oj/{ojId}/contests/{nativeId}',
      '/api/v4/sources/oj/{ojId}/groups/{nativeId}',
    ]) {
      expect(_jsonResponseSchema(_get(contract, path), '404'), notFoundSchema);
    }

    final profile = _get(contract, '/api/v4/users/{handle}');
    final profileProperties = _properties(_responseSchema(profile));
    final profileAffiliations = _map(profileProperties['affiliations']);
    final profileAffiliation = _map(profileAffiliations['items']);
    final profileAffiliationProperties = _properties(profileAffiliation);
    const profileSharedFields = {
      'id',
      'name',
      'type',
      'logoThumbnailUrl',
      'color',
    };
    for (final field in profileSharedFields) {
      expect(properties[field], profileAffiliationProperties[field]);
    }
    expect(
      _required(schema).where(profileSharedFields.contains).toSet(),
      profileSharedFields,
    );
    expect(
      _required(profileAffiliation).where(profileSharedFields.contains).toSet(),
      profileSharedFields,
    );
    expect(_map(profileAffiliationProperties['affiliationId']), {
      'type': 'number',
    });
    expect(
      properties['affiliationId'],
      isNot(profileAffiliationProperties['affiliationId']),
    );
    expect(
      properties['ratingProblemsHistogram'],
      profileProperties['ratingProblemsHistogram'],
    );

    final catalog = _get(contract, '/api/v4/rankings/affiliations');
    final catalogAffiliations =
        _map(_properties(_responseSchema(catalog))['affiliations']);
    final catalogAffiliation = _map(catalogAffiliations['items']);
    final catalogProperties = _properties(catalogAffiliation);
    final board = _get(contract, '/api/v4/rankings/affiliation-board');
    final boardItems = _map(_properties(_responseSchema(board))['items']);
    final boardAffiliation = _map(boardItems['items']);
    final boardProperties = _properties(boardAffiliation);
    const rankingSharedFields = {
      'affiliationId',
      'name',
      'type',
      'userCount',
      'logoThumbnailUrl',
      'color',
    };
    for (final field in rankingSharedFields) {
      expect(properties[field], catalogProperties[field]);
      expect(properties[field], boardProperties[field]);
    }
    for (final sharedSchema in [catalogAffiliation, boardAffiliation]) {
      expect(
        _required(sharedSchema).where(rankingSharedFields.contains).toSet(),
        rankingSharedFields,
      );
    }
    expect(
      _required(schema).where(rankingSharedFields.contains).toSet(),
      rankingSharedFields,
    );
    expect(_map(catalogProperties['id']), {'type': 'integer'});
    expect(_map(boardProperties['id']), {'type': 'integer'});
    expect(properties['id'], isNot(catalogProperties['id']));
    expect(properties['id'], isNot(boardProperties['id']));

    final siteStats = _get(contract, '/api/v4/site/stats');
    final siteProperties = _properties(_responseSchema(siteStats));
    expect(properties['tierCounts'], siteProperties['usersByTier']);
  });

  test('pins the public bookmark folders without inferred relations', () {
    final bookmarks = _get(contract, '/api/v4/bookmarks');

    expect(_accessClass(bookmarks), 'public');
    expect(bookmarks.containsKey('security'), isFalse);
    expect(bookmarks.containsKey('requestBody'), isFalse);
    expect(bookmarks['summary'], "Everyone's public bookmark folders");
    expect(_parameters(bookmarks), [
      {
        'in': 'query',
        'name': 'page',
        'required': false,
        'schema': {
          'default': 1,
          'maximum': 10000,
          'minimum': 1,
          'type': 'integer',
        },
      },
      {
        'in': 'query',
        'name': 'sort',
        'required': false,
        'schema': {
          'default': 'updated',
          'enum': ['updated', 'problems'],
          'type': 'string',
        },
      },
      {
        'in': 'query',
        'name': 'q',
        'required': false,
        'schema': {'maxLength': 100, 'type': 'string'},
      },
    ]);
    final responses = _map(bookmarks['responses']);
    expect(responses.keys.toList(growable: false), ['200']);
    expect(_map(responses['200'])['description'], 'One page of folders.');

    final schema = _responseSchema(bookmarks);
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), ['folders', 'total', 'page', 'pageSize']);
    final properties = _properties(schema);
    expect(properties.keys.length, 4);
    for (final field in ['total', 'page', 'pageSize']) {
      expect(_map(properties[field]), {'type': 'number'});
    }
    final folders = _map(properties['folders']);
    expect(folders['type'], 'array');
    final folder = _map(folders['items']);
    expect(folder['type'], 'object');
    expect(folder.containsKey('additionalProperties'), isFalse);
    expect(_required(folder), [
      'slug',
      'name',
      'description',
      'color',
      'visibility',
      'problemCount',
      'favoriteCount',
      'solvedCount',
      'owner',
      'createdAt',
      'updatedAt',
    ]);
    final folderProperties = _properties(folder);
    expect(folderProperties.keys.length, 11);
    for (final field in ['slug', 'name', 'description']) {
      expect(_map(folderProperties[field]), {'type': 'string'});
    }
    for (final field in ['problemCount', 'favoriteCount']) {
      expect(_map(folderProperties[field]), {'type': 'number'});
    }
    expect(_map(folderProperties['solvedCount']), {
      'type': ['number', 'null'],
    });
    for (final field in ['createdAt', 'updatedAt']) {
      expect(_map(folderProperties[field]), {
        'format': 'date-time',
        'type': 'string',
      });
    }
    expect(_map(folderProperties['visibility']), {
      'enum': ['private', 'unlisted', 'public'],
      'type': 'string',
    });
    expect(_map(folderProperties['color']), {
      'enum': [
        'red',
        'violet',
        'blue',
        'teal',
        'lime',
        'yellow',
        'orange',
        null,
      ],
      'type': ['string', 'null'],
    });
    expect(_map(folderProperties['owner']), {
      'properties': {
        'handle': {'type': 'string'},
        'id': {'type': 'number'},
        'profileImageUrl': {
          'format': 'uri',
          'type': ['string', 'null'],
        },
        'tier': {
          'maximum': 31,
          'minimum': 0,
          'type': ['integer', 'null'],
        },
      },
      'required': ['id', 'handle', 'tier', 'profileImageUrl'],
      'type': 'object',
    });
  });

  test('pins the viewer folders to the shared folder shape', () {
    final own = _get(contract, '/api/v4/account/bookmarks');
    final public = _get(contract, '/api/v4/bookmarks');

    expect(_accessClass(own), 'user');
    expect(_accessScope(own), 'bookmarks');
    expect(own.containsKey('security'), isFalse);
    expect(own.containsKey('requestBody'), isFalse);
    expect(
      own['summary'],
      "The signed-in user's folders, for the add-to-folder menu",
    );
    expect(_parameters(own), [
      {
        'in': 'query',
        'name': 'problemId',
        'required': false,
        'schema': {'exclusiveMinimum': 0, 'type': 'integer'},
      },
    ]);
    final responses = _map(own['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
        _map(responses['200'])['description'], 'Every folder, newest first.');
    expect(_map(responses['401'])['description'], 'Not signed in.');
    expect(
      _jsonResponseSchema(own, '401'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    final schema = _responseSchema(own);
    expect(_required(schema), ['folders']);
    expect(_properties(schema).keys.toList(growable: false), ['folders']);
    final folder = _map(_map(_properties(schema)['folders'])['items']);
    final publicFolder = _map(
      _map(_properties(_responseSchema(public))['folders'])['items'],
    );
    expect(folder['type'], 'object');
    expect(_required(folder), [..._required(publicFolder), 'containsProblem']);
    final folderProperties = Map<String, dynamic>.of(_properties(folder));
    expect(folderProperties.remove('containsProblem'), {'type': 'boolean'});
    expect(folderProperties, _properties(publicFolder));
  });

  test('pins favorited folders to the shared folder-list schema', () {
    final favorites = _get(contract, '/api/v4/account/bookmark-favorites');
    final public = _get(contract, '/api/v4/bookmarks');

    expect(_accessClass(favorites), 'user');
    expect(_accessScope(favorites), 'bookmarks');
    expect(favorites.containsKey('security'), isFalse);
    expect(favorites.containsKey('requestBody'), isFalse);
    expect(
      favorites['summary'],
      "Other people's folders the signed-in user favorited",
    );
    expect(_parameters(favorites), [_parameters(public).first]);
    final responses = _map(favorites['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(_map(responses['200']), _map(_map(public['responses'])['200']));
    expect(_map(responses['401'])['description'], 'Not signed in.');
    expect(
      _jsonResponseSchema(favorites, '401'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );
  });

  test('pins user bookmark folders to the shared folder-list schema', () {
    final bookmarks = _get(contract, '/api/v4/users/{handle}/bookmarks');
    final public = _get(contract, '/api/v4/bookmarks');

    expect(_accessClass(bookmarks), 'public');
    expect(_accessScope(bookmarks), 'bookmarks');
    expect(_map(public['x-access']).containsKey('scope'), isFalse);
    expect(bookmarks.containsKey('security'), isFalse);
    expect(bookmarks.containsKey('requestBody'), isFalse);
    expect(
      bookmarks['summary'],
      'A user\'s folders: public ones, or all of them for the owner',
    );
    expect(_parameters(bookmarks), [
      {
        'in': 'path',
        'name': 'handle',
        'required': true,
        'schema': {'maxLength': 64, 'minLength': 1, 'type': 'string'},
      },
      _parameters(public).first,
    ]);
    final responses = _map(bookmarks['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200']), _map(_map(public['responses'])['200']));
    expect(_map(responses['404'])['description'], 'No such user.');
    expect(
      _jsonResponseSchema(bookmarks, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );
  });

  test('pins the bookmark folder detail and its shared shapes', () {
    final detail = _get(contract, '/api/v4/users/{handle}/bookmarks/{slug}');
    final list = _get(contract, '/api/v4/users/{handle}/bookmarks');

    expect(_accessClass(detail), 'public');
    expect(_accessScope(detail), 'bookmarks');
    expect(detail.containsKey('security'), isFalse);
    expect(detail.containsKey('requestBody'), isFalse);
    expect(detail['summary'], 'One folder and a page of its problems');
    final parameters = _parameters(detail);
    expect(parameters, [
      _parameters(list).first,
      {
        'in': 'path',
        'name': 'slug',
        'required': true,
        'schema': {'pattern': r'^[0-9a-z_]{1,32}$', 'type': 'string'},
      },
      _parameters(list).last,
      {
        'in': 'query',
        'name': 'sort',
        'required': false,
        'schema': {
          'default': 'order',
          'enum': ['order', 'level', 'solved', 'average_try', 'id'],
          'type': 'string',
        },
      },
      {
        'in': 'query',
        'name': 'direction',
        'required': false,
        'schema': {
          'default': 'asc',
          'enum': ['asc', 'desc'],
          'type': 'string',
        },
      },
      {
        'in': 'query',
        'name': 'q',
        'required': false,
        'schema': {'maxLength': 512, 'type': 'string'},
      },
    ]);
    final responses = _map(detail['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'The folder.');
    expect(
      _map(responses['404'])['description'],
      'No such folder, or it is private.',
    );
    expect(
      _jsonResponseSchema(detail, '404'),
      _jsonResponseSchema(list, '404'),
    );

    final schema = _responseSchema(detail);
    final listProperties = _properties(_responseSchema(list));
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'folder',
      'isOwner',
      'isFavorite',
      'levels',
      'problems',
      'total',
      'page',
      'pageSize',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 8);
    expect(
      _map(properties['folder']),
      _map(_map(listProperties['folders'])['items']),
    );
    for (final field in ['total', 'page', 'pageSize']) {
      expect(properties[field], listProperties[field]);
    }
    expect(_map(properties['isOwner']), {'type': 'boolean'});
    expect(_map(properties['isFavorite']), {
      'type': ['boolean', 'null'],
    });
    expect(_map(properties['levels']), {
      'items': {
        'properties': {
          'count': {'type': 'number'},
          'level': {'type': 'number'},
          'solved': {
            'type': ['number', 'null'],
          },
        },
        'required': ['level', 'count', 'solved'],
        'type': 'object',
      },
      'type': 'array',
    });
    final problems = _map(properties['problems']);
    expect(problems['type'], 'array');
    final item = _map(problems['items']);
    expect(item['type'], 'object');
    expect(item.containsKey('additionalProperties'), isFalse);
    expect(_required(item), ['problem', 'note', 'addedAt']);
    final itemProperties = Map<String, dynamic>.of(_properties(item));
    final searchItem = _map(
      _map(_properties(_responseSchema(_get(contract, '/api/v4/problems')))[
          'problems'])['items'],
    );
    expect(itemProperties.remove('problem'), searchItem);
    expect(itemProperties, {
      'addedAt': {'format': 'date-time', 'type': 'string'},
      'note': {
        'type': ['string', 'null'],
      },
    });
  });

  test('pins the public user collection and its shared item shape', () {
    final collection = _get(contract, '/api/v4/users/{handle}/collection');

    expect(_accessClass(collection), 'public');
    expect(_map(collection['x-access']).containsKey('scope'), isFalse);
    expect(collection.containsKey('security'), isFalse);
    expect(collection.containsKey('requestBody'), isFalse);
    expect(
      collection['summary'],
      'A page of the badges or backgrounds a user owns',
    );
    expect(_parameters(collection), [
      {
        'in': 'path',
        'name': 'handle',
        'required': true,
        'schema': {'maxLength': 64, 'minLength': 1, 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'lang',
        'required': false,
        'schema': {'default': 'ko', 'maxLength': 16, 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'kind',
        'required': false,
        'schema': {
          'default': 'badge',
          'enum': ['badge', 'background'],
          'type': 'string',
        },
      },
      {
        'in': 'query',
        'name': 'sort',
        'required': false,
        'schema': {
          'default': 'recent',
          'enum': ['recent', 'rarity', 'name'],
          'type': 'string',
        },
      },
      {
        'in': 'query',
        'name': 'category',
        'required': false,
        'schema': {'maxLength': 64, 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'q',
        'required': false,
        'schema': {'maxLength': 64, 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'offset',
        'required': false,
        'schema': {
          'default': 0,
          'minimum': 0,
          'type': ['integer', 'null'],
        },
      },
    ]);
    final responses = _map(collection['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(
      _map(responses['200'])['description'],
      'Owned items of one kind, filtered and sorted.',
    );
    expect(_map(responses['404'])['description'], 'No such user.');
    expect(
      _jsonResponseSchema(collection, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    final schema = _responseSchema(collection);
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'items',
      'total',
      'nextOffset',
      'counts',
      'categories',
      'equipped',
      'equippedByKind',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 7);
    expect(_map(properties['total']), {'type': 'integer'});
    expect(_map(properties['nextOffset']), {
      'type': ['integer', 'null'],
    });
    expect(_map(properties['categories']), {
      'items': {'type': 'string'},
      'type': 'array',
    });
    expect(_map(properties['counts']), {
      'properties': {
        'background': {'type': 'integer'},
        'badge': {'type': 'integer'},
      },
      'required': ['badge', 'background'],
      'type': 'object',
    });

    const item = {
      'properties': {
        'acquiredAt': {
          'type': ['string', 'null'],
        },
        'addedAt': {'type': 'string'},
        'category': {'type': 'string'},
        'equipped': {'type': 'boolean'},
        'holderCount': {
          'type': ['integer', 'null'],
        },
        'id': {'type': 'integer'},
        'imageUrl': {'type': 'string'},
        'key': {'type': 'string'},
        'kind': {
          'enum': ['badge', 'background'],
          'type': 'string',
        },
        'name': {'type': 'string'},
      },
      'required': [
        'kind',
        'id',
        'key',
        'name',
        'imageUrl',
        'category',
        'addedAt',
        'equipped',
        'acquiredAt',
        'holderCount',
      ],
    };
    expect(_map(properties['items']), {
      'items': {...item, 'type': 'object'},
      'type': 'array',
    });
    final nullableItem = {
      ...item,
      'type': ['object', 'null'],
    };
    expect(_map(properties['equipped']), nullableItem);
    expect(_map(properties['equippedByKind']), {
      'properties': {
        'background': nullableItem,
        'badge': nullableItem,
      },
      'required': ['badge', 'background'],
      'type': 'object',
    });
  });

  test('pins the viewer collection to the shared collection schema', () {
    final account = _get(contract, '/api/v4/account/collection');
    final user = _get(contract, '/api/v4/users/{handle}/collection');

    expect(_accessClass(account), 'user');
    expect(_accessScope(account), 'collection');
    expect(account.containsKey('security'), isFalse);
    expect(account.containsKey('requestBody'), isFalse);
    expect(
      account['summary'],
      'A page of the badges or backgrounds the viewer owns',
    );
    expect(_parameters(account), _parameters(user).skip(1).toList());
    final responses = _map(account['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(_map(responses['200']), _map(_map(user['responses'])['200']));
    expect(_map(responses['401'])['description'], 'Not signed in.');
    expect(
      _jsonResponseSchema(account, '401'),
      _jsonResponseSchema(user, '404'),
    );
  });

  test('pins the public affiliation board without inferred relations', () {
    final board = _get(contract, '/api/v4/rankings/affiliation-board');

    expect(_accessClass(board), 'public');
    expect(_parameterNames(board), ['page', 'type', 'lang']);
    final parameters = _parameters(board);
    for (final parameter in parameters) {
      expect(parameter['in'], 'query');
      expect(parameter['required'], isFalse);
    }
    expect(_map(parameters[0]['schema']), {
      'default': 1,
      'minimum': 1,
      'type': 'integer',
    });
    expect(_map(parameters[1]['schema']), {
      'enum': [
        'undefined',
        'university',
        'high_school',
        'middle_school',
        'elementary_school',
        'company',
        'community',
      ],
      'type': 'string',
    });
    expect(_map(parameters[2]['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });
    expect(board.containsKey('requestBody'), isFalse);
    expect(_map(board['responses']).keys.toList(), ['200']);
    expect(board['summary'], 'Affiliations themselves, by rating');
    expect(
      _map(_map(board['responses'])['200'])['description'],
      'One page of the board.',
    );

    final schema = _responseSchema(board);
    expect(schema['type'], 'object');
    expect(_required(schema), ['mine', 'total', 'page', 'pageSize', 'items']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final outerProperties = _properties(schema);
    expect(outerProperties.keys.toList(growable: false), [
      'items',
      'mine',
      'page',
      'pageSize',
      'total',
    ]);
    for (final field in ['total', 'page', 'pageSize']) {
      expect(_map(outerProperties[field]), {'type': 'integer'});
    }

    final items = _map(outerProperties['items']);
    final mine = _map(outerProperties['mine']);
    for (final array in [items, mine]) {
      expect(array['type'], 'array');
      for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
        expect(array.containsKey(constraint), isFalse);
      }
    }

    final item = _map(items['items']);
    expect(item['type'], 'object');
    expect(_required(item), [
      'id',
      'affiliationId',
      'name',
      'type',
      'logoThumbnailUrl',
      'color',
      'rank',
      'globalRank',
      'rating',
      'userCount',
      'solvedCount',
    ]);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(itemProperties.keys.toList(growable: false), [
      'affiliationId',
      'color',
      'globalRank',
      'id',
      'logoThumbnailUrl',
      'name',
      'rank',
      'rating',
      'solvedCount',
      'type',
      'userCount',
    ]);
    for (final field in [
      'id',
      'affiliationId',
      'rank',
      'rating',
      'userCount',
      'solvedCount',
    ]) {
      expect(_map(itemProperties[field]), {'type': 'integer'});
    }
    expect(_map(itemProperties['globalRank']), {
      'type': ['integer', 'null'],
    });

    final mineItem = _map(mine['items']);
    expect(mineItem['type'], 'object');
    expect(_required(mineItem), [
      'id',
      'affiliationId',
      'name',
      'type',
      'logoThumbnailUrl',
      'color',
      'rank',
      'globalRank',
      'rating',
      'userCount',
      'solvedCount',
      'page',
    ]);
    expect(mineItem.containsKey('additionalProperties'), isFalse);
    final mineProperties = _properties(mineItem);
    expect(mineProperties.keys.toList(growable: false), [
      'affiliationId',
      'color',
      'globalRank',
      'id',
      'logoThumbnailUrl',
      'name',
      'page',
      'rank',
      'rating',
      'solvedCount',
      'type',
      'userCount',
    ]);
    expect(_map(mineProperties['page']), {'type': 'integer'});
    final mineWithoutPage = Map<String, dynamic>.from(mineProperties)
      ..remove('page');
    expect(mineWithoutPage, itemProperties);
    expect(
      _required(mineItem).where((field) => field != 'page').toList(),
      _required(item),
    );

    final catalog = _get(contract, '/api/v4/rankings/affiliations');
    final catalogAffiliations =
        _map(_properties(_responseSchema(catalog))['affiliations']);
    final catalogItem = _map(catalogAffiliations['items']);
    final catalogProperties = _properties(catalogItem);
    const commonFields = {
      'id',
      'affiliationId',
      'name',
      'type',
      'userCount',
      'logoThumbnailUrl',
      'color',
    };
    for (final field in commonFields) {
      expect(itemProperties[field], catalogProperties[field]);
      expect(mineProperties[field], catalogProperties[field]);
    }
    expect(
      _required(item).where(commonFields.contains).toSet(),
      commonFields,
    );
    expect(
      _required(mineItem).where(commonFields.contains).toSet(),
      commonFields,
    );
    expect(_required(catalogItem).toSet(), commonFields);

    final profile = _get(contract, '/api/v4/users/{handle}');
    final profileAffiliations =
        _map(_properties(_responseSchema(profile))['affiliations']);
    final profileItem = _map(profileAffiliations['items']);
    expect(
      _map(itemProperties['type']),
      _map(_properties(profileItem)['type']),
    );
  });

  test('pins public ranking affiliations without inferred relations', () {
    final rankingAffiliations =
        _get(contract, '/api/v4/rankings/affiliations');

    expect(_accessClass(rankingAffiliations), 'public');
    expect(_parameterNames(rankingAffiliations), ['q', 'lang']);
    final parameters = _parameters(rankingAffiliations);
    expect(parameters.first['in'], 'query');
    expect(parameters.first['required'], isFalse);
    expect(_map(parameters.first['schema']), {
      'maxLength': 64,
      'type': 'string',
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'default': 'ko',
      'maxLength': 16,
      'type': 'string',
    });
    expect(rankingAffiliations.containsKey('requestBody'), isFalse);
    expect(_map(rankingAffiliations['responses']).keys.toList(), ['200']);
    expect(
      rankingAffiliations['summary'],
      'Affiliations with a rankable population',
    );
    expect(
      _map(_map(rankingAffiliations['responses'])['200'])['description'],
      'Affiliations that have members, largest first.',
    );

    final schema = _responseSchema(rankingAffiliations);
    expect(schema['type'], 'object');
    expect(_required(schema), ['affiliations']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final outerProperties = _properties(schema);
    expect(outerProperties.keys.toList(growable: false), ['affiliations']);
    final affiliations = _map(outerProperties['affiliations']);
    expect(affiliations['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(affiliations.containsKey(constraint), isFalse);
    }

    final affiliation = _map(affiliations['items']);
    expect(affiliation['type'], 'object');
    expect(_required(affiliation), [
      'id',
      'affiliationId',
      'name',
      'type',
      'userCount',
      'logoThumbnailUrl',
      'color',
    ]);
    expect(affiliation.containsKey('additionalProperties'), isFalse);
    final properties = _properties(affiliation);
    expect(properties.keys.toList(growable: false), [
      'affiliationId',
      'color',
      'id',
      'logoThumbnailUrl',
      'name',
      'type',
      'userCount',
    ]);
    for (final field in ['id', 'affiliationId', 'userCount']) {
      expect(_map(properties[field]), {'type': 'integer'});
    }
    expect(_map(properties['name']), {'type': 'string'});
    expect(_map(properties['type']), {
      'enum': [
        'undefined',
        'university',
        'high_school',
        'middle_school',
        'elementary_school',
        'company',
        'community',
      ],
      'type': 'string',
    });
    final profile = _get(contract, '/api/v4/users/{handle}');
    final profileAffiliations =
        _map(_properties(_responseSchema(profile))['affiliations']);
    final profileAffiliation = _map(profileAffiliations['items']);
    expect(
      _map(properties['type']),
      _map(_properties(profileAffiliation)['type']),
    );
    for (final field in ['logoThumbnailUrl', 'color']) {
      expect(_map(properties[field]), {
        'type': ['string', 'null'],
      });
    }
  });

  test('pins public ranking regions without inferred sorting or bounds', () {
    final rankingRegions = _get(contract, '/api/v4/rankings/regions');

    expect(_accessClass(rankingRegions), 'public');
    expect(rankingRegions.containsKey('parameters'), isFalse);
    expect(rankingRegions.containsKey('requestBody'), isFalse);
    expect(_map(rankingRegions['responses']).keys.toList(), ['200']);
    expect(
      _map(_map(rankingRegions['responses'])['200'])['description'],
      'Regions people have chosen to show, largest first.',
    );

    final schema = _responseSchema(rankingRegions);
    expect(schema['type'], 'object');
    expect(_required(schema), ['regions']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final regions = _map(_properties(schema)['regions']);
    expect(regions['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(regions.containsKey(constraint), isFalse);
    }

    final region = _map(regions['items']);
    expect(region['type'], 'object');
    expect(_required(region), ['countryCode', 'userCount']);
    expect(region.containsKey('additionalProperties'), isFalse);
    final properties = _properties(region);
    expect(properties.keys.toList(growable: false), [
      'countryCode',
      'userCount',
    ]);
    expect(_map(properties['countryCode']), {'type': 'string'});
    expect(_map(properties['userCount']), {'type': 'integer'});
  });

  test('pins public ranking tags without inferred query or value bounds', () {
    final rankingTags = _get(contract, '/api/v4/rankings/tags');

    expect(_accessClass(rankingTags), 'public');
    expect(_parameterNames(rankingTags), ['lang']);
    final language = _parameters(rankingTags).single;
    expect(language['in'], 'query');
    expect(language['required'], isFalse);
    expect(_map(language['schema']), {
      'default': 'ko',
      'type': 'string',
    });
    expect(rankingTags.containsKey('requestBody'), isFalse);
    expect(_map(rankingTags['responses']).keys.toList(), ['200']);
    expect(
      _map(_map(rankingTags['responses'])['200'])['description'],
      'Rated tag slots, named for the requested language.',
    );

    final schema = _responseSchema(rankingTags);
    expect(schema['type'], 'object');
    expect(_required(schema), ['tags']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final tags = _map(_properties(schema)['tags']);
    expect(tags['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(tags.containsKey(constraint), isFalse);
    }

    final tag = _map(tags['items']);
    expect(tag['type'], 'object');
    expect(_required(tag), ['key', 'ratingTagIndex', 'displayName']);
    expect(tag.containsKey('additionalProperties'), isFalse);
    final properties = _properties(tag);
    expect(properties.keys.toList(growable: false), [
      'displayName',
      'key',
      'ratingTagIndex',
    ]);
    expect(_map(properties['key']), {'type': 'string'});
    expect(_map(properties['ratingTagIndex']), {'type': 'integer'});
    expect(_map(properties['displayName']), {'type': 'string'});
  });

  test('pins the public site-wide totals without inferred constraints', () {
    final siteStats = _get(contract, '/api/v4/site/stats');

    expect(_map(siteStats['x-access']), {'class': 'public'});
    expect(siteStats.containsKey('parameters'), isFalse);
    expect(siteStats.containsKey('requestBody'), isFalse);
    expect(_map(siteStats['responses']).keys.toList(), ['200']);
    expect(
      _map(_map(siteStats['responses'])['200'])['description'],
      'The totals, up to ten minutes old.',
    );

    const fields = [
      'problemsWithLevel',
      'users',
      'contributors',
      'contributions',
      'usersByTier',
    ];
    final schema = _responseSchema(siteStats);
    expect(schema['type'], 'object');
    expect(_required(schema), fields);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys, unorderedEquals(fields));
    for (final field in fields.take(4)) {
      final property = _map(properties[field]);
      expect(property, {'type': 'integer'});
      for (final constraint in ['minimum', 'maximum']) {
        expect(property.containsKey(constraint), isFalse);
      }
    }

    final usersByTier = _map(properties['usersByTier']);
    expect(usersByTier['type'], 'array');
    expect(_map(usersByTier['items']), {'type': 'integer'});
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(usersByTier.containsKey(constraint), isFalse);
    }
  });

  test('pins the public notice board without inferred relations', () {
    final notices = _get(contract, '/api/v4/posts/notice');

    expect(_accessClass(notices), 'public');
    expect(_map(notices['x-access']).containsKey('scope'), isFalse);
    expect(notices.containsKey('security'), isFalse);
    expect(notices.containsKey('requestBody'), isFalse);
    expect(
      notices['summary'],
      'List the notice board, pinned first, then newest first',
    );
    expect(_parameters(notices), [
      {
        'in': 'query',
        'name': 'lang',
        'required': false,
        'schema': {'maxLength': 16, 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'page',
        'required': false,
        'schema': {
          'default': 1,
          'maximum': 10000,
          'minimum': 1,
          'type': 'integer',
        },
      },
      {
        'in': 'query',
        'name': 'q',
        'required': false,
        'schema': {'maxLength': 64, 'type': 'string'},
      },
    ]);
    final responses = _map(notices['responses']);
    expect(responses.keys.toList(growable: false), ['200']);
    expect(_map(responses['200'])['description'], 'One page of notices.');

    final schema = _responseSchema(notices);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), ['items', 'total', 'page', 'perPage']);
    final properties = _properties(schema);
    expect(properties.keys.length, 4);
    for (final field in ['total', 'page', 'perPage']) {
      expect(_map(properties[field]), {'type': 'integer'});
    }
    expect(_map(properties['items']), {
      'items': {
        'properties': {
          'coverImageUrl': {
            'type': ['string', 'null'],
          },
          'isNew': {'type': 'boolean'},
          'language': {'type': 'string'},
          'path': {'type': 'string'},
          'pinned': {'type': 'boolean'},
          'publishedAt': {'type': 'string'},
          'summary': {
            'type': ['string', 'null'],
          },
          'title': {'type': 'string'},
        },
        'required': [
          'path',
          'language',
          'title',
          'summary',
          'publishedAt',
          'pinned',
          'isNew',
          'coverImageUrl',
        ],
        'type': 'object',
      },
      'type': 'array',
    });
  });

  test('pins the public notice post and its open document shape', () {
    final notice = _get(contract, '/api/v4/posts/notice/{slug}');

    expect(_accessClass(notice), 'public');
    expect(_map(notice['x-access']).containsKey('scope'), isFalse);
    expect(notice.containsKey('security'), isFalse);
    expect(notice.containsKey('requestBody'), isFalse);
    expect(notice['summary'], 'Read a notice');
    expect(_parameters(notice), [
      {
        'in': 'path',
        'name': 'slug',
        'required': true,
        'schema': {
          'maxLength': 64,
          'minLength': 1,
          'pattern': r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
          'type': 'string',
        },
      },
      _parameters(_get(contract, '/api/v4/posts/notice')).first,
    ]);
    final responses = _map(notice['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(
      _map(responses['200'])['description'],
      'The post. `language` reports what was served, which may differ from '
      '`lang`.',
    );
    expect(
      _map(responses['404'])['description'],
      "No such post, or it isn't published.",
    );
    expect(
      _jsonResponseSchema(notice, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    final schema = _responseSchema(notice);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'board',
      'path',
      'language',
      'languages',
      'title',
      'summary',
      'content',
      'publishedAt',
      'updatedAt',
      'pinned',
      'coverImageUrl',
      'basisDate',
      'breadcrumbs',
      'previous',
      'next',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 15);
    expect(_map(properties['board']), {
      'enum': ['notice', 'help'],
      'type': 'string',
    });
    for (final field in [
      'path',
      'language',
      'title',
      'publishedAt',
      'updatedAt',
    ]) {
      expect(_map(properties[field]), {'type': 'string'});
    }
    for (final field in ['summary', 'coverImageUrl', 'basisDate']) {
      expect(_map(properties[field]), {
        'type': ['string', 'null'],
      });
    }
    expect(_map(properties['pinned']), {'type': 'boolean'});
    expect(_map(properties['languages']), {
      'items': {'type': 'string'},
      'type': 'array',
    });
    expect(_map(properties['content']), {
      'additionalProperties': <String, Object?>{},
      'properties': {
        'content': {
          'items': <String, Object?>{},
          'type': 'array',
        },
        'type': {
          'enum': ['doc'],
          'type': 'string',
        },
      },
      'required': ['type'],
      'type': 'object',
    });
    const link = {
      'properties': {
        'path': {'type': 'string'},
        'title': {'type': 'string'},
      },
      'required': ['path', 'title'],
    };
    expect(_map(properties['breadcrumbs']), {
      'items': {...link, 'type': 'object'},
      'type': 'array',
    });
    for (final field in ['previous', 'next']) {
      expect(_map(properties[field]), {
        ...link,
        'type': ['object', 'null'],
      });
    }
  });

  test('pins the public help page to the shared post schema', () {
    final page = _get(contract, '/api/v4/posts/help/page');
    final notice = _get(contract, '/api/v4/posts/notice/{slug}');

    expect(_accessClass(page), 'public');
    expect(_map(page['x-access']).containsKey('scope'), isFalse);
    expect(page.containsKey('security'), isFalse);
    expect(page.containsKey('requestBody'), isFalse);
    expect(page['summary'], 'Read a help center document');
    expect(_parameters(page), [
      _parameters(notice).last,
      {
        'in': 'query',
        'name': 'path',
        'required': true,
        'schema': {
          'maxLength': 255,
          'minLength': 1,
          'pattern':
              r'^[a-z0-9]+(?:-[a-z0-9]+)*(?:\/[a-z0-9]+(?:-[a-z0-9]+)*)*$',
          'type': 'string',
        },
      },
    ]);
    final responses = _map(page['responses']);
    expect(responses, _map(notice['responses']));
  });

  test('pins the public help article and its shared document shape', () {
    final article = _get(contract, '/api/v4/help/{slug}');
    final notice = _get(contract, '/api/v4/posts/notice/{slug}');

    expect(_accessClass(article), 'public');
    expect(_map(article['x-access']).containsKey('scope'), isFalse);
    expect(article.containsKey('security'), isFalse);
    expect(article.containsKey('requestBody'), isFalse);
    expect(
      article['summary'],
      'Read a help article in the requested language',
    );
    expect(_parameters(article), [
      {
        'in': 'path',
        'name': 'slug',
        'required': true,
        'schema': {
          'maxLength': 128,
          'minLength': 1,
          'pattern': r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
          'type': 'string',
        },
      },
      {
        'in': 'query',
        'name': 'lang',
        'required': false,
        'schema': {'type': 'string'},
      },
    ]);
    final responses = _map(article['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(
      _map(responses['200'])['description'],
      'The article. `language` reports what was actually served, which may '
      'differ from `lang`.',
    );
    expect(
      _map(responses['404'])['description'],
      'No such slug, or the slug exists but has no content yet.',
    );
    expect(
      _jsonResponseSchema(article, '404'),
      _jsonResponseSchema(notice, '404'),
    );

    final schema = _responseSchema(article);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'slug',
      'language',
      'title',
      'content',
      'updatedAt',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 5);
    for (final field in ['slug', 'language', 'title', 'updatedAt']) {
      expect(_map(properties[field]), {'type': 'string'});
    }
    expect(
        properties['content'], _properties(_responseSchema(notice))['content']);
  });

  test('pins the public policy and its content union', () {
    final policy = _get(contract, '/api/v4/policies/{slug}');
    final article = _get(contract, '/api/v4/help/{slug}');

    expect(_accessClass(policy), 'public');
    expect(_map(policy['x-access']).containsKey('scope'), isFalse);
    expect(policy.containsKey('security'), isFalse);
    expect(policy.containsKey('requestBody'), isFalse);
    expect(
      policy['summary'],
      'Read the version of a policy in force now, or its soonest upcoming one '
      'while none is',
    );
    const slugEnum = [
      'tos',
      'tos_recurring',
      'privacy',
      'chrome_privacy',
      'guideline',
      'rules',
      'developer_terms',
      'partner_terms',
    ];
    expect(_parameters(policy), [
      {
        'in': 'path',
        'name': 'slug',
        'required': true,
        'schema': {'enum': slugEnum, 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'lang',
        'required': false,
        'schema': {'maxLength': 16, 'type': 'string'},
      },
    ]);
    final responses = _map(policy['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(
      _map(responses['200'])['description'],
      "The version's text. `language` reports what was served, which may "
      'differ from `lang`.',
    );
    expect(
      _map(responses['404'])['description'],
      'No such document or version, or none published yet.',
    );
    expect(
      _jsonResponseSchema(policy, '404'),
      _jsonResponseSchema(article, '404'),
    );

    final schema = _responseSchema(policy);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'slug',
      'version',
      'label',
      'announcedAt',
      'effectiveAt',
      'language',
      'title',
      'content',
      'revisedAt',
      'isCurrent',
      'currentLabel',
      'versions',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 12);
    expect(_map(properties['slug']), {'enum': slugEnum, 'type': 'string'});
    for (final field in [
      'version',
      'label',
      'effectiveAt',
      'language',
      'title',
    ]) {
      expect(_map(properties[field]), {'type': 'string'});
    }
    for (final field in ['announcedAt', 'revisedAt', 'currentLabel']) {
      expect(_map(properties[field]), {
        'type': ['string', 'null'],
      });
    }
    expect(_map(properties['isCurrent']), {'type': 'boolean'});
    expect(_map(properties['versions']), {
      'items': {
        'properties': {
          'announcedAt': {
            'type': ['string', 'null'],
          },
          'effectiveAt': {'type': 'string'},
          'label': {'type': 'string'},
          'version': {'type': 'string'},
        },
        'required': ['version', 'label', 'announcedAt', 'effectiveAt'],
        'type': 'object',
      },
      'type': 'array',
    });
    expect(_map(properties['content']), {
      'oneOf': [
        {
          'properties': {
            'body': {'type': 'string'},
            'format': {
              'enum': ['markdown'],
              'type': 'string',
            },
          },
          'required': ['format', 'body'],
          'type': 'object',
        },
        {
          'properties': {
            'doc': _properties(_responseSchema(article))['content'],
            'format': {
              'enum': ['tiptap'],
              'type': 'string',
            },
          },
          'required': ['format', 'doc'],
          'type': 'object',
        },
      ],
    });
  });

  test('pins the public policy version to the shared policy schema', () {
    final version = _get(contract, '/api/v4/policies/{slug}/{ref}');
    final policy = _get(contract, '/api/v4/policies/{slug}');

    expect(_accessClass(version), 'public');
    expect(_map(version['x-access']).containsKey('scope'), isFalse);
    expect(version.containsKey('security'), isFalse);
    expect(version.containsKey('requestBody'), isFalse);
    expect(
      version['summary'],
      'Read one version of a policy, past, current or upcoming, by label (v3) '
      'or effective day (20240714)',
    );
    expect(_parameters(version), [
      _parameters(policy).first,
      {
        'in': 'path',
        'name': 'ref',
        'required': true,
        'schema': {
          'anyOf': [
            {'pattern': r'^(v\d{1,3}|beta)$', 'type': 'string'},
            {'pattern': r'^\d{8}$', 'type': 'string'},
          ],
        },
      },
      _parameters(policy).last,
    ]);
    expect(_map(version['responses']), _map(policy['responses']));
  });

  test('pins public OJ source lookups and their exact shared response', () {
    const operations = {
      '/api/v4/sources/oj/{ojId}/contests/{nativeId}':
          "solved.ac's contest for a judge's contest id",
      '/api/v4/sources/oj/{ojId}/groups/{nativeId}':
          "solved.ac's source group for a judge's group id",
    };

    for (final entry in operations.entries) {
      final operation = _get(contract, entry.key);
      expect(_accessClass(operation), 'public');
      expect(operation['summary'], entry.value);
      expect(operation.containsKey('requestBody'), isFalse);
      expect(_parameterNames(operation), ['ojId', 'nativeId']);

      final parameters = _parameters(operation);
      expect(parameters.map((parameter) => parameter['in']), ['path', 'path']);
      expect(
        parameters.map((parameter) => parameter['required']),
        [true, true],
      );
      expect(_map(parameters.first['schema']), {
        'maxLength': 32,
        'minLength': 1,
        'type': 'string',
      });
      expect(_map(parameters.last['schema']), {
        'maxLength': 64,
        'minLength': 1,
        'type': 'string',
      });

      final responses = _map(operation['responses']);
      expect(responses.keys.toList(growable: false), ['200', '404']);
      expect(_map(responses['200'])['description'], "solved.ac's id.");
      expect(_map(responses['404'])['description'], 'No match.');

      final schema = _responseSchema(operation);
      expect(schema['type'], 'object');
      expect(_required(schema), ['id']);
      expect(schema.containsKey('additionalProperties'), isFalse);
      final properties = _properties(schema);
      expect(properties.keys.toList(growable: false), ['id']);
      expect(_map(properties['id']), {'type': 'number'});
    }
  });

  test('pins the public source groups without inferred relations', () {
    final sources = _get(contract, '/api/v4/sources');

    expect(_accessClass(sources), 'public');
    expect(sources.containsKey('security'), isFalse);
    expect(sources.containsKey('requestBody'), isFalse);
    expect(sources.containsKey('parameters'), isFalse);
    expect(sources['summary'], 'The top-level source groups');
    final responses = _map(sources['responses']);
    expect(responses.keys.toList(growable: false), ['200']);
    expect(
        _map(responses['200'])['description'], 'Groups with anything in them.');

    final schema = _responseSchema(sources);
    expect(schema['type'], 'object');
    expect(_required(schema), ['groups']);
    expect(_properties(schema).keys.toList(growable: false), ['groups']);
    final groups = _map(_properties(schema)['groups']);
    expect(groups['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(groups.containsKey(constraint), isFalse);
    }

    const order = {
      'enum': ['ascending', 'random', 'mixed', null],
      'type': ['string', 'null'],
    };
    final group = _map(groups['items']);
    expect(group['type'], 'object');
    expect(group.containsKey('additionalProperties'), isFalse);
    expect(_required(group), [
      'id',
      'name',
      'abbreviation',
      'groupCount',
      'contestCount',
      'problemCount',
      'solvedCount',
      'level',
      'order',
    ]);
    final groupProperties = _properties(group);
    expect(groupProperties.keys.length, 9);
    for (final field in ['id', 'groupCount', 'contestCount']) {
      expect(_map(groupProperties[field]), {'type': 'number'});
    }
    for (final field in ['problemCount', 'solvedCount']) {
      expect(_map(groupProperties[field]), {
        'type': ['number', 'null'],
      });
    }
    expect(_map(groupProperties['name']), {'type': 'string'});
    expect(_map(groupProperties['abbreviation']), {
      'type': ['string', 'null'],
    });
    expect(_map(groupProperties['order']), order);

    final level = _map(groupProperties['level']);
    expect(level['type'], ['object', 'null']);
    expect(level.containsKey('additionalProperties'), isFalse);
    expect(_required(level), [
      'q25',
      'q50',
      'q75',
      'tierCounts',
      'ratedCount',
      'order',
      'progress',
    ]);
    final levelProperties = _properties(level);
    expect(levelProperties.keys.length, 7);
    for (final field in ['q25', 'q50', 'q75', 'ratedCount']) {
      expect(_map(levelProperties[field]), {'type': 'integer'});
    }
    expect(_map(levelProperties['tierCounts']), {
      'items': {'type': 'integer'},
      'type': 'array',
    });
    expect(_map(levelProperties['order']), order);
    expect(_map(levelProperties['progress']), {
      'properties': {
        'solved': {'type': 'integer'},
        'through': {
          'properties': {
            'q25': {'type': 'boolean'},
            'q50': {'type': 'boolean'},
            'q75': {'type': 'boolean'},
          },
          'required': ['q25', 'q50', 'q75'],
          'type': 'object',
        },
      },
      'required': ['solved', 'through'],
      'type': ['object', 'null'],
    });
  });

  test('pins the public source group detail and its shared shapes', () {
    final detail = _get(contract, '/api/v4/sources/groups/{id}');

    expect(_accessClass(detail), 'public');
    expect(detail.containsKey('security'), isFalse);
    expect(detail.containsKey('requestBody'), isFalse);
    expect(
      detail['summary'],
      'A source group: its path, child groups and contests',
    );
    expect(_parameters(detail), [
      {
        'in': 'path',
        'name': 'id',
        'required': true,
        'schema': {'exclusiveMinimum': 0, 'type': 'integer'},
      },
    ]);
    final responses = _map(detail['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'The group.');
    expect(_map(responses['404'])['description'], 'No such group.');
    expect(
      _jsonResponseSchema(detail, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    final schema = _responseSchema(detail);
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'group',
      'path',
      'links',
      'query',
      'groups',
      'contests',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 6);

    final rootGroup = _map(
      _map(_properties(_responseSchema(_get(contract, '/api/v4/sources')))[
          'groups'])['items'],
    );
    expect(_map(properties['group']), rootGroup);
    expect(_map(properties['groups']), {'items': rootGroup, 'type': 'array'});
    expect(_map(properties['query']), {
      'type': ['string', 'null'],
    });
    expect(_map(properties['path']), {
      'items': {
        'properties': {
          'id': {'type': 'number'},
          'name': {'type': 'string'},
        },
        'required': ['id', 'name'],
        'type': 'object',
      },
      'type': 'array',
    });
    expect(_map(properties['links']), {
      'items': {
        'properties': {
          'ojId': {'type': 'string'},
          'ojName': {'type': 'string'},
          'url': {'type': 'string'},
        },
        'required': ['ojId', 'ojName', 'url'],
        'type': 'object',
      },
      'type': 'array',
    });

    final contests = _map(properties['contests']);
    expect(contests['type'], 'array');
    final contest = _map(contests['items']);
    expect(contest['type'], 'object');
    expect(contest.containsKey('additionalProperties'), isFalse);
    expect(_required(contest), [
      'id',
      'name',
      'abbreviation',
      'startsAt',
      'problemCount',
      'solvedCount',
      'level',
    ]);
    final contestProperties = Map<String, dynamic>.of(_properties(contest));
    expect(contestProperties.remove('level'), _properties(rootGroup)['level']);
    expect(contestProperties, {
      'abbreviation': {
        'type': ['string', 'null'],
      },
      'id': {'type': 'number'},
      'name': {'type': 'string'},
      'problemCount': {'type': 'number'},
      'solvedCount': {
        'type': ['number', 'null'],
      },
      'startsAt': {
        'format': 'date-time',
        'type': ['string', 'null'],
      },
    });
  });

  test('pins the public source contest detail and its shared shapes', () {
    final detail = _get(contract, '/api/v4/sources/contests/{id}');
    final group = _get(contract, '/api/v4/sources/groups/{id}');

    expect(_accessClass(detail), 'public');
    expect(detail.containsKey('security'), isFalse);
    expect(detail.containsKey('requestBody'), isFalse);
    expect(
      detail['summary'],
      'A contest and its problems, in contest order',
    );
    expect(_parameters(detail), _parameters(group));
    final responses = _map(detail['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'The contest.');
    expect(_map(responses['404'])['description'], 'No such contest.');
    expect(
      _jsonResponseSchema(detail, '404'),
      _jsonResponseSchema(group, '404'),
    );

    final schema = _responseSchema(detail);
    final groupProperties = _properties(_responseSchema(group));
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      'contest',
      'path',
      'links',
      'query',
      'problems',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 5);
    for (final field in ['path', 'links', 'query']) {
      expect(properties[field], groupProperties[field], reason: field);
    }

    final contest = _map(properties['contest']);
    final groupContest = _map(_map(groupProperties['contests'])['items']);
    expect(contest['type'], 'object');
    expect(contest.containsKey('additionalProperties'), isFalse);
    expect(_required(contest), [..._required(groupContest), 'url', 'venue']);
    final contestProperties = Map<String, dynamic>.of(_properties(contest));
    expect(contestProperties.remove('url'), {
      'type': ['string', 'null'],
    });
    expect(contestProperties.remove('venue'), {
      'type': ['string', 'null'],
    });
    expect(contestProperties, _properties(groupContest));

    final problems = _map(properties['problems']);
    expect(problems['type'], 'array');
    final item = _map(problems['items']);
    expect(item['type'], 'object');
    expect(item.containsKey('additionalProperties'), isFalse);
    expect(_required(item), ['numberInContest', 'problem']);
    expect(_properties(item).keys.length, 2);
    expect(_map(_properties(item)['numberInContest']), {'type': 'string'});
    final searchItem = _map(
      _map(_properties(_responseSchema(_get(contract, '/api/v4/problems')))[
          'problems'])['items'],
    );
    expect(_map(_properties(item)['problem']), searchItem);
  });

  test('pins the public problem-search analysis schema without inference', () {
    final analysis = _get(contract, '/api/v4/search/analyze');

    expect(_map(analysis['x-access']), {'class': 'public'});
    expect(_parameterNames(analysis), ['q']);
    final parameter = _parameters(analysis).single;
    expect(parameter['in'], 'query');
    expect(parameter['required'], isFalse);
    expect(_map(parameter['schema']), {
      'type': 'string',
      'maxLength': 1000,
    });
    expect(_map(analysis['responses']).keys, unorderedEquals(['200']));

    final schema = _responseSchema(analysis);
    expect(_required(schema), ['diagnostics']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys, unorderedEquals(['diagnostics']));
    final diagnostics = _map(properties['diagnostics']);
    expect(diagnostics['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(diagnostics.containsKey(constraint), isFalse);
    }
    final item = _map(diagnostics['items']);
    expect(item['type'], 'object');
    expect(_required(item), [
      'start',
      'end',
      'severity',
      'code',
      'messageKey',
      'message',
    ]);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(
        itemProperties.keys,
        unorderedEquals([
          'start',
          'end',
          'severity',
          'code',
          'messageKey',
          'message',
          'data',
        ]));
    for (final field in ['start', 'end']) {
      final number = _map(itemProperties[field]);
      expect(number, {'type': 'number'});
      for (final constraint in ['minimum', 'maximum', 'multipleOf']) {
        expect(number.containsKey(constraint), isFalse);
      }
    }
    expect(_map(itemProperties['severity']), {
      'enum': ['error', 'warning'],
      'type': 'string',
    });
    expect(_map(itemProperties['code']), {
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
      'type': 'string',
    });
    for (final field in ['messageKey', 'message']) {
      expect(_map(itemProperties[field]), {'type': 'string'});
    }
    final data = _map(itemProperties['data']);
    expect(data['type'], 'object');
    expect(_map(data['additionalProperties']), {'type': 'string'});

    final problemSearch = _responseSchema(_get(contract, '/api/v4/problems'));
    final problemDiagnostics = _map(_properties(problemSearch)['diagnostics']);
    expect(item, _map(problemDiagnostics['items']));
  });

  test('pins the public search-suggestion schema without inference', () {
    final suggestions = _get(contract, '/api/v4/search/suggest');

    expect(_map(suggestions['x-access']), {'class': 'public'});
    expect(_parameterNames(suggestions), ['topic', 'value']);
    final parameters = _parameters(suggestions);
    expect(parameters.first['in'], 'query');
    expect(parameters.first['required'], isTrue);
    expect(_map(parameters.first['schema']), {
      'type': 'string',
      'maxLength': 64,
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'type': 'string',
      'maxLength': 100,
      'default': '',
    });
    expect(
      _map(suggestions['responses']).keys,
      unorderedEquals(['200']),
    );

    final schema = _responseSchema(suggestions);
    expect(_required(schema), ['suggestions']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys, unorderedEquals(['suggestions']));
    final list = _map(properties['suggestions']);
    expect(list['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(list.containsKey(constraint), isFalse);
    }
    final item = _map(list['items']);
    expect(item['type'], 'object');
    expect(_required(item), ['value', 'detail', 'tier']);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(itemProperties.keys, unorderedEquals(['value', 'detail', 'tier']));
    expect(_map(itemProperties['value']), {'type': 'string'});
    expect(_map(itemProperties['detail']), {
      'type': ['string', 'null'],
    });
    expect(_map(itemProperties['tier']), {
      'type': ['integer', 'null'],
    });
    for (final field in ['value', 'detail']) {
      final value = _map(itemProperties[field]);
      for (final constraint in [
        'minLength',
        'maxLength',
        'pattern',
        'format',
      ]) {
        expect(value.containsKey(constraint), isFalse);
      }
    }
    final tier = _map(itemProperties['tier']);
    for (final constraint in ['minimum', 'maximum', 'multipleOf']) {
      expect(tier.containsKey(constraint), isFalse);
    }
  });

  test('pins the public tag detail schema without inference', () {
    final tagDetail = _get(contract, '/api/v4/tags/{key}');

    expect(_accessClass(tagDetail), 'public');
    expect(_parameterNames(tagDetail), ['key']);
    final parameter = _parameters(tagDetail).single;
    expect(parameter['in'], 'path');
    expect(parameter['required'], isTrue);
    expect(_map(parameter['schema']), {
      'type': 'string',
      'minLength': 1,
      'maxLength': 64,
    });
    expect(_map(tagDetail['responses']).keys, containsAll(['200', '404']));

    const fields = [
      'id',
      'key',
      'names',
      'aliases',
      'parents',
      'children',
      'rated',
      'problemCount',
      'solvedCount',
      'levels',
    ];
    final schema = _responseSchema(tagDetail);
    expect(_required(schema), fields);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys.toList(growable: false), fields);
    expect(_map(properties['id']), {'type': 'number'});
    expect(_map(properties['key']), {'type': 'string'});
    expect(_map(properties['rated']), {'type': 'boolean'});
    expect(_map(properties['problemCount']), {'type': 'integer'});
    expect(_map(properties['solvedCount']), {
      'type': ['integer', 'null'],
    });

    void expectStringMap(Object? value) {
      final map = _map(value);
      expect(map['type'], 'object');
      expect(_map(map['additionalProperties']), {'type': 'string'});
      for (final constraint in [
        'minProperties',
        'maxProperties',
        'propertyNames',
      ]) {
        expect(map.containsKey(constraint), isFalse);
      }
    }

    expectStringMap(properties['names']);
    final aliases = _map(properties['aliases']);
    expect(aliases['type'], 'array');
    expect(_map(aliases['items']), {'type': 'string'});

    for (final field in ['aliases', 'parents', 'children', 'levels']) {
      final list = _map(properties[field]);
      expect(list['type'], 'array');
      for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
        expect(list.containsKey(constraint), isFalse);
      }
    }

    for (final field in ['parents', 'children']) {
      final relation = _map(_map(properties[field])['items']);
      expect(relation['type'], 'object');
      expect(_required(relation), ['key', 'names']);
      expect(relation.containsKey('additionalProperties'), isFalse);
      final relationProperties = _properties(relation);
      expect(relationProperties.keys.toList(growable: false), [
        'key',
        'names',
      ]);
      expect(_map(relationProperties['key']), {'type': 'string'});
      expectStringMap(relationProperties['names']);
    }

    final level = _map(_map(properties['levels'])['items']);
    expect(level['type'], 'object');
    expect(_required(level), ['level', 'count', 'solved']);
    expect(level.containsKey('additionalProperties'), isFalse);
    final levelProperties = _properties(level);
    expect(levelProperties.keys.toList(growable: false), [
      'level',
      'count',
      'solved',
    ]);
    expect(_map(levelProperties['level']), {'type': 'integer'});
    expect(_map(levelProperties['count']), {'type': 'integer'});
    expect(_map(levelProperties['solved']), {
      'type': ['integer', 'null'],
    });
  });

  test('pins the required activity range and sparse-day response', () {
    final activity = _get(contract, '/api/v4/users/{handle}/activity/days');
    expect(_accessClass(activity), 'public');
    expect(_parameterNames(activity), ['handle', 'from', 'to']);
    final activityParameters = _parameters(activity);
    expect(
      activityParameters
          .where((parameter) => parameter['required'] == true)
          .map((parameter) => parameter['name']),
      ['handle', 'from', 'to'],
    );
    for (final field in ['from', 'to']) {
      final parameter = activityParameters.singleWhere(
        (parameter) => parameter['name'] == field,
      );
      expect(parameter['in'], 'query');
      expect(parameter['required'], isTrue);
      expect(_map(parameter['schema']), {
        'type': 'string',
        'pattern': r'^\d{4}-\d{2}-\d{2}$',
      });
    }
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

  test('pins the public activity feed without inferred event relations', () {
    final feed = _get(contract, '/api/v4/users/{handle}/activity/feed');
    expect(_accessClass(feed), 'public');
    expect(_parameterNames(feed), ['handle', 'before', 'from', 'to', 'limit']);

    final parameters = _parameters(feed);
    final handle = parameters.singleWhere(
      (parameter) => parameter['name'] == 'handle',
    );
    expect(handle['in'], 'path');
    expect(handle['required'], isTrue);
    expect(_map(handle['schema']), {
      'maxLength': 64,
      'minLength': 1,
      'type': 'string',
    });
    final before = parameters.singleWhere(
      (parameter) => parameter['name'] == 'before',
    );
    expect(before['in'], 'query');
    expect(before['required'], isFalse);
    expect(_map(before['schema']), {'type': 'string'});
    for (final name in ['from', 'to']) {
      final parameter = parameters.singleWhere(
        (candidate) => candidate['name'] == name,
      );
      expect(parameter['in'], 'query');
      expect(parameter['required'], isFalse);
      expect(_map(parameter['schema']), {
        'pattern': r'^\d{4}-\d{2}-\d{2}$',
        'type': 'string',
      });
    }
    final limit = parameters.singleWhere(
      (parameter) => parameter['name'] == 'limit',
    );
    expect(limit['in'], 'query');
    expect(limit['required'], isFalse);
    expect(_map(limit['schema']), {
      'maximum': 500,
      'minimum': 1,
      'type': 'integer',
    });

    final responses = _map(feed['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'One page, newest first.');
    expect(_map(responses['404'])['description'], 'No such user.');

    final schema = _responseSchema(feed);
    expect(schema['type'], 'object');
    expect(_required(schema), ['events', 'nextCursor']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(_map(properties['nextCursor']), {
      'type': ['string', 'null'],
    });

    final events = _map(properties['events']);
    expect(events['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(events.containsKey(constraint), isFalse);
    }
    final event = _map(events['items']);
    expect(event['type'], 'object');
    expect(_required(event), [
      'id',
      'type',
      'occurredAt',
      'problem',
      'reason',
      'milestone',
    ]);
    expect(event.containsKey('additionalProperties'), isFalse);
    final eventProperties = _properties(event);
    expect(_map(eventProperties['id']), {'type': 'integer'});
    expect(_map(eventProperties['type']), {
      'enum': [
        'solved',
        'unsolved',
        'vote',
        'rating',
        'tier',
        'solvedMilestone',
        'voteMilestone',
      ],
      'type': 'string',
    });
    expect(_map(eventProperties['occurredAt']), {'type': 'string'});
    expect(_map(eventProperties['reason']), {
      'type': ['string', 'null'],
    });
    expect(_map(eventProperties['milestone']), {
      'type': ['integer', 'null'],
    });
    expect(_map(eventProperties['payload']), isEmpty);

    final problem = _map(eventProperties['problem']);
    expect(problem['type'], ['object', 'null']);
    expect(_required(problem), [
      'problemId',
      'subId',
      'level',
      'effectiveVoteCount',
      'givesNoRating',
      'isStandard',
      'titles',
      'userStatus',
    ]);
    expect(problem.containsKey('additionalProperties'), isFalse);
    final problemProperties = _properties(problem);
    expect(_map(problemProperties['problemId']), {'type': 'integer'});
    expect(_map(problemProperties['subId']), {'type': 'string'});
    expect(_map(problemProperties['level']), {
      'maximum': 30,
      'minimum': 0,
      'type': 'integer',
    });
    expect(_map(problemProperties['effectiveVoteCount']), {
      'minimum': 0,
      'type': 'integer',
    });
    for (final field in ['givesNoRating', 'isStandard']) {
      expect(_map(problemProperties[field]), {'type': 'boolean'});
    }
    expect(_map(problemProperties['userStatus']), {
      'enum': ['solved', 'partial', 'tried', null],
      'type': ['string', 'null'],
    });
    final titles = _map(problemProperties['titles']);
    expect(titles['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(titles.containsKey(constraint), isFalse);
    }
    final search = _get(contract, '/api/v4/problems');
    final searchProblem = _map(
      _map(_properties(_responseSchema(search))['problems'])['items'],
    );
    final searchTitle = _map(
      _map(_properties(searchProblem)['titles'])['items'],
    );
    expect(_map(titles['items']), searchTitle);
  });

  test('pins the public reputation log and its shared problem shape', () {
    final log = _get(contract, '/api/v4/users/{handle}/reputation/log');

    expect(_accessClass(log), 'public');
    expect(log.containsKey('security'), isFalse);
    expect(log.containsKey('requestBody'), isFalse);
    expect(log['summary'], "What moved a user's reputation, day by day");
    expect(_parameters(log), [
      {
        'in': 'path',
        'name': 'handle',
        'required': true,
        'schema': {'maxLength': 64, 'minLength': 1, 'type': 'string'},
      },
      {
        'in': 'query',
        'name': 'month',
        'required': false,
        'schema': {
          'pattern': r'^\d{4}-(0[1-9]|1[0-2])$',
          'type': 'string',
        },
      },
    ]);
    final responses = _map(log['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'The days, newest first.');
    expect(_map(responses['404'])['description'], 'No such user.');
    expect(
      _jsonResponseSchema(log, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    const dayPattern = r'^\d{4}-\d{2}-\d{2}$';
    final schema = _responseSchema(log);
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), ['days', 'firstDay']);
    final properties = _properties(schema);
    expect(properties.keys.length, 2);
    expect(_map(properties['firstDay']), {
      'pattern': dayPattern,
      'type': ['string', 'null'],
    });

    final days = _map(properties['days']);
    expect(days['type'], 'array');
    final day = _map(days['items']);
    expect(day['type'], 'object');
    expect(day.containsKey('additionalProperties'), isFalse);
    expect(_required(day), [
      'day',
      'change',
      'after',
      'capped',
      'items',
      'others',
    ]);
    final dayProperties = _properties(day);
    expect(dayProperties.keys.length, 6);
    expect(_map(dayProperties['day']), {
      'pattern': dayPattern,
      'type': 'string',
    });
    for (final field in ['change', 'after', 'capped']) {
      expect(_map(dayProperties[field]), {'type': 'integer'});
    }
    expect(_map(dayProperties['others']), {
      'properties': {
        'count': {'type': 'integer'},
        'points': {'type': 'integer'},
      },
      'required': ['count', 'points'],
      'type': ['object', 'null'],
    });

    final items = _map(dayProperties['items']);
    expect(items['type'], 'array');
    final item = _map(items['items']);
    expect(item['type'], 'object');
    expect(item.containsKey('additionalProperties'), isFalse);
    expect(_required(item), ['kind', 'problem', 'count', 'points']);
    final itemProperties = _properties(item);
    expect(itemProperties.keys.length, 4);
    expect(_map(itemProperties['kind']), {
      'enum': [
        'contribution',
        'helpful',
        'unhelpful',
        'markedUnhelpful',
        'takedown',
      ],
      'type': 'string',
    });
    for (final field in ['count', 'points']) {
      expect(_map(itemProperties[field]), {'type': 'integer'});
    }
    final feedProblem = _map(
      _properties(_map(_map(_properties(_responseSchema(
        _get(contract, '/api/v4/users/{handle}/activity/feed'),
      ))['events'])['items']))['problem'],
    );
    expect(_map(itemProperties['problem']), feedProblem);
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

  test('pins the public overall ranking without inferred relations', () {
    final ranking = _get(contract, '/api/v4/rankings/users');

    expect(_accessClass(ranking), 'public');
    expect(ranking.containsKey('security'), isFalse);
    expect(ranking.containsKey('requestBody'), isFalse);
    expect(
      ranking['summary'],
      'The overall ranking, by rating, solved count, or contributions',
    );
    expect(_parameterNames(ranking), ['page', 'sort']);

    final parameters = _parameters(ranking);
    for (final parameter in parameters) {
      expect(parameter['in'], 'query');
      expect(parameter['required'], isFalse);
    }
    expect(_map(parameters.first['schema']), {
      'default': 1,
      'minimum': 1,
      'type': 'integer',
    });
    expect(_map(parameters.last['schema']), {
      'default': 'rating',
      'enum': ['rating', 'solved', 'contribution'],
      'type': 'string',
    });

    final responses = _map(ranking['responses']);
    expect(responses.keys.toList(growable: false), ['200']);
    expect(_map(responses['200'])['description'], 'One page of the board.');

    final schema = _responseSchema(ranking);
    expect(schema['type'], 'object');
    expect(_required(schema), [
      'me',
      'mePage',
      'total',
      'page',
      'pageSize',
      'items',
    ]);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys.toList(growable: false), [
      'items',
      'me',
      'mePage',
      'page',
      'pageSize',
      'total',
    ]);

    for (final field in ['page', 'pageSize', 'total']) {
      expect(_map(properties[field]), {'type': 'integer'});
    }
    expect(_map(properties['mePage']), {
      'type': ['integer', 'null'],
    });

    final items = _map(properties['items']);
    expect(items['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(items.containsKey(constraint), isFalse);
    }
    final item = _map(items['items']);
    final me = _map(properties['me']);
    expect(item['type'], 'object');
    expect(me['type'], ['object', 'null']);

    const userFields = [
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
    ];
    for (final user in [item, me]) {
      expect(_required(user), userFields);
      expect(user.containsKey('additionalProperties'), isFalse);
    }
    final userProperties = _properties(item);
    expect(_properties(me), userProperties);
    expect(userProperties.keys.toList(growable: false), [
      'class',
      'classPlus',
      'globalRank',
      'handle',
      'id',
      'profileImageUrl',
      'rank',
      'rating',
      'reputation',
      'solvedCount',
      'tagRating',
      'tier',
      'voteCount',
    ]);

    expect(_map(userProperties['id']), {'type': 'number'});
    expect(_map(userProperties['handle']), {'type': 'string'});
    expect(_map(userProperties['tier']), {
      'maximum': 31,
      'minimum': 0,
      'type': ['integer', 'null'],
    });
    expect(_map(userProperties['profileImageUrl']), {
      'format': 'uri',
      'type': ['string', 'null'],
    });
    for (final field in [
      'rank',
      'rating',
      'solvedCount',
      'voteCount',
      'reputation',
      'class',
    ]) {
      expect(_map(userProperties[field]), {'type': 'integer'});
    }
    expect(_map(userProperties['classPlus']), {'type': 'boolean'});
    for (final field in ['tagRating', 'globalRank']) {
      expect(_map(userProperties[field]), {
        'type': ['integer', 'null'],
      });
    }

    final search = _get(contract, '/api/v4/rankings/users/search');
    final searchItems = _map(_properties(_responseSchema(search))['items']);
    final searchUser = _map(searchItems['items']);
    final searchProperties = _properties(searchUser);
    expect(_required(searchUser), [...userFields, 'page']);
    for (final field in userFields) {
      expect(searchProperties[field], userProperties[field]);
    }
    expect(_map(searchProperties['page']), {'type': 'integer'});
    expect(userProperties.containsKey('page'), isFalse);
  });

  test('pins the public region ranking to the shared leaderboard schema', () {
    final region = _get(contract, '/api/v4/rankings/regions/{countryCode}');

    expect(_accessClass(region), 'public');
    expect(region.containsKey('security'), isFalse);
    expect(region.containsKey('requestBody'), isFalse);
    expect(region['summary'], 'The ranking within one region');
    expect(_parameterNames(region), ['countryCode', 'page']);

    final parameters = _parameters(region);
    expect(parameters.first, {
      'in': 'path',
      'name': 'countryCode',
      'required': true,
      'schema': {'maxLength': 2, 'minLength': 2, 'type': 'string'},
    });
    expect(parameters.last, {
      'in': 'query',
      'name': 'page',
      'required': false,
      'schema': {'default': 1, 'minimum': 1, 'type': 'integer'},
    });

    final responses = _map(region['responses']);
    expect(responses.keys.toList(growable: false), ['200']);
    expect(_map(responses['200'])['description'], 'One page of the board.');
    expect(
      _responseSchema(region),
      _responseSchema(_get(contract, '/api/v4/rankings/users')),
    );
  });

  test('pins the viewer wallet history and its shared shapes', () {
    final history = _get(contract, '/api/v4/account/wallet/history');
    final wallet = _get(contract, '/api/v4/account/wallet');
    final log = _get(contract, '/api/v4/users/{handle}/reputation/log');
    final reports = _get(contract, '/api/v4/problems/{problemId}/reports');
    final search = _get(contract, '/api/v4/problems');

    expect(_accessClass(history), 'user');
    expect(_accessScope(history), 'wallet');
    expect(history.containsKey('security'), isFalse);
    expect(history.containsKey('requestBody'), isFalse);
    expect(
      history['summary'],
      "A month of the signed-in user's Stardust history",
    );
    expect(_parameters(history), [
      _parameters(log).last,
      {
        'in': 'query',
        'name': 'lang',
        'required': false,
        'schema': {'default': 'ko', 'maxLength': 16, 'type': 'string'},
      },
    ]);
    final responses = _map(history['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(_map(responses['200'])['description'], 'Newest first.');
    expect(_map(responses['401']), _map(_map(wallet['responses'])['401']));

    final schema = _responseSchema(history);
    expect(_required(schema), ['month', 'moves']);
    final properties = _properties(schema);
    expect(properties.keys.length, 2);
    expect(_map(properties['month']), {'type': 'string'});
    final move = _map(_map(properties['moves'])['items']);
    expect(_required(move), [
      'id',
      'delta',
      'balanceAfter',
      'reason',
      'at',
      'day',
      'problem',
      'label',
    ]);
    final moveProperties = _properties(move);
    expect(moveProperties.keys.length, 8);
    for (final field in ['id', 'delta', 'balanceAfter']) {
      expect(_map(moveProperties[field]), {'type': 'integer'});
    }
    expect(_map(moveProperties['at']), {'type': 'string'});
    for (final field in ['day', 'label']) {
      expect(_map(moveProperties[field]), {
        'type': ['string', 'null'],
      });
    }
    expect(_map(moveProperties['reason']), {
      'enum': [
        'migration',
        'welcome',
        'first_solve',
        'solve',
        'contribute',
        'shop_purchase',
        'redeem',
        'admin',
      ],
      'type': 'string',
    });
    final reportItem =
        _map(_map(_properties(_responseSchema(reports))['items'])['items']);
    final sameProblem =
        _map(_map(_properties(reportItem)['sameProblems'])['items']);
    final searchItem =
        _map(_map(_properties(_responseSchema(search))['problems'])['items']);
    final problem = _map(moveProperties['problem']);
    expect(problem['type'], ['object', 'null']);
    expect(_required(problem), [..._required(sameProblem), 'titles']);
    final problemProperties = Map<String, dynamic>.of(_properties(problem));
    expect(
        problemProperties.remove('titles'), _properties(searchItem)['titles']);
    expect(problemProperties, _properties(sameProblem));
  });

  test('pins the viewer wallet without inferred relationships', () {
    final wallet = _get(contract, '/api/v4/account/wallet');

    expect(_accessClass(wallet), 'user');
    expect(_accessScope(wallet), 'wallet');
    expect(wallet.containsKey('security'), isFalse);
    expect(wallet.containsKey('requestBody'), isFalse);
    expect(wallet.containsKey('parameters'), isFalse);
    expect(wallet['summary'], "The signed-in user's Stardust");
    final responses = _map(wallet['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      "The balance, and today's capped earnings.",
    );
    expect(_map(responses['401'])['description'], 'Not signed in.');
    expect(
      _jsonResponseSchema(wallet, '401'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );
    expect(_responseSchema(wallet), {
      'properties': {
        'earnings': {
          'properties': {
            'contribute': {'type': 'integer'},
            'firstSolve': {'type': 'integer'},
            'solve': {'type': 'integer'},
            'welcomeMax': {'type': 'integer'},
            'welcomePerSolve': {'type': 'integer'},
          },
          'required': [
            'firstSolve',
            'solve',
            'contribute',
            'welcomePerSolve',
            'welcomeMax',
          ],
          'type': 'object',
        },
        'stardusts': {'type': 'integer'},
        'today': {
          'properties': {
            'cap': {'type': 'integer'},
            'day': {'type': 'string'},
            'earned': {'type': 'integer'},
          },
          'required': ['day', 'earned', 'cap'],
          'type': 'object',
        },
      },
      'required': ['stardusts', 'today', 'earnings'],
      'type': 'object',
    });
  });

  test('pins the viewer pending consents and their two slugs', () {
    final consents = _get(contract, '/api/v4/account/consents');

    expect(_accessClass(consents), 'user');
    expect(_accessScope(consents), 'profile');
    expect(consents.containsKey('security'), isFalse);
    expect(consents.containsKey('requestBody'), isFalse);
    expect(consents.containsKey('parameters'), isFalse);
    expect(
      consents['summary'],
      'The policy versions in force that this account has not agreed to',
    );
    final responses = _map(consents['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      'Empty when the account is up to date.',
    );
    expect(_map(responses['401'])['description'], 'Not signed in.');
    expect(
      _jsonResponseSchema(consents, '401'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );
    expect(_responseSchema(consents), {
      'properties': {
        'pending': {
          'items': {
            'properties': {
              'label': {'type': 'string'},
              'slug': {
                'enum': ['tos', 'privacy'],
                'type': 'string',
              },
              'version': {'type': 'string'},
            },
            'required': ['slug', 'version', 'label'],
            'type': 'object',
          },
          'type': 'array',
        },
      },
      'required': ['pending'],
      'type': 'object',
    });
  });

  test('pins the viewer items and the shared vacation shape', () {
    final items = _get(contract, '/api/v4/account/items');
    final days = _get(contract, '/api/v4/users/{handle}/activity/days');

    expect(_accessClass(items), 'user');
    expect(_accessScope(items), 'collection');
    expect(items.containsKey('security'), isFalse);
    expect(items.containsKey('requestBody'), isFalse);
    expect(items['summary'], 'The items the signed-in user holds');
    expect(_parameters(items), [
      {
        'in': 'query',
        'name': 'lang',
        'required': false,
        'schema': {'default': 'ko', 'maxLength': 16, 'type': 'string'},
      },
    ]);
    final responses = _map(items['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      'Held items, and the vacation the user is on.',
    );
    expect(_map(responses['401'])['description'], 'Not signed in.');

    final schema = _responseSchema(items);
    expect(_required(schema), ['items', 'streakThemes', 'vacation']);
    final properties = _properties(schema);
    expect(properties.keys.length, 3);
    expect(
      _map(properties['vacation']),
      _map(_properties(_responseSchema(days))['vacation']),
    );
    const nullableString = {
      'type': ['string', 'null'],
    };
    expect(_map(properties['streakThemes']), {
      'properties': {
        'equipped': {'type': 'string'},
        'owned': {
          'items': {
            'properties': {
              'acquiredAt': nullableString,
              'theme': {'type': 'string'},
            },
            'required': ['theme', 'acquiredAt'],
            'type': 'object',
          },
          'type': 'array',
        },
      },
      'required': ['equipped', 'owned'],
      'type': 'object',
    });
    expect(_map(properties['items']), {
      'items': {
        'properties': {
          'description': {'type': 'string'},
          'effect': nullableString,
          'equipped': {
            'type': ['boolean', 'null'],
          },
          'imageUrl': {'type': 'string'},
          'key': {'type': 'string'},
          'kind': {
            'enum': ['consumable', 'equippable', 'voucher', 'keepsake'],
            'type': 'string',
          },
          'maxUnits': {'type': 'integer'},
          'name': {'type': 'string'},
          'progress': {
            'properties': {
              'held': {'type': 'integer'},
              'total': {'type': 'integer'},
            },
            'required': ['held', 'total'],
            'type': ['object', 'null'],
          },
          'stacks': {
            'items': {
              'properties': {
                'counted': {'type': 'boolean'},
                'day': nullableString,
                'expiresAt': nullableString,
                'units': {'type': 'integer'},
                'usable': {'type': 'boolean'},
              },
              'required': ['units', 'expiresAt', 'day', 'usable', 'counted'],
              'type': 'object',
            },
            'type': 'array',
          },
          'units': {'type': 'integer'},
          'usable': {'type': 'boolean'},
        },
        'required': [
          'key',
          'kind',
          'effect',
          'name',
          'description',
          'imageUrl',
          'units',
          'maxUnits',
          'usable',
          'equipped',
          'progress',
          'stacks',
        ],
        'type': 'object',
      },
      'type': 'array',
    });
  });

  test('pins the viewer profile and its documented bounds', () {
    final profile = _get(contract, '/api/v4/account/profile');

    expect(_accessClass(profile), 'user');
    expect(_accessScope(profile), 'profile.personal');
    expect(profile.containsKey('security'), isFalse);
    expect(profile.containsKey('requestBody'), isFalse);
    expect(profile.containsKey('parameters'), isFalse);
    expect(
      profile['summary'],
      "The signed-in user's own profile, editable fields only",
    );
    final responses = _map(profile['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      'Every editable field beside its visibility flag.',
    );
    expect(_map(responses['401'])['description'], 'Not signed in.');

    final schema = _responseSchema(profile);
    expect(_required(schema), ['profile']);
    expect(_properties(schema).keys.length, 1);
    final body = _map(_properties(schema)['profile']);
    expect(body['type'], 'object');
    expect(_required(body), [
      'bio',
      'profileImageUrl',
      'countryCode',
      'showCountry',
      'gender',
      'customGender',
      'pronouns',
      'showPronouns',
      'birthYear',
      'birthMonth',
      'birthDay',
      'showBirthday',
      'showBirthYear',
      'name',
      'nameNative',
      'showName',
      'showDiscord',
      'showIcpc',
      'backgroundId',
    ]);
    final properties = _properties(body);
    expect(properties.keys.length, 19);
    const nullableString = ['string', 'null'];
    const nullableInteger = ['integer', 'null'];
    for (final MapEntry(key: field, value: maximum) in {
      'bio': 2000,
      'customGender': 64,
      'pronouns': 64,
      'name': 128,
      'nameNative': 128,
    }.entries) {
      expect(_map(properties[field]), {
        'maxLength': maximum,
        'type': nullableString,
      });
    }
    expect(_map(properties['profileImageUrl']), {
      'format': 'uri',
      'maxLength': 1024,
      'type': nullableString,
    });
    expect(_map(properties['countryCode']), {
      'pattern': r'^[A-Z]{2}$',
      'type': nullableString,
    });
    for (final MapEntry(key: field, value: (minimum, maximum)) in {
      'birthYear': (1900, 2100),
      'birthMonth': (1, 12),
      'birthDay': (1, 31),
    }.entries) {
      expect(_map(properties[field]), {
        'maximum': maximum,
        'minimum': minimum,
        'type': nullableInteger,
      });
    }
    expect(_map(properties['backgroundId']), {'type': nullableInteger});
    expect(_map(properties['gender']), {
      'anyOf': [
        for (final code in [0, 1, 2, 9])
          {
            'enum': [code],
            'type': 'number',
          },
      ],
    });
    for (final field in [
      'showCountry',
      'showPronouns',
      'showBirthday',
      'showBirthYear',
      'showName',
      'showDiscord',
      'showIcpc',
    ]) {
      expect(_map(properties[field]), {'type': 'boolean'});
    }
  });

  test('pins the viewer settings and their exact value sets', () {
    final path = _map(_map(contract['paths'])['/api/v4/account/settings']);
    final settings = _get(contract, '/api/v4/account/settings');

    expect(path.keys.toList(growable: false), ['get', 'patch']);
    expect(_accessClass(settings), 'user');
    expect(_accessScope(settings), 'settings');
    expect(settings.containsKey('security'), isFalse);
    expect(settings.containsKey('requestBody'), isFalse);
    expect(settings.containsKey('parameters'), isFalse);
    expect(
      settings['summary'],
      "The signed-in user's settings, defaults applied",
    );
    final responses = _map(settings['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(_map(responses['200'])['description'], 'Every setting, resolved.');
    expect(_map(responses['401'])['description'], 'Not signed in.');

    final schema = _responseSchema(settings);
    expect(_required(schema), ['settings']);
    expect(_properties(schema).keys.length, 1);
    final body = _map(_properties(schema)['settings']);
    expect(body['type'], 'object');
    expect(_required(body), [
      'theme',
      'iconTheme',
      'iconSchemeSolved',
      'iconSchemeUnsolved',
      'iconSchemeHover',
      'iconWarnMode',
      'iconWarnRelative',
      'iconWarnAbsolute',
      'alwaysShowUnrated',
      'alwaysShowUnratable',
      'showSolvedUserCount',
      'showVotedUserCount',
      'showTagButton',
      'tagDisplayLanguage',
      'problemSort',
      'problemSortDirection',
      'showOriginalTitle',
      'showOriginalContest',
      'sourceLevelAllSolved',
      'sourceLevelPartlySolved',
      'sourceLevelUnsolved',
      'sourceLevelHover',
      'sourceLevelDisplay',
      'sourceSort',
      'sourceSortDirection',
      'sourceOrderType',
      'sourceOrderHover',
    ]);
    expect(_properties(body), {
      'alwaysShowUnratable': {'type': 'boolean'},
      'alwaysShowUnrated': {'type': 'boolean'},
      'iconSchemeHover': {
        'enum': ['show', 'warn', 'hide'],
        'type': 'string'
      },
      'iconSchemeSolved': {
        'enum': ['show', 'warn', 'hide'],
        'type': 'string'
      },
      'iconSchemeUnsolved': {
        'enum': ['show', 'warn', 'hide'],
        'type': 'string'
      },
      'iconTheme': {
        'enum': ['default', 'legacy'],
        'type': 'string'
      },
      'iconWarnAbsolute': {'maximum': 30, 'minimum': 0, 'type': 'integer'},
      'iconWarnMode': {
        'enum': ['relative', 'absolute'],
        'type': 'string'
      },
      'iconWarnRelative': {'maximum': 30, 'minimum': -30, 'type': 'integer'},
      'problemSort': {
        'enum': ['id', 'level', 'solved', 'average_try', 'random'],
        'type': 'string'
      },
      'problemSortDirection': {
        'enum': ['asc', 'desc'],
        'type': 'string'
      },
      'showOriginalContest': {'type': 'boolean'},
      'showOriginalTitle': {'type': 'boolean'},
      'showSolvedUserCount': {
        'enum': ['show', 'solved-only', 'hide'],
        'type': 'string'
      },
      'showTagButton': {
        'enum': ['show', 'solved-only', 'hide'],
        'type': 'string'
      },
      'showVotedUserCount': {
        'enum': ['show', 'solved-only', 'hide'],
        'type': 'string'
      },
      'sourceLevelAllSolved': {
        'enum': ['show', 'hide'],
        'type': 'string'
      },
      'sourceLevelDisplay': {
        'enum': ['dots', 'gradient', 'none'],
        'type': 'string'
      },
      'sourceLevelHover': {
        'enum': ['show', 'hide'],
        'type': 'string'
      },
      'sourceLevelPartlySolved': {
        'enum': ['show', 'partial-if-ascending', 'partial', 'hide'],
        'type': 'string'
      },
      'sourceLevelUnsolved': {
        'enum': ['show', 'hide'],
        'type': 'string'
      },
      'sourceOrderHover': {
        'enum': ['show', 'hide'],
        'type': 'string'
      },
      'sourceOrderType': {
        'enum': ['show', 'partly-solved', 'all-solved', 'hide'],
        'type': 'string'
      },
      'sourceSort': {
        'enum': ['default', 'name', 'size', 'p25', 'p50', 'p75'],
        'type': 'string'
      },
      'sourceSortDirection': {
        'enum': ['asc', 'desc'],
        'type': 'string'
      },
      'tagDisplayLanguage': {
        'enum': ['identifier', 'ko', 'en', 'ja'],
        'type': 'string'
      },
      'theme': {
        'enum': ['system', 'light', 'dark'],
        'type': 'string'
      },
    });
  });

  test('pins the viewer settings patch as the nullable read schema', () {
    final item = _map(_map(contract['paths'])['/api/v4/account/settings']);
    final read = _map(item['get']);
    final patch = _map(item['patch']);

    expect(_accessClass(patch), 'user');
    expect(_accessScope(patch), 'settings.write');
    expect(patch.containsKey('security'), isFalse);
    expect(patch.containsKey('parameters'), isFalse);
    expect(patch['summary'], "Change some of the signed-in user's settings");
    final requestBody = _map(patch['requestBody']);
    expect(requestBody.keys.toList(growable: false), ['content']);
    final content = _map(requestBody['content']);
    expect(content.keys.toList(growable: false), ['application/json']);
    final body = _map(_map(content['application/json'])['schema']);
    expect(body['type'], 'object');
    expect(body['additionalProperties'], isFalse);
    expect(body.containsKey('required'), isFalse);
    final readSettings = _map(_properties(_responseSchema(read))['settings']);
    final readProperties = _properties(readSettings);
    final patchProperties = _properties(body);
    expect(patchProperties.keys.toSet(), readProperties.keys.toSet());
    for (final MapEntry(key: field, value: value) in readProperties.entries) {
      final schema = Map<String, dynamic>.of(_map(value));
      schema['type'] = [schema['type'], 'null'];
      if (schema['enum'] case final List<dynamic> values) {
        schema['enum'] = [...values, null];
      }
      expect(_map(patchProperties[field]), schema, reason: field);
    }

    final responses = _map(patch['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      'Every setting after the patch, resolved.',
    );
    expect(
      _map(responses['200'])['content'],
      _map(_map(read['responses'])['200'])['content'],
    );
    expect(_map(responses['401']), _map(_map(read['responses'])['401']));
  });

  test('pins adding a bookmark favorite as a bodyless POST', () {
    final item = _map(
      _map(contract['paths'])[
          '/api/v4/account/bookmark-favorites/{handle}/{slug}'],
    );
    final add = _map(item['post']);
    final remove = _map(item['delete']);
    final folders = _get(contract, '/api/v4/account/bookmarks');

    expect(item.keys.toList(growable: false), ['delete', 'post']);
    expect(_accessClass(add), 'user');
    expect(_accessScope(add), 'bookmarks.write');
    expect(add.containsKey('security'), isFalse);
    expect(add.containsKey('requestBody'), isFalse);
    expect(
      add['summary'],
      "Add someone else's folder to the signed-in user's favorites",
    );
    expect(_parameters(add), [
      {
        'in': 'path',
        'name': 'handle',
        'required': true,
        'schema': {'maxLength': 64, 'minLength': 1, 'type': 'string'},
      },
      {
        'in': 'path',
        'name': 'slug',
        'required': true,
        'schema': {'pattern': r'^[0-9a-z_]{1,32}$', 'type': 'string'},
      },
    ]);
    final responses = _map(add['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401', '404']);
    expect(
      _map(responses['200'])['description'],
      'Favorited, or already was.',
    );
    expect(
      _map(responses['404'])['description'],
      "No such folder, it is private, or it is the caller's own.",
    );
    expect(
      _map(responses['401']),
      _map(_map(folders['responses'])['401']),
    );
    expect(_responseSchema(add), {
      'properties': {
        'favoriteCount': {'type': 'number'},
        'isFavorite': {'type': 'boolean'},
      },
      'required': ['isFavorite', 'favoriteCount'],
      'type': 'object',
    });
    expect(_responseSchema(remove), _responseSchema(add));
  });

  test('pins removing a bookmark favorite as a bodyless DELETE', () {
    final item = _map(
      _map(contract['paths'])[
          '/api/v4/account/bookmark-favorites/{handle}/{slug}'],
    );
    final add = _map(item['post']);
    final remove = _map(item['delete']);

    expect(_accessClass(remove), 'user');
    expect(_accessScope(remove), 'bookmarks.write');
    expect(remove.containsKey('security'), isFalse);
    expect(remove.containsKey('requestBody'), isFalse);
    expect(
      remove['summary'],
      "Remove a folder from the signed-in user's favorites",
    );
    expect(_parameters(remove), _parameters(add));
    final responses = _map(remove['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(_map(responses['200'])['description'], 'Not favorited, now.');
    expect(_map(responses['401']), _map(_map(add['responses'])['401']));
  });

  test('pins updating a bookmark folder as a partial JSON PATCH', () {
    final paths = _map(contract['paths']);
    final item = _map(paths['/api/v4/account/bookmarks/{slug}']);
    final update = _map(item['patch']);
    final delete = _map(item['delete']);
    final create = _map(_map(paths['/api/v4/account/bookmarks'])['post']);

    expect(_accessClass(update), 'user');
    expect(_accessScope(update), 'bookmarks.write');
    expect(update.containsKey('security'), isFalse);
    expect(
      update['summary'],
      "Rename, describe, recolour or change a folder's visibility",
    );
    expect(_parameters(update), _parameters(delete));
    final content = _map(_map(update['requestBody'])['content']);
    expect(content.keys.toList(growable: false), ['application/json']);
    final body = _map(_map(content['application/json'])['schema']);
    expect(body['type'], 'object');
    expect(body.containsKey('required'), isFalse);
    expect(body.containsKey('additionalProperties'), isFalse);
    final createProperties = _properties(
      _map(_map(
              _map(_map(create['requestBody'])['content'])['application/json'])[
          'schema']),
    );
    final properties = _properties(body);
    expect(properties.keys.toSet(), createProperties.keys.toSet());
    for (final field in properties.keys) {
      final expected = Map<String, dynamic>.of(_map(createProperties[field]))
        ..remove('default');
      expect(_map(properties[field]), expected, reason: field);
    }
    final responses = _map(update['responses']);
    expect(
      responses.keys.toList(growable: false),
      ['200', '401', '404', '409'],
    );
    expect(_map(responses['200'])['description'], 'The folder.');
    expect(_map(responses['404'])['description'], 'No such folder.');
    expect(_map(responses['409'])['description'], 'That slug is taken.');
    expect(
      _map(responses['200'])['content'],
      _map(_map(create['responses'])['201'])['content'],
    );
    expect(_map(responses['401']), _map(_map(delete['responses'])['401']));
  });

  test('pins deleting a bookmark folder as a bodyless 204 DELETE', () {
    final item =
        _map(_map(contract['paths'])['/api/v4/account/bookmarks/{slug}']);
    final delete = _map(item['delete']);
    final folders = _get(contract, '/api/v4/account/bookmarks');

    expect(item.keys.toList(growable: false), ['delete', 'patch']);
    expect(_accessClass(delete), 'user');
    expect(_accessScope(delete), 'bookmarks.write');
    expect(delete.containsKey('security'), isFalse);
    expect(delete.containsKey('requestBody'), isFalse);
    expect(delete['summary'], 'Delete a folder and its list');
    expect(_parameters(delete), [
      {
        'in': 'path',
        'name': 'slug',
        'required': true,
        'schema': {'pattern': r'^[0-9a-z_]{1,32}$', 'type': 'string'},
      },
    ]);
    final responses = _map(delete['responses']);
    expect(responses.keys.toList(growable: false), ['204', '401', '404']);
    expect(_map(responses['204']), {'description': 'Deleted.'});
    expect(_map(responses['404'])['description'], 'No such folder.');
    expect(
      _map(responses['401']),
      _map(_map(folders['responses'])['401']),
    );
  });

  test('pins reordering bookmark folders as a 204 JSON POST', () {
    final item =
        _map(_map(contract['paths'])['/api/v4/account/bookmarks/order']);
    final order = _map(item['post']);
    final folders = _get(contract, '/api/v4/account/bookmarks');

    expect(item.keys.toList(growable: false), ['post']);
    expect(_accessClass(order), 'user');
    expect(_accessScope(order), 'bookmarks.write');
    expect(order.containsKey('security'), isFalse);
    expect(order.containsKey('parameters'), isFalse);
    expect(order['summary'], "Rearrange the signed-in user's folders");
    expect(_map(order['requestBody']), {
      'content': {
        'application/json': {
          'schema': {
            'properties': {
              'slugs': {
                'items': {
                  'pattern': r'^[0-9a-z_]{1,32}$',
                  'type': 'string',
                },
                'maxItems': 20,
                'minItems': 1,
                'type': 'array',
              },
            },
            'required': ['slugs'],
            'type': 'object',
          },
        },
      },
    });
    final responses = _map(order['responses']);
    expect(responses.keys.toList(growable: false), ['204', '401', '409']);
    expect(_map(responses['204']), {'description': 'Rearranged.'});
    expect(
      _map(responses['409'])['description'],
      "`STALE_ORDER`: the slugs are not exactly the caller's folders.",
    );
    expect(
      _map(responses['401']),
      _map(_map(folders['responses'])['401']),
    );
  });

  test('pins creating a bookmark folder as a 201 JSON POST', () {
    final item = _map(_map(contract['paths'])['/api/v4/account/bookmarks']);
    final create = _map(item['post']);
    final folders = _get(contract, '/api/v4/account/bookmarks');
    final public = _get(contract, '/api/v4/users/{handle}/bookmarks');

    expect(item.keys.toList(growable: false), ['get', 'post']);
    expect(_accessClass(create), 'user');
    expect(_accessScope(create), 'bookmarks.write');
    expect(create.containsKey('security'), isFalse);
    expect(create.containsKey('parameters'), isFalse);
    expect(create['summary'], 'Create a folder');
    final content = _map(_map(create['requestBody'])['content']);
    expect(content.keys.toList(growable: false), ['application/json']);
    expect(_map(_map(content['application/json'])['schema']), {
      'properties': {
        'color': {
          'default': null,
          'enum': [
            'red',
            'violet',
            'blue',
            'teal',
            'lime',
            'yellow',
            'orange',
            null,
          ],
          'type': ['string', 'null'],
        },
        'description': {'default': '', 'maxLength': 2048, 'type': 'string'},
        'name': {'maxLength': 256, 'minLength': 1, 'type': 'string'},
        'slug': {'pattern': r'^[0-9a-z_]{1,32}$', 'type': 'string'},
        'visibility': {
          'default': 'private',
          'enum': ['private', 'unlisted', 'public'],
          'type': 'string',
        },
      },
      'required': ['slug', 'name'],
      'type': 'object',
    });
    final responses = _map(create['responses']);
    expect(
      responses.keys.toList(growable: false),
      ['201', '401', '409', '422'],
    );
    expect(_map(responses['201'])['description'], 'Created.');
    expect(_map(responses['409'])['description'], 'That slug is taken.');
    expect(_map(responses['422'])['description'], 'Too many folders.');
    expect(
      _map(responses['401']),
      _map(_map(folders['responses'])['401']),
    );
    expect(
      _map(_map(_map(responses['201'])['content'])['application/json'])[
          'schema'],
      _map(_properties(_responseSchema(public))['folders'])['items'],
    );
  });

  test('pins adding bookmark problems and the folder-change shape', () {
    final paths = _map(contract['paths']);
    final item = _map(paths['/api/v4/account/bookmarks/{slug}/problems']);
    final add = _map(item['post']);
    final folder = _map(paths['/api/v4/account/bookmarks/{slug}']);
    final create = _map(_map(paths['/api/v4/account/bookmarks'])['post']);

    expect(item.keys.toList(growable: false), ['post']);
    expect(_accessClass(add), 'user');
    expect(_accessScope(add), 'bookmarks.write');
    expect(add.containsKey('security'), isFalse);
    expect(add['summary'], 'Add problems to the end of a folder');
    expect(_parameters(add), _parameters(_map(folder['delete'])));
    expect(_map(add['requestBody']), {
      'content': {
        'application/json': {
          'schema': {
            'properties': {
              'problemIds': {
                'items': {'exclusiveMinimum': 0, 'type': 'integer'},
                'maxItems': 100,
                'minItems': 1,
                'type': 'array',
              },
            },
            'required': ['problemIds'],
            'type': 'object',
          },
        },
      },
    });
    final responses = _map(add['responses']);
    expect(
      responses.keys.toList(growable: false),
      ['200', '401', '404', '422'],
    );
    expect(_map(responses['200'])['description'], 'Added; repeats skipped.');
    expect(_map(responses['404'])['description'], 'No such folder.');
    expect(
      _map(responses['422'])['description'],
      'The folder would be too large.',
    );
    expect(
      _map(responses['401']),
      _map(_map(_map(folder['delete'])['responses'])['401']),
    );
    final schema = _responseSchema(add);
    expect(schema['type'], 'object');
    expect(_required(schema), ['folder', 'changed']);
    final properties = _properties(schema);
    expect(properties.keys.toSet(), {'folder', 'changed'});
    expect(_map(properties['changed']), {'type': 'number'});
    expect(
      _map(properties['folder']),
      _map(_map(_map(_map(create['responses'])['201'])['content'])[
          'application/json'])['schema'],
    );
  });

  test('pins removing bookmark problems with the shared add shapes', () {
    final paths = _map(contract['paths']);
    final item =
        _map(paths['/api/v4/account/bookmarks/{slug}/problems/remove']);
    final remove = _map(item['post']);
    final add =
        _map(_map(paths['/api/v4/account/bookmarks/{slug}/problems'])['post']);

    expect(item.keys.toList(growable: false), ['post']);
    expect(_accessClass(remove), 'user');
    expect(_accessScope(remove), 'bookmarks.write');
    expect(remove.containsKey('security'), isFalse);
    expect(remove['summary'], 'Remove problems from a folder');
    expect(_parameters(remove), _parameters(add));
    expect(_map(remove['requestBody']), _map(add['requestBody']));
    final responses = _map(remove['responses']);
    final addResponses = _map(add['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401', '404']);
    expect(_map(responses['200'])['description'], 'Removed.');
    expect(
      _map(responses['200'])['content'],
      _map(addResponses['200'])['content'],
    );
    expect(_map(responses['401']), _map(addResponses['401']));
    expect(_map(responses['404']), _map(addResponses['404']));
  });

  test('pins moving a bookmark problem or setting its note', () {
    final paths = _map(contract['paths']);
    final item =
        _map(paths['/api/v4/account/bookmarks/{slug}/problems/{problemId}']);
    final update = _map(item['patch']);
    final add =
        _map(_map(paths['/api/v4/account/bookmarks/{slug}/problems'])['post']);

    expect(item.keys.toList(growable: false), ['patch']);
    expect(_accessClass(update), 'user');
    expect(_accessScope(update), 'bookmarks.write');
    expect(update.containsKey('security'), isFalse);
    expect(
      update['summary'],
      'Move a problem within its folder, or set its note',
    );
    expect(_parameters(update), [
      ..._parameters(add),
      {
        'in': 'path',
        'name': 'problemId',
        'required': true,
        'schema': {'exclusiveMinimum': 0, 'type': 'integer'},
      },
    ]);
    expect(_map(update['requestBody']), {
      'content': {
        'application/json': {
          'schema': {
            'properties': {
              'after': {'exclusiveMinimum': 0, 'type': 'integer'},
              'before': {
                'exclusiveMinimum': 0,
                'type': ['integer', 'null'],
              },
              'note': {
                'maxLength': 2048,
                'type': ['string', 'null'],
              },
            },
            'type': 'object',
          },
        },
      },
    });
    final responses = _map(update['responses']);
    final addResponses = _map(add['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401', '404']);
    expect(_map(responses['200'])['description'], 'Updated.');
    expect(
      _map(responses['404'])['description'],
      'No such folder or problem in it.',
    );
    expect(
      _map(responses['200'])['content'],
      _map(addResponses['200'])['content'],
    );
    expect(_map(responses['401']), _map(addResponses['401']));
  });

  test('pins token revocation as the app-authenticated OAuth twin', () {
    final paths = _map(contract['paths']);
    final revokeItem = _map(paths['/api/v4/oauth/revoke']);
    final revoke = _map(revokeItem['post']);
    final token = _map(_map(paths['/api/v4/oauth/token'])['post']);

    expect(revokeItem.keys.toList(growable: false), ['post']);
    expect(revoke.keys.toList(growable: false), [
      'description',
      'responses',
      'summary',
      'x-access',
    ]);
    expect(revoke['x-access'], {'class': 'app'});
    expect(
      revoke['summary'],
      'Revoke a token: sign the user out of this app on that device',
    );
    expect(
      revoke['description'],
      'RFC 7009. `token` is an access or refresh token; either ends both, '
      'and every token of the same sign-in. The app authenticates as for the '
      'token endpoint. Answers 200 whether or not the token was known.',
    );
    final responses = _map(revoke['responses']);
    final tokenResponses = _map(token['responses']);
    expect(responses.keys.toList(growable: false), ['200', '400', '401']);
    expect(_map(responses['200']), {
      'content': {
        'application/json': {
          'schema': {'properties': <String, Object?>{}, 'type': 'object'},
        },
      },
      'description': 'Revoked, or never valid.',
    });
    expect(
      _map(responses['400'])['description'],
      '`invalid_request`: no `token`.',
    );
    expect(_map(responses['401'])['description'], '`invalid_client`.');
    for (final status in ['400', '401']) {
      expect(
        _map(responses[status])['content'],
        _map(tokenResponses[status])['content'],
        reason: status,
      );
    }
  });

  test('pins the viewer standing and its shared ban shapes', () {
    final standing = _get(contract, '/api/v4/account/standing');
    final bans = _get(contract, '/api/v4/account/bans');
    final profile = _get(contract, '/api/v4/users/{handle}');
    final reports = _get(contract, '/api/v4/problems/{problemId}/reports');

    expect(_accessClass(standing), 'user');
    expect(_accessScope(standing), 'standing');
    expect(standing.containsKey('security'), isFalse);
    expect(standing.containsKey('requestBody'), isFalse);
    expect(standing.containsKey('parameters'), isFalse);
    expect(standing['summary'], "The viewer's standing warnings and bans");
    final responses = _map(standing['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      'What the account standing page shows.',
    );
    expect(_map(responses['401']), _map(_map(bans['responses'])['401']));

    final schema = _responseSchema(standing);
    expect(_required(schema), [
      'strikes',
      'bans',
      'priorStrikeBans',
      'nextBanDays',
    ]);
    final properties = _properties(schema);
    expect(properties.keys.length, 4);
    expect(_map(properties['priorStrikeBans']), {'type': 'integer'});
    expect(_map(properties['nextBanDays']), {'type': 'integer'});
    expect(
      _map(properties['bans']),
      _map(_properties(_responseSchema(profile))['bans']),
    );

    final strike = _map(_map(properties['strikes'])['items']);
    expect(strike['type'], 'object');
    expect(_required(strike), [
      'id',
      'problem',
      'category',
      'text',
      'action',
      'createdAt',
      'seen',
      'restored',
      'appeal',
      'appealable',
      'strikeCleared',
      'strikeExpiresAt',
    ]);
    final strikeProperties = _properties(strike);
    expect(strikeProperties.keys.length, 12);
    expect(_map(strikeProperties['category']), {
      'enum': [
        'hate',
        'disparagement',
        'profanity',
        'spam',
        'personal-info',
        'off-topic',
        'troll-level',
        'irrelevant-tags',
      ],
      'type': 'string',
    });
    expect(_map(strikeProperties['action']), {
      'enum': ['hidden', 'removed'],
      'type': 'string',
    });
    expect(_map(strikeProperties['id']), {'type': 'integer'});
    for (final field in ['text', 'createdAt']) {
      expect(_map(strikeProperties[field]), {'type': 'string'});
    }
    for (final field in [
      'seen',
      'restored',
      'appealable',
      'strikeCleared',
    ]) {
      expect(_map(strikeProperties[field]), {'type': 'boolean'});
    }
    expect(_map(strikeProperties['strikeExpiresAt']), {
      'type': ['string', 'null'],
    });
    final banItem =
        _map(_map(_properties(_responseSchema(bans))['items'])['items']);
    final banAppeal = _map(_properties(banItem)['appeal']);
    final appeal = _map(strikeProperties['appeal']);
    expect(appeal['type'], banAppeal['type']);
    expect(appeal['properties'], banAppeal['properties']);
    expect(
      (appeal['required'] as List).toSet(),
      (banAppeal['required'] as List).toSet(),
    );
    final reportItem =
        _map(_map(_properties(_responseSchema(reports))['items'])['items']);
    final sameProblem =
        _map(_map(_properties(reportItem)['sameProblems'])['items']);
    final problem = _map(strikeProperties['problem']);
    expect(problem['type'], ['object', 'null']);
    expect(_required(problem), [..._required(sameProblem), 'title']);
    final problemProperties = Map<String, dynamic>.of(_properties(problem));
    expect(problemProperties.remove('title'), {
      'type': ['string', 'null'],
    });
    expect(problemProperties, _properties(sameProblem));
  });

  test('pins the viewer bans to the shared profile ban fields', () {
    final bans = _get(contract, '/api/v4/account/bans');
    final profile = _get(contract, '/api/v4/users/{handle}');

    expect(_accessClass(bans), 'user');
    expect(_accessScope(bans), 'standing');
    expect(bans.containsKey('security'), isFalse);
    expect(bans.containsKey('requestBody'), isFalse);
    expect(bans.containsKey('parameters'), isFalse);
    expect(
      bans['summary'],
      "The viewer's bans that can be or have been appealed",
    );
    final responses = _map(bans['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      'Those still binding, and any appealed; no warning bans.',
    );
    expect(_map(responses['401'])['description'], 'Not signed in.');
    expect(
      _jsonResponseSchema(bans, '401'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    final schema = _responseSchema(bans);
    expect(_required(schema), ['items']);
    final item = _map(_map(_properties(schema)['items'])['items']);
    final profileBan = _map(
      _map(_properties(_responseSchema(profile))['bans'])['items'],
    );
    expect(item['type'], 'object');
    expect(_required(item), [
      ..._required(profileBan),
      'id',
      'appealable',
      'appeal',
    ]);
    final itemProperties = Map<String, dynamic>.of(_properties(item));
    expect(itemProperties.remove('id'), {'type': 'integer'});
    expect(itemProperties.remove('appealable'), {'type': 'boolean'});
    expect(itemProperties.remove('appeal'), {
      'properties': {
        'appealedAt': {'type': 'string'},
        'response': {
          'type': ['string', 'null'],
        },
        'status': {
          'enum': ['pending', 'granted', 'denied'],
          'type': 'string',
        },
        'text': {'type': 'string'},
      },
      'required': ['status', 'text', 'appealedAt', 'response'],
      'type': ['object', 'null'],
    });
    expect(itemProperties, _properties(profileBan));
  });

  test('pins the viewer equippable backgrounds', () {
    final backgrounds = _get(contract, '/api/v4/account/backgrounds');

    expect(_accessClass(backgrounds), 'user');
    expect(_accessScope(backgrounds), 'collection');
    expect(backgrounds.containsKey('security'), isFalse);
    expect(backgrounds.containsKey('requestBody'), isFalse);
    expect(backgrounds.containsKey('parameters'), isFalse);
    expect(
      backgrounds['summary'],
      'Backgrounds the signed-in user may equip',
    );
    final responses = _map(backgrounds['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(
      _map(responses['200'])['description'],
      'Owned backgrounds and those everyone has, in picker order.',
    );
    expect(_map(responses['401'])['description'], 'Not signed in.');
    expect(
      _jsonResponseSchema(backgrounds, '401'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );
    const nullableString = {
      'type': ['string', 'null'],
    };
    expect(_responseSchema(backgrounds), {
      'properties': {
        'backgrounds': {
          'items': {
            'properties': {
              'acquiredAt': nullableString,
              'backgroundImageUrl': {'type': 'string'},
              'category': {'type': 'string'},
              'createdAt': {'type': 'string'},
              'fallbackBackgroundImageUrl': nullableString,
              'id': {'type': 'integer'},
              'isIllust': {'type': 'boolean'},
              'key': {'type': 'string'},
              'ownedUserCount': {'type': 'integer'},
              'thumbnailImageUrl': nullableString,
              'thumbnailPlaceholder': nullableString,
            },
            'required': [
              'id',
              'key',
              'backgroundImageUrl',
              'fallbackBackgroundImageUrl',
              'thumbnailImageUrl',
              'thumbnailPlaceholder',
              'isIllust',
              'category',
              'createdAt',
              'acquiredAt',
              'ownedUserCount',
            ],
            'type': 'object',
          },
          'type': 'array',
        },
      },
      'required': ['backgrounds'],
      'type': 'object',
    });
  });

  test('pins the viewer emoticon catalog and ownership flags', () {
    final emoticons = _get(contract, '/api/v4/me/emoticons');

    expect(_accessClass(emoticons), 'user');
    expect(_accessScope(emoticons), 'collection');
    expect(emoticons.containsKey('security'), isFalse);
    expect(emoticons.containsKey('requestBody'), isFalse);
    expect(emoticons.containsKey('parameters'), isFalse);
    expect(
      emoticons['summary'],
      'List the emoticon catalog with viewer ownership flags',
    );
    final responses = _map(emoticons['responses']);
    expect(responses.keys.toList(growable: false), ['200']);
    expect(
      _map(responses['200'])['description'],
      'Catalog with `owned` flag per item.',
    );
    expect(_responseSchema(emoticons), {
      'properties': {
        'items': {
          'items': {
            'properties': {
              'category': {'type': 'string'},
              'displayName': {
                'type': ['string', 'null'],
              },
              'key': {'type': 'string'},
              'owned': {'type': 'boolean'},
              'url': {'type': 'string'},
            },
            'required': ['key', 'url', 'category', 'displayName', 'owned'],
            'type': 'object',
          },
          'type': 'array',
        },
      },
      'required': ['items'],
      'type': 'object',
    });
  });

  test('pins the viewer tag progress without joining its lists', () {
    final progress = _get(contract, '/api/v4/me/tag-progress');

    expect(_accessClass(progress), 'user');
    expect(_accessScope(progress), 'solves');
    expect(progress.containsKey('security'), isFalse);
    expect(progress.containsKey('requestBody'), isFalse);
    expect(progress.containsKey('parameters'), isFalse);
    expect(
      progress['summary'],
      "The viewer's solved and tried counts per tag",
    );
    final responses = _map(progress['responses']);
    expect(responses.keys.toList(growable: false), ['200']);
    expect(
      _map(responses['200'])['description'],
      'Per tag the viewer has a problem row in.',
    );
    final schema = _responseSchema(progress);
    expect(schema['type'], 'object');
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), ['counts', 'items', 'ratings']);
    Map<String, Object?> list(Map<String, Object?> properties) => {
          'items': {
            'properties': properties,
            'required': properties.keys.toList(),
            'type': 'object',
          },
          'type': 'array',
        };
    expect(_properties(schema), {
      'counts': list({
        'key': {'type': 'string'},
        'problemCount': {'type': 'integer'},
      }),
      'items': list({
        'key': {'type': 'string'},
        'solved': {'type': 'integer'},
        'tried': {'type': 'integer'},
      }),
      'ratings': list({
        'key': {'type': 'string'},
        'rating': {'type': 'integer'},
      }),
    });
  });

  test('pins the user-scoped rival board to the leaderboard shapes', () {
    final rivals = _get(contract, '/api/v4/rankings/rivals');
    final users = _get(contract, '/api/v4/rankings/users');

    expect(_accessClass(rivals), 'user');
    expect(_accessScope(rivals), 'rivals');
    expect(rivals.containsKey('security'), isFalse);
    expect(rivals.containsKey('requestBody'), isFalse);
    expect(rivals['summary'], "The viewer's rivals and the viewer, by rating");
    expect(_parameters(rivals), [
      {
        'in': 'query',
        'name': 'page',
        'required': false,
        'schema': {'default': 1, 'minimum': 1, 'type': 'integer'},
      },
    ]);
    final responses = _map(rivals['responses']);
    expect(responses.keys.toList(growable: false), ['200', '401']);
    expect(_map(responses['200'])['description'], 'One page of the board.');
    expect(
      _map(responses['401'])['description'],
      "Not signed in: the board is the viewer's own.",
    );
    expect(
      _jsonResponseSchema(rivals, '401'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );

    final schema = _responseSchema(rivals);
    final board = _responseSchema(users);
    expect(schema.containsKey('additionalProperties'), isFalse);
    expect(_required(schema), [
      ..._required(board),
      'rivalCount',
      'reverseRivalCount',
    ]);
    final properties = Map<String, dynamic>.of(_properties(schema));
    final boardProperties = _properties(board);
    expect(properties.remove('rivalCount'), {'type': 'integer'});
    expect(properties.remove('reverseRivalCount'), {'type': 'integer'});
    final item = _map(_map(properties.remove('items'))['items']);
    final boardItem = _map(_map(boardProperties['items'])['items']);
    expect(
      properties,
      Map<String, dynamic>.of(boardProperties)..remove('items'),
    );
    expect(item['type'], 'object');
    expect(_required(item), [
      ..._required(boardItem),
      'isRival',
      'isReverseRival',
    ]);
    final itemProperties = Map<String, dynamic>.of(_properties(item));
    expect(itemProperties.remove('isRival'), {'type': 'boolean'});
    expect(itemProperties.remove('isReverseRival'), {'type': 'boolean'});
    expect(itemProperties, _properties(boardItem));
  });

  test('pins the reverse-rival board to the rival board schema', () {
    final reverse = _get(contract, '/api/v4/rankings/reverse-rivals');
    final rivals = _get(contract, '/api/v4/rankings/rivals');

    expect(_accessClass(reverse), 'user');
    expect(_accessScope(reverse), 'rivals');
    expect(reverse.containsKey('security'), isFalse);
    expect(reverse.containsKey('requestBody'), isFalse);
    expect(
      reverse['summary'],
      'Those who have the viewer as a rival and the viewer, by rating',
    );
    expect(_parameters(reverse), _parameters(rivals));
    expect(_map(reverse['responses']), _map(rivals['responses']));
  });

  test('pins the public tag ranking to the shared leaderboard schema', () {
    final tag = _get(contract, '/api/v4/rankings/tags/{key}');

    expect(_accessClass(tag), 'public');
    expect(tag.containsKey('security'), isFalse);
    expect(tag.containsKey('requestBody'), isFalse);
    expect(tag['summary'], 'The ranking within one tag');
    expect(_parameterNames(tag), ['key', 'page']);

    final parameters = _parameters(tag);
    expect(parameters.first, {
      'in': 'path',
      'name': 'key',
      'required': true,
      'schema': {'maxLength': 64, 'minLength': 1, 'type': 'string'},
    });
    expect(parameters.last, {
      'in': 'query',
      'name': 'page',
      'required': false,
      'schema': {'default': 1, 'minimum': 1, 'type': 'integer'},
    });

    final responses = _map(tag['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'One page of the board.');
    expect(
      _map(responses['404'])['description'],
      'No such tag, or it has no ranking.',
    );
    expect(
      _responseSchema(tag),
      _responseSchema(_get(contract, '/api/v4/rankings/users')),
    );
    expect(
      _jsonResponseSchema(tag, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );
  });

  test('pins the affiliation ranking and its raw path anomaly', () {
    final affiliation = _get(
      contract,
      '/api/v4/rankings/affiliations/{affiliationId}',
    );

    expect(_accessClass(affiliation), 'public');
    expect(affiliation.containsKey('security'), isFalse);
    expect(affiliation.containsKey('requestBody'), isFalse);
    expect(affiliation['summary'], 'The ranking within one affiliation');
    expect(_parameterNames(affiliation), ['affiliationId', 'page']);

    // The raw document marks this path parameter optional and nullable. The
    // client follows the reviewed proxy overlay: required non-null integer.
    final parameters = _parameters(affiliation);
    expect(parameters.first, {
      'in': 'path',
      'name': 'affiliationId',
      'required': false,
      'schema': {
        'type': ['integer', 'null'],
      },
    });
    expect(parameters.last, {
      'in': 'query',
      'name': 'page',
      'required': false,
      'schema': {'default': 1, 'minimum': 1, 'type': 'integer'},
    });

    final responses = _map(affiliation['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'One page of the board.');
    expect(_map(responses['404'])['description'], 'No such affiliation.');
    expect(
      _responseSchema(affiliation),
      _responseSchema(_get(contract, '/api/v4/rankings/users')),
    );
    expect(
      _jsonResponseSchema(affiliation, '404'),
      _jsonResponseSchema(_get(contract, '/api/v4/affiliations/{id}'), '404'),
    );
  });

  test('pins the tag catalog and standalone asset item envelope', () {
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
    final itemParameters = _parameters(item);
    expect(itemParameters.first['required'], isTrue);
    expect(_map(itemParameters.first['schema']), {
      'type': 'string',
      'enum': ['badge', 'background'],
    });
    expect(itemParameters[1]['required'], isTrue);
    expect(_map(itemParameters[1]['schema']), {
      'type': 'string',
      'minLength': 1,
      'maxLength': 64,
    });
    expect(itemParameters.last['required'], isFalse);
    expect(_map(itemParameters.last['schema']), {
      'type': 'string',
      'maxLength': 16,
      'default': 'ko',
    });

    const itemFields = [
      'kind',
      'id',
      'key',
      'name',
      'imageUrl',
      'category',
      'addedAt',
      'unlockedByDefault',
      'owned',
      'equipped',
      'background',
      'credits',
      'userCount',
      'achievements',
    ];
    final itemSchema = _responseSchema(item);
    expect(_required(itemSchema), itemFields);
    expect(itemSchema.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(itemSchema);
    expect(itemProperties.keys.toList(growable: false), itemFields);
    expect(_map(itemProperties['kind']), {
      'type': 'string',
      'enum': ['badge', 'background'],
    });
    expect(_map(itemProperties['id']), {'type': 'integer'});
    for (final field in ['key', 'name', 'imageUrl', 'category', 'addedAt']) {
      expect(_map(itemProperties[field]), {'type': 'string'});
    }
    expect(_map(itemProperties['unlockedByDefault']), {'type': 'boolean'});
    for (final field in ['owned', 'equipped']) {
      expect(_map(itemProperties[field]), {
        'type': ['boolean', 'null'],
      });
    }
    expect(_map(itemProperties['userCount']), {
      'type': 'integer',
      'minimum': 0,
    });

    final background = _map(itemProperties['background']);
    expect(background['type'], ['object', 'null']);
    const backgroundFields = [
      'key',
      'backgroundImageUrl',
      'fallbackBackgroundImageUrl',
      'backgroundVideoUrl',
      'thumbnailPlaceholder',
      'isIllust',
      'displayName',
      'authors',
    ];
    expect(_required(background), backgroundFields);
    expect(background.containsKey('additionalProperties'), isFalse);
    final backgroundProperties = _properties(background);
    expect(
      backgroundProperties.keys.toList(growable: false),
      backgroundFields,
    );
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
    final credits = _map(itemProperties['credits']);
    for (final listSchema in [authors, credits]) {
      expect(listSchema['type'], 'array');
      for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
        expect(listSchema.containsKey(constraint), isFalse);
      }
      final credit = _map(listSchema['items']);
      const creditFields = [
        'key',
        'displayName',
        'role',
        'authorUrl',
        'handle',
        'twitter',
        'instagram',
      ];
      expect(_required(credit), creditFields);
      expect(credit.containsKey('additionalProperties'), isFalse);
      final creditProperties = _properties(credit);
      expect(creditProperties.keys.toList(growable: false), creditFields);
      for (final field in ['key', 'role']) {
        expect(_map(creditProperties[field]), {'type': 'string'});
      }
      for (final field in creditFields.skip(1).where(
            (field) => field != 'role',
          )) {
        expect(_map(creditProperties[field]), {
          'type': ['string', 'null'],
        });
      }
    }

    final achievements = _map(itemProperties['achievements']);
    expect(achievements['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(achievements.containsKey(constraint), isFalse);
    }
    final achievement = _map(achievements['items']);
    const achievementFields = [
      'key',
      'name',
      'condition',
      'historic',
      'hidden',
      'holderCount',
      'earnedAt',
      'problems',
    ];
    expect(achievement['type'], 'object');
    expect(_required(achievement), achievementFields);
    expect(achievement.containsKey('additionalProperties'), isFalse);
    final achievementProperties = _properties(achievement);
    expect(
      achievementProperties.keys.toList(growable: false),
      achievementFields,
    );
    for (final field in ['key', 'name']) {
      expect(_map(achievementProperties[field]), {'type': 'string'});
    }
    for (final field in ['condition', 'earnedAt']) {
      expect(_map(achievementProperties[field]), {
        'type': ['string', 'null'],
      });
    }
    for (final field in ['historic', 'hidden']) {
      expect(_map(achievementProperties[field]), {'type': 'boolean'});
    }
    expect(_map(achievementProperties['holderCount']), {'type': 'integer'});

    final problems = _map(achievementProperties['problems']);
    expect(problems['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(problems.containsKey(constraint), isFalse);
    }
    final problem = _map(problems['items']);
    const problemFields = [
      'problemId',
      'level',
      'effectiveVoteCount',
      'givesNoRating',
      'isStandard',
      'titles',
      'userStatus',
    ];
    expect(problem['type'], 'object');
    expect(_required(problem), problemFields);
    expect(problem.containsKey('additionalProperties'), isFalse);
    final problemProperties = _properties(problem);
    expect(problemProperties.keys.toList(growable: false), problemFields);
    for (final field in ['problemId', 'level', 'effectiveVoteCount']) {
      expect(_map(problemProperties[field]), {'type': 'number'});
    }
    for (final field in ['givesNoRating', 'isStandard']) {
      expect(_map(problemProperties[field]), {'type': 'boolean'});
    }
    expect(_map(problemProperties['userStatus']), {
      'type': ['string', 'null'],
      'enum': ['solved', 'partial', 'tried', null],
    });

    final titles = _map(problemProperties['titles']);
    expect(titles['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(titles.containsKey(constraint), isFalse);
    }
    final title = _map(titles['items']);
    const titleFields = ['language', 'title', 'isOriginal', 'latex', 'html'];
    expect(title['type'], 'object');
    expect(_required(title), titleFields);
    expect(title.containsKey('additionalProperties'), isFalse);
    final titleProperties = _properties(title);
    expect(titleProperties.keys.toList(growable: false), titleFields);
    for (final field in ['language', 'title']) {
      expect(_map(titleProperties[field]), {'type': 'string'});
    }
    for (final field in ['isOriginal', 'latex', 'html']) {
      expect(_map(titleProperties[field]), {'type': 'boolean'});
    }
  });

  test('pins public achievement holders and their official error shape', () {
    final holders =
        _get(contract, '/api/v4/achievements/items/{kind}/{key}/holders');

    expect(_accessClass(holders), 'public');
    expect(holders.containsKey('requestBody'), isFalse);
    expect(holders['summary'], 'Who holds a badge or background');
    expect(_parameterNames(holders), ['kind', 'key', 'sort', 'page']);
    final parameters = _parameters(holders);
    expect(parameters.first['in'], 'path');
    expect(parameters.first['required'], isTrue);
    expect(_map(parameters.first['schema']), {
      'enum': ['badge', 'background'],
      'type': 'string',
    });
    expect(parameters[1]['in'], 'path');
    expect(parameters[1]['required'], isTrue);
    expect(_map(parameters[1]['schema']), {
      'maxLength': 64,
      'minLength': 1,
      'type': 'string',
    });
    expect(parameters[2]['in'], 'query');
    expect(parameters[2]['required'], isFalse);
    expect(_map(parameters[2]['schema']), {
      'default': 'recent',
      'enum': ['recent', 'first'],
      'type': 'string',
    });
    expect(parameters.last['in'], 'query');
    expect(parameters.last['required'], isFalse);
    expect(_map(parameters.last['schema']), {
      'default': 1,
      'maximum': 200,
      'minimum': 1,
      'type': 'integer',
    });

    final responses = _map(holders['responses']);
    expect(responses.keys.toList(growable: false), ['200', '404']);
    expect(_map(responses['200'])['description'], 'A page of holders.');
    expect(_map(responses['404'])['description'], 'No such item.');

    final schema = _responseSchema(holders);
    expect(schema['type'], 'object');
    expect(_required(schema), ['unlockedByDefault', 'total', 'items']);
    expect(schema.containsKey('additionalProperties'), isFalse);
    final properties = _properties(schema);
    expect(properties.keys.toList(growable: false), [
      'items',
      'total',
      'unlockedByDefault',
    ]);
    expect(_map(properties['unlockedByDefault']), {'type': 'boolean'});
    expect(_map(properties['total']), {'type': 'integer'});

    final items = _map(properties['items']);
    expect(items['type'], 'array');
    for (final constraint in ['minItems', 'maxItems', 'uniqueItems']) {
      expect(items.containsKey(constraint), isFalse);
    }
    final item = _map(items['items']);
    expect(item['type'], 'object');
    expect(_required(item), ['user', 'acquiredAt']);
    expect(item.containsKey('additionalProperties'), isFalse);
    final itemProperties = _properties(item);
    expect(itemProperties.keys.toList(growable: false), [
      'acquiredAt',
      'user',
    ]);
    expect(_map(itemProperties['acquiredAt']), {'type': 'string'});

    final user = _map(itemProperties['user']);
    expect(user['type'], 'object');
    expect(_required(user), ['id', 'handle', 'tier', 'profileImageUrl']);
    expect(user.containsKey('additionalProperties'), isFalse);
    final userProperties = _properties(user);
    expect(userProperties.keys.toList(growable: false), [
      'handle',
      'id',
      'profileImageUrl',
      'tier',
    ]);
    expect(_map(userProperties['handle']), {'type': 'string'});
    expect(_map(userProperties['id']), {'type': 'number'});
    expect(_map(userProperties['profileImageUrl']), {
      'format': 'uri',
      'type': ['string', 'null'],
    });
    expect(_map(userProperties['tier']), {
      'maximum': 31,
      'minimum': 0,
      'type': ['integer', 'null'],
    });

    final notFound = _map(responses['404']);
    final notFoundContent = _map(notFound['content']);
    expect(notFoundContent.keys.toList(growable: false), [
      'application/json',
    ]);
    final notFoundSchema = _map(
      _map(notFoundContent['application/json'])['schema'],
    );
    expect(notFoundSchema['type'], 'object');
    expect(_required(notFoundSchema), ['error']);
    expect(notFoundSchema.containsKey('additionalProperties'), isFalse);
    final error = _map(_properties(notFoundSchema)['error']);
    expect(error['type'], 'object');
    expect(_required(error), ['code', 'message']);
    expect(error.containsKey('additionalProperties'), isFalse);
    final errorProperties = _properties(error);
    expect(errorProperties.keys.toList(growable: false), [
      'code',
      'details',
      'message',
    ]);
    expect(_map(errorProperties['code']), {'type': 'string'});
    expect(_map(errorProperties['message']), {'type': 'string'});
    final details = _map(errorProperties['details']);
    expect(details['type'], 'object');
    expect(details.containsKey('required'), isFalse);
    expect(_map(details['additionalProperties']), {
      'anyOf': [
        {'type': 'string'},
        {'type': 'number'},
        {'type': 'boolean'},
      ],
    });
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

Map<String, dynamic> _jsonResponseSchema(
  Map<String, dynamic> operation,
  String status,
) =>
    _map(
      _map(
        _map(
          _map(_map(operation['responses'])[status])['content'],
        )['application/json'],
      )['schema'],
    );

List<String> _required(Map<String, dynamic> schema) =>
    List<String>.from(schema['required'] as List? ?? const []);

Map<String, dynamic> _properties(Map<String, dynamic> schema) =>
    _map(schema['properties']);
