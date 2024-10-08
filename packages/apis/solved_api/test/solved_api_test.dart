import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class FakeUri extends Fake implements Uri {}

void main() {
  group('SolvedApiClient', () {
    late http.Client httpClient;
    late SolvedApiClient apiClient;

    setUpAll(() {
      registerFallbackValue(FakeUri());
    });

    setUp(() {
      httpClient = MockHttpClient();
      apiClient = SolvedApiClient(httpClient: httpClient);
    });

    group('userShow', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userShow(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/user/show',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns User on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(
          '''
{
  "handle": "w8385",
  "bio": "https://github.com/w8385",
  "badgeId": "boardgame",
  "backgroundId": "boardgame_5",
  "profileImageUrl": "https://static.solved.ac/uploads/profile/w8385-picture-1661145114047.png",
  "solvedCount": 2766,
  "voteCount": 1442,
  "class": 6,
  "classDecoration": "none",
  "rivalCount": 64,
  "reverseRivalCount": 44,
  "tier": 20,
  "rating": 2126,
  "ratingByProblemsSum": 1716,
  "ratingByClass": 210,
  "ratingBySolvedCount": 175,
  "ratingByVoteCount": 25,
  "arenaTier": 6,
  "arenaRating": 1545,
  "arenaMaxTier": 6,
  "arenaMaxRating": 1545,
  "arenaCompetedRoundCount": 5,
  "maxStreak": 477,
  "coins": 12,
  "stardusts": 10499,
  "joinedAt": "2022-03-20T14:55:40.000Z",
  "bannedUntil": "1970-01-01T00:00:00.000Z",
  "proUntil": "2025-08-29T22:20:53.000Z",
  "rank": 1232,
  "isRival": false,
  "isReverseRival": false,
  "blocked": false,
  "reverseBlocked": false
}''',
        );
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userShow(handle);
        expect(
          actual,
          isA<User>().having((l) => l.handle, 'handle', 'w8385'),
        );
      });
    });

    group('userOrganizations', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userOrganizations(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/user/organizations',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns List<Organization> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
            [
  {
    "organizationId": 323,
    "name": "숭실대학교",
    "type": "university",
    "rating": 3132,
    "userCount": 816,
    "voteCount": 15899,
    "solvedCount": 14493,
    "color": "#000000"
  },
  {
    "organizationId": 1609,
    "name": "SW마에스트로",
    "type": "community",
    "rating": 2904,
    "userCount": 185,
    "voteCount": 13428,
    "solvedCount": 10730,
    "color": "#000000"
  },
  {
    "organizationId": 1932,
    "name": "Best of the Best",
    "type": "community",
    "rating": 2243,
    "userCount": 2,
    "voteCount": 1590,
    "solvedCount": 3354,
    "color": "#000000"
  }
]
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userOrganizations(handle);
        expect(
          actual,
          isA<List<Organization>>().having(
            (l) => l.length,
            'length',
            3,
          ),
        );
      });
    });

    group('userAvailableBadges', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userAvailableBadges(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/user/available_badges',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns List<Badge> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
        {
  "count": 3,
  "items": [
    {
      "badgeId": "grass_01",
      "badgeImageUrl": "https://static.solved.ac/profile_badge/grass_01.png",
      "unlockedUserCount": 93103,
      "displayName": "Level 1 Sprout",
      "displayDescription": "Solved problems for 2 days in a row",
      "badgeTier": "bronze",
      "badgeCategory": "achievement",
      "solvedCompanyRights": true,
      "createdAt": "2021-09-14T06:18:34.000Z"
    },
    {
      "badgeId": "grass_02",
      "badgeImageUrl": "https://static.solved.ac/profile_badge/grass_02.png",
      "unlockedUserCount": 57957,
      "displayName": "Level 2 Sprout",
      "displayDescription": "Solved problems for 4 days in a row",
      "badgeTier": "bronze",
      "badgeCategory": "achievement",
      "solvedCompanyRights": true,
      "createdAt": "2021-09-14T06:18:47.000Z"
    },
    {
      "badgeId": "grass_03",
      "badgeImageUrl": "https://static.solved.ac/profile_badge/grass_03.png",
      "unlockedUserCount": 26105,
      "displayName": "Level 3 Sprout",
      "displayDescription": "Solved problems for 8 days in a row",
      "badgeTier": "bronze",
      "badgeCategory": "achievement",
      "solvedCompanyRights": true,
      "createdAt": "2021-09-14T06:18:57.000Z"
    }
  ]
}
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userAvailableBadges(handle);
        expect(
          actual,
          isA<List<Badge>>().having(
            (l) => l.length,
            'length',
            3,
          ),
        );
      });
    });

    group('userGrass', () {
      const handle = 'w8385';
      const topic = 'default';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userGrass(handle, null);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/user/grass',
              {'handle': handle, 'topic': topic},
            ),
          ),
        ).called(1);
      });

      test('returns Streak on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
{
  "grass": [
    {
      "date": "2023-11-25",
      "value": "frozen"
    },
    {
      "date": "2023-10-06",
      "value": "frozen"
    },
    {
      "date": "2023-09-11",
      "value": "frozen"
    }
  ],
  "theme": "special_hanbyeol",
  "currentStreak": 478,
  "longestStreak": 478,
  "topic": "today-solved-max-tier"
}
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userGrass(handle, topic);
        expect(
            actual,
            isA<Streak>()
                .having((streak) => streak.grass, 'grass', isA<List<Grass>>()));
      });
    });

    group('userTop100', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userTop100(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/user/top_100',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns List<Problem> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
{
  "count": 3,
  "items": [
    {
      "problemId": 10854,
      "titleKo": "Divisions",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Divisions",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 452,
      "level": 21,
      "votedUserCount": 97,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.9779,
      "official": true,
      "tags": [
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "miller_rabin",
          "isMeta": false,
          "bojTagId": 47,
          "problemCount": 21,
          "displayNames": [
            {
              "language": "ko",
              "name": "밀러–라빈 소수 판별법",
              "short": "밀러–라빈 소수 판별법"
            },
            {
              "language": "en",
              "name": "miller–rabin",
              "short": "miller–rabin"
            },
            {
              "language": "ja",
              "name": "ミラー–ラビン素数判定法",
              "short": "ミラー–ラビン"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "pollard_rho",
          "isMeta": false,
          "bojTagId": 58,
          "problemCount": 21,
          "displayNames": [
            {
              "language": "ko",
              "name": "폴라드 로",
              "short": "폴라드 로"
            },
            {
              "language": "en",
              "name": "pollard rho",
              "short": "pollard rho"
            },
            {
              "language": "ja",
              "name": "ポラード・ロー素因数分解法",
              "short": "ポラード・ロー"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "primality_test",
          "isMeta": false,
          "bojTagId": 9,
          "problemCount": 303,
          "displayNames": [
            {
              "language": "ko",
              "name": "소수 판정",
              "short": "소수 판정"
            },
            {
              "language": "en",
              "name": "primality test",
              "short": "primality test"
            },
            {
              "language": "ja",
              "name": "素数性テスト",
              "short": "素数性テスト"
            }
          ],
          "aliases": [
            {
              "alias": "소수"
            },
            {
              "alias": "소수판별"
            },
            {
              "alias": "소수판정"
            },
            {
              "alias": "prime"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13926,
      "titleKo": "gcd(n, k) = 1",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "gcd(n, k) = 1",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 562,
      "level": 21,
      "votedUserCount": 114,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.9715,
      "official": true,
      "tags": [
        {
          "key": "euler_phi",
          "isMeta": false,
          "bojTagId": 151,
          "problemCount": 37,
          "displayNames": [
            {
              "language": "ko",
              "name": "오일러 피 함수",
              "short": "오일러 피 함수"
            },
            {
              "language": "en",
              "name": "euler totient function",
              "short": "euler phi function"
            },
            {
              "language": "ja",
              "name": "euler totient function",
              "short": "euler phi function"
            }
          ],
          "aliases": [
            {
              "alias": "오일러 파이"
            },
            {
              "alias": "토션트"
            },
            {
              "alias": "eulerphi"
            },
            {
              "alias": "euler phi"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "miller_rabin",
          "isMeta": false,
          "bojTagId": 47,
          "problemCount": 21,
          "displayNames": [
            {
              "language": "ko",
              "name": "밀러–라빈 소수 판별법",
              "short": "밀러–라빈 소수 판별법"
            },
            {
              "language": "en",
              "name": "miller–rabin",
              "short": "miller–rabin"
            },
            {
              "language": "ja",
              "name": "ミラー–ラビン素数判定法",
              "short": "ミラー–ラビン"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "pollard_rho",
          "isMeta": false,
          "bojTagId": 58,
          "problemCount": 21,
          "displayNames": [
            {
              "language": "ko",
              "name": "폴라드 로",
              "short": "폴라드 로"
            },
            {
              "language": "en",
              "name": "pollard rho",
              "short": "pollard rho"
            },
            {
              "language": "ja",
              "name": "ポラード・ロー素因数分解法",
              "short": "ポラード・ロー"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "primality_test",
          "isMeta": false,
          "bojTagId": 9,
          "problemCount": 303,
          "displayNames": [
            {
              "language": "ko",
              "name": "소수 판정",
              "short": "소수 판정"
            },
            {
              "language": "en",
              "name": "primality test",
              "short": "primality test"
            },
            {
              "language": "ja",
              "name": "素数性テスト",
              "short": "素数性テスト"
            }
          ],
          "aliases": [
            {
              "alias": "소수"
            },
            {
              "alias": "소수판별"
            },
            {
              "alias": "소수판정"
            },
            {
              "alias": "prime"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 16214,
      "titleKo": "N과 M",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "N과 M",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 155,
      "level": 21,
      "votedUserCount": 42,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.871,
      "official": true,
      "tags": [
        {
          "key": "euler_phi",
          "isMeta": false,
          "bojTagId": 151,
          "problemCount": 37,
          "displayNames": [
            {
              "language": "ko",
              "name": "오일러 피 함수",
              "short": "오일러 피 함수"
            },
            {
              "language": "en",
              "name": "euler totient function",
              "short": "euler phi function"
            },
            {
              "language": "ja",
              "name": "euler totient function",
              "short": "euler phi function"
            }
          ],
          "aliases": [
            {
              "alias": "오일러 파이"
            },
            {
              "alias": "토션트"
            },
            {
              "alias": "eulerphi"
            },
            {
              "alias": "euler phi"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1077,
      "titleKo": "넓이",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "넓이",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 125,
      "level": 20,
      "votedUserCount": 21,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.536,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "line_intersection",
          "isMeta": false,
          "bojTagId": 42,
          "problemCount": 107,
          "displayNames": [
            {
              "language": "ko",
              "name": "선분 교차 판정",
              "short": "선분 교차 판정"
            },
            {
              "language": "en",
              "name": "line segment intersection check",
              "short": "line segment intersection check"
            },
            {
              "language": "ja",
              "name": "直線の交点",
              "short": "直線の交点"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "point_in_convex_polygon",
          "isMeta": false,
          "bojTagId": 56,
          "problemCount": 34,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 다각형 내부의 점 판정",
              "short": "볼록 다각형 내부의 점 판정"
            },
            {
              "language": "en",
              "name": "point in convex polygon check",
              "short": "point in convex polygon check"
            },
            {
              "language": "ja",
              "name": "凸多角形の点包含判定",
              "short": "凸多角形の点包含判定"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "polygon_area",
          "isMeta": false,
          "bojTagId": 3,
          "problemCount": 59,
          "displayNames": [
            {
              "language": "ko",
              "name": "다각형의 넓이",
              "short": "다각형의 넓이"
            },
            {
              "language": "en",
              "name": "area of a polygon",
              "short": "area of a polygon"
            },
            {
              "language": "ja",
              "name": "多角形の面積",
              "short": "多角形の面積"
            }
          ],
          "aliases": [
            {
              "alias": "넓이"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 5615,
      "titleKo": "아파트 임대",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "아파트 임대",
          "isOriginal": false
        },
        {
          "language": "ja",
          "languageDisplayName": "ja",
          "title": "問題 ４",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1080,
      "level": 20,
      "votedUserCount": 168,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": true,
      "averageTries": 5.1657,
      "official": true,
      "tags": [
        {
          "key": "miller_rabin",
          "isMeta": false,
          "bojTagId": 47,
          "problemCount": 21,
          "displayNames": [
            {
              "language": "ko",
              "name": "밀러–라빈 소수 판별법",
              "short": "밀러–라빈 소수 판별법"
            },
            {
              "language": "en",
              "name": "miller–rabin",
              "short": "miller–rabin"
            },
            {
              "language": "ja",
              "name": "ミラー–ラビン素数判定法",
              "short": "ミラー–ラビン"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "primality_test",
          "isMeta": false,
          "bojTagId": 9,
          "problemCount": 303,
          "displayNames": [
            {
              "language": "ko",
              "name": "소수 판정",
              "short": "소수 판정"
            },
            {
              "language": "en",
              "name": "primality test",
              "short": "primality test"
            },
            {
              "language": "ja",
              "name": "素数性テスト",
              "short": "素数性テスト"
            }
          ],
          "aliases": [
            {
              "alias": "소수"
            },
            {
              "alias": "소수판별"
            },
            {
              "alias": "소수판정"
            },
            {
              "alias": "prime"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 12728,
      "titleKo": "n제곱 계산",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "n제곱 계산",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Numbers (Large)",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 671,
      "level": 20,
      "votedUserCount": 165,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.5171,
      "official": true,
      "tags": [
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 22289,
      "titleKo": "큰 수 곱셈 (3)",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "큰 수 곱셈 (3)",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 400,
      "level": 20,
      "votedUserCount": 75,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.1725,
      "official": true,
      "tags": [
        {
          "key": "fft",
          "isMeta": false,
          "bojTagId": 28,
          "problemCount": 117,
          "displayNames": [
            {
              "language": "ko",
              "name": "고속 푸리에 변환",
              "short": "고속 푸리에 변환"
            },
            {
              "language": "en",
              "name": "fast fourier transform",
              "short": "fft"
            },
            {
              "language": "ja",
              "name": "高速フーリエ変換",
              "short": "fft"
            }
          ],
          "aliases": [
            {
              "alias": "푸리에변환"
            },
            {
              "alias": "컨볼루션"
            },
            {
              "alias": "convolution"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 28123,
      "titleKo": "삶, 우주, 그리고 모든 것에 관한 궁극적인 질문의 해답",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "삶, 우주, 그리고 모든 것에 관한 궁극적인 질문의 해답",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 56,
      "level": 20,
      "votedUserCount": 29,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.6071,
      "official": true,
      "tags": [
        {
          "key": "ad_hoc",
          "isMeta": false,
          "bojTagId": 109,
          "problemCount": 1254,
          "displayNames": [
            {
              "language": "ko",
              "name": "애드 혹",
              "short": "애드 혹"
            },
            {
              "language": "en",
              "name": "ad-hoc",
              "short": "ad-hoc"
            },
            {
              "language": "ja",
              "name": "アドホック",
              "short": "アドホック"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 8927,
      "titleKo": "Squares",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Squares",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 63,
      "level": 19,
      "votedUserCount": 12,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.6984,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 10254,
      "titleKo": "고속도로",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "고속도로",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Highway",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1036,
      "level": 19,
      "votedUserCount": 126,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.4585,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 10438,
      "titleKo": "페리 수열의 합",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "페리 수열의 합",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Farey Sums",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 56,
      "level": 19,
      "votedUserCount": 9,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.0893,
      "official": true,
      "tags": [
        {
          "key": "euler_phi",
          "isMeta": false,
          "bojTagId": 151,
          "problemCount": 37,
          "displayNames": [
            {
              "language": "ko",
              "name": "오일러 피 함수",
              "short": "오일러 피 함수"
            },
            {
              "language": "en",
              "name": "euler totient function",
              "short": "euler phi function"
            },
            {
              "language": "ja",
              "name": "euler totient function",
              "short": "euler phi function"
            }
          ],
          "aliases": [
            {
              "alias": "오일러 파이"
            },
            {
              "alias": "토션트"
            },
            {
              "alias": "eulerphi"
            },
            {
              "alias": "euler phi"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 15948,
      "titleKo": "간단한 문제",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "간단한 문제",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 154,
      "level": 19,
      "votedUserCount": 34,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.1818,
      "official": true,
      "tags": [
        {
          "key": "ad_hoc",
          "isMeta": false,
          "bojTagId": 109,
          "problemCount": 1254,
          "displayNames": [
            {
              "language": "ko",
              "name": "애드 혹",
              "short": "애드 혹"
            },
            {
              "language": "en",
              "name": "ad-hoc",
              "short": "ad-hoc"
            },
            {
              "language": "ja",
              "name": "アドホック",
              "short": "アドホック"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 30681,
      "titleKo": "별 포획",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "별 포획",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 29,
      "level": 19,
      "votedUserCount": 11,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.1724,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 30984,
      "titleKo": "파댕이의 케이크 만들기",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "파댕이의 케이크 만들기",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 18,
      "level": 19,
      "votedUserCount": 4,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.2222,
      "official": true,
      "tags": [
        {
          "key": "combinatorics",
          "isMeta": false,
          "bojTagId": 6,
          "problemCount": 810,
          "displayNames": [
            {
              "language": "ko",
              "name": "조합론",
              "short": "조합론"
            },
            {
              "language": "en",
              "name": "combinatorics",
              "short": "combinatorics"
            },
            {
              "language": "ja",
              "name": "組み合わせ",
              "short": "組み合わせ"
            }
          ],
          "aliases": [
            {
              "alias": "combination"
            },
            {
              "alias": "permutation"
            },
            {
              "alias": "probability"
            },
            {
              "alias": "확률"
            },
            {
              "alias": "순열"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1017,
      "titleKo": "소수 쌍",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "소수 쌍",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 2076,
      "level": 18,
      "votedUserCount": 191,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.8372,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "primality_test",
          "isMeta": false,
          "bojTagId": 9,
          "problemCount": 303,
          "displayNames": [
            {
              "language": "ko",
              "name": "소수 판정",
              "short": "소수 판정"
            },
            {
              "language": "en",
              "name": "primality test",
              "short": "primality test"
            },
            {
              "language": "ja",
              "name": "素数性テスト",
              "short": "素数性テスト"
            }
          ],
          "aliases": [
            {
              "alias": "소수"
            },
            {
              "alias": "소수판별"
            },
            {
              "alias": "소수판정"
            },
            {
              "alias": "prime"
            }
          ]
        },
        {
          "key": "sieve",
          "isMeta": false,
          "bojTagId": 67,
          "problemCount": 190,
          "displayNames": [
            {
              "language": "ko",
              "name": "에라토스테네스의 체",
              "short": "에라토스테네스의 체"
            },
            {
              "language": "en",
              "name": "sieve of eratosthenes",
              "short": "eratosthenes"
            },
            {
              "language": "ja",
              "name": "エラトステネスの篩",
              "short": "エラトステネス"
            }
          ],
          "aliases": [
            {
              "alias": "sieve"
            },
            {
              "alias": "에라체"
            },
            {
              "alias": "소수"
            },
            {
              "alias": "prime"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1310,
      "titleKo": "달리기 코스",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "달리기 코스",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 363,
      "level": 18,
      "votedUserCount": 63,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.9504,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1533,
      "titleKo": "길의 개수",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "길의 개수",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 840,
      "level": 18,
      "votedUserCount": 123,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.65,
      "official": true,
      "tags": [
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1867,
      "titleKo": "돌멩이 제거",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "돌멩이 제거",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Asteroids",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1323,
      "level": 18,
      "votedUserCount": 97,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.737,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2049,
      "titleKo": "가장 먼 두 점",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "가장 먼 두 점",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 350,
      "level": 18,
      "votedUserCount": 71,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.5571,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2105,
      "titleKo": "꼬리달린 박성원숭이",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "꼬리달린 박성원숭이",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Monkeys",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 42,
      "level": 18,
      "votedUserCount": 11,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.4048,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        },
        {
          "key": "smaller_to_larger",
          "isMeta": false,
          "bojTagId": 169,
          "problemCount": 116,
          "displayNames": [
            {
              "language": "ko",
              "name": "작은 집합에서 큰 집합으로 합치는 테크닉",
              "short": "작은 집합에서 큰 집합으로 합치는 테크닉"
            },
            {
              "language": "en",
              "name": "smaller to larger technique",
              "short": "smaller to larger"
            },
            {
              "language": "ja",
              "name": "smaller to larger technique",
              "short": "smaller to larger"
            }
          ],
          "aliases": [
            {
              "alias": "merge heuristics"
            },
            {
              "alias": "sack"
            },
            {
              "alias": "small to large"
            },
            {
              "alias": "작은거"
            },
            {
              "alias": "큰거"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2385,
      "titleKo": "Secret Sharing",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Secret Sharing",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 163,
      "level": 18,
      "votedUserCount": 49,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 5.3681,
      "official": true,
      "tags": [
        {
          "key": "greedy",
          "isMeta": false,
          "bojTagId": 33,
          "problemCount": 2266,
          "displayNames": [
            {
              "language": "ko",
              "name": "그리디 알고리즘",
              "short": "그리디 알고리즘"
            },
            {
              "language": "en",
              "name": "greedy",
              "short": "greedy"
            },
            {
              "language": "ja",
              "name": "貪欲法",
              "short": "貪欲法"
            }
          ],
          "aliases": [
            {
              "alias": "탐욕법"
            }
          ]
        },
        {
          "key": "sorting",
          "isMeta": false,
          "bojTagId": 97,
          "problemCount": 1673,
          "displayNames": [
            {
              "language": "ko",
              "name": "정렬",
              "short": "정렬"
            },
            {
              "language": "en",
              "name": "sorting",
              "short": "sorting"
            },
            {
              "language": "ja",
              "name": "ソート",
              "short": "ソート"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "string",
          "isMeta": false,
          "bojTagId": 158,
          "problemCount": 2217,
          "displayNames": [
            {
              "language": "ko",
              "name": "문자열",
              "short": "문자열"
            },
            {
              "language": "en",
              "name": "string",
              "short": "string"
            },
            {
              "language": "ja",
              "name": "文字列",
              "short": "文字列"
            }
          ],
          "aliases": [
            {
              "alias": "스트링"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2843,
      "titleKo": "마블",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "마블",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "KUGLICE",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 251,
      "level": 18,
      "votedUserCount": 31,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.2749,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 3830,
      "titleKo": "교수님은 기다리지 않는다",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "교수님은 기다리지 않는다",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Never Wait for Weights",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1656,
      "level": 18,
      "votedUserCount": 162,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.7579,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 4225,
      "titleKo": "쓰레기 슈트",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "쓰레기 슈트",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Trash Removal",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 514,
      "level": 18,
      "votedUserCount": 87,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.716,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 9240,
      "titleKo": "로버트 후드",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "로버트 후드",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Robert Hood",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1328,
      "level": 18,
      "votedUserCount": 125,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.8215,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 11377,
      "titleKo": "열혈강호 3",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "열혈강호 3",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 2053,
      "level": 18,
      "votedUserCount": 130,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.4822,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "flow",
          "isMeta": false,
          "bojTagId": 45,
          "problemCount": 309,
          "displayNames": [
            {
              "language": "ko",
              "name": "최대 유량",
              "short": "최대 유량"
            },
            {
              "language": "en",
              "name": "maximum flow",
              "short": "flow"
            },
            {
              "language": "ja",
              "name": "最大フロー",
              "short": "flow"
            }
          ],
          "aliases": [
            {
              "alias": "dinic"
            },
            {
              "alias": "dinitz"
            },
            {
              "alias": "ford"
            },
            {
              "alias": "fulkerson"
            },
            {
              "alias": "fordfulkerson"
            },
            {
              "alias": "디닉"
            },
            {
              "alias": "디니츠"
            },
            {
              "alias": "포드풀커슨"
            },
            {
              "alias": "플로우"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 15028,
      "titleKo": "Breaking Biscuits",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Breaking Biscuits",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 116,
      "level": 18,
      "votedUserCount": 31,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.6293,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 15420,
      "titleKo": "Blowing Candles",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Blowing Candles",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 90,
      "level": 18,
      "votedUserCount": 25,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.4111,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "rotating_calipers",
          "isMeta": false,
          "bojTagId": 64,
          "problemCount": 29,
          "displayNames": [
            {
              "language": "ko",
              "name": "회전하는 캘리퍼스",
              "short": "회전하는 캘리퍼스"
            },
            {
              "language": "en",
              "name": "rotating calipers",
              "short": "rotating calipers"
            },
            {
              "language": "ja",
              "name": "rotating calipers",
              "short": "rotating calipers"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 17469,
      "titleKo": "트리의 색깔과 쿼리",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "트리의 색깔과 쿼리",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 361,
      "level": 18,
      "votedUserCount": 75,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.5235,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        },
        {
          "key": "smaller_to_larger",
          "isMeta": false,
          "bojTagId": 169,
          "problemCount": 116,
          "displayNames": [
            {
              "language": "ko",
              "name": "작은 집합에서 큰 집합으로 합치는 테크닉",
              "short": "작은 집합에서 큰 집합으로 합치는 테크닉"
            },
            {
              "language": "en",
              "name": "smaller to larger technique",
              "short": "smaller to larger"
            },
            {
              "language": "ja",
              "name": "smaller to larger technique",
              "short": "smaller to larger"
            }
          ],
          "aliases": [
            {
              "alias": "merge heuristics"
            },
            {
              "alias": "sack"
            },
            {
              "alias": "small to large"
            },
            {
              "alias": "작은거"
            },
            {
              "alias": "큰거"
            }
          ]
        },
        {
          "key": "trees",
          "isMeta": false,
          "bojTagId": 120,
          "problemCount": 1284,
          "displayNames": [
            {
              "language": "ko",
              "name": "트리",
              "short": "트리"
            },
            {
              "language": "en",
              "name": "tree",
              "short": "tree"
            },
            {
              "language": "ja",
              "name": "木",
              "short": "木"
            }
          ],
          "aliases": [
            {
              "alias": "trees"
            }
          ]
        },
        {
          "key": "tree_set",
          "isMeta": false,
          "bojTagId": 74,
          "problemCount": 461,
          "displayNames": [
            {
              "language": "ko",
              "name": "트리를 사용한 집합과 맵",
              "short": "트리를 사용한 집합과 맵"
            },
            {
              "language": "en",
              "name": "set / map by trees",
              "short": "treeset"
            },
            {
              "language": "ja",
              "name": "木によるセット・マップ",
              "short": "treeset"
            }
          ],
          "aliases": [
            {
              "alias": "집합"
            },
            {
              "alias": "맵"
            },
            {
              "alias": "셋"
            },
            {
              "alias": "딕셔너리"
            },
            {
              "alias": "dictionary"
            },
            {
              "alias": "map"
            },
            {
              "alias": "set"
            },
            {
              "alias": "bbst"
            },
            {
              "alias": "트리"
            },
            {
              "alias": "tree"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 27300,
      "titleKo": "섯섯시싀 저주",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "섯섯시싀 저주",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 14,
      "level": 18,
      "votedUserCount": 4,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.7857,
      "official": true,
      "tags": [
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 27318,
      "titleKo": "세상에서 가장 달달한 디저트 만들기",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "세상에서 가장 달달한 디저트 만들기",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 43,
      "level": 18,
      "votedUserCount": 19,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.4884,
      "official": true,
      "tags": [
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 27947,
      "titleKo": "가지 밭 게임",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "가지 밭 게임",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 44,
      "level": 18,
      "votedUserCount": 14,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.3636,
      "official": true,
      "tags": [
        {
          "key": "binary_search",
          "isMeta": false,
          "bojTagId": 12,
          "problemCount": 1109,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 탐색",
              "short": "이분 탐색"
            },
            {
              "language": "en",
              "name": "binary search",
              "short": "binary search"
            },
            {
              "language": "ja",
              "name": "二分探索",
              "short": "二分探索"
            }
          ],
          "aliases": [
            {
              "alias": "이분탐색"
            },
            {
              "alias": "이진탐색"
            }
          ]
        },
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "parametric_search",
          "isMeta": false,
          "bojTagId": 170,
          "problemCount": 322,
          "displayNames": [
            {
              "language": "ko",
              "name": "매개 변수 탐색",
              "short": "매개 변수 탐색"
            },
            {
              "language": "en",
              "name": "parametric search",
              "short": "parametric search"
            },
            {
              "language": "ja",
              "name": "parametric search",
              "short": "parametric search"
            }
          ],
          "aliases": [
            {
              "alias": "파라메트릭"
            }
          ]
        },
        {
          "key": "polygon_area",
          "isMeta": false,
          "bojTagId": 3,
          "problemCount": 59,
          "displayNames": [
            {
              "language": "ko",
              "name": "다각형의 넓이",
              "short": "다각형의 넓이"
            },
            {
              "language": "en",
              "name": "area of a polygon",
              "short": "area of a polygon"
            },
            {
              "language": "ja",
              "name": "多角形の面積",
              "short": "多角形の面積"
            }
          ],
          "aliases": [
            {
              "alias": "넓이"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1298,
      "titleKo": "노트북의 주인을 찾아서",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "노트북의 주인을 찾아서",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1841,
      "level": 17,
      "votedUserCount": 122,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.0462,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1422,
      "titleKo": "숫자의 신",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "숫자의 신",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1278,
      "level": 17,
      "votedUserCount": 167,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.6401,
      "official": true,
      "tags": [
        {
          "key": "greedy",
          "isMeta": false,
          "bojTagId": 33,
          "problemCount": 2266,
          "displayNames": [
            {
              "language": "ko",
              "name": "그리디 알고리즘",
              "short": "그리디 알고리즘"
            },
            {
              "language": "en",
              "name": "greedy",
              "short": "greedy"
            },
            {
              "language": "ja",
              "name": "貪欲法",
              "short": "貪欲法"
            }
          ],
          "aliases": [
            {
              "alias": "탐욕법"
            }
          ]
        },
        {
          "key": "sorting",
          "isMeta": false,
          "bojTagId": 97,
          "problemCount": 1673,
          "displayNames": [
            {
              "language": "ko",
              "name": "정렬",
              "short": "정렬"
            },
            {
              "language": "en",
              "name": "sorting",
              "short": "sorting"
            },
            {
              "language": "ja",
              "name": "ソート",
              "short": "ソート"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1604,
      "titleKo": "정사각형 자르기",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "정사각형 자르기",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 89,
      "level": 17,
      "votedUserCount": 21,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.2697,
      "official": true,
      "tags": [
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "line_intersection",
          "isMeta": false,
          "bojTagId": 42,
          "problemCount": 107,
          "displayNames": [
            {
              "language": "ko",
              "name": "선분 교차 판정",
              "short": "선분 교차 판정"
            },
            {
              "language": "en",
              "name": "line segment intersection check",
              "short": "line segment intersection check"
            },
            {
              "language": "ja",
              "name": "直線の交点",
              "short": "直線の交点"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2188,
      "titleKo": "축사 배정",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "축사 배정",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 3640,
      "level": 17,
      "votedUserCount": 181,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.0865,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2191,
      "titleKo": "들쥐의 탈출",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "들쥐의 탈출",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 513,
      "level": 17,
      "votedUserCount": 42,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.9454,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2244,
      "titleKo": "민코프스키 합",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "민코프스키 합",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Polygon",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 190,
      "level": 17,
      "votedUserCount": 30,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.4842,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2254,
      "titleKo": "감옥 건설",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "감옥 건설",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Captives of War",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 540,
      "level": 17,
      "votedUserCount": 59,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.1333,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "point_in_convex_polygon",
          "isMeta": false,
          "bojTagId": 56,
          "problemCount": 34,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 다각형 내부의 점 판정",
              "short": "볼록 다각형 내부의 점 판정"
            },
            {
              "language": "en",
              "name": "point in convex polygon check",
              "short": "point in convex polygon check"
            },
            {
              "language": "ja",
              "name": "凸多角形の点包含判定",
              "short": "凸多角形の点包含判定"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 3145,
      "titleKo": "지리지도",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "지리지도",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "KARTA",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 24,
      "level": 17,
      "votedUserCount": 4,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.9167,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 3679,
      "titleKo": "단순 다각형",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "단순 다각형",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Simple Polygon",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 750,
      "level": 17,
      "votedUserCount": 106,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.948,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "sorting",
          "isMeta": false,
          "bojTagId": 97,
          "problemCount": 1673,
          "displayNames": [
            {
              "language": "ko",
              "name": "정렬",
              "short": "정렬"
            },
            {
              "language": "en",
              "name": "sorting",
              "short": "sorting"
            },
            {
              "language": "ja",
              "name": "ソート",
              "short": "ソート"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 4196,
      "titleKo": "도미노",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "도미노",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Dominos",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1987,
      "level": 17,
      "votedUserCount": 150,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.3337,
      "official": true,
      "tags": [
        {
          "key": "dag",
          "isMeta": false,
          "bojTagId": 213,
          "problemCount": 167,
          "displayNames": [
            {
              "language": "ko",
              "name": "방향 비순환 그래프",
              "short": "dag"
            },
            {
              "language": "en",
              "name": "directed acyclic graph",
              "short": "dag"
            },
            {
              "language": "ja",
              "name": "有向非巡回グラフ",
              "short": "有向非巡回グラフ"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "scc",
          "isMeta": false,
          "bojTagId": 76,
          "problemCount": 146,
          "displayNames": [
            {
              "language": "ko",
              "name": "강한 연결 요소",
              "short": "강한 연결 요소"
            },
            {
              "language": "en",
              "name": "strongly connected component",
              "short": "scc"
            },
            {
              "language": "ja",
              "name": "強連結",
              "short": "強連結"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "topological_sorting",
          "isMeta": false,
          "bojTagId": 78,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "위상 정렬",
              "short": "위상 정렬"
            },
            {
              "language": "en",
              "name": "topological sorting",
              "short": "topological sorting"
            },
            {
              "language": "ja",
              "name": "トポロジカルソート",
              "short": "トポロジカルソート"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 4376,
      "titleKo": "Gopher II",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Gopher II",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 105,
      "level": 17,
      "votedUserCount": 23,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.3524,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 7420,
      "titleKo": "맹독 방벽",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "맹독 방벽",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Wall",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 771,
      "level": 17,
      "votedUserCount": 111,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.4397,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 9737,
      "titleKo": "Area Between Outer Hull and Inner Hull",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Area Between Outer Hull and Inner Hull",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 13,
      "level": 17,
      "votedUserCount": 7,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.4615,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "polygon_area",
          "isMeta": false,
          "bojTagId": 3,
          "problemCount": 59,
          "displayNames": [
            {
              "language": "ko",
              "name": "다각형의 넓이",
              "short": "다각형의 넓이"
            },
            {
              "language": "en",
              "name": "area of a polygon",
              "short": "area of a polygon"
            },
            {
              "language": "ja",
              "name": "多角形の面積",
              "short": "多角形の面積"
            }
          ],
          "aliases": [
            {
              "alias": "넓이"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 10255,
      "titleKo": "교차점",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "교차점",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Intersections",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 478,
      "level": 17,
      "votedUserCount": 42,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.4163,
      "official": true,
      "tags": [
        {
          "key": "case_work",
          "isMeta": false,
          "bojTagId": 137,
          "problemCount": 755,
          "displayNames": [
            {
              "language": "ko",
              "name": "많은 조건 분기",
              "short": "많은 조건 분기"
            },
            {
              "language": "en",
              "name": "case work",
              "short": "case work"
            },
            {
              "language": "ja",
              "name": "ケースワーク",
              "short": "ケースワーク"
            }
          ],
          "aliases": [
            {
              "alias": "케이스"
            },
            {
              "alias": "케이스워크"
            },
            {
              "alias": "케이스 워크"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "line_intersection",
          "isMeta": false,
          "bojTagId": 42,
          "problemCount": 107,
          "displayNames": [
            {
              "language": "ko",
              "name": "선분 교차 판정",
              "short": "선분 교차 판정"
            },
            {
              "language": "en",
              "name": "line segment intersection check",
              "short": "line segment intersection check"
            },
            {
              "language": "ja",
              "name": "直線の交点",
              "short": "直線の交点"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 11375,
      "titleKo": "열혈강호",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "열혈강호",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 3588,
      "level": 17,
      "votedUserCount": 175,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.3606,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 11376,
      "titleKo": "열혈강호 2",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "열혈강호 2",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 2475,
      "level": 17,
      "votedUserCount": 132,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.2089,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 11439,
      "titleKo": "이항 계수 5",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "이항 계수 5",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 381,
      "level": 17,
      "votedUserCount": 44,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.1706,
      "official": true,
      "tags": [
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "primality_test",
          "isMeta": false,
          "bojTagId": 9,
          "problemCount": 303,
          "displayNames": [
            {
              "language": "ko",
              "name": "소수 판정",
              "short": "소수 판정"
            },
            {
              "language": "en",
              "name": "primality test",
              "short": "primality test"
            },
            {
              "language": "ja",
              "name": "素数性テスト",
              "short": "素数性テスト"
            }
          ],
          "aliases": [
            {
              "alias": "소수"
            },
            {
              "alias": "소수판별"
            },
            {
              "alias": "소수판정"
            },
            {
              "alias": "prime"
            }
          ]
        },
        {
          "key": "sieve",
          "isMeta": false,
          "bojTagId": 67,
          "problemCount": 190,
          "displayNames": [
            {
              "language": "ko",
              "name": "에라토스테네스의 체",
              "short": "에라토스테네스의 체"
            },
            {
              "language": "en",
              "name": "sieve of eratosthenes",
              "short": "eratosthenes"
            },
            {
              "language": "ja",
              "name": "エラトステネスの篩",
              "short": "エラトステネス"
            }
          ],
          "aliases": [
            {
              "alias": "sieve"
            },
            {
              "alias": "에라체"
            },
            {
              "alias": "소수"
            },
            {
              "alias": "prime"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 12920,
      "titleKo": "평범한 배낭 2",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "평범한 배낭 2",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1110,
      "level": 17,
      "votedUserCount": 107,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.1414,
      "official": true,
      "tags": [
        {
          "key": "dp",
          "isMeta": false,
          "bojTagId": 25,
          "problemCount": 3705,
          "displayNames": [
            {
              "language": "ko",
              "name": "다이나믹 프로그래밍",
              "short": "다이나믹 프로그래밍"
            },
            {
              "language": "en",
              "name": "dynamic programming",
              "short": "dp"
            },
            {
              "language": "ja",
              "name": "動的計画法",
              "short": "dp"
            }
          ],
          "aliases": [
            {
              "alias": "동적계획법"
            },
            {
              "alias": "동적 계획법"
            },
            {
              "alias": "다이나믹프로그래밍"
            }
          ]
        },
        {
          "key": "knapsack",
          "isMeta": false,
          "bojTagId": 148,
          "problemCount": 217,
          "displayNames": [
            {
              "language": "ko",
              "name": "배낭 문제",
              "short": "배낭 문제"
            },
            {
              "language": "en",
              "name": "knapsack",
              "short": "knapsack"
            },
            {
              "language": "ja",
              "name": "ナップサック問題",
              "short": "ナップサック"
            }
          ],
          "aliases": [
            {
              "alias": "냅색"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13306,
      "titleKo": "트리",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "트리",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1433,
      "level": 17,
      "votedUserCount": 142,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.6923,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13354,
      "titleKo": "Artwork",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Artwork",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 52,
      "level": 17,
      "votedUserCount": 9,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.2885,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 15586,
      "titleKo": "MooTube (Gold)",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "MooTube (Gold)",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 317,
      "level": 17,
      "votedUserCount": 46,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.6246,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 15745,
      "titleKo": "Snow Boots",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Snow Boots",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 147,
      "level": 17,
      "votedUserCount": 19,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.9048,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        },
        {
          "key": "tree_set",
          "isMeta": false,
          "bojTagId": 74,
          "problemCount": 461,
          "displayNames": [
            {
              "language": "ko",
              "name": "트리를 사용한 집합과 맵",
              "short": "트리를 사용한 집합과 맵"
            },
            {
              "language": "en",
              "name": "set / map by trees",
              "short": "treeset"
            },
            {
              "language": "ja",
              "name": "木によるセット・マップ",
              "short": "treeset"
            }
          ],
          "aliases": [
            {
              "alias": "집합"
            },
            {
              "alias": "맵"
            },
            {
              "alias": "셋"
            },
            {
              "alias": "딕셔너리"
            },
            {
              "alias": "dictionary"
            },
            {
              "alias": "map"
            },
            {
              "alias": "set"
            },
            {
              "alias": "bbst"
            },
            {
              "alias": "트리"
            },
            {
              "alias": "tree"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 17403,
      "titleKo": "가장 높고 넓은 성",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "가장 높고 넓은 성",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 238,
      "level": 17,
      "votedUserCount": 42,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.3655,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 17990,
      "titleKo": "Killing Chaos",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Killing Chaos",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 7,
      "level": 17,
      "votedUserCount": 4,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.2857,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 20149,
      "titleKo": "선분 교차 3",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "선분 교차 3",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1260,
      "level": 17,
      "votedUserCount": 194,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.6571,
      "official": true,
      "tags": [
        {
          "key": "case_work",
          "isMeta": false,
          "bojTagId": 137,
          "problemCount": 755,
          "displayNames": [
            {
              "language": "ko",
              "name": "많은 조건 분기",
              "short": "많은 조건 분기"
            },
            {
              "language": "en",
              "name": "case work",
              "short": "case work"
            },
            {
              "language": "ja",
              "name": "ケースワーク",
              "short": "ケースワーク"
            }
          ],
          "aliases": [
            {
              "alias": "케이스"
            },
            {
              "alias": "케이스워크"
            },
            {
              "alias": "케이스 워크"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "line_intersection",
          "isMeta": false,
          "bojTagId": 42,
          "problemCount": 107,
          "displayNames": [
            {
              "language": "ko",
              "name": "선분 교차 판정",
              "short": "선분 교차 판정"
            },
            {
              "language": "en",
              "name": "line segment intersection check",
              "short": "line segment intersection check"
            },
            {
              "language": "ja",
              "name": "直線の交点",
              "short": "直線の交点"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 20156,
      "titleKo": "기왕 이렇게 된 거 암기왕이 되어라",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "기왕 이렇게 된 거 암기왕이 되어라",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 93,
      "level": 17,
      "votedUserCount": 27,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.5269,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 25172,
      "titleKo": "꼼꼼한 쿠기의 졸업여행",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "꼼꼼한 쿠기의 졸업여행",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 101,
      "level": 17,
      "votedUserCount": 22,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.4554,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 27894,
      "titleKo": "특별한 숙제 순서 바꾸기",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "특별한 숙제 순서 바꾸기",
          "isOriginal": true
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Exceptional Homework Jargon",
          "isOriginal": false
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 66,
      "level": 17,
      "votedUserCount": 26,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.5303,
      "official": true,
      "tags": [
        {
          "key": "ad_hoc",
          "isMeta": false,
          "bojTagId": 109,
          "problemCount": 1254,
          "displayNames": [
            {
              "language": "ko",
              "name": "애드 혹",
              "short": "애드 혹"
            },
            {
              "language": "en",
              "name": "ad-hoc",
              "short": "ad-hoc"
            },
            {
              "language": "ja",
              "name": "アドホック",
              "short": "アドホック"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 30921,
      "titleKo": "🧩 N-Queen (Area)",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "🧩 N-Queen (Area)",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 33,
      "level": 17,
      "votedUserCount": 9,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.9697,
      "official": true,
      "tags": [
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "polygon_area",
          "isMeta": false,
          "bojTagId": 3,
          "problemCount": 59,
          "displayNames": [
            {
              "language": "ko",
              "name": "다각형의 넓이",
              "short": "다각형의 넓이"
            },
            {
              "language": "en",
              "name": "area of a polygon",
              "short": "area of a polygon"
            },
            {
              "language": "ja",
              "name": "多角形の面積",
              "short": "多角形の面積"
            }
          ],
          "aliases": [
            {
              "alias": "넓이"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 30976,
      "titleKo": "사랑의 큐피드",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "사랑의 큐피드",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 31,
      "level": 17,
      "votedUserCount": 13,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.7419,
      "official": true,
      "tags": [
        {
          "key": "bipartite_matching",
          "isMeta": false,
          "bojTagId": 13,
          "problemCount": 175,
          "displayNames": [
            {
              "language": "ko",
              "name": "이분 매칭",
              "short": "이분 매칭"
            },
            {
              "language": "en",
              "name": "bipartite matching",
              "short": "bipartite matching"
            },
            {
              "language": "ja",
              "name": "2部マッチング",
              "short": "2部マッチング"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 30983,
      "titleKo": "충성! 파란댕댕이",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "충성! 파란댕댕이",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 35,
      "level": 17,
      "votedUserCount": 9,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.8571,
      "official": true,
      "tags": [
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1086,
      "titleKo": "박성원",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "박성원",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1911,
      "level": 16,
      "votedUserCount": 38,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": true,
      "averageTries": 3.719,
      "official": true,
      "tags": [
        {
          "key": "bitmask",
          "isMeta": false,
          "bojTagId": 14,
          "problemCount": 653,
          "displayNames": [
            {
              "language": "ko",
              "name": "비트마스킹",
              "short": "비트마스킹"
            },
            {
              "language": "en",
              "name": "bitmask",
              "short": "bitmask"
            },
            {
              "language": "ja",
              "name": "ビット表現",
              "short": "ビット表現"
            }
          ],
          "aliases": [
            {
              "alias": "비트필드"
            }
          ]
        },
        {
          "key": "dp",
          "isMeta": false,
          "bojTagId": 25,
          "problemCount": 3705,
          "displayNames": [
            {
              "language": "ko",
              "name": "다이나믹 프로그래밍",
              "short": "다이나믹 프로그래밍"
            },
            {
              "language": "en",
              "name": "dynamic programming",
              "short": "dp"
            },
            {
              "language": "ja",
              "name": "動的計画法",
              "short": "dp"
            }
          ],
          "aliases": [
            {
              "alias": "동적계획법"
            },
            {
              "alias": "동적 계획법"
            },
            {
              "alias": "다이나믹프로그래밍"
            }
          ]
        },
        {
          "key": "dp_bitfield",
          "isMeta": false,
          "bojTagId": 87,
          "problemCount": 277,
          "displayNames": [
            {
              "language": "ko",
              "name": "비트필드를 이용한 다이나믹 프로그래밍",
              "short": "비트필드를 이용한 다이나믹 프로그래밍"
            },
            {
              "language": "en",
              "name": "dynamic programming using bitfield",
              "short": "bitfield dp"
            },
            {
              "language": "ja",
              "name": "ビットを使用した動的計画法",
              "short": "ビットdp"
            }
          ],
          "aliases": [
            {
              "alias": "동적계획법"
            },
            {
              "alias": "비트마스크"
            },
            {
              "alias": "비트dp"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1506,
      "titleKo": "경찰서",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "경찰서",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 615,
      "level": 16,
      "votedUserCount": 79,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.7171,
      "official": true,
      "tags": [
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "scc",
          "isMeta": false,
          "bojTagId": 76,
          "problemCount": 146,
          "displayNames": [
            {
              "language": "ko",
              "name": "강한 연결 요소",
              "short": "강한 연결 요소"
            },
            {
              "language": "en",
              "name": "strongly connected component",
              "short": "scc"
            },
            {
              "language": "ja",
              "name": "強連結",
              "short": "強連結"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1708,
      "titleKo": "볼록 껍질",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "볼록 껍질",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 3825,
      "level": 16,
      "votedUserCount": 243,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.8539,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 1725,
      "titleKo": "히스토그램",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Largest Rectangle in a Histogram",
          "isOriginal": true
        },
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "히스토그램",
          "isOriginal": false
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 6498,
      "level": 16,
      "votedUserCount": 312,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.5132,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "divide_and_conquer",
          "isMeta": false,
          "bojTagId": 24,
          "problemCount": 395,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복",
              "short": "분할 정복"
            },
            {
              "language": "en",
              "name": "divide and conquer",
              "short": "d&c"
            },
            {
              "language": "ja",
              "name": "分割統治法",
              "short": "分割統治法"
            }
          ],
          "aliases": [
            {
              "alias": "dnc"
            }
          ]
        },
        {
          "key": "segtree",
          "isMeta": false,
          "bojTagId": 65,
          "problemCount": 1193,
          "displayNames": [
            {
              "language": "ko",
              "name": "세그먼트 트리",
              "short": "세그먼트 트리"
            },
            {
              "language": "en",
              "name": "segment tree",
              "short": "segtree"
            },
            {
              "language": "ja",
              "name": "セグメント木",
              "short": "セグ木"
            }
          ],
          "aliases": [
            {
              "alias": "구간트리"
            },
            {
              "alias": "세그트리"
            },
            {
              "alias": "fenwick"
            },
            {
              "alias": "펜윅"
            }
          ]
        },
        {
          "key": "stack",
          "isMeta": false,
          "bojTagId": 71,
          "problemCount": 341,
          "displayNames": [
            {
              "language": "ko",
              "name": "스택",
              "short": "스택"
            },
            {
              "language": "en",
              "name": "stack",
              "short": "stack"
            },
            {
              "language": "ja",
              "name": "スタック",
              "short": "スタック"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2150,
      "titleKo": "Strongly Connected Component",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "Strongly Connected Component",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 4019,
      "level": 16,
      "votedUserCount": 245,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.1886,
      "official": true,
      "tags": [
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "scc",
          "isMeta": false,
          "bojTagId": 76,
          "problemCount": 146,
          "displayNames": [
            {
              "language": "ko",
              "name": "강한 연결 요소",
              "short": "강한 연결 요소"
            },
            {
              "language": "en",
              "name": "strongly connected component",
              "short": "scc"
            },
            {
              "language": "ja",
              "name": "強連結",
              "short": "強連結"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2162,
      "titleKo": "선분 그룹",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "선분 그룹",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 2967,
      "level": 16,
      "votedUserCount": 226,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.5659,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "line_intersection",
          "isMeta": false,
          "bojTagId": 42,
          "problemCount": 107,
          "displayNames": [
            {
              "language": "ko",
              "name": "선분 교차 판정",
              "short": "선분 교차 판정"
            },
            {
              "language": "en",
              "name": "line segment intersection check",
              "short": "line segment intersection check"
            },
            {
              "language": "ja",
              "name": "直線の交点",
              "short": "直線の交点"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 2699,
      "titleKo": "격자점 컨벡스헐",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "격자점 컨벡스헐",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Convex Hull of Lattice Points",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 540,
      "level": 16,
      "votedUserCount": 45,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.787,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 3197,
      "titleKo": "백조의 호수",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "백조의 호수",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "labudovi",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 4004,
      "level": 16,
      "votedUserCount": 221,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 5.1928,
      "official": true,
      "tags": [
        {
          "key": "bfs",
          "isMeta": false,
          "bojTagId": 126,
          "problemCount": 925,
          "displayNames": [
            {
              "language": "ko",
              "name": "너비 우선 탐색",
              "short": "너비 우선 탐색"
            },
            {
              "language": "en",
              "name": "breadth-first search",
              "short": "bfs"
            },
            {
              "language": "ja",
              "name": "幅優先検索",
              "short": "bfs"
            }
          ],
          "aliases": [
            {
              "alias": "breadthfirst"
            },
            {
              "alias": "breadth first"
            }
          ]
        },
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "graph_traversal",
          "isMeta": false,
          "bojTagId": 11,
          "problemCount": 1864,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 탐색",
              "short": "그래프 탐색"
            },
            {
              "language": "en",
              "name": "graph traversal",
              "short": "traversal"
            },
            {
              "language": "ja",
              "name": "グラフの横断",
              "short": "横断"
            }
          ],
          "aliases": [
            {
              "alias": "bfs"
            },
            {
              "alias": "dfs"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 3734,
      "titleKo": "RSA 인수 분해",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "RSA 인수 분해",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "RSA Factorization",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 28,
      "level": 16,
      "votedUserCount": 10,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 8.6429,
      "official": true,
      "tags": [
        {
          "key": "ad_hoc",
          "isMeta": false,
          "bojTagId": 109,
          "problemCount": 1254,
          "displayNames": [
            {
              "language": "ko",
              "name": "애드 혹",
              "short": "애드 혹"
            },
            {
              "language": "en",
              "name": "ad-hoc",
              "short": "ad-hoc"
            },
            {
              "language": "ja",
              "name": "アドホック",
              "short": "アドホック"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "arbitrary_precision",
          "isMeta": false,
          "bojTagId": 117,
          "problemCount": 239,
          "displayNames": [
            {
              "language": "ko",
              "name": "임의 정밀도 / 큰 수 연산",
              "short": "임의 정밀도 / 큰 수 연산"
            },
            {
              "language": "en",
              "name": "arbitrary precision / big integers",
              "short": "arbitrary precision / big integers"
            },
            {
              "language": "ja",
              "name": "高精度または大きな数の演算",
              "short": "高精度または大きな数の演算"
            }
          ],
          "aliases": [
            {
              "alias": "빅인티저"
            },
            {
              "alias": "빅데시멀"
            },
            {
              "alias": "biginteger"
            },
            {
              "alias": "bigdecimal"
            }
          ]
        },
        {
          "key": "bruteforcing",
          "isMeta": false,
          "bojTagId": 125,
          "problemCount": 1997,
          "displayNames": [
            {
              "language": "ko",
              "name": "브루트포스 알고리즘",
              "short": "브루트포스 알고리즘"
            },
            {
              "language": "en",
              "name": "bruteforcing",
              "short": "bruteforce"
            },
            {
              "language": "ja",
              "name": "全探索",
              "short": "全探索"
            }
          ],
          "aliases": [
            {
              "alias": "완전탐색"
            },
            {
              "alias": "완전 탐색"
            },
            {
              "alias": "브루트포스"
            },
            {
              "alias": "bruteforce"
            },
            {
              "alias": "brute force"
            },
            {
              "alias": "완탐"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 3955,
      "titleKo": "캔디 분배",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "캔디 분배",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Candy Distribution",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1529,
      "level": 16,
      "votedUserCount": 94,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.5749,
      "official": true,
      "tags": [
        {
          "key": "extended_euclidean",
          "isMeta": false,
          "bojTagId": 27,
          "problemCount": 32,
          "displayNames": [
            {
              "language": "ko",
              "name": "확장 유클리드 호제법",
              "short": "확장 유클리드 호제법"
            },
            {
              "language": "en",
              "name": "extended euclidean algorithm",
              "short": "extended euclidean algorithm"
            },
            {
              "language": "ja",
              "name": "拡張ユークリッドの互除法",
              "short": "拡張ユークリッド"
            }
          ],
          "aliases": [
            {
              "alias": "확장유클리드알고리즘"
            },
            {
              "alias": "egcd"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 4181,
      "titleKo": "Convex Hull",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Convex Hull",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 502,
      "level": 16,
      "votedUserCount": 77,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.8127,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "sorting",
          "isMeta": false,
          "bojTagId": 97,
          "problemCount": 1673,
          "displayNames": [
            {
              "language": "ko",
              "name": "정렬",
              "short": "정렬"
            },
            {
              "language": "en",
              "name": "sorting",
              "short": "sorting"
            },
            {
              "language": "ja",
              "name": "ソート",
              "short": "ソート"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 4924,
      "titleKo": "정수론 싫어",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "정수론 싫어",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Johnny Hates Number Theory",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 57,
      "level": 16,
      "votedUserCount": 16,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.3509,
      "official": true,
      "tags": [
        {
          "key": "dp",
          "isMeta": false,
          "bojTagId": 25,
          "problemCount": 3705,
          "displayNames": [
            {
              "language": "ko",
              "name": "다이나믹 프로그래밍",
              "short": "다이나믹 프로그래밍"
            },
            {
              "language": "en",
              "name": "dynamic programming",
              "short": "dp"
            },
            {
              "language": "ja",
              "name": "動的計画法",
              "short": "dp"
            }
          ],
          "aliases": [
            {
              "alias": "동적계획법"
            },
            {
              "alias": "동적 계획법"
            },
            {
              "alias": "다이나믹프로그래밍"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "prefix_sum",
          "isMeta": false,
          "bojTagId": 139,
          "problemCount": 855,
          "displayNames": [
            {
              "language": "ko",
              "name": "누적 합",
              "short": "누적 합"
            },
            {
              "language": "en",
              "name": "prefix sum",
              "short": "prefix sum"
            },
            {
              "language": "ja",
              "name": "累積和",
              "short": "累積和"
            }
          ],
          "aliases": [
            {
              "alias": "구간합"
            },
            {
              "alias": "부분합"
            },
            {
              "alias": "rangesum"
            }
          ]
        },
        {
          "key": "primality_test",
          "isMeta": false,
          "bojTagId": 9,
          "problemCount": 303,
          "displayNames": [
            {
              "language": "ko",
              "name": "소수 판정",
              "short": "소수 판정"
            },
            {
              "language": "en",
              "name": "primality test",
              "short": "primality test"
            },
            {
              "language": "ja",
              "name": "素数性テスト",
              "short": "素数性テスト"
            }
          ],
          "aliases": [
            {
              "alias": "소수"
            },
            {
              "alias": "소수판별"
            },
            {
              "alias": "소수판정"
            },
            {
              "alias": "prime"
            }
          ]
        },
        {
          "key": "sieve",
          "isMeta": false,
          "bojTagId": 67,
          "problemCount": 190,
          "displayNames": [
            {
              "language": "ko",
              "name": "에라토스테네스의 체",
              "short": "에라토스테네스의 체"
            },
            {
              "language": "en",
              "name": "sieve of eratosthenes",
              "short": "eratosthenes"
            },
            {
              "language": "ja",
              "name": "エラトステネスの篩",
              "short": "エラトステネス"
            }
          ],
          "aliases": [
            {
              "alias": "sieve"
            },
            {
              "alias": "에라체"
            },
            {
              "alias": "소수"
            },
            {
              "alias": "prime"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 6194,
      "titleKo": "Building the Moat",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Building the Moat",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 186,
      "level": 16,
      "votedUserCount": 28,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.5699,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 6646,
      "titleKo": "Wooden Fence",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Wooden Fence",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 6,
      "level": 16,
      "votedUserCount": 4,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.1667,
      "official": true,
      "tags": [
        {
          "key": "bruteforcing",
          "isMeta": false,
          "bojTagId": 125,
          "problemCount": 1997,
          "displayNames": [
            {
              "language": "ko",
              "name": "브루트포스 알고리즘",
              "short": "브루트포스 알고리즘"
            },
            {
              "language": "en",
              "name": "bruteforcing",
              "short": "bruteforce"
            },
            {
              "language": "ja",
              "name": "全探索",
              "short": "全探索"
            }
          ],
          "aliases": [
            {
              "alias": "완전탐색"
            },
            {
              "alias": "완전 탐색"
            },
            {
              "alias": "브루트포스"
            },
            {
              "alias": "bruteforce"
            },
            {
              "alias": "brute force"
            },
            {
              "alias": "완탐"
            }
          ]
        },
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 6850,
      "titleKo": "Cows",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Cows",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 528,
      "level": 16,
      "votedUserCount": 53,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.5379,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "polygon_area",
          "isMeta": false,
          "bojTagId": 3,
          "problemCount": 59,
          "displayNames": [
            {
              "language": "ko",
              "name": "다각형의 넓이",
              "short": "다각형의 넓이"
            },
            {
              "language": "en",
              "name": "area of a polygon",
              "short": "area of a polygon"
            },
            {
              "language": "ja",
              "name": "多角形の面積",
              "short": "多角形の面積"
            }
          ],
          "aliases": [
            {
              "alias": "넓이"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 6962,
      "titleKo": "Maple Roundup",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Maple Roundup",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 73,
      "level": 16,
      "votedUserCount": 15,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.7123,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 9487,
      "titleKo": "Cut the Cake",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Cut the Cake",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 16,
      "level": 16,
      "votedUserCount": 1,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.375,
      "official": true,
      "tags": [
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "line_intersection",
          "isMeta": false,
          "bojTagId": 42,
          "problemCount": 107,
          "displayNames": [
            {
              "language": "ko",
              "name": "선분 교차 판정",
              "short": "선분 교차 판정"
            },
            {
              "language": "en",
              "name": "line segment intersection check",
              "short": "line segment intersection check"
            },
            {
              "language": "ja",
              "name": "直線の交点",
              "short": "直線の交点"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 10903,
      "titleKo": "Wall construction",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "Wall construction",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 247,
      "level": 16,
      "votedUserCount": 52,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.6721,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 11402,
      "titleKo": "이항 계수 4",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "이항 계수 4",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1427,
      "level": 16,
      "votedUserCount": 133,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.3924,
      "official": true,
      "tags": [
        {
          "key": "combinatorics",
          "isMeta": false,
          "bojTagId": 6,
          "problemCount": 810,
          "displayNames": [
            {
              "language": "ko",
              "name": "조합론",
              "short": "조합론"
            },
            {
              "language": "en",
              "name": "combinatorics",
              "short": "combinatorics"
            },
            {
              "language": "ja",
              "name": "組み合わせ",
              "short": "組み合わせ"
            }
          ],
          "aliases": [
            {
              "alias": "combination"
            },
            {
              "alias": "permutation"
            },
            {
              "alias": "probability"
            },
            {
              "alias": "확률"
            },
            {
              "alias": "순열"
            }
          ]
        },
        {
          "key": "dp",
          "isMeta": false,
          "bojTagId": 25,
          "problemCount": 3705,
          "displayNames": [
            {
              "language": "ko",
              "name": "다이나믹 프로그래밍",
              "short": "다이나믹 프로그래밍"
            },
            {
              "language": "en",
              "name": "dynamic programming",
              "short": "dp"
            },
            {
              "language": "ja",
              "name": "動的計画法",
              "short": "dp"
            }
          ],
          "aliases": [
            {
              "alias": "동적계획법"
            },
            {
              "alias": "동적 계획법"
            },
            {
              "alias": "다이나믹프로그래밍"
            }
          ]
        },
        {
          "key": "lucas",
          "isMeta": false,
          "bojTagId": 113,
          "problemCount": 13,
          "displayNames": [
            {
              "language": "ko",
              "name": "뤼카 정리",
              "short": "뤼카 정리"
            },
            {
              "language": "en",
              "name": "lucas theorem",
              "short": "lucas thm"
            },
            {
              "language": "ja",
              "name": "lucas theorem",
              "short": "lucas thm"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 11440,
      "titleKo": "피보나치 수의 제곱의 합",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "피보나치 수의 제곱의 합",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 785,
      "level": 16,
      "votedUserCount": 98,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.6688,
      "official": true,
      "tags": [
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 12012,
      "titleKo": "Closing the Farm (Gold)",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Closing the Farm (Gold)",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 237,
      "level": 16,
      "votedUserCount": 42,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.5232,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 12985,
      "titleKo": "비밀 회선",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "비밀 회선",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "MooFest",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 36,
      "level": 16,
      "votedUserCount": 13,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.1667,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "segtree",
          "isMeta": false,
          "bojTagId": 65,
          "problemCount": 1193,
          "displayNames": [
            {
              "language": "ko",
              "name": "세그먼트 트리",
              "short": "세그먼트 트리"
            },
            {
              "language": "en",
              "name": "segment tree",
              "short": "segtree"
            },
            {
              "language": "ja",
              "name": "セグメント木",
              "short": "セグ木"
            }
          ],
          "aliases": [
            {
              "alias": "구간트리"
            },
            {
              "alias": "세그트리"
            },
            {
              "alias": "fenwick"
            },
            {
              "alias": "펜윅"
            }
          ]
        },
        {
          "key": "sorting",
          "isMeta": false,
          "bojTagId": 97,
          "problemCount": 1673,
          "displayNames": [
            {
              "language": "ko",
              "name": "정렬",
              "short": "정렬"
            },
            {
              "language": "en",
              "name": "sorting",
              "short": "sorting"
            },
            {
              "language": "ja",
              "name": "ソート",
              "short": "ソート"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13072,
      "titleKo": "Fence",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Fence",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 26,
      "level": 16,
      "votedUserCount": 7,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.1154,
      "official": true,
      "tags": [
        {
          "key": "convex_hull",
          "isMeta": false,
          "bojTagId": 20,
          "problemCount": 161,
          "displayNames": [
            {
              "language": "ko",
              "name": "볼록 껍질",
              "short": "볼록 껍질"
            },
            {
              "language": "en",
              "name": "convex hull",
              "short": "convex hull"
            },
            {
              "language": "ja",
              "name": "凸包",
              "short": "凸包"
            }
          ],
          "aliases": [
            {
              "alias": "컨벡스헐"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "greedy",
          "isMeta": false,
          "bojTagId": 33,
          "problemCount": 2266,
          "displayNames": [
            {
              "language": "ko",
              "name": "그리디 알고리즘",
              "short": "그리디 알고리즘"
            },
            {
              "language": "en",
              "name": "greedy",
              "short": "greedy"
            },
            {
              "language": "ja",
              "name": "貪欲法",
              "short": "貪欲法"
            }
          ],
          "aliases": [
            {
              "alias": "탐욕법"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13141,
      "titleKo": "Ignition",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "Ignition",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 698,
      "level": 16,
      "votedUserCount": 108,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.9011,
      "official": true,
      "tags": [
        {
          "key": "bruteforcing",
          "isMeta": false,
          "bojTagId": 125,
          "problemCount": 1997,
          "displayNames": [
            {
              "language": "ko",
              "name": "브루트포스 알고리즘",
              "short": "브루트포스 알고리즘"
            },
            {
              "language": "en",
              "name": "bruteforcing",
              "short": "bruteforce"
            },
            {
              "language": "ja",
              "name": "全探索",
              "short": "全探索"
            }
          ],
          "aliases": [
            {
              "alias": "완전탐색"
            },
            {
              "alias": "완전 탐색"
            },
            {
              "alias": "브루트포스"
            },
            {
              "alias": "bruteforce"
            },
            {
              "alias": "brute force"
            },
            {
              "alias": "완탐"
            }
          ]
        },
        {
          "key": "floyd_warshall",
          "isMeta": false,
          "bojTagId": 31,
          "problemCount": 160,
          "displayNames": [
            {
              "language": "ko",
              "name": "플로이드–워셜",
              "short": "플로이드–워셜"
            },
            {
              "language": "en",
              "name": "floyd–warshall",
              "short": "floyd–warshall"
            },
            {
              "language": "ja",
              "name": "ワーシャル–フロイド法",
              "short": "ワーシャル–フロイド法"
            }
          ],
          "aliases": [
            {
              "alias": "플로이드"
            },
            {
              "alias": "플로이드와셜"
            },
            {
              "alias": "플로이드와샬"
            }
          ]
        },
        {
          "key": "graphs",
          "isMeta": false,
          "bojTagId": 7,
          "problemCount": 3399,
          "displayNames": [
            {
              "language": "ko",
              "name": "그래프 이론",
              "short": "그래프 이론"
            },
            {
              "language": "en",
              "name": "graph theory",
              "short": "graph"
            },
            {
              "language": "ja",
              "name": "グラフ理論",
              "short": "グラフ"
            }
          ],
          "aliases": [
            {
              "alias": "그래프이론"
            }
          ]
        },
        {
          "key": "shortest_path",
          "isMeta": false,
          "bojTagId": 215,
          "problemCount": 709,
          "displayNames": [
            {
              "language": "ko",
              "name": "최단 경로",
              "short": "최단 경로"
            },
            {
              "language": "en",
              "name": "shortest path",
              "short": "shortest path"
            },
            {
              "language": "ja",
              "name": "最短経路",
              "short": "最短経路"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13618,
      "titleKo": "RSA",
      "titles": [
        {
          "language": "pt",
          "languageDisplayName": "pt",
          "title": "RSA",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 52,
      "level": 16,
      "votedUserCount": 11,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 1.4808,
      "official": true,
      "tags": [
        {
          "key": "euler_phi",
          "isMeta": false,
          "bojTagId": 151,
          "problemCount": 37,
          "displayNames": [
            {
              "language": "ko",
              "name": "오일러 피 함수",
              "short": "오일러 피 함수"
            },
            {
              "language": "en",
              "name": "euler totient function",
              "short": "euler phi function"
            },
            {
              "language": "ja",
              "name": "euler totient function",
              "short": "euler phi function"
            }
          ],
          "aliases": [
            {
              "alias": "오일러 파이"
            },
            {
              "alias": "토션트"
            },
            {
              "alias": "eulerphi"
            },
            {
              "alias": "euler phi"
            }
          ]
        },
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "extended_euclidean",
          "isMeta": false,
          "bojTagId": 27,
          "problemCount": 32,
          "displayNames": [
            {
              "language": "ko",
              "name": "확장 유클리드 호제법",
              "short": "확장 유클리드 호제법"
            },
            {
              "language": "en",
              "name": "extended euclidean algorithm",
              "short": "extended euclidean algorithm"
            },
            {
              "language": "ja",
              "name": "拡張ユークリッドの互除法",
              "short": "拡張ユークリッド"
            }
          ],
          "aliases": [
            {
              "alias": "확장유클리드알고리즘"
            },
            {
              "alias": "egcd"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "modular_multiplicative_inverse",
          "isMeta": false,
          "bojTagId": 164,
          "problemCount": 86,
          "displayNames": [
            {
              "language": "ko",
              "name": "모듈로 곱셈 역원",
              "short": "모듈로 곱셈 역원"
            },
            {
              "language": "en",
              "name": "modular multiplicative inverse",
              "short": "modular multiplicative inverse"
            },
            {
              "language": "ja",
              "name": "モジュラ逆数",
              "short": "モジュラ逆数"
            }
          ],
          "aliases": [
            {
              "alias": "modinv"
            }
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13646,
      "titleKo": "Estrela",
      "titles": [
        {
          "language": "pt",
          "languageDisplayName": "pt",
          "title": "Estrela",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 81,
      "level": 16,
      "votedUserCount": 25,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.1111,
      "official": true,
      "tags": [
        {
          "key": "euler_phi",
          "isMeta": false,
          "bojTagId": 151,
          "problemCount": 37,
          "displayNames": [
            {
              "language": "ko",
              "name": "오일러 피 함수",
              "short": "오일러 피 함수"
            },
            {
              "language": "en",
              "name": "euler totient function",
              "short": "euler phi function"
            },
            {
              "language": "ja",
              "name": "euler totient function",
              "short": "euler phi function"
            }
          ],
          "aliases": [
            {
              "alias": "오일러 파이"
            },
            {
              "alias": "토션트"
            },
            {
              "alias": "eulerphi"
            },
            {
              "alias": "euler phi"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13976,
      "titleKo": "타일 채우기 2",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "타일 채우기 2",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 700,
      "level": 16,
      "votedUserCount": 103,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.1443,
      "official": true,
      "tags": [
        {
          "key": "dp",
          "isMeta": false,
          "bojTagId": 25,
          "problemCount": 3705,
          "displayNames": [
            {
              "language": "ko",
              "name": "다이나믹 프로그래밍",
              "short": "다이나믹 프로그래밍"
            },
            {
              "language": "en",
              "name": "dynamic programming",
              "short": "dp"
            },
            {
              "language": "ja",
              "name": "動的計画法",
              "short": "dp"
            }
          ],
          "aliases": [
            {
              "alias": "동적계획법"
            },
            {
              "alias": "동적 계획법"
            },
            {
              "alias": "다이나믹프로그래밍"
            }
          ]
        },
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 13977,
      "titleKo": "이항 계수와 쿼리",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "이항 계수와 쿼리",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1523,
      "level": 16,
      "votedUserCount": 153,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.1648,
      "official": true,
      "tags": [
        {
          "key": "combinatorics",
          "isMeta": false,
          "bojTagId": 6,
          "problemCount": 810,
          "displayNames": [
            {
              "language": "ko",
              "name": "조합론",
              "short": "조합론"
            },
            {
              "language": "en",
              "name": "combinatorics",
              "short": "combinatorics"
            },
            {
              "language": "ja",
              "name": "組み合わせ",
              "short": "組み合わせ"
            }
          ],
          "aliases": [
            {
              "alias": "combination"
            },
            {
              "alias": "permutation"
            },
            {
              "alias": "probability"
            },
            {
              "alias": "확률"
            },
            {
              "alias": "순열"
            }
          ]
        },
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "flt",
          "isMeta": false,
          "bojTagId": 29,
          "problemCount": 54,
          "displayNames": [
            {
              "language": "ko",
              "name": "페르마의 소정리",
              "short": "페르마의 소정리"
            },
            {
              "language": "en",
              "name": "fermat's little theorem",
              "short": "fermat's little thm"
            },
            {
              "language": "ja",
              "name": "フェルマーの小定理",
              "short": "フェルマー"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "modular_multiplicative_inverse",
          "isMeta": false,
          "bojTagId": 164,
          "problemCount": 86,
          "displayNames": [
            {
              "language": "ko",
              "name": "모듈로 곱셈 역원",
              "short": "모듈로 곱셈 역원"
            },
            {
              "language": "en",
              "name": "modular multiplicative inverse",
              "short": "modular multiplicative inverse"
            },
            {
              "language": "ja",
              "name": "モジュラ逆数",
              "short": "モジュラ逆数"
            }
          ],
          "aliases": [
            {
              "alias": "modinv"
            }
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 14258,
      "titleKo": "XOR 그룹",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "XOR 그룹",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 56,
      "level": 16,
      "votedUserCount": 14,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.6429,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 16496,
      "titleKo": "큰 수 만들기",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "큰 수 만들기",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 1758,
      "level": 16,
      "votedUserCount": 238,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.3868,
      "official": true,
      "tags": [
        {
          "key": "greedy",
          "isMeta": false,
          "bojTagId": 33,
          "problemCount": 2266,
          "displayNames": [
            {
              "language": "ko",
              "name": "그리디 알고리즘",
              "short": "그리디 알고리즘"
            },
            {
              "language": "en",
              "name": "greedy",
              "short": "greedy"
            },
            {
              "language": "ja",
              "name": "貪欲法",
              "short": "貪欲法"
            }
          ],
          "aliases": [
            {
              "alias": "탐욕법"
            }
          ]
        },
        {
          "key": "sorting",
          "isMeta": false,
          "bojTagId": 97,
          "problemCount": 1673,
          "displayNames": [
            {
              "language": "ko",
              "name": "정렬",
              "short": "정렬"
            },
            {
              "language": "en",
              "name": "sorting",
              "short": "sorting"
            },
            {
              "language": "ja",
              "name": "ソート",
              "short": "ソート"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 17398,
      "titleKo": "통신망 분할",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "통신망 분할",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 673,
      "level": 16,
      "votedUserCount": 62,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.9064,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 17401,
      "titleKo": "일하는 세포",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "일하는 세포",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 501,
      "level": 16,
      "votedUserCount": 92,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.0559,
      "official": true,
      "tags": [
        {
          "key": "exponentiation_by_squaring",
          "isMeta": false,
          "bojTagId": 39,
          "problemCount": 264,
          "displayNames": [
            {
              "language": "ko",
              "name": "분할 정복을 이용한 거듭제곱",
              "short": "분할 정복을 이용한 거듭제곱"
            },
            {
              "language": "en",
              "name": "exponentiation by squaring",
              "short": "exponentiation by squaring"
            },
            {
              "language": "ja",
              "name": "二乗法によるべき乗",
              "short": "二乗法によるべき乗"
            }
          ],
          "aliases": [
            {
              "alias": "거듭제곱"
            },
            {
              "alias": "제곱"
            },
            {
              "alias": "power"
            },
            {
              "alias": "square"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 19577,
      "titleKo": "수학은 재밌어",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "수학은 재밌어",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 399,
      "level": 16,
      "votedUserCount": 83,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.9273,
      "official": true,
      "tags": [
        {
          "key": "euler_phi",
          "isMeta": false,
          "bojTagId": 151,
          "problemCount": 37,
          "displayNames": [
            {
              "language": "ko",
              "name": "오일러 피 함수",
              "short": "오일러 피 함수"
            },
            {
              "language": "en",
              "name": "euler totient function",
              "short": "euler phi function"
            },
            {
              "language": "ja",
              "name": "euler totient function",
              "short": "euler phi function"
            }
          ],
          "aliases": [
            {
              "alias": "오일러 파이"
            },
            {
              "alias": "토션트"
            },
            {
              "alias": "eulerphi"
            },
            {
              "alias": "euler phi"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 19670,
      "titleKo": "Pilot",
      "titles": [
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "Pilot",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 34,
      "level": 16,
      "votedUserCount": 7,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.5588,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 26087,
      "titleKo": "피보나치와 마지막 수열과 쿼리",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "피보나치와 마지막 수열과 쿼리",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 86,
      "level": 16,
      "votedUserCount": 35,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 2.814,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "disjoint_set",
          "isMeta": false,
          "bojTagId": 81,
          "problemCount": 425,
          "displayNames": [
            {
              "language": "ko",
              "name": "분리 집합",
              "short": "분리 집합"
            },
            {
              "language": "en",
              "name": "disjoint set",
              "short": "dsu"
            },
            {
              "language": "ja",
              "name": "素集合データ構造",
              "short": "素集合データ構造"
            }
          ],
          "aliases": [
            {
              "alias": "union"
            },
            {
              "alias": "find"
            },
            {
              "alias": "유니온"
            },
            {
              "alias": "파인드"
            },
            {
              "alias": "dsu"
            }
          ]
        },
        {
          "key": "offline_queries",
          "isMeta": false,
          "bojTagId": 123,
          "problemCount": 232,
          "displayNames": [
            {
              "language": "ko",
              "name": "오프라인 쿼리",
              "short": "오프라인 쿼리"
            },
            {
              "language": "en",
              "name": "offline queries",
              "short": "offline query"
            },
            {
              "language": "ja",
              "name": "offline queries",
              "short": "offline query"
            }
          ],
          "aliases": [
            {
              "alias": "offlinequery"
            }
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 27718,
      "titleKo": "선분 교차 EX",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "선분 교차 EX",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 87,
      "level": 16,
      "votedUserCount": 21,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 4.5977,
      "official": true,
      "tags": [
        {
          "key": "case_work",
          "isMeta": false,
          "bojTagId": 137,
          "problemCount": 755,
          "displayNames": [
            {
              "language": "ko",
              "name": "많은 조건 분기",
              "short": "많은 조건 분기"
            },
            {
              "language": "en",
              "name": "case work",
              "short": "case work"
            },
            {
              "language": "ja",
              "name": "ケースワーク",
              "short": "ケースワーク"
            }
          ],
          "aliases": [
            {
              "alias": "케이스"
            },
            {
              "alias": "케이스워크"
            },
            {
              "alias": "케이스 워크"
            }
          ]
        },
        {
          "key": "geometry",
          "isMeta": false,
          "bojTagId": 100,
          "problemCount": 1370,
          "displayNames": [
            {
              "language": "ko",
              "name": "기하학",
              "short": "기하학"
            },
            {
              "language": "en",
              "name": "geometry",
              "short": "geom"
            },
            {
              "language": "ja",
              "name": "幾何学",
              "short": "幾何"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "line_intersection",
          "isMeta": false,
          "bojTagId": 42,
          "problemCount": 107,
          "displayNames": [
            {
              "language": "ko",
              "name": "선분 교차 판정",
              "short": "선분 교차 판정"
            },
            {
              "language": "en",
              "name": "line segment intersection check",
              "short": "line segment intersection check"
            },
            {
              "language": "ja",
              "name": "直線の交点",
              "short": "直線の交点"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    },
    {
      "problemId": 27944,
      "titleKo": "가지 이모지",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "가지 이모지",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 69,
      "level": 16,
      "votedUserCount": 28,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 3.3623,
      "official": true,
      "tags": [
        {
          "key": "data_structures",
          "isMeta": false,
          "bojTagId": 175,
          "problemCount": 3466,
          "displayNames": [
            {
              "language": "ko",
              "name": "자료 구조",
              "short": "자료 구조"
            },
            {
              "language": "en",
              "name": "data structures",
              "short": "ds"
            },
            {
              "language": "ja",
              "name": "データ構造",
              "short": "ds"
            }
          ],
          "aliases": [
            {
              "alias": "자료구조"
            },
            {
              "alias": "자구"
            }
          ]
        },
        {
          "key": "hash_set",
          "isMeta": false,
          "bojTagId": 136,
          "problemCount": 559,
          "displayNames": [
            {
              "language": "ko",
              "name": "해시를 사용한 집합과 맵",
              "short": "해시를 사용한 집합과 맵"
            },
            {
              "language": "en",
              "name": "set / map by hashing",
              "short": "hashset"
            },
            {
              "language": "ja",
              "name": "ハッシュ化によるセット・マップ",
              "short": "hashset"
            }
          ],
          "aliases": [
            {
              "alias": "집합"
            },
            {
              "alias": "맵"
            },
            {
              "alias": "셋"
            },
            {
              "alias": "딕셔너리"
            },
            {
              "alias": "dictionary"
            },
            {
              "alias": "map"
            },
            {
              "alias": "set"
            },
            {
              "alias": "해싱"
            },
            {
              "alias": "hashing"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [
            
          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [
            
          ]
        }
      ],
      "metadata": {
        
      }
    }
  ]
}
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userTop100(handle);
        expect(actual, isA<List<Problem>>());
        for (final problem in actual) {
          expect(problem, isA<Problem>());
          expect(problem.tags, isA<List<Tag>>());
        }
      });
    });

    group('userProblemStats', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userProblemStats(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/user/problem_stats',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns List<ProblemStat> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
[
  {
    "level": 0,
    "solved": 15,
    "tried": 2,
    "partial": 0,
    "total": 6277
  },
  {
    "level": 1,
    "solved": 152,
    "tried": 0,
    "partial": 0,
    "total": 154
  },
  {
    "level": 2,
    "solved": 300,
    "tried": 0,
    "partial": 0,
    "total": 307
  },
  {
    "level": 3,
    "solved": 670,
    "tried": 2,
    "partial": 0,
    "total": 721
  },
  {
    "level": 4,
    "solved": 506,
    "tried": 4,
    "partial": 0,
    "total": 945
  },
  {
    "level": 5,
    "solved": 227,
    "tried": 7,
    "partial": 0,
    "total": 799
  },
  {
    "level": 6,
    "solved": 214,
    "tried": 4,
    "partial": 0,
    "total": 828
  },
  {
    "level": 7,
    "solved": 162,
    "tried": 6,
    "partial": 0,
    "total": 891
  },
  {
    "level": 8,
    "solved": 127,
    "tried": 4,
    "partial": 0,
    "total": 955
  },
  {
    "level": 9,
    "solved": 122,
    "tried": 5,
    "partial": 0,
    "total": 942
  },
  {
    "level": 10,
    "solved": 109,
    "tried": 4,
    "partial": 0,
    "total": 1055
  },
  {
    "level": 11,
    "solved": 109,
    "tried": 10,
    "partial": 0,
    "total": 1126
  },
  {
    "level": 12,
    "solved": 96,
    "tried": 12,
    "partial": 1,
    "total": 1523
  },
  {
    "level": 13,
    "solved": 64,
    "tried": 16,
    "partial": 1,
    "total": 1428
  },
  {
    "level": 14,
    "solved": 47,
    "tried": 6,
    "partial": 1,
    "total": 1235
  },
  {
    "level": 15,
    "solved": 63,
    "tried": 10,
    "partial": 0,
    "total": 1093
  },
  {
    "level": 16,
    "solved": 152,
    "tried": 13,
    "partial": 1,
    "total": 1269
  },
  {
    "level": 17,
    "solved": 107,
    "tried": 10,
    "partial": 0,
    "total": 1217
  },
  {
    "level": 18,
    "solved": 80,
    "tried": 11,
    "partial": 1,
    "total": 1296
  },
  {
    "level": 19,
    "solved": 29,
    "tried": 2,
    "partial": 0,
    "total": 1210
  },
  {
    "level": 20,
    "solved": 14,
    "tried": 4,
    "partial": 0,
    "total": 960
  },
  {
    "level": 21,
    "solved": 15,
    "tried": 3,
    "partial": 0,
    "total": 1010
  },
  {
    "level": 22,
    "solved": 5,
    "tried": 3,
    "partial": 0,
    "total": 942
  },
  {
    "level": 23,
    "solved": 1,
    "tried": 0,
    "partial": 0,
    "total": 642
  },
  {
    "level": 24,
    "solved": 2,
    "tried": 1,
    "partial": 0,
    "total": 487
  },
  {
    "level": 25,
    "solved": 1,
    "tried": 0,
    "partial": 0,
    "total": 376
  },
  {
    "level": 26,
    "solved": 1,
    "tried": 0,
    "partial": 0,
    "total": 301
  },
  {
    "level": 27,
    "solved": 0,
    "tried": 1,
    "partial": 0,
    "total": 156
  },
  {
    "level": 28,
    "solved": 0,
    "tried": 0,
    "partial": 0,
    "total": 100
  },
  {
    "level": 29,
    "solved": 0,
    "tried": 0,
    "partial": 0,
    "total": 37
  },
  {
    "level": 30,
    "solved": 0,
    "tried": 0,
    "partial": 0,
    "total": 28
  }
]
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userProblemStats(handle);
        expect(actual, isA<List<ProblemStat>>());
        for (final stat in actual) {
          expect(stat, isA<ProblemStat>());
        }
      });
    });

    group('userTagRatings', () {
      const handle = 'w8385';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.userTagRatings(handle);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/user/tag_ratings',
              {'handle': handle},
            ),
          ),
        ).called(1);
      });

      test('returns List<TagRating> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
[
  {
    "tag": {
      "key": "ad_hoc",
      "isMeta": false,
      "bojTagId": 109,
      "problemCount": 1254,
      "displayNames": [
        {
          "language": "ko",
          "name": "애드 혹",
          "short": "애드 혹"
        },
        {
          "language": "en",
          "name": "ad-hoc",
          "short": "ad-hoc"
        },
        {
          "language": "ja",
          "name": "アドホック",
          "short": "アドホック"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 70,
    "rating": 1011,
    "ratingByProblemsSum": 910,
    "ratingByClass": 0,
    "ratingBySolvedCount": 101,
    "ratingProblemsCutoff": 5
  },
  {
    "tag": {
      "key": "arithmetic",
      "isMeta": false,
      "bojTagId": 121,
      "problemCount": 1035,
      "displayNames": [
        {
          "language": "ko",
          "name": "사칙연산",
          "short": "사칙연산"
        },
        {
          "language": "en",
          "name": "arithmetic",
          "short": "arithmetic"
        },
        {
          "language": "ja",
          "name": "算数",
          "short": "算数"
        }
      ],
      "aliases": [
        {
          "alias": "덧셈"
        },
        {
          "alias": "뺄셈"
        },
        {
          "alias": "곱셈"
        },
        {
          "alias": "나눗셈"
        },
        {
          "alias": "더하기"
        },
        {
          "alias": "빼기"
        },
        {
          "alias": "곱하기"
        },
        {
          "alias": "나누기"
        }
      ]
    },
    "solvedCount": 641,
    "rating": 690,
    "ratingByProblemsSum": 490,
    "ratingByClass": 0,
    "ratingBySolvedCount": 200,
    "ratingProblemsCutoff": 4
  },
  {
    "tag": {
      "key": "bfs",
      "isMeta": false,
      "bojTagId": 126,
      "problemCount": 925,
      "displayNames": [
        {
          "language": "ko",
          "name": "너비 우선 탐색",
          "short": "너비 우선 탐색"
        },
        {
          "language": "en",
          "name": "breadth-first search",
          "short": "bfs"
        },
        {
          "language": "ja",
          "name": "幅優先検索",
          "short": "bfs"
        }
      ],
      "aliases": [
        {
          "alias": "breadthfirst"
        },
        {
          "alias": "breadth first"
        }
      ]
    },
    "solvedCount": 51,
    "rating": 1138,
    "ratingByProblemsSum": 1058,
    "ratingByClass": 0,
    "ratingBySolvedCount": 80,
    "ratingProblemsCutoff": 9
  },
  {
    "tag": {
      "key": "binary_search",
      "isMeta": false,
      "bojTagId": 12,
      "problemCount": 1109,
      "displayNames": [
        {
          "language": "ko",
          "name": "이분 탐색",
          "short": "이분 탐색"
        },
        {
          "language": "en",
          "name": "binary search",
          "short": "binary search"
        },
        {
          "language": "ja",
          "name": "二分探索",
          "short": "二分探索"
        }
      ],
      "aliases": [
        {
          "alias": "이분탐색"
        },
        {
          "alias": "이진탐색"
        }
      ]
    },
    "solvedCount": 19,
    "rating": 421,
    "ratingByProblemsSum": 386,
    "ratingByClass": 0,
    "ratingBySolvedCount": 35,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "bitmask",
      "isMeta": false,
      "bojTagId": 14,
      "problemCount": 653,
      "displayNames": [
        {
          "language": "ko",
          "name": "비트마스킹",
          "short": "비트마스킹"
        },
        {
          "language": "en",
          "name": "bitmask",
          "short": "bitmask"
        },
        {
          "language": "ja",
          "name": "ビット表現",
          "short": "ビット表現"
        }
      ],
      "aliases": [
        {
          "alias": "비트필드"
        }
      ]
    },
    "solvedCount": 18,
    "rating": 369,
    "ratingByProblemsSum": 336,
    "ratingByClass": 0,
    "ratingBySolvedCount": 33,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "bruteforcing",
      "isMeta": false,
      "bojTagId": 125,
      "problemCount": 1997,
      "displayNames": [
        {
          "language": "ko",
          "name": "브루트포스 알고리즘",
          "short": "브루트포스 알고리즘"
        },
        {
          "language": "en",
          "name": "bruteforcing",
          "short": "bruteforce"
        },
        {
          "language": "ja",
          "name": "全探索",
          "short": "全探索"
        }
      ],
      "aliases": [
        {
          "alias": "완전탐색"
        },
        {
          "alias": "완전 탐색"
        },
        {
          "alias": "브루트포스"
        },
        {
          "alias": "bruteforce"
        },
        {
          "alias": "brute force"
        },
        {
          "alias": "완탐"
        }
      ]
    },
    "solvedCount": 265,
    "rating": 1308,
    "ratingByProblemsSum": 1122,
    "ratingByClass": 0,
    "ratingBySolvedCount": 186,
    "ratingProblemsCutoff": 9
  },
  {
    "tag": {
      "key": "case_work",
      "isMeta": false,
      "bojTagId": 137,
      "problemCount": 755,
      "displayNames": [
        {
          "language": "ko",
          "name": "많은 조건 분기",
          "short": "많은 조건 분기"
        },
        {
          "language": "en",
          "name": "case work",
          "short": "case work"
        },
        {
          "language": "ja",
          "name": "ケースワーク",
          "short": "ケースワーク"
        }
      ],
      "aliases": [
        {
          "alias": "케이스"
        },
        {
          "alias": "케이스워크"
        },
        {
          "alias": "케이스 워크"
        }
      ]
    },
    "solvedCount": 46,
    "rating": 572,
    "ratingByProblemsSum": 498,
    "ratingByClass": 0,
    "ratingBySolvedCount": 74,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "combinatorics",
      "isMeta": false,
      "bojTagId": 6,
      "problemCount": 810,
      "displayNames": [
        {
          "language": "ko",
          "name": "조합론",
          "short": "조합론"
        },
        {
          "language": "en",
          "name": "combinatorics",
          "short": "combinatorics"
        },
        {
          "language": "ja",
          "name": "組み合わせ",
          "short": "組み合わせ"
        }
      ],
      "aliases": [
        {
          "alias": "combination"
        },
        {
          "alias": "permutation"
        },
        {
          "alias": "probability"
        },
        {
          "alias": "확률"
        },
        {
          "alias": "순열"
        }
      ]
    },
    "solvedCount": 48,
    "rating": 931,
    "ratingByProblemsSum": 854,
    "ratingByClass": 0,
    "ratingBySolvedCount": 77,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "constructive",
      "isMeta": false,
      "bojTagId": 128,
      "problemCount": 881,
      "displayNames": [
        {
          "language": "ko",
          "name": "해 구성하기",
          "short": "해 구성하기"
        },
        {
          "language": "en",
          "name": "constructive",
          "short": "constructive"
        },
        {
          "language": "ja",
          "name": "構成的",
          "short": "構成的"
        }
      ],
      "aliases": [
        {
          "alias": "constructive"
        },
        {
          "alias": "컨스트럭티브"
        },
        {
          "alias": "구성적"
        }
      ]
    },
    "solvedCount": 31,
    "rating": 516,
    "ratingByProblemsSum": 462,
    "ratingByClass": 0,
    "ratingBySolvedCount": 54,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "data_structures",
      "isMeta": false,
      "bojTagId": 175,
      "problemCount": 3466,
      "displayNames": [
        {
          "language": "ko",
          "name": "자료 구조",
          "short": "자료 구조"
        },
        {
          "language": "en",
          "name": "data structures",
          "short": "ds"
        },
        {
          "language": "ja",
          "name": "データ構造",
          "short": "ds"
        }
      ],
      "aliases": [
        {
          "alias": "자료구조"
        },
        {
          "alias": "자구"
        }
      ]
    },
    "solvedCount": 138,
    "rating": 1632,
    "ratingByProblemsSum": 1482,
    "ratingByClass": 0,
    "ratingBySolvedCount": 150,
    "ratingProblemsCutoff": 12
  },
  {
    "tag": {
      "key": "dfs",
      "isMeta": false,
      "bojTagId": 127,
      "problemCount": 745,
      "displayNames": [
        {
          "language": "ko",
          "name": "깊이 우선 탐색",
          "short": "깊이 우선 탐색"
        },
        {
          "language": "en",
          "name": "depth-first search",
          "short": "dfs"
        },
        {
          "language": "ja",
          "name": "深さ優先探索",
          "short": "dfs"
        }
      ],
      "aliases": [
        {
          "alias": "depth first"
        },
        {
          "alias": "depthfirst"
        }
      ]
    },
    "solvedCount": 34,
    "rating": 752,
    "ratingByProblemsSum": 694,
    "ratingByClass": 0,
    "ratingBySolvedCount": 58,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "dijkstra",
      "isMeta": false,
      "bojTagId": 22,
      "problemCount": 544,
      "displayNames": [
        {
          "language": "ko",
          "name": "데이크스트라",
          "short": "데이크스트라"
        },
        {
          "language": "en",
          "name": "dijkstra's",
          "short": "dijkstra's"
        },
        {
          "language": "ja",
          "name": "ダイクストラ法",
          "short": "ダイクストラ法"
        }
      ],
      "aliases": [
        {
          "alias": "다익"
        },
        {
          "alias": "다익스트라"
        },
        {
          "alias": "데이크스트라"
        }
      ]
    },
    "solvedCount": 7,
    "rating": 184,
    "ratingByProblemsSum": 170,
    "ratingByClass": 0,
    "ratingBySolvedCount": 14,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "dp",
      "isMeta": false,
      "bojTagId": 25,
      "problemCount": 3705,
      "displayNames": [
        {
          "language": "ko",
          "name": "다이나믹 프로그래밍",
          "short": "다이나믹 프로그래밍"
        },
        {
          "language": "en",
          "name": "dynamic programming",
          "short": "dp"
        },
        {
          "language": "ja",
          "name": "動的計画法",
          "short": "dp"
        }
      ],
      "aliases": [
        {
          "alias": "동적계획법"
        },
        {
          "alias": "동적 계획법"
        },
        {
          "alias": "다이나믹프로그래밍"
        }
      ]
    },
    "solvedCount": 119,
    "rating": 1390,
    "ratingByProblemsSum": 1250,
    "ratingByClass": 0,
    "ratingBySolvedCount": 140,
    "ratingProblemsCutoff": 10
  },
  {
    "tag": {
      "key": "geometry",
      "isMeta": false,
      "bojTagId": 100,
      "problemCount": 1370,
      "displayNames": [
        {
          "language": "ko",
          "name": "기하학",
          "short": "기하학"
        },
        {
          "language": "en",
          "name": "geometry",
          "short": "geom"
        },
        {
          "language": "ja",
          "name": "幾何学",
          "short": "幾何"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 118,
    "rating": 1731,
    "ratingByProblemsSum": 1592,
    "ratingByClass": 0,
    "ratingBySolvedCount": 139,
    "ratingProblemsCutoff": 11
  },
  {
    "tag": {
      "key": "graphs",
      "isMeta": false,
      "bojTagId": 7,
      "problemCount": 3399,
      "displayNames": [
        {
          "language": "ko",
          "name": "그래프 이론",
          "short": "그래프 이론"
        },
        {
          "language": "en",
          "name": "graph theory",
          "short": "graph"
        },
        {
          "language": "ja",
          "name": "グラフ理論",
          "short": "グラフ"
        }
      ],
      "aliases": [
        {
          "alias": "그래프이론"
        }
      ]
    },
    "solvedCount": 106,
    "rating": 1471,
    "ratingByProblemsSum": 1340,
    "ratingByClass": 0,
    "ratingBySolvedCount": 131,
    "ratingProblemsCutoff": 12
  },
  {
    "tag": {
      "key": "graph_traversal",
      "isMeta": false,
      "bojTagId": 11,
      "problemCount": 1864,
      "displayNames": [
        {
          "language": "ko",
          "name": "그래프 탐색",
          "short": "그래프 탐색"
        },
        {
          "language": "en",
          "name": "graph traversal",
          "short": "traversal"
        },
        {
          "language": "ja",
          "name": "グラフの横断",
          "short": "横断"
        }
      ],
      "aliases": [
        {
          "alias": "bfs"
        },
        {
          "alias": "dfs"
        }
      ]
    },
    "solvedCount": 75,
    "rating": 1248,
    "ratingByProblemsSum": 1142,
    "ratingByClass": 0,
    "ratingBySolvedCount": 106,
    "ratingProblemsCutoff": 10
  },
  {
    "tag": {
      "key": "greedy",
      "isMeta": false,
      "bojTagId": 33,
      "problemCount": 2266,
      "displayNames": [
        {
          "language": "ko",
          "name": "그리디 알고리즘",
          "short": "그리디 알고리즘"
        },
        {
          "language": "en",
          "name": "greedy",
          "short": "greedy"
        },
        {
          "language": "ja",
          "name": "貪欲法",
          "short": "貪欲法"
        }
      ],
      "aliases": [
        {
          "alias": "탐욕법"
        }
      ]
    },
    "solvedCount": 142,
    "rating": 1272,
    "ratingByProblemsSum": 1120,
    "ratingByClass": 0,
    "ratingBySolvedCount": 152,
    "ratingProblemsCutoff": 8
  },
  {
    "tag": {
      "key": "hash_set",
      "isMeta": false,
      "bojTagId": 136,
      "problemCount": 559,
      "displayNames": [
        {
          "language": "ko",
          "name": "해시를 사용한 집합과 맵",
          "short": "해시를 사용한 집합과 맵"
        },
        {
          "language": "en",
          "name": "set / map by hashing",
          "short": "hashset"
        },
        {
          "language": "ja",
          "name": "ハッシュ化によるセット・マップ",
          "short": "hashset"
        }
      ],
      "aliases": [
        {
          "alias": "집합"
        },
        {
          "alias": "맵"
        },
        {
          "alias": "셋"
        },
        {
          "alias": "딕셔너리"
        },
        {
          "alias": "dictionary"
        },
        {
          "alias": "map"
        },
        {
          "alias": "set"
        },
        {
          "alias": "해싱"
        },
        {
          "alias": "hashing"
        }
      ]
    },
    "solvedCount": 46,
    "rating": 828,
    "ratingByProblemsSum": 754,
    "ratingByClass": 0,
    "ratingBySolvedCount": 74,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "implementation",
      "isMeta": false,
      "bojTagId": 102,
      "problemCount": 5008,
      "displayNames": [
        {
          "language": "ko",
          "name": "구현",
          "short": "구현"
        },
        {
          "language": "en",
          "name": "implementation",
          "short": "impl"
        },
        {
          "language": "ja",
          "name": "実装",
          "short": "impl"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 1373,
    "rating": 1230,
    "ratingByProblemsSum": 1030,
    "ratingByClass": 0,
    "ratingBySolvedCount": 200,
    "ratingProblemsCutoff": 8
  },
  {
    "tag": {
      "key": "math",
      "isMeta": false,
      "bojTagId": 124,
      "problemCount": 5873,
      "displayNames": [
        {
          "language": "ko",
          "name": "수학",
          "short": "수학"
        },
        {
          "language": "en",
          "name": "mathematics",
          "short": "math"
        },
        {
          "language": "ja",
          "name": "数学",
          "short": "数学"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 1335,
    "rating": 1868,
    "ratingByProblemsSum": 1668,
    "ratingByClass": 0,
    "ratingBySolvedCount": 200,
    "ratingProblemsCutoff": 15
  },
  {
    "tag": {
      "key": "number_theory",
      "isMeta": false,
      "bojTagId": 95,
      "problemCount": 1314,
      "displayNames": [
        {
          "language": "ko",
          "name": "정수론",
          "short": "정수론"
        },
        {
          "language": "en",
          "name": "number theory",
          "short": "number theory"
        },
        {
          "language": "ja",
          "name": "整数論",
          "short": "整数論"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 263,
    "rating": 1752,
    "ratingByProblemsSum": 1566,
    "ratingByClass": 0,
    "ratingBySolvedCount": 186,
    "ratingProblemsCutoff": 13
  },
  {
    "tag": {
      "key": "prefix_sum",
      "isMeta": false,
      "bojTagId": 139,
      "problemCount": 855,
      "displayNames": [
        {
          "language": "ko",
          "name": "누적 합",
          "short": "누적 합"
        },
        {
          "language": "en",
          "name": "prefix sum",
          "short": "prefix sum"
        },
        {
          "language": "ja",
          "name": "累積和",
          "short": "累積和"
        }
      ],
      "aliases": [
        {
          "alias": "구간합"
        },
        {
          "alias": "부분합"
        },
        {
          "alias": "rangesum"
        }
      ]
    },
    "solvedCount": 33,
    "rating": 674,
    "ratingByProblemsSum": 618,
    "ratingByClass": 0,
    "ratingBySolvedCount": 56,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "segtree",
      "isMeta": false,
      "bojTagId": 65,
      "problemCount": 1193,
      "displayNames": [
        {
          "language": "ko",
          "name": "세그먼트 트리",
          "short": "세그먼트 트리"
        },
        {
          "language": "en",
          "name": "segment tree",
          "short": "segtree"
        },
        {
          "language": "ja",
          "name": "セグメント木",
          "short": "セグ木"
        }
      ],
      "aliases": [
        {
          "alias": "구간트리"
        },
        {
          "alias": "세그트리"
        },
        {
          "alias": "fenwick"
        },
        {
          "alias": "펜윅"
        }
      ]
    },
    "solvedCount": 6,
    "rating": 196,
    "ratingByProblemsSum": 184,
    "ratingByClass": 0,
    "ratingBySolvedCount": 12,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "shortest_path",
      "isMeta": false,
      "bojTagId": 215,
      "problemCount": 709,
      "displayNames": [
        {
          "language": "ko",
          "name": "최단 경로",
          "short": "최단 경로"
        },
        {
          "language": "en",
          "name": "shortest path",
          "short": "shortest path"
        },
        {
          "language": "ja",
          "name": "最短経路",
          "short": "最短経路"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 14,
    "rating": 358,
    "ratingByProblemsSum": 332,
    "ratingByClass": 0,
    "ratingBySolvedCount": 26,
    "ratingProblemsCutoff": 0
  },
  {
    "tag": {
      "key": "simulation",
      "isMeta": false,
      "bojTagId": 141,
      "problemCount": 955,
      "displayNames": [
        {
          "language": "ko",
          "name": "시뮬레이션",
          "short": "시뮬레이션"
        },
        {
          "language": "en",
          "name": "simulation",
          "short": "simulation"
        },
        {
          "language": "ja",
          "name": "シミュレーション",
          "short": "シミュレーション"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 120,
    "rating": 762,
    "ratingByProblemsSum": 622,
    "ratingByClass": 0,
    "ratingBySolvedCount": 140,
    "ratingProblemsCutoff": 4
  },
  {
    "tag": {
      "key": "sorting",
      "isMeta": false,
      "bojTagId": 97,
      "problemCount": 1673,
      "displayNames": [
        {
          "language": "ko",
          "name": "정렬",
          "short": "정렬"
        },
        {
          "language": "en",
          "name": "sorting",
          "short": "sorting"
        },
        {
          "language": "ja",
          "name": "ソート",
          "short": "ソート"
        }
      ],
      "aliases": [

      ]
    },
    "solvedCount": 161,
    "rating": 1200,
    "ratingByProblemsSum": 1040,
    "ratingByClass": 0,
    "ratingBySolvedCount": 160,
    "ratingProblemsCutoff": 7
  },
  {
    "tag": {
      "key": "string",
      "isMeta": false,
      "bojTagId": 158,
      "problemCount": 2217,
      "displayNames": [
        {
          "language": "ko",
          "name": "문자열",
          "short": "문자열"
        },
        {
          "language": "en",
          "name": "string",
          "short": "string"
        },
        {
          "language": "ja",
          "name": "文字列",
          "short": "文字列"
        }
      ],
      "aliases": [
        {
          "alias": "스트링"
        }
      ]
    },
    "solvedCount": 491,
    "rating": 1041,
    "ratingByProblemsSum": 842,
    "ratingByClass": 0,
    "ratingBySolvedCount": 199,
    "ratingProblemsCutoff": 6
  },
  {
    "tag": {
      "key": "trees",
      "isMeta": false,
      "bojTagId": 120,
      "problemCount": 1284,
      "displayNames": [
        {
          "language": "ko",
          "name": "트리",
          "short": "트리"
        },
        {
          "language": "en",
          "name": "tree",
          "short": "tree"
        },
        {
          "language": "ja",
          "name": "木",
          "short": "木"
        }
      ],
      "aliases": [
        {
          "alias": "trees"
        }
      ]
    },
    "solvedCount": 16,
    "rating": 396,
    "ratingByProblemsSum": 366,
    "ratingByClass": 0,
    "ratingBySolvedCount": 30,
    "ratingProblemsCutoff": 0
  }
]
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.userTagRatings(handle);
        expect(actual, isA<List<TagRating>>());
        for (final tagRating in actual) {
          expect(tagRating.tag, isA<Tag>());
        }
      });
    });

    group('backgroundShow', () {
      const backgroundId = 'anniversary_1st';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.backgroundShow(backgroundId);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/background/show',
              {'backgroundId': backgroundId},
            ),
          ),
        ).called(1);
      });

      test('returns Background on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
        {
  "backgroundId": "anniversary_1st",
  "backgroundImageUrl": "https://static.solved.ac/profile_bg/anniversary_1st/anniversary_1st.png",
  "fallbackBackgroundImageUrl": null,
  "backgroundVideoUrl": null,
  "unlockedUserCount": 5041,
  "displayName": "Standard Library",
  "displayDescription": "Celebrated the 1st anniversary of solved.ac",
  "conditions": "Solved previously unsolved problem at between May 31st, 2021 00:00 and June 8th, 2021 00:00 (KST)",
  "hiddenConditions": false,
  "isIllust": true,
  "backgroundCategory": "season",
  "solvedCompanyRights": true,
  "authors": [
    {
      "authorId": "havana723",
      "role": "Illustration",
      "authorUrl": null,
      "handle": "havana723",
      "twitter": null,
      "instagram": null,
      "displayName": "havana723"
    }
  ]
}
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.backgroundShow(backgroundId);
        expect(
            actual,
            isA<Background>()
                .having((b) => b.backgroundId, 'backgroundId', backgroundId));
      });
    });

    group('badgeShow', () {
      const badgeId = 'boardgame';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.badgeShow(badgeId);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/badge/show',
              {'badgeId': badgeId},
            ),
          ),
        ).called(1);
      });

      test('returns Badge on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
        {
  "badgeId": "boardgame",
  "badgeImageUrl": "https://static.solved.ac/profile_badge/boardgame.png",
  "unlockedUserCount": 584,
  "displayName": "Boardgame Cup (2023)",
  "displayDescription": "Solved 1 or more problems in Boardgame Cup",
  "badgeTier": "bronze",
  "badgeCategory": "contest",
  "solvedCompanyRights": true,
  "createdAt": "2023-01-09T07:54:03.000Z"
}
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.badgeShow(badgeId);
        expect(
            actual, isA<Badge>().having((b) => b.badgeId, 'badgeId', badgeId));
      });
    });

    group('searchSuggestions', () {
      const query = 'rsa';
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchSuggestion(query);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/search/suggestion',
              {'query': query},
            ),
          ),
        ).called(1);
      });

      test('returns SearchSuggestion on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
{
  "autocomplete": [
    {
      "caption": "rsa",
      "description": ""
    }
  ],
  "problems": [
    {
      "id": 3734,
      "title": "RSA 인수 분해",
      "level": 16,
      "solved": 28,
      "caption": "RSA 인수 분해",
      "description": "#3734",
      "href": "https://www.acmicpc.net/problem/3734"
    },
    {
      "id": 6283,
      "title": "Universal Question Answering System",
      "level": 0,
      "solved": 1,
      "caption": "Universal Question Answering System",
      "description": "#6283",
      "href": "https://www.acmicpc.net/problem/6283"
    },
    {
      "id": 6872,
      "title": "RSA Numbers",
      "level": 6,
      "solved": 33,
      "caption": "RSA Numbers",
      "description": "#6872",
      "href": "https://www.acmicpc.net/problem/6872"
    },
    {
      "id": 7656,
      "title": "만능 오라클",
      "level": 6,
      "solved": 114,
      "caption": "만능 오라클",
      "description": "#7656",
      "href": "https://www.acmicpc.net/problem/7656"
    },
    {
      "id": 9093,
      "title": "단어 뒤집기",
      "level": 5,
      "solved": 14453,
      "caption": "단어 뒤집기",
      "description": "#9093",
      "href": "https://www.acmicpc.net/problem/9093"
    }
  ],
  "problemCount": 21,
  "tags": [
    {
      "key": "graph_traversal",
      "name": "그래프 탐색",
      "problemCount": 1864,
      "caption": "tag:graph_traversal",
      "description": "1864 problems",
      "href": "/problems/tags/graph_traversal"
    }
  ],
  "tagCount": 1,
  "users": [
    {
      "handle": "rsatang5",
      "bio": "",
      "badgeId": null,
      "backgroundId": "balloon_004",
      "profileImageUrl": null,
      "solvedCount": 112,
      "voteCount": 0,
      "class": 2,
      "classDecoration": "none",
      "rivalCount": 0,
      "reverseRivalCount": 0,
      "tier": 11,
      "rating": 824,
      "ratingByProblemsSum": 699,
      "ratingByClass": 50,
      "ratingBySolvedCount": 75,
      "ratingByVoteCount": 0,
      "arenaTier": 0,
      "arenaRating": 0,
      "arenaMaxTier": 0,
      "arenaMaxRating": 0,
      "arenaCompetedRoundCount": 0,
      "maxStreak": 0,
      "coins": 0,
      "stardusts": 0,
      "joinedAt": "2021-09-17T09:32:29.000Z",
      "bannedUntil": "1970-01-01T00:00:00.000Z",
      "proUntil": "1970-01-01T00:00:00.000Z"
    }
  ],
  "userCount": 1
}
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchSuggestion(query);
        expect(actual, isA<SearchSuggestion>());
        expect(actual.problems, isA<List<ProblemSuggestion>>());
        expect(actual.tags, isA<List<TagSuggestion>>());
        expect(actual.users, isA<List<UserSuggestion>>());
      });
    });

    group('searchProblems', () {
      const query = 'rsa';
      const page = 1;
      const sort = 'id';
      const direction = 'asc';

      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchProblem(query, page, sort, direction);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/search/problem',
              {
                'query': query,
                'page': '$page',
                'sort': sort,
                'direction': direction
              },
            ),
          ),
        ).called(1);
      });

      test('returns SearchObject on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
{
  "count": 1,
  "items": [
    {
      "problemId": 3734,
      "titleKo": "RSA 인수 분해",
      "titles": [
        {
          "language": "ko",
          "languageDisplayName": "ko",
          "title": "RSA 인수 분해",
          "isOriginal": false
        },
        {
          "language": "en",
          "languageDisplayName": "en",
          "title": "RSA Factorization",
          "isOriginal": true
        }
      ],
      "isSolvable": true,
      "isPartial": false,
      "acceptedUserCount": 28,
      "level": 16,
      "votedUserCount": 10,
      "sprout": false,
      "givesNoRating": false,
      "isLevelLocked": false,
      "averageTries": 8.6429,
      "official": true,
      "tags": [
        {
          "key": "ad_hoc",
          "isMeta": false,
          "bojTagId": 109,
          "problemCount": 1254,
          "displayNames": [
            {
              "language": "ko",
              "name": "애드 혹",
              "short": "애드 혹"
            },
            {
              "language": "en",
              "name": "ad-hoc",
              "short": "ad-hoc"
            },
            {
              "language": "ja",
              "name": "アドホック",
              "short": "アドホック"
            }
          ],
          "aliases": [

          ]
        },
        {
          "key": "arbitrary_precision",
          "isMeta": false,
          "bojTagId": 117,
          "problemCount": 239,
          "displayNames": [
            {
              "language": "ko",
              "name": "임의 정밀도 / 큰 수 연산",
              "short": "임의 정밀도 / 큰 수 연산"
            },
            {
              "language": "en",
              "name": "arbitrary precision / big integers",
              "short": "arbitrary precision / big integers"
            },
            {
              "language": "ja",
              "name": "高精度または大きな数の演算",
              "short": "高精度または大きな数の演算"
            }
          ],
          "aliases": [
            {
              "alias": "빅인티저"
            },
            {
              "alias": "빅데시멀"
            },
            {
              "alias": "biginteger"
            },
            {
              "alias": "bigdecimal"
            }
          ]
        },
        {
          "key": "bruteforcing",
          "isMeta": false,
          "bojTagId": 125,
          "problemCount": 1997,
          "displayNames": [
            {
              "language": "ko",
              "name": "브루트포스 알고리즘",
              "short": "브루트포스 알고리즘"
            },
            {
              "language": "en",
              "name": "bruteforcing",
              "short": "bruteforce"
            },
            {
              "language": "ja",
              "name": "全探索",
              "short": "全探索"
            }
          ],
          "aliases": [
            {
              "alias": "완전탐색"
            },
            {
              "alias": "완전 탐색"
            },
            {
              "alias": "브루트포스"
            },
            {
              "alias": "bruteforce"
            },
            {
              "alias": "brute force"
            },
            {
              "alias": "완탐"
            }
          ]
        },
        {
          "key": "math",
          "isMeta": false,
          "bojTagId": 124,
          "problemCount": 5873,
          "displayNames": [
            {
              "language": "ko",
              "name": "수학",
              "short": "수학"
            },
            {
              "language": "en",
              "name": "mathematics",
              "short": "math"
            },
            {
              "language": "ja",
              "name": "数学",
              "short": "数学"
            }
          ],
          "aliases": [

          ]
        },
        {
          "key": "number_theory",
          "isMeta": false,
          "bojTagId": 95,
          "problemCount": 1314,
          "displayNames": [
            {
              "language": "ko",
              "name": "정수론",
              "short": "정수론"
            },
            {
              "language": "en",
              "name": "number theory",
              "short": "number theory"
            },
            {
              "language": "ja",
              "name": "整数論",
              "short": "整数論"
            }
          ],
          "aliases": [

          ]
        }
      ],
      "metadata": {

      }
    }
  ]
}
''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual =
            await apiClient.searchProblem(query, page, sort, direction);
        expect(actual, isA<SearchObject>());
        expect(actual.items, isA<List<Problem>>());
      });
    });

    group('searchUsers', () {
      const query = 'fdsa';
      const page = 1;

      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchUser(query, page);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/search/user',
              {'query': query, 'page': page.toString()},
            ),
          ),
        ).called(1);
      });

      test('returns SearchObject on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
        {}''');
        when(() => response.bodyBytes).thenReturn(utf8.encode('''
        {
    "count": 2,
    "items": [
        {
            "handle": "fdsajklt2",
            "bio": "",
            "badgeId": null,
            "backgroundId": "balloon_001",
            "profileImageUrl": null,
            "solvedCount": 489,
            "voteCount": 0,
            "class": 4,
            "classDecoration": "none",
            "rivalCount": 0,
            "reverseRivalCount": 0,
            "tier": 16,
            "rating": 1675,
            "ratingByProblemsSum": 1365,
            "ratingByClass": 150,
            "ratingBySolvedCount": 160,
            "ratingByVoteCount": 0,
            "arenaTier": 0,
            "arenaRating": 0,
            "arenaMaxTier": 0,
            "arenaMaxRating": 0,
            "arenaCompetedRoundCount": 0,
            "maxStreak": 1,
            "coins": 0,
            "stardusts": 5185,
            "joinedAt": "2021-06-19T00:00:00.000Z",
            "bannedUntil": "1970-01-01T00:00:00.000Z",
            "proUntil": "1970-01-01T00:00:00.000Z",
            "rank": 5169
        },
        {
            "handle": "fdsa0106",
            "bio": "",
            "badgeId": null,
            "backgroundId": "balloon_004",
            "profileImageUrl": null,
            "solvedCount": 192,
            "voteCount": 0,
            "class": 3,
            "classDecoration": "none",
            "rivalCount": 1,
            "reverseRivalCount": 2,
            "tier": 14,
            "rating": 1282,
            "ratingByProblemsSum": 1074,
            "ratingByClass": 100,
            "ratingBySolvedCount": 108,
            "ratingByVoteCount": 0,
            "arenaTier": 0,
            "arenaRating": 0,
            "arenaMaxTier": 0,
            "arenaMaxRating": 0,
            "arenaCompetedRoundCount": 0,
            "maxStreak": 16,
            "coins": 136,
            "stardusts": 2878,
            "joinedAt": "2022-01-20T05:07:36.000Z",
            "bannedUntil": "1970-01-01T00:00:00.000Z",
            "proUntil": "1970-01-01T00:00:00.000Z",
            "rank": 17200
        }
    ]
}
        '''));
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchUser(query, page);
        expect(actual, isA<SearchObject>());
        expect(actual.items, isA<List<User>>());
      });
    });

    group('searchTag', () {
      const query = 'number_theory';
      const page = 1;

      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.searchTag(query, page);
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/search/tag',
              {'query': query, 'page': page.toString()},
            ),
          ),
        ).called(1);
      });

      test('returns SearchObject on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(
          '''
{
  "count": 1,
  "items": [
    {
      "key": "number_theory",
      "isMeta": false,
      "bojTagId": 95,
      "problemCount": 1314,
      "displayNames": [
        {
          "language": "ko",
          "name": "정수론",
          "short": "정수론"
        },
        {
          "language": "en",
          "name": "number theory",
          "short": "number theory"
        },
        {
          "language": "ja",
          "name": "整数論",
          "short": "整数論"
        }
      ],
      "aliases": [

      ]
    }
  ]
}
        ''',
        );
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.searchTag(query, page);
        expect(actual, isA<SearchObject>());
        expect(actual.items, isA<List<Tag>>());
      });
    });

    group('arenaContests', () {
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.arenaContests();
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/arena/contests',
            ),
          ),
        ).called(1);
      });

      test('returns List<ArenaContest> on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
{
  "upcoming": [
    {
      "arenaId": 20,
      "arenaDisplayId": 17,
      "divisionDisplayName": null,
      "divisionShortDisplayName": null,
      "arenaIdFixed": true,
      "arenaBojContestId": null,
      "title": "2023 shake! (2023 경인지역 6개 대학 연합 프로그래밍 경시대회) Open Contest",
      "isGrandArena": false,
      "grandArenaId": 0,
      "startTime": "2024-01-13T05:00:00.000Z",
      "endTime": "2024-01-13T08:00:00.000Z",
      "registerEndTime": "2024-01-13T04:55:00.000Z",
      "ratedRangeStart": 0,
      "ratedRangeEnd": 0,
      "isRated": true,
      "ratedContestants": 0,
      "totalContestants": 0,
      "isScoreBased": false,
      "isLevelSorted": false,
      "givesLanguageBonus": true,
      "penaltyMinutes": 20,
      "bojNoticeLink": null,
      "registrationOpen": false,
      "needsApproval": false,
      "needsAclToRegister": false,
      "cancellationDisabled": false,
      "languages": [

      ],
      "isRegistered": false
    }
  ],
  "ongoing": [
  ],
  "ended": [
    {
      "arenaId": 1,
      "arenaDisplayId": 1,
      "divisionDisplayName": null,
      "divisionShortDisplayName": null,
      "arenaIdFixed": true,
      "arenaBojContestId": 1065,
      "title": "solved.ac Grand Arena #1",
      "isGrandArena": true,
      "grandArenaId": 1,
      "startTime": "2023-08-06T05:00:00.000Z",
      "endTime": "2023-08-06T08:00:00.000Z",
      "registerEndTime": "2023-08-06T04:55:00.000Z",
      "ratedRangeStart": 0,
      "ratedRangeEnd": 10,
      "isRated": true,
      "ratedContestants": 1363,
      "totalContestants": 1363,
      "isScoreBased": false,
      "isLevelSorted": false,
      "givesLanguageBonus": true,
      "penaltyMinutes": 20,
      "bojNoticeLink": "https://www.acmicpc.net/board/view/121450",
      "registrationOpen": true,
      "needsApproval": false,
      "needsAclToRegister": false,
      "cancellationDisabled": false,
      "languages": [
        "ko",
        "en"
      ]
    }
  ]
}
        ''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.arenaContests();
        expect(actual, isA<List<ArenaContest>>());
      });
    });

    group('siteStats', () {
      test('makes correct http request', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('{}');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await apiClient.siteStats();
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.https(
              'solved.ac',
              '/api/v3/site/stats',
            ),
          ),
        ).called(1);
      });

      test('returns SiteStats on valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('''
{
  "problemCount": 29378,
  "problemVotedCount": 21917,
  "userCount": 121493,
  "contributorCount": 3480,
  "contributionCount": 385079
}''');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final actual = await apiClient.siteStats();
        expect(actual, isA<SiteStats>());
      });
    });
  });
}
