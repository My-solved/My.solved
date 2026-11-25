import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

typedef _RequestHandler = Future<http.StreamedResponse> Function(
  http.Request request,
);

final class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.handler);

  _RequestHandler handler;
  final List<http.Request> requests = <http.Request>[];
  bool wasClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (wasClosed) throw StateError('Recording client is closed');
    if (request is! http.Request) {
      throw StateError('Expected a buffered HTTP request');
    }
    requests.add(request);
    return handler(request);
  }

  @override
  void close() {
    wasClosed = true;
  }
}

void main() {
  group('SolvedApiClient.officialV4', () {
    late _RequestHandler handler;
    late _RecordingClient httpClient;
    late SolvedApiClient client;

    setUp(() {
      handler = (_) async => _jsonResponse(fixture('v4/badge_item.json'));
      httpClient = _RecordingClient((request) => handler(request));
      client = _client(httpClient);
    });

    tearDown(() => client.close());

    test(
      'sends exact bodyless bounded GETs and decodes all public operations',
      () async {
        handler = (request) async {
          final fixturePath = switch (request.url.path) {
            '/solved/v4/users/index' => 'v4/user_profile.json',
            '/solved/v4/users/index/activity/days' =>
              'v4/user_activity_days.json',
            '/solved/v4/users/index/activity/feed' =>
              'v4/user_activity_feed.json',
            '/solved/v4/users/index/reputation' => 'v4/user_reputation.json',
            '/solved/v4/users/index/rating/history' =>
              'v4/user_rating_history.json',
            '/solved/v4/users/index/tags/number_theory/histogram' =>
              'v4/user_tag_level_histogram.json',
            '/solved/v4/users/index/achievements/summary' =>
              'v4/user_achievement_summary.json',
            '/solved/v4/users/index/badge-stand' => 'v4/user_badge_stand.json',
            '/solved/v4/achievements/items/background/anniversary_1st' =>
              'v4/background_item.json',
            '/solved/v4/achievements/items/badge/boardgame' =>
              'v4/badge_item.json',
            '/solved/v4/problems/1000' => 'v4/problem_detail.json',
            '/solved/v4/problems' => 'v4/search_problems.json',
            '/solved/v4/rankings/regions' => 'v4/ranking_regions.json',
            '/solved/v4/rankings/tags' => 'v4/ranking_tags.json',
            '/solved/v4/rankings/users/search' => 'v4/search_users.json',
            '/solved/v4/search/analyze' => 'v4/search_analysis.json',
            '/solved/v4/search/random-problem' => 'v4/random_problem.json',
            '/solved/v4/search/suggest' => 'v4/search_suggestions.json',
            '/solved/v4/site/stats' => 'v4/site_stats.json',
            '/solved/v4/sources/oj/boj/contests/round-1' =>
              'v4/source_lookup.json',
            '/solved/v4/sources/oj/boj/groups/team-1' =>
              'v4/source_lookup.json',
            '/solved/v4/achievements' => 'v4/achievement_catalog.json',
            '/solved/v4/achievements/for-problem/1000' =>
              'v4/problem_achievements.json',
            '/solved/v4/tags' => 'v4/tags.json',
            '/solved/v4/tags/number_theory' => 'v4/tag_detail.json',
            _ => throw StateError('Unexpected request: ${request.url}'),
          };
          return _jsonResponse(_paddedFixture(fixturePath));
        };

        final OfficialUserProfile profile = await client.v4UserProfile('index');
        final ProfileActivityResult activity = await client.v4UserActivity(
          'index',
          from: DateTime.utc(2026, 11),
          to: DateTime.utc(2026, 11, 17),
        );
        final ProfileActivityFeedResult activityFeed =
            await client.v4UserActivityFeed(
          'index',
          before: '',
          from: '9999-99-99',
          to: '0000-00-00',
          limit: 500,
        );
        final ProfileReputationResult reputation =
            await client.v4UserReputation(
          'index',
          range: SolvedApiV4ReputationRange.year,
        );
        final ProfileRatingHistoryResult ratingHistory =
            await client.v4UserRatingHistory(
          'index',
          range: SolvedApiV4RatingHistoryRange.days90,
        );
        final ProfileTagLevelHistogramResult tagLevelHistogram =
            await client.v4UserTagLevelHistogram('index', 'number_theory');
        final ProfileAchievementSummaryResult achievementSummary =
            await client.v4UserAchievementSummary('index');
        final ProfileBadgeStandResult badgeStand =
            await client.v4UserBadgeStand('index');
        final OfficialAchievementItem achievementBackground =
            await client.v4AchievementItem(
          OfficialAchievementItemKind.background,
          'anniversary_1st',
        );
        final OfficialAchievementItem achievementBadge =
            await client.v4AchievementItem(
          OfficialAchievementItemKind.badge,
          'boardgame',
        );
        final background = await client.v4BackgroundShow('anniversary_1st');
        final badge = await client.v4BadgeShow('boardgame');
        final ProblemDetailResult problemDetail =
            await client.v4ProblemDetail(1000, sub: '');
        final ProblemSearchResult problems = await client.v4SearchProblems(
          'number',
          page: 2,
          sort: SolvedApiV4ProblemSort.level,
          direction: SolvedApiV4SearchDirection.desc,
          seed: 'stable-seed',
        );
        final users = await client.v4SearchUsers(
          'index',
          sort: SolvedApiV4UserSort.contribution,
        );
        final RankingRegionsResult rankingRegions =
            await client.v4RankingRegions();
        final RankingTagsResult rankingTags =
            await client.v4RankingTags(language: '');
        final suggestions = await client.v4SearchSuggestions(
          'tag&한',
          value: '',
        );
        final analysis = await client.v4AnalyzeProblemSearch(query: 'tag&한');
        final RandomProblemResult randomProblem =
            await client.v4RandomProblem(query: '');
        final SiteStatsResult siteStats = await client.v4SiteStats();
        final SourceLookupResult sourceContest =
            await client.v4SourceContest('boj', 'round-1');
        final SourceLookupResult sourceGroup =
            await client.v4SourceGroup('boj', 'team-1');
        final AchievementCatalogResult achievementCatalog =
            await client.v4AchievementCatalog(language: '');
        final ProblemAchievementsResult problemAchievements =
            await client.v4AchievementsForProblem(1000, language: '');
        final tags = await client.v4SearchTags('NUMBER');
        final TagDetailResult tagDetail =
            await client.v4TagDetail('number_theory');

        expect(profile.handle, 'index');
        expect(profile.id, 1);
        expect(profile.voteCount, 37);
        expect(profile.solvedCount, 2048);
        expect(profile.streakVacation, isNull);
        expect(profile.streakCountedToday, isTrue);
        expect(profile.streakFrozenYesterday, isFalse);
        expect(profile.streakTheme, isNull);
        expect(profile.isRival, isFalse);
        expect(profile.isReverseRival, isFalse);
        expect(profile.ojAccounts, hasLength(2));
        expect(profile.ojAccounts.first.ojId, 'boj');
        expect(profile.ojAccounts.first.handle, 'index');
        expect(profile.ojAccounts.first.logoUrl, isNull);
        expect(profile.ojAccounts.first.verified, isTrue);
        expect(profile.ojAccounts.last.ojId, 'codeforces');
        expect(profile.ojAccounts.last.profileUrl, isNull);
        expect(profile.ojAccounts.last.verified, isFalse);
        expect(profile.linkedAccounts, hasLength(2));
        expect(
          profile.linkedAccounts.first.provider,
          OfficialUserProfileLinkedAccountProvider.discord,
        );
        expect(profile.linkedAccounts.first.name, 'index');
        expect(
          profile.linkedAccounts.last.provider,
          OfficialUserProfileLinkedAccountProvider.icpc,
        );
        expect(profile.linkedAccounts.last.name, 'Index Team');
        expect(profile.affiliations, hasLength(2));
        expect(profile.affiliations.first.id, 901);
        expect(profile.affiliations.first.affiliationId, 101);
        expect(
          profile.affiliations.first.type,
          OfficialUserProfileAffiliationType.university,
        );
        expect(
          profile.affiliations.first.logoThumbnailUrl,
          'https://example.com/university.png',
        );
        expect(profile.affiliations.first.color, '#336699');
        expect(profile.affiliations.last.id, 902);
        expect(profile.affiliations.last.affiliationId, 202);
        expect(
          profile.affiliations.last.type,
          OfficialUserProfileAffiliationType.community,
        );
        expect(profile.affiliations.last.logoThumbnailUrl, isNull);
        expect(profile.affiliations.last.color, isNull);
        expect(profile.bans, hasLength(2));
        expect(profile.bans.first.banType, OfficialUserProfileBanType.rating);
        expect(
          profile.bans.first.banReason,
          OfficialUserProfileBanReason.ratingCopiedCode,
        );
        expect(profile.bans.first.until, '2027-01-01');
        expect(profile.bans.last.banType, OfficialUserProfileBanType.vote);
        expect(profile.bans.last.banReason, isNull);
        expect(profile.bans.last.until, '2027-12-31');
        expect(profile.metadata.countryCode, 'KR');
        expect(profile.metadata.pronouns, 'they/them');
        expect(profile.metadata.name, 'Index');
        expect(profile.metadata.nameNative, '인덱스');
        expect(profile.metadata.birthday?.year, 1999);
        expect(profile.metadata.birthday?.month, 12);
        expect(profile.metadata.birthday?.day, 31);
        expect(profile.backgroundId, 'anniversary_1st');
        expect(profile.background, isA<OfficialUserProfileBackground>());
        expect(profile.background?.backgroundVideoUrl, isNull);
        expect(profile.background?.isIllust, isTrue);
        expect(profile.background?.displayName, 'First Anniversary');
        expect(profile.background?.authors, isEmpty);
        expect(profile.badgeId, 'boardgame');
        expect(profile.badge, isA<OfficialUserProfileBadge>());
        expect(profile.badge?.name, 'Board Game');
        expect(activity.from, '2026-11-01');
        expect(activity.to, '2026-11-17');
        expect(activity.maxSolvedCount, 4);
        expect(activity.currentStreak, 12);
        final int maxStreak = activity.maxStreak;
        expect(maxStreak, 365);
        expect(activity.vacation, isNull);
        expect(activity.vacations, isEmpty);
        expect(activity.countedToday, isTrue);
        expect(activity.frozenYesterday, isFalse);
        expect(activity.days, hasLength(2));
        expect(activityFeed.events, hasLength(3));
        expect(
          activityFeed.events.first.type,
          ProfileActivityFeedEventType.solved,
        );
        expect(activityFeed.events.first.problem?.problemId, -1000);
        expect(activityFeed.events[1].hasPayload, isTrue);
        expect(activityFeed.events[1].payload, isNull);
        expect(activityFeed.events.last.hasPayload, isFalse);
        expect(activityFeed.nextCursor, '');
        expect(reputation.reputation, 314);
        expect(reputation.history.single.day, '2026-11-17');
        expect(reputation.history.single.value, 314);
        expect(reputation.today.contributions.count, 2);
        expect(reputation.today.contributions.max, 10);
        expect(reputation.today.helpful.earned, 1);
        expect(reputation.today.helpful.cap, 5);
        expect(ratingHistory.history.map((entry) => entry.day), [
          '2026-11-01',
          '2026-11-17',
        ]);
        expect(ratingHistory.history.map((entry) => entry.value), [2400, 2417]);
        expect(tagLevelHistogram.key, 'response_key');
        expect(tagLevelHistogram.histogram, [-3, 0, 0, 31, 7]);
        expect(achievementSummary.earned, 12);
        expect(achievementSummary.total, 34);
        expect(achievementSummary.past, 2);
        expect(achievementSummary.badges, 7);
        expect(achievementSummary.backgrounds, 5);
        expect(achievementSummary.recent, hasLength(2));
        expect(
          achievementSummary.recent.map((item) => item.kind),
          [
            OfficialAchievementItemKind.badge,
            OfficialAchievementItemKind.background,
          ],
        );
        expect(badgeStand.chosen, isTrue);
        expect(badgeStand.badges, hasLength(2));
        expect(
          badgeStand.badges.map((item) => item.kind),
          [
            OfficialAchievementItemKind.badge,
            OfficialAchievementItemKind.background,
          ],
        );
        expect(badgeStand.badges.first.holderCount, 42);
        expect(badgeStand.badges.last.holderCount, 7);
        expect(
          achievementBackground.kind,
          OfficialAchievementItemKind.background,
        );
        expect(achievementBackground.achievements.single.key, 'first_solve');
        expect(
          achievementBackground.achievements.single.problems.single.userStatus,
          ProblemUserStatus.solved,
        );
        expect(achievementBadge.kind, OfficialAchievementItemKind.badge);
        expect(achievementBadge.achievements, isEmpty);
        expect(background?.key, 'anniversary_1st');
        expect(badge.key, 'boardgame');
        expect(problemDetail.id, 1000.5);
        expect(problemDetail.problemId, 1000);
        expect(problemDetail.userStatus, isNull);
        expect(problemDetail.noRatingWarnings, hasLength(2));
        expect(problemDetail.contests.single.abbreviation, isNull);
        expect(problemDetail.ojLinks.first.logoUrl, isNull);
        expect(problems.count, 4);
        expect(problems.page, 1);
        expect(problems.pageSize, 50);
        expect(problems.diagnostics, isNull);
        expect(problems.seed, isNull);
        expect(users.exact?.handle, 'index');
        expect(
          rankingRegions.regions.map((region) => region.countryCode),
          ['KR', '', 'KR'],
        );
        expect(
          rankingRegions.regions.map((region) => region.userCount),
          [0, -7, 100],
        );
        expect(rankingTags.tags.map((tag) => tag.key), ['math', '', 'math']);
        expect(
          rankingTags.tags.map((tag) => tag.ratingTagIndex),
          [0, -7, 42],
        );
        expect(
          rankingTags.tags.map((tag) => tag.displayName),
          ['수학', '', 'Mathematics'],
        );
        expect(suggestions.suggestions, hasLength(3));
        expect(suggestions.suggestions.first.value, 'ko');
        expect(suggestions.suggestions.last.tier, -1);
        expect(analysis.diagnostics, hasLength(3));
        expect(
          analysis.diagnostics.first.code,
          ProblemSearchDiagnosticCode.unknownFilter,
        );
        expect(analysis.diagnostics[1].data, isNull);
        expect(analysis.diagnostics.last.data, isEmpty);
        expect(randomProblem.problemId, 1000.5);
        expect(randomProblem.problemId, isA<double>());
        expect(randomProblem.level, 12.5);
        expect(randomProblem.level, isA<double>());
        expect(randomProblem.viewerFolders.last.color,
            ProblemSearchViewerFolderColor.red);
        expect(siteStats.problemsWithLevel, 120000);
        expect(siteStats.users, 0);
        expect(siteStats.contributors, -7);
        expect(siteStats.contributions, 345678);
        expect(siteStats.usersByTier, [-3, 0, 0, 31, 7]);
        expect(sourceContest.id, -42.5);
        expect(sourceContest.id, isA<double>());
        expect(sourceGroup.id, -42.5);
        expect(sourceGroup.id, isA<double>());
        expect(achievementCatalog.userCount, 0);
        expect(achievementCatalog.items, hasLength(2));
        expect(achievementCatalog.items.first.id, -1);
        expect(achievementCatalog.items.first.rewards, hasLength(2));
        expect(achievementCatalog.items.last.progress, isNull);
        expect(problemAchievements.items, hasLength(2));
        expect(
          problemAchievements.items.first.relation,
          ProblemAchievementRelation.unlocks,
        );
        expect(problemAchievements.items.first.rewards, hasLength(2));
        expect(problemAchievements.items.last.condition, isNull);
        expect(tags.items.single.key, 'number_theory');
        expect(tagDetail.id, 42.5);
        expect(tagDetail.key, 'number_theory');
        expect(tagDetail.names['ko'], '수학 > 정수론');
        expect(tagDetail.parents.single.key, 'mathematics');
        expect(tagDetail.children.single.key, 'prime_number');
        expect(tagDetail.solvedCount, 123);
        expect(tagDetail.levels.map((level) => level.solved), [null, 5]);

        expect(
          httpClient.requests.map((request) => request.url),
          <Uri>[
            _uri('users/index', <String, String>{'lang': 'ko'}),
            _uri('users/index/activity/days', <String, String>{
              'from': '2026-11-01',
              'to': '2026-11-17',
            }),
            Uri.parse(
              'https://proxy.example/solved/v4/users/index/activity/feed?'
              'before=&from=9999-99-99&to=0000-00-00&limit=500',
            ),
            _uri('users/index/reputation', <String, String>{'range': '1y'}),
            _uri(
              'users/index/rating/history',
              <String, String>{'range': '90d'},
            ),
            _uri('users/index/tags/number_theory/histogram'),
            _uri(
              'users/index/achievements/summary',
              <String, String>{'lang': 'ko'},
            ),
            _uri(
              'users/index/badge-stand',
              <String, String>{'lang': 'ko'},
            ),
            _uri(
              'achievements/items/background/anniversary_1st',
              <String, String>{'lang': 'ko'},
            ),
            _uri(
              'achievements/items/badge/boardgame',
              <String, String>{'lang': 'ko'},
            ),
            _uri(
              'achievements/items/background/anniversary_1st',
              <String, String>{'lang': 'ko'},
            ),
            _uri(
              'achievements/items/badge/boardgame',
              <String, String>{'lang': 'ko'},
            ),
            Uri.parse(
              'https://proxy.example/solved/v4/problems/1000?sub=',
            ),
            _uri('problems', <String, String>{
              'q': 'number',
              'page': '2',
              'sort': 'level',
              'direction': 'desc',
              'seed': 'stable-seed',
            }),
            _uri('rankings/users/search', <String, String>{
              'q': 'index',
              'sort': 'contribution',
            }),
            _uri('rankings/regions'),
            Uri.parse(
              'https://proxy.example/solved/v4/rankings/tags?lang=',
            ),
            Uri.parse(
              'https://proxy.example/solved/v4/search/suggest?'
              'topic=tag%26%ED%95%9C&value=',
            ),
            Uri.parse(
              'https://proxy.example/solved/v4/search/analyze?'
              'q=tag%26%ED%95%9C',
            ),
            Uri.parse(
              'https://proxy.example/solved/v4/search/random-problem?q=',
            ),
            _uri('site/stats'),
            _uri('sources/oj/boj/contests/round-1'),
            _uri('sources/oj/boj/groups/team-1'),
            Uri.parse(
              'https://proxy.example/solved/v4/achievements?lang=',
            ),
            Uri.parse(
              'https://proxy.example/solved/v4/'
              'achievements/for-problem/1000?lang=',
            ),
            _uri('tags'),
            _uri('tags/number_theory'),
          ],
        );
        expect(httpClient.requests, hasLength(27));
        expect(
          httpClient.requests[12].url.toString(),
          'https://proxy.example/solved/v4/problems/1000?sub=',
        );
        expect(
          httpClient.requests[17].url.toString(),
          'https://proxy.example/solved/v4/search/suggest?'
          'topic=tag%26%ED%95%9C&value=',
        );
        expect(
          httpClient.requests[18].url.toString(),
          'https://proxy.example/solved/v4/search/analyze?'
          'q=tag%26%ED%95%9C',
        );
        expect(
          httpClient.requests[19].url.toString(),
          'https://proxy.example/solved/v4/search/random-problem?q=',
        );
        for (final request in httpClient.requests) {
          expect(request, isA<http.AbortableRequest>());
          expect(request.method, 'GET');
          expect(request.followRedirects, isFalse);
          expect(request.maxRedirects, 0);
          expect(request.headers, const <String, String>{
            'accept': 'application/json',
          });
          expect(request.bodyBytes, isEmpty);
        }
      },
    );

    test('accepts exactly 5 MiB and cancels a larger response', () async {
      final fixtureBytes = utf8.encode(fixture('v4/tags.json'));
      final exactBody = List<int>.of(fixtureBytes, growable: true)
        ..addAll(
          List<int>.filled(
            _maximumPublicResponseBytes - fixtureBytes.length,
            0x20,
          ),
        );
      handler = (_) async => _bytesResponse(
            exactBody,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );

      final tags = await client.v4SearchTags('NUMBER');
      expect(tags.items.single.key, 'number_theory');

      final streamCancelled = Completer<void>();
      late StreamController<List<int>> responseController;
      responseController = StreamController<List<int>>(
        onListen: () {
          responseController.add(
            List<int>.filled(_maximumPublicResponseBytes + 1, 0x20),
          );
        },
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      handler = (_) async => http.StreamedResponse(
            responseController.stream,
            503,
          );

      final error = await _captureFailure(client.v4SearchTags('dp'));
      await streamCancelled.future.timeout(const Duration(seconds: 1));
      await responseController.close();

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 503);
      expect(error.cause, isA<SolvedApiResponseTooLarge>());
      expect(error.responseBody, isNull);
      expect(error.isRetryable, isFalse);
      expect(httpClient.requests, hasLength(2));
    });

    test('aborts a timed-out body read without retrying', () async {
      client.close();
      client = _client(
        httpClient,
        requestTimeout: const Duration(milliseconds: 1),
      );
      final wasAborted = Completer<void>();
      final streamCancelled = Completer<void>();
      late StreamController<List<int>> responseController;
      responseController = StreamController<List<int>>(
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      handler = (request) async {
        final abortTrigger = (request as http.AbortableRequest).abortTrigger!;
        unawaited(
          abortTrigger.then((_) async {
            if (!wasAborted.isCompleted) wasAborted.complete();
            responseController.addError(
              http.RequestAbortedException(request.url),
            );
            await responseController.close();
          }),
        );
        return http.StreamedResponse(responseController.stream, 200);
      };

      final error = await _captureFailure(client.v4SearchTags('dp'));
      await wasAborted.future.timeout(const Duration(seconds: 1));
      await streamCancelled.future.timeout(const Duration(seconds: 1));

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, isNull);
      expect(error.cause, isA<TimeoutException>());
      expect(error.isTimeout, isTrue);
      expect(error.isRetryable, isTrue);
      expect(httpClient.requests, hasLength(1));
    });

    test('classifies status before interpreting an untrusted body', () async {
      final cases = <(int, bool)>[
        (201, false),
        (204, false),
        (302, false),
        (400, false),
        (401, false),
        (403, false),
        (404, false),
        (408, true),
        (429, true),
        (500, true),
        (599, true),
        (600, false),
      ];

      for (final entry in cases) {
        handler = (_) async => _bytesResponse(
              const <int>[0xff],
              statusCode: entry.$1,
              headers: <String, String>{
                'content-type': 'text/plain',
                if (entry.$1 == 429) 'retry-after': '12',
              },
            );

        final error = await _captureFailure(client.v4BadgeShow('boardgame'));

        expect(error, isA<BadgeRequestFailed>());
        expect(error.statusCode, entry.$1);
        expect(error.cause, isNull);
        expect(error.responseBody, isNull);
        expect(error.isRetryable, entry.$2, reason: '${entry.$1}');
        expect(
          error.retryAfter,
          entry.$1 == 429 ? const Duration(seconds: 12) : isNull,
        );
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('preserves the public failure type for every operation family',
        () async {
      handler = (_) async => _bytesResponse(const <int>[], statusCode: 404);

      expect(
        await _captureFailure(client.v4UserProfile('index')),
        isA<UserRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4UserActivityFeed('index')),
        isA<UserRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4UserRatingHistory('index')),
        isA<UserRequestFailed>(),
      );
      expect(
        await _captureFailure(
          client.v4UserTagLevelHistogram('index', 'number_theory'),
        ),
        isA<UserRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4UserAchievementSummary('index')),
        isA<UserRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4UserBadgeStand('index')),
        isA<UserRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4AchievementCatalog()),
        isA<AchievementRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4AchievementsForProblem(1000)),
        isA<AchievementRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4BackgroundShow('anniversary_1st')),
        isA<BackgroundRequestFailed>(),
      );
      expect(
        await _captureFailure(
          client.v4AchievementItem(
            OfficialAchievementItemKind.background,
            'anniversary_1st',
          ),
        ),
        isA<BackgroundRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4BadgeShow('boardgame')),
        isA<BadgeRequestFailed>(),
      );
      expect(
        await _captureFailure(
          client.v4AchievementItem(
            OfficialAchievementItemKind.badge,
            'boardgame',
          ),
        ),
        isA<BadgeRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4SearchTags('dp')),
        isA<SearchRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4TagDetail('number_theory')),
        isA<SearchRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4ProblemDetail(1000)),
        isA<SearchRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4SearchSuggestions('tag')),
        isA<SearchRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4AnalyzeProblemSearch()),
        isA<SearchRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4RandomProblem()),
        isA<SearchRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4RankingRegions()),
        isA<RankingRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4RankingTags()),
        isA<RankingRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4SiteStats()),
        isA<SiteRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4SourceContest('boj', 'contest')),
        isA<SourceRequestFailed>(),
      );
      expect(
        await _captureFailure(client.v4SourceGroup('boj', 'group')),
        isA<SourceRequestFailed>(),
      );
      expect(httpClient.requests, hasLength(23));
    });

    test('wraps malformed rating history as a user failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'history': <Object?>[
                <String, Object?>{'day': '2026-11-17'},
              ],
            }),
          );

      final error = await _captureFailure(
        client.v4UserRatingHistory('index'),
      );

      expect(error, isA<UserRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(
        httpClient.requests.single.url,
        _uri('users/index/rating/history'),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves omitted, empty, and combined activity-feed queries',
        () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/user_activity_feed.json'),
          );

      final omitted = await client.v4UserActivityFeed('index');
      final empty = await client.v4UserActivityFeed('index', before: '');
      final combined = await client.v4UserActivityFeed(
        '한 글',
        before: '커서 & raw',
        from: '9999-99-99',
        to: '0000-00-00',
        limit: 500,
      );

      expect(omitted.events.first.type, ProfileActivityFeedEventType.solved);
      expect(empty.nextCursor, '');
      expect(combined.events.last.hasPayload, isFalse);
      expect(httpClient.requests.map((request) => request.url), [
        _uri('users/index/activity/feed'),
        Uri.parse(
          'https://proxy.example/solved/v4/users/index/activity/feed?before=',
        ),
        _uri(
          'users/%ED%95%9C%20%EA%B8%80/activity/feed',
          <String, String>{
            'before': '커서 & raw',
            'from': '9999-99-99',
            'to': '0000-00-00',
            'limit': '500',
          },
        ),
      ]);
      expect(httpClient.requests, hasLength(3));
    });

    test('rejects invalid activity-feed queries before transport', () {
      expect(
        () => client.v4UserActivityFeed('index', from: '2026-1-01'),
        throwsArgumentError,
      );
      expect(
        () => client.v4UserActivityFeed('index', to: 'not-a-day'),
        throwsArgumentError,
      );
      expect(
        () => client.v4UserActivityFeed('index', limit: 0),
        throwsArgumentError,
      );
      expect(
        () => client.v4UserActivityFeed('index', limit: 501),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps a malformed activity feed as a user failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({'events': <Object?>[]}),
          );

      final error = await _captureFailure(
        client.v4UserActivityFeed('index'),
      );

      expect(error, isA<UserRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('users/index/activity/feed'),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves activity-feed 404 and 429 failures', () async {
      for (final status in [404, 429]) {
        handler = (_) async => _bytesResponse(
              const <int>[0xff],
              statusCode: status,
              headers: <String, String>{
                'content-type': 'text/plain',
                if (status == 429) 'retry-after': '11',
              },
            );

        final error = await _captureFailure(
          client.v4UserActivityFeed('index'),
        );

        expect(error, isA<UserRequestFailed>());
        expect(error.statusCode, status);
        expect(error.cause, isNull);
        expect(error.responseBody, isNull);
        expect(
          error.retryAfter,
          status == 429 ? const Duration(seconds: 11) : isNull,
        );
        expect(error.isRetryable, status == 429);
      }
      expect(httpClient.requests, hasLength(2));
    });

    test('sends an encoded anonymous user-tag histogram request', () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/user_tag_level_histogram.json'),
          );

      final actual = await client.v4UserTagLevelHistogram('한 글', 'tag key');

      expect(actual.key, 'response_key');
      expect(actual.histogram, [-3, 0, 0, 31, 7]);
      final request = httpClient.requests.single;
      expect(
        request.url.toString(),
        'https://proxy.example/solved/v4/users/'
        '%ED%95%9C%20%EA%B8%80/tags/tag%20key/histogram',
      );
      expect(request.method, 'GET');
      expect(request.headers, const <String, String>{
        'accept': 'application/json',
      });
      expect(request.bodyBytes, isEmpty);
    });

    test('rejects unsafe user-tag histogram segments before transport', () {
      expect(
        () => client.v4UserTagLevelHistogram('', 'tag'),
        throwsArgumentError,
      );
      expect(
        () => client.v4UserTagLevelHistogram('index', 'a/b'),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps a malformed user-tag histogram as a user failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'key': 'tag',
              'histogram': <Object?>[1, 2.0],
            }),
          );

      final error = await _captureFailure(
        client.v4UserTagLevelHistogram('index', 'number_theory'),
      );

      expect(error, isA<UserRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('users/index/tags/number_theory/histogram'),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves user-tag histogram 404 and 429 failures', () async {
      for (final status in [404, 429]) {
        handler = (_) async => _bytesResponse(
              const <int>[0xff],
              statusCode: status,
              headers: <String, String>{
                'content-type': 'text/plain',
                if (status == 429) 'retry-after': '9',
              },
            );

        final error = await _captureFailure(
          client.v4UserTagLevelHistogram('index', 'number_theory'),
        );

        expect(error, isA<UserRequestFailed>());
        expect(error.statusCode, status);
        expect(error.cause, isNull);
        expect(error.responseBody, isNull);
        expect(
          error.retryAfter,
          status == 429 ? const Duration(seconds: 9) : isNull,
        );
      }
      expect(httpClient.requests, hasLength(2));
    });

    test('preserves omitted empty and encoded catalog language queries',
        () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/achievement_catalog.json'),
          );

      final omitted = await client.v4AchievementCatalog();
      final empty = await client.v4AchievementCatalog(language: '');
      final raw = await client.v4AchievementCatalog(language: '한 글 & raw');

      expect(omitted.items.first.id, -1);
      expect(empty.items.last.progress, isNull);
      expect(raw.items.first.rewards, hasLength(2));
      expect(
        httpClient.requests.map((request) => request.url.toString()),
        [
          'https://proxy.example/solved/v4/achievements',
          'https://proxy.example/solved/v4/achievements?lang=',
          'https://proxy.example/solved/v4/achievements?'
              'lang=%ED%95%9C+%EA%B8%80+%26+raw',
        ],
      );
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
        });
        expect(request.bodyBytes, isEmpty);
      }
      expect(httpClient.requests, hasLength(3));
    });

    test('rejects an oversized catalog language before transport', () {
      expect(
        () => client.v4AchievementCatalog(
          language: List<String>.filled(17, '🌏').join(),
        ),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps a malformed achievement catalog as its own failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'items': <Object?>[],
              'userCount': -1,
            }),
          );

      final error = await _captureFailure(client.v4AchievementCatalog());

      expect(error, isA<AchievementRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(httpClient.requests.single.url, _uri('achievements'));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves achievement-catalog 429 failure metadata', () async {
      handler = (_) async => _bytesResponse(
            const <int>[0xff],
            statusCode: 429,
            headers: const <String, String>{
              'content-type': 'text/plain',
              'retry-after': '23',
            },
          );

      final error = await _captureFailure(client.v4AchievementCatalog());

      expect(error, isA<AchievementRequestFailed>());
      expect(error.statusCode, 429);
      expect(error.cause, isNull);
      expect(error.responseBody, isNull);
      expect(error.retryAfter, const Duration(seconds: 23));
      expect(error.isRetryable, isTrue);
      expect(httpClient.requests.single.url, _uri('achievements'));
      expect(httpClient.requests, hasLength(1));
    });

    test(
        'preserves omitted empty and encoded problem-achievement queries',
        () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/problem_achievements.json'),
          );

      final omitted = await client.v4AchievementsForProblem(1000);
      final empty = await client.v4AchievementsForProblem(1000, language: '');
      final raw = await client.v4AchievementsForProblem(
        1000,
        language: '한 글 & raw',
      );

      expect(omitted.items.first.relation, ProblemAchievementRelation.unlocks);
      expect(empty.items.last.earnedAt, isNull);
      expect(raw.items.first.rewards, hasLength(2));
      expect(
        httpClient.requests.map((request) => request.url.toString()),
        [
          'https://proxy.example/solved/v4/achievements/for-problem/1000',
          'https://proxy.example/solved/v4/'
              'achievements/for-problem/1000?lang=',
          'https://proxy.example/solved/v4/'
              'achievements/for-problem/1000?'
              'lang=%ED%95%9C+%EA%B8%80+%26+raw',
        ],
      );
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
        });
        expect(request.bodyBytes, isEmpty);
      }
      expect(httpClient.requests, hasLength(3));
    });

    test('rejects invalid problem-achievement requests before transport', () {
      for (final invalid in [0, -1]) {
        expect(
          () => client.v4AchievementsForProblem(invalid),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', 'problemId')
                .having(
                  (error) => error.invalidValue,
                  'invalidValue',
                  invalid,
                ),
          ),
        );
      }
      expect(
        () => client.v4AchievementsForProblem(
          1,
          language: List<String>.filled(17, '🌏').join(),
        ),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps malformed problem achievements as achievement failure',
        () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({'items': null}),
          );

      final error = await _captureFailure(
        client.v4AchievementsForProblem(1000),
      );

      expect(error, isA<AchievementRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('achievements/for-problem/1000'),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves problem-achievement 429 failure metadata', () async {
      handler = (_) async => _bytesResponse(
            const <int>[0xff],
            statusCode: 429,
            headers: const <String, String>{
              'content-type': 'text/plain',
              'retry-after': '29',
            },
          );

      final error = await _captureFailure(
        client.v4AchievementsForProblem(1000),
      );

      expect(error, isA<AchievementRequestFailed>());
      expect(error.statusCode, 429);
      expect(error.cause, isNull);
      expect(error.responseBody, isNull);
      expect(error.retryAfter, const Duration(seconds: 29));
      expect(error.isRetryable, isTrue);
      expect(
        httpClient.requests.single.url,
        _uri('achievements/for-problem/1000'),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('wraps malformed achievement summary as a user failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'earned': 1,
              'total': 1,
              'past': 0,
              'badges': 1,
              'backgrounds': 0,
              'recent': <Object?>[
                <String, Object?>{
                  'kind': 'badge',
                  'id': 1,
                  'key': 'key',
                  'name': 'name',
                  'imageUrl': 'image',
                  'category': 'category',
                  'addedAt': 'added',
                },
              ],
            }),
          );

      final error = await _captureFailure(
        client.v4UserAchievementSummary('index'),
      );

      expect(error, isA<UserRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(
        httpClient.requests.single.url,
        _uri(
          'users/index/achievements/summary',
          const <String, String>{'lang': 'ko'},
        ),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('wraps a malformed badge stand as a user failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'chosen': true,
              'badges': <Object?>[
                <String, Object?>{
                  'kind': 'badge',
                  'id': 1,
                  'key': 'key',
                  'name': 'name',
                  'imageUrl': 'image',
                  'category': 'category',
                  'addedAt': 'added',
                },
              ],
            }),
          );

      final error = await _captureFailure(
        client.v4UserBadgeStand('index'),
      );

      expect(error, isA<UserRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(
        httpClient.requests.single.url,
        _uri(
          'users/index/badge-stand',
          const <String, String>{'lang': 'ko'},
        ),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('wraps a malformed tag detail as a search failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'id': 1,
              'key': 'number_theory',
              'names': <String, String>{'en': 'Number Theory'},
              'aliases': <String>[],
              'parents': <Object?>[],
              'children': <Object?>[],
              'rated': true,
              'problemCount': 1,
              'solvedCount': null,
              'levels': <Object?>[
                <String, Object?>{'level': 1, 'count': 1},
              ],
            }),
          );

      final error = await _captureFailure(
        client.v4TagDetail('number_theory'),
      );

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('tags/number_theory'),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('rejects an invalid problem ID before transport', () {
      expect(() => client.v4ProblemDetail(0), throwsArgumentError);
      expect(httpClient.requests, isEmpty);
    });

    test('preserves omitted, empty, and encoded analysis queries', () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/search_analysis.json'),
          );

      await client.v4AnalyzeProblemSearch();
      await client.v4AnalyzeProblemSearch(query: '');
      await client.v4AnalyzeProblemSearch(query: '태그 & tier');

      expect(
        httpClient.requests.map((request) => request.url.toString()),
        [
          'https://proxy.example/solved/v4/search/analyze',
          'https://proxy.example/solved/v4/search/analyze?q=',
          'https://proxy.example/solved/v4/search/analyze?'
              'q=%ED%83%9C%EA%B7%B8+%26+tier',
        ],
      );
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
        });
        expect(request.bodyBytes, isEmpty);
      }
    });

    test('rejects an oversized analysis query before transport', () {
      final query1001 = List<String>.filled(1001, '😀').join();

      expect(
        () => client.v4AnalyzeProblemSearch(query: query1001),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps malformed search analysis as a search failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'diagnostics': <Object?>[
                <String, Object?>{
                  'start': 0,
                  'end': 1,
                  'severity': 'error',
                  'code': 'unknown-filter',
                  'messageKey': 'key',
                },
              ],
            }),
          );

      final error = await _captureFailure(
        client.v4AnalyzeProblemSearch(query: 'tag'),
      );

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('search/analyze', const <String, String>{'q': 'tag'}),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves search-analysis 429 failure metadata', () async {
      handler = (_) async => _bytesResponse(
            const <int>[0xff],
            statusCode: 429,
            headers: const <String, String>{
              'content-type': 'text/plain',
              'retry-after': '11',
            },
          );

      final error = await _captureFailure(
        client.v4AnalyzeProblemSearch(query: 'tag'),
      );

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 429);
      expect(error.cause, isNull);
      expect(error.responseBody, isNull);
      expect(error.retryAfter, const Duration(seconds: 11));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves omitted, empty, encoded, and boundary random queries',
        () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/random_problem.json'),
          );
      final boundary = List<String>.filled(1000, '🧩').join();

      await client.v4RandomProblem();
      await client.v4RandomProblem(query: '');
      await client.v4RandomProblem(query: '태그 & tier');
      await client.v4RandomProblem(query: boundary);

      expect(
        httpClient.requests.map((request) => request.url),
        [
          Uri.parse(
            'https://proxy.example/solved/v4/search/random-problem',
          ),
          Uri.parse(
            'https://proxy.example/solved/v4/search/random-problem?q=',
          ),
          Uri.parse(
            'https://proxy.example/solved/v4/search/random-problem?'
            'q=%ED%83%9C%EA%B7%B8+%26+tier',
          ),
          _uri('search/random-problem', <String, String>{'q': boundary}),
        ],
      );
      for (final request in httpClient.requests) {
        expect(request, isA<http.AbortableRequest>());
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(request.maxRedirects, 0);
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
        });
        expect(request.bodyBytes, isEmpty);
      }
    });

    test('rejects an oversized random query before transport', () {
      final query1001 = List<String>.filled(1001, '😀').join();

      expect(
        () => client.v4RandomProblem(query: query1001),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps a malformed random problem as a search failure', () async {
      final malformed = Map<String, dynamic>.from(
        jsonDecode(fixture('v4/random_problem.json')) as Map,
      )..remove('viewerFolders');
      handler = (_) async => _jsonResponse(jsonEncode(malformed));

      final error = await _captureFailure(
        client.v4RandomProblem(query: 'tag'),
      );

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('search/random-problem', const <String, String>{'q': 'tag'}),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves random-problem 404 and 429 failures', () async {
      for (final status in [404, 429]) {
        handler = (_) async => _bytesResponse(
              const <int>[0xff],
              statusCode: status,
              headers: <String, String>{
                'content-type': 'text/plain',
                if (status == 429) 'retry-after': '13',
              },
            );

        final error = await _captureFailure(
          client.v4RandomProblem(query: 'tag'),
        );

        expect(error, isA<SearchRequestFailed>());
        expect(error.statusCode, status);
        expect(error.cause, isNull);
        expect(error.responseBody, isNull);
        expect(error.isRetryable, status == 429);
        expect(
          error.retryAfter,
          status == 429 ? const Duration(seconds: 13) : isNull,
        );
      }
      expect(httpClient.requests, hasLength(2));
    });

    test('wraps malformed ranking regions as a ranking failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'regions': <Object?>[
                <String, Object?>{'countryCode': 'KR'},
              ],
            }),
          );

      final error = await _captureFailure(client.v4RankingRegions());

      expect(error, isA<RankingRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(httpClient.requests.single.url, _uri('rankings/regions'));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves ranking-regions 429 failure metadata', () async {
      handler = (_) async => _bytesResponse(
            const <int>[0xff],
            statusCode: 429,
            headers: const <String, String>{
              'content-type': 'text/plain',
              'retry-after': '15',
            },
          );

      final error = await _captureFailure(client.v4RankingRegions());

      expect(error, isA<RankingRequestFailed>());
      expect(error.statusCode, 429);
      expect(error.cause, isNull);
      expect(error.responseBody, isNull);
      expect(error.retryAfter, const Duration(seconds: 15));
      expect(error.isRetryable, isTrue);
      expect(httpClient.requests.single.url, _uri('rankings/regions'));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves omitted empty and raw ranking-tags language queries',
        () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/ranking_tags.json'),
          );

      final omitted = await client.v4RankingTags();
      final empty = await client.v4RankingTags(language: '');
      final raw = await client.v4RankingTags(language: '한 글 & raw');

      expect(omitted.tags.first.key, 'math');
      expect(empty.tags[1].ratingTagIndex, -7);
      expect(raw.tags.last.displayName, 'Mathematics');
      expect(httpClient.requests.map((request) => request.url), [
        _uri('rankings/tags'),
        Uri.parse(
          'https://proxy.example/solved/v4/rankings/tags?lang=',
        ),
        _uri(
          'rankings/tags',
          const <String, String>{'lang': '한 글 & raw'},
        ),
      ]);
      expect(httpClient.requests, hasLength(3));
    });

    test('wraps malformed ranking tags as a ranking failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'tags': <Object?>[
                <String, Object?>{
                  'key': 'math',
                  'ratingTagIndex': 0,
                },
              ],
            }),
          );

      final error = await _captureFailure(client.v4RankingTags());

      expect(error, isA<RankingRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(httpClient.requests.single.url, _uri('rankings/tags'));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves ranking-tags 429 failure metadata', () async {
      handler = (_) async => _bytesResponse(
            const <int>[0xff],
            statusCode: 429,
            headers: const <String, String>{
              'content-type': 'text/plain',
              'retry-after': '17',
            },
          );

      final error = await _captureFailure(client.v4RankingTags());

      expect(error, isA<RankingRequestFailed>());
      expect(error.statusCode, 429);
      expect(error.cause, isNull);
      expect(error.responseBody, isNull);
      expect(error.retryAfter, const Duration(seconds: 17));
      expect(error.isRetryable, isTrue);
      expect(httpClient.requests.single.url, _uri('rankings/tags'));
      expect(httpClient.requests, hasLength(1));
    });

    test('wraps malformed site stats as a site failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'problemsWithLevel': 1,
              'users': 2,
              'contributors': 3,
              'contributions': 4,
            }),
          );

      final error = await _captureFailure(client.v4SiteStats());

      expect(error, isA<SiteRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(httpClient.requests.single.url, _uri('site/stats'));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves site-stats 429 failure metadata', () async {
      handler = (_) async => _bytesResponse(
            const <int>[0xff],
            statusCode: 429,
            headers: const <String, String>{
              'content-type': 'text/plain',
              'retry-after': '17',
            },
          );

      final error = await _captureFailure(client.v4SiteStats());

      expect(error, isA<SiteRequestFailed>());
      expect(error.statusCode, 429);
      expect(error.cause, isNull);
      expect(error.responseBody, isNull);
      expect(error.retryAfter, const Duration(seconds: 17));
      expect(error.isRetryable, isTrue);
      expect(httpClient.requests.single.url, _uri('site/stats'));
      expect(httpClient.requests, hasLength(1));
    });

    test('sends encoded anonymous contest and group source lookups', () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/source_lookup.json'),
          );

      final contest = await client.v4SourceContest('한 글', 'round & #1');
      final group = await client.v4SourceGroup('boj', 'team & #1');

      expect(contest.id, -42.5);
      expect(group.id, -42.5);
      expect(
        httpClient.requests.map((request) => request.url.toString()),
        [
          'https://proxy.example/solved/v4/sources/oj/'
              '%ED%95%9C%20%EA%B8%80/contests/round%20%26%20%231',
          'https://proxy.example/solved/v4/sources/oj/boj/'
              'groups/team%20%26%20%231',
        ],
      );
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
        });
        expect(request.bodyBytes, isEmpty);
      }
      expect(httpClient.requests, hasLength(2));
    });

    test('rejects invalid source lookup segments before transport', () {
      final ojId33 = List<String>.filled(33, 'a').join();
      final nativeId65 = List<String>.filled(65, 'b').join();

      expect(
        () => client.v4SourceContest(ojId33, 'contest'),
        throwsArgumentError,
      );
      expect(
        () => client.v4SourceGroup('boj', nativeId65),
        throwsArgumentError,
      );
      expect(
        () => client.v4SourceContest('boj', 'a/b'),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps a malformed source lookup as a source failure', () async {
      handler = (_) async => _jsonResponse(jsonEncode({'id': 'not-number'}));

      final error = await _captureFailure(
        client.v4SourceContest('boj', 'contest'),
      );

      expect(error, isA<SourceRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('sources/oj/boj/contests/contest'),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves source lookup 404 and 429 failure metadata', () async {
      final lookups = <Future<SourceLookupResult> Function()>[
        () => client.v4SourceContest('boj', 'contest'),
        () => client.v4SourceGroup('boj', 'group'),
      ];

      for (final lookup in lookups) {
        for (final status in [404, 429]) {
          handler = (_) async => _bytesResponse(
                const <int>[0xff],
                statusCode: status,
                headers: <String, String>{
                  'content-type': 'text/plain',
                  if (status == 429) 'retry-after': '19',
                },
              );

          final error = await _captureFailure(lookup());

          expect(error, isA<SourceRequestFailed>());
          expect(error.statusCode, status);
          expect(error.cause, isNull);
          expect(error.responseBody, isNull);
          expect(
            error.retryAfter,
            status == 429 ? const Duration(seconds: 19) : isNull,
          );
          expect(error.isRetryable, status == 429);
        }
      }
      expect(httpClient.requests, hasLength(4));
    });

    test('preserves omitted, empty, and encoded suggestion queries', () async {
      handler = (_) async => _jsonResponse(
            fixture('v4/search_suggestions.json'),
          );

      await client.v4SearchSuggestions('');
      await client.v4SearchSuggestions('tag', value: '');
      await client.v4SearchSuggestions('태그 & tier', value: 'A B&한');

      expect(
        httpClient.requests.map((request) => request.url.toString()),
        [
          'https://proxy.example/solved/v4/search/suggest?topic=',
          'https://proxy.example/solved/v4/search/suggest?topic=tag&value=',
          'https://proxy.example/solved/v4/search/suggest?'
              'topic=%ED%83%9C%EA%B7%B8+%26+tier&'
              'value=A+B%26%ED%95%9C',
        ],
      );
      for (final request in httpClient.requests) {
        expect(request.method, 'GET');
        expect(request.headers, const <String, String>{
          'accept': 'application/json',
        });
        expect(request.bodyBytes, isEmpty);
      }
    });

    test('rejects oversized suggestion queries before transport', () {
      final topic65 = List<String>.filled(65, '😀').join();
      final value101 = List<String>.filled(101, '🧩').join();

      expect(
        () => client.v4SearchSuggestions(topic65),
        throwsArgumentError,
      );
      expect(
        () => client.v4SearchSuggestions('tag', value: value101),
        throwsArgumentError,
      );
      expect(httpClient.requests, isEmpty);
    });

    test('wraps malformed search suggestions as a search failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'suggestions': <Object?>[
                <String, Object?>{
                  'value': 'value',
                  'detail': null,
                },
              ],
            }),
          );

      final error = await _captureFailure(
        client.v4SearchSuggestions('tag'),
      );

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(
        httpClient.requests.single.url,
        _uri('search/suggest', const <String, String>{'topic': 'tag'}),
      );
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves search-suggestion 429 failure metadata', () async {
      handler = (_) async => _bytesResponse(
            const <int>[0xff],
            statusCode: 429,
            headers: const <String, String>{
              'content-type': 'text/plain',
              'retry-after': '7',
            },
          );

      final error = await _captureFailure(
        client.v4SearchSuggestions('tag'),
      );

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 429);
      expect(error.cause, isNull);
      expect(error.responseBody, isNull);
      expect(error.retryAfter, const Duration(seconds: 7));
      expect(httpClient.requests, hasLength(1));
    });

    test('wraps a malformed problem detail as a search failure', () async {
      handler = (_) async => _jsonResponse(
            jsonEncode({
              'id': 1,
              'problemId': 1,
              'subId': '',
              'level': 1,
              'levelAverage': 1,
              'levelStdev': 0,
              'isStandard': true,
              'votedUserCount': 1,
              'effectiveVoteCount': 1,
              'solvedUserCount': 1,
              'givesNoRating': false,
              'noRatingReasons': <Object?>[],
              'noRatingWarnings': <Object?>[],
              'titles': <Object?>[],
              'userStatus': null,
              'contests': <Object?>[],
              'tags': <Object?>[],
            }),
          );

      final error = await _captureFailure(client.v4ProblemDetail(1000));

      expect(error, isA<SearchRequestFailed>());
      expect(error.statusCode, 200);
      expect(error.cause, isA<FormatException>());
      expect(error.responseBody, isNull);
      expect(httpClient.requests.single.url, _uri('problems/1000'));
      expect(httpClient.requests, hasLength(1));
    });

    test('preserves problem-detail 404 and 429 failures', () async {
      for (final status in [404, 429]) {
        handler = (_) async => _bytesResponse(
              const <int>[0xff],
              statusCode: status,
              headers: <String, String>{
                'content-type': 'text/plain',
                if (status == 429) 'retry-after': '7',
              },
            );

        final error = await _captureFailure(client.v4ProblemDetail(1000));

        expect(error, isA<SearchRequestFailed>());
        expect(error.statusCode, status);
        expect(error.cause, isNull);
        expect(error.responseBody, isNull);
        expect(
          error.retryAfter,
          status == 429 ? const Duration(seconds: 7) : isNull,
        );
      }
      expect(httpClient.requests, hasLength(2));
    });

    test('wraps malformed canonical items by requested asset family', () async {
      handler = (request) async {
        final isBackground = request.url.path.contains('/background/');
        final source = Map<String, dynamic>.from(
          jsonDecode(
            fixture(
              isBackground ? 'v4/background_item.json' : 'v4/badge_item.json',
            ),
          ) as Map,
        )..['achievements'] = <Object?>[
            <String, Object?>{'key': 'malformed'},
          ];
        return _jsonResponse(jsonEncode(source));
      };

      final backgroundError = await _captureFailure(
        client.v4AchievementItem(
          OfficialAchievementItemKind.background,
          'item',
        ),
      );
      final badgeError = await _captureFailure(
        client.v4AchievementItem(
          OfficialAchievementItemKind.badge,
          'item',
        ),
      );

      expect(backgroundError, isA<BackgroundRequestFailed>());
      expect(backgroundError.statusCode, 200);
      expect(backgroundError.cause, isA<FormatException>());
      expect(badgeError, isA<BadgeRequestFailed>());
      expect(badgeError.statusCode, 200);
      expect(badgeError.cause, isA<FormatException>());
      expect(
        httpClient.requests.map((request) => request.url),
        [
          _uri(
            'achievements/items/background/item',
            const <String, String>{'lang': 'ko'},
          ),
          _uri(
            'achievements/items/badge/item',
            const <String, String>{'lang': 'ko'},
          ),
        ],
      );
      expect(httpClient.requests, hasLength(2));
    });

    test('wraps eagerly validated item envelopes by requested asset family',
        () async {
      handler = (request) async {
        final isBackground = request.url.path.endsWith('/background/item');
        final source = Map<String, dynamic>.from(
          jsonDecode(
            fixture(
              isBackground ? 'v4/background_item.json' : 'v4/badge_item.json',
            ),
          ) as Map,
        );
        if (isBackground) {
          final background = Map<String, dynamic>.from(
            source['background'] as Map,
          );
          final authors = List<Object?>.from(background['authors'] as List)
            ..add(<String, Object?>{
              'key': 'malformed-trailing-author',
              'displayName': null,
              'role': 'Illustration',
              'authorUrl': null,
              'handle': null,
              'twitter': null,
            });
          source['background'] = background..['authors'] = authors;
        } else {
          final credits = List<Object?>.from(source['credits'] as List)
            ..add(<String, Object?>{
              'key': 'malformed-trailing-credit',
              'displayName': null,
              'role': 'Design',
              'authorUrl': null,
              'handle': null,
              'twitter': null,
            });
          source['credits'] = credits;
        }
        return _jsonResponse(jsonEncode(source));
      };

      final backgroundError = await _captureFailure(
        client.v4BackgroundShow('item'),
      );
      final badgeError = await _captureFailure(client.v4BadgeShow('item'));

      expect(backgroundError, isA<BackgroundRequestFailed>());
      expect(backgroundError.statusCode, 200);
      expect(backgroundError.cause, isA<FormatException>());
      expect(badgeError, isA<BadgeRequestFailed>());
      expect(badgeError.statusCode, 200);
      expect(badgeError.cause, isA<FormatException>());
      expect(
        httpClient.requests.map((request) => request.url),
        [
          _uri(
            'achievements/items/background/item',
            const <String, String>{'lang': 'ko'},
          ),
          _uri(
            'achievements/items/badge/item',
            const <String, String>{'lang': 'ko'},
          ),
        ],
      );
      expect(httpClient.requests, hasLength(2));
    });

    test('preserves only valid Retry-After metadata on retryable 429s',
        () async {
      final cases = <(String?, Duration?, bool)>[
        ('12', const Duration(seconds: 12), true),
        (null, null, true),
        ('', null, true),
        ('invalid', null, true),
        ('-1', null, true),
        ('+1', null, true),
        ('1.0', null, true),
      ];

      for (final entry in cases) {
        handler = (_) async => _bytesResponse(
              utf8.encode('do-not-interpret'),
              statusCode: 429,
              headers: <String, String>{
                if (entry.$1 != null) 'Retry-After': entry.$1!,
              },
            );

        final error = await _captureFailure(client.v4UserProfile('index'));

        expect(error, isA<UserRequestFailed>());
        expect(error.statusCode, 429);
        expect(error.retryAfter, entry.$2);
        expect(error.isRetryable, entry.$3);
        expect(error.responseBody, isNull);
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('requires JSON metadata, fatal UTF-8, JSON, and the DTO shape',
        () async {
      final cases = <(List<int>, Map<String, String>)>[
        (
          utf8.encode('{"secret":"missing-content-type"}'),
          const <String, String>{},
        ),
        (
          utf8.encode('{"secret":"wrong-content-type"}'),
          const <String, String>{'content-type': 'text/plain'},
        ),
        (
          utf8.encode('{"secret":"malformed-content-type"}'),
          const <String, String>{'content-type': 'application/json,'},
        ),
        (
          const <int>[0xff],
          const <String, String>{'content-type': 'application/json'},
        ),
        (
          utf8.encode('{"secret":"invalid-json"'),
          const <String, String>{'content-type': 'application/json'},
        ),
        (
          utf8.encode('{"kind":"badge","key":"secret-dto"}'),
          const <String, String>{'content-type': 'application/json'},
        ),
      ];

      for (final entry in cases) {
        handler = (_) async => _bytesResponse(
              entry.$1,
              headers: entry.$2,
            );

        final error = await _captureFailure(client.v4BadgeShow('boardgame'));

        expect(error, isA<BadgeRequestFailed>());
        expect(error.statusCode, 200);
        expect(error.cause, isA<FormatException>());
        expect(error.responseBody, isNull);
        expect(error.isRetryable, isFalse);
        expect(error.toString(), isNot(contains('secret')));
        expect(error.cause.toString(), isNot(contains('secret')));
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('preserves and classifies injected transport failures', () async {
      final cases = <(Object, bool, bool)>[
        (TimeoutException('injected timeout'), true, true),
        (http.ClientException('offline'), true, false),
        (StateError('offline'), false, false),
      ];

      for (final entry in cases) {
        handler = (_) => Future<http.StreamedResponse>.error(entry.$1);

        final error = await _captureFailure(client.v4UserProfile('index'));

        expect(error, isA<UserRequestFailed>());
        expect(error.statusCode, isNull);
        expect(error.cause, same(entry.$1));
        expect(error.isRetryable, entry.$2);
        expect(error.isTimeout, entry.$3);
      }
      expect(httpClient.requests, hasLength(cases.length));
    });

    test('keeps the shared client caller-owned across close and validation',
        () async {
      client.close();
      client.close();

      expect(httpClient.wasClosed, isFalse);
      expect(httpClient.requests, isEmpty);
      await expectLater(
        client.v4SearchTags('dp'),
        throwsA(isA<StateError>()),
      );

      expect(
        () => SolvedApiClient.officialV4(
          proxyBaseUri: Uri.parse('https://solved.ac/solved/v4/'),
          httpClient: httpClient,
        ),
        throwsArgumentError,
      );
      expect(httpClient.wasClosed, isFalse);

      expect(
        () => SolvedApiClient.officialV4(
          proxyBaseUri: Uri.parse('http://localhost:3000/solved/v4/'),
          httpClient: httpClient,
        ),
        throwsArgumentError,
      );
      final loopbackClient = SolvedApiClient.officialV4(
        proxyBaseUri: Uri.parse('http://localhost:3000/solved/v4/'),
        httpClient: httpClient,
        allowInsecureLoopback: true,
      );
      loopbackClient.close();

      expect(httpClient.wasClosed, isFalse);
      expect(httpClient.requests, isEmpty);
    });
  });
}

const int _legacyResponseLimitBytes = 64 * 1024;
const int _maximumPublicResponseBytes = 5 * 1024 * 1024;
final Uri _proxyBaseUri = Uri.parse('https://proxy.example/solved/v4/');

SolvedApiClient _client(
  http.Client httpClient, {
  Duration requestTimeout = const Duration(seconds: 10),
}) =>
    SolvedApiClient.officialV4(
      proxyBaseUri: _proxyBaseUri,
      httpClient: httpClient,
      requestTimeout: requestTimeout,
    );

Uri _uri(
  String relativePath, [
  Map<String, String> queryParameters = const <String, String>{},
]) {
  final resolved = _proxyBaseUri.resolve(relativePath);
  return queryParameters.isEmpty
      ? resolved
      : resolved.replace(queryParameters: queryParameters);
}

String _paddedFixture(String path) =>
    '${fixture(path)}${List<String>.filled(_legacyResponseLimitBytes, ' ').join()}';

http.StreamedResponse _jsonResponse(
  String body, {
  int statusCode = 200,
  Map<String, String>? headers,
}) =>
    _bytesResponse(
      utf8.encode(body),
      statusCode: statusCode,
      headers: headers ??
          const <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
    );

http.StreamedResponse _bytesResponse(
  List<int> bytes, {
  int statusCode = 200,
  Map<String, String> headers = const <String, String>{},
}) =>
    http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      statusCode,
      headers: headers,
    );

Future<SolvedApiException> _captureFailure(Future<Object?> future) async {
  try {
    await future;
  } on SolvedApiException catch (error) {
    return error;
  }
  throw StateError('Expected a solved API request failure');
}
