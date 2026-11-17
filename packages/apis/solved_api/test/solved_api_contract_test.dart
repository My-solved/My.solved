import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

void main() {
  group('SolvedApiV3Contract', () {
    test('describes the verified user request for direct and proxy targets',
        () {
      final endpoint = const SolvedApiV3Contract().userShow('index');

      expect(endpoint.direct.baseUri, Uri.parse('https://solved.ac/api/v3/'));
      expect(endpoint.direct.path, 'user/show');
      expect(endpoint.direct.queryParameters, {'handle': 'index'});
      expect(
        endpoint.proxy.baseUri,
        Uri.parse('https://codepoker.w8385.dev/solved/'),
      );
      expect(endpoint.proxy.path, 'user/show');
      expect(endpoint.proxy.queryParameters, {'handle': 'index'});
    });

    test('normalizes profile streak days without mutating v3 wire data', () {
      final json = <String, dynamic>{
        'grass': [
          {'date': '2026-11-15', 'value': 4},
          {'date': '2026-11-16', 'value': 'frozen'},
          {'date': '2026-11-17', 'value': 'frozen-repaired'},
        ],
        'theme': 'wire-only-theme',
        'currentStreak': 7,
        'longestStreak': 100,
        'topic': 'default',
      };

      final endpoint = const SolvedApiV3Contract().userGrass('index', null);
      final actual = endpoint.decode(json);

      expect(endpoint.direct.queryParameters, {
        'handle': 'index',
        'topic': 'default',
      });
      expect(actual.currentStreak, 7);
      expect(actual.days, hasLength(3));
      expect(actual.days.map((day) => day.solvedCount), [4, 0, 1]);
      expect(actual.days.last.year, 2026);
      expect(actual.days.last.month, 11);
      expect(actual.days.last.day, 17);
      expect((json['grass'] as List).first, {
        'date': '2026-11-15',
        'value': 4,
      });
      expect(json['theme'], 'wire-only-theme');
    });

    test('normalizes selected problem stat wire fields', () {
      final json = <Map<String, dynamic>>[
        {
          'level': 17,
          'solved': 107,
          'total': 1217,
          'partial': 1,
          'tried': 10,
        },
      ];

      final actual =
          const SolvedApiV3Contract().userProblemStats('index').decode(json);

      expect(actual.single.tier, 17);
      expect(actual.single.solvedCount, 107);
      expect(json.single['total'], 1217);
    });

    test('normalizes selected tag rating wire fields', () {
      final json = <Map<String, dynamic>>[
        {
          'tag': {'key': 'bfs'},
          'solvedCount': 51,
          'rating': 1138,
          'ratingByProblemsSum': 1058,
          'ratingByClass': 0,
          'ratingBySolvedCount': 80,
          'ratingProblemsCutoff': 9,
        },
      ];

      final actual =
          const SolvedApiV3Contract().userTagRatings('index').decode(json);

      expect(actual.single.rating, 1138);
      expect((json.single['tag'] as Map)['key'], 'bfs');
    });

    test('normalizes background wire fields without mutating the response', () {
      final json = <String, dynamic>{
        'backgroundId': 'anniversary_1st',
        'backgroundImageUrl': 'https://example.com/background.png',
        'fallbackBackgroundImageUrl': 'https://example.com/fallback.png',
        'wireOnlyField': true,
      };

      final actual =
          const SolvedApiV3Contract().backgroundShow('anniversary_1st').decode(
                json,
              );

      expect(actual.imageUrl, 'https://example.com/background.png');
      expect(actual.fallbackImageUrl, 'https://example.com/fallback.png');
      expect(json['wireOnlyField'], isTrue);
    });

    test('normalizes selected badge wire fields', () {
      final actual = const SolvedApiV3Contract().badgeShow('boardgame').decode({
        'badgeId': 'boardgame',
        'badgeImageUrl': 'https://example.com/badge.png',
        'wireOnlyField': true,
      });

      expect(actual.imageUrl, 'https://example.com/badge.png');
    });
  });

  group('SolvedApiTarget', () {
    test('normalizes its base and defensively copies query parameters', () {
      final query = {'handle': 'index'};
      final target = SolvedApiTarget(
        baseUri: Uri.parse('https://example.com/api'),
        path: 'user/show',
        queryParameters: query,
      );
      query['handle'] = 'changed';

      expect(target.baseUri, Uri.parse('https://example.com/api/'));
      expect(target.queryParameters, {'handle': 'index'});
      expect(
        () => target.queryParameters['handle'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('rejects ambiguous bases and non-relative endpoint paths', () {
      expect(
        () => SolvedApiTarget(
          baseUri: Uri.parse('/api/v3/'),
          path: 'user/show',
        ),
        throwsArgumentError,
      );
      expect(
        () => SolvedApiTarget(
          baseUri: Uri.parse('https://example.com/api/?token=secret'),
          path: 'user/show',
        ),
        throwsArgumentError,
      );
      for (final path in [
        '/user/show',
        '../user/show',
        '%2e%2e/user/show',
        r'user\show',
        'https://evil.example/user/show',
        'user/show?handle=index',
        'user/show#fragment',
      ]) {
        expect(
          () => SolvedApiTarget(
            baseUri: Uri.parse('https://example.com/api/'),
            path: path,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
