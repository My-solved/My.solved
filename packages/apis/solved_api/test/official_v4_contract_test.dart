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

List<String> _required(Map<String, dynamic> schema) =>
    List<String>.from(schema['required'] as List? ?? const []);

Map<String, dynamic> _properties(Map<String, dynamic> schema) =>
    _map(schema['properties']);
