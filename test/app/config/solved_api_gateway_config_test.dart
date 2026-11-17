import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_solved/app/config/solved_api_gateway_config.dart';

void main() {
  group('SolvedApiGatewayConfig', () {
    test('defaults the missing compile-time mode to legacy v3', () {
      final config = SolvedApiGatewayConfig.fromEnvironment();

      expect(config.mode, SolvedApiMode.legacyV3);
      expect(config.hasV4Gateway, isFalse);
      expect(config.v4ProxyBaseUri, isNull);
      expect(config.usesInsecureV4Loopback, isFalse);
    });

    test('keeps the explicit legacy mode on v3 transport', () {
      final config = SolvedApiGatewayConfig.parse(
        mode: solvedApiLegacyV3Mode,
        v4ProxyBaseUri: '',
        allowInsecureLoopback: false,
      );
      final client = config.createClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(config.mode, SolvedApiMode.legacyV3);
      expect(config.hasV4Gateway, isFalse);
      expect(config.v4ProxyBaseUri, isNull);
      expect(config.usesInsecureV4Loopback, isFalse);
      expect(() => client.v4SearchTags('dp'), throwsStateError);
    });

    test('injects a configured HTTPS gateway into v4 requests', () async {
      Uri? requestedUri;
      final config = SolvedApiGatewayConfig.parse(
        mode: solvedApiOfficialV4Mode,
        v4ProxyBaseUri: 'https://gateway.example/solved/v4/',
        allowInsecureLoopback: false,
      );
      final client = config.createClient(
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode(<String, Object>{'tags': <Object>[]}),
            200,
          );
        }),
      );

      final result = await client.v4SearchTags('dp');

      expect(config.mode, SolvedApiMode.officialV4);
      expect(config.hasV4Gateway, isTrue);
      expect(config.usesInsecureV4Loopback, isFalse);
      expect(result.items, isEmpty);
      expect(requestedUri, Uri.parse('https://gateway.example/solved/v4/tags'));
    });

    test('closes legacy transport when a v4 gateway is configured', () {
      var requestCount = 0;
      final config = SolvedApiGatewayConfig.parse(
        mode: solvedApiOfficialV4Mode,
        v4ProxyBaseUri: 'https://gateway.example/solved/v4/',
        allowInsecureLoopback: false,
      );
      final client = config.createClient(
        httpClient: MockClient((_) async {
          requestCount += 1;
          return http.Response('{}', 200);
        }),
      );

      expect(() => client.userShow('index'), throwsStateError);
      expect(requestCount, 0);
    });

    test('rejects mode and gateway partial activation', () {
      expect(
        () => SolvedApiGatewayConfig.parse(
          mode: solvedApiLegacyV3Mode,
          v4ProxyBaseUri: 'https://gateway.example/solved/v4/',
          allowInsecureLoopback: false,
        ),
        throwsFormatException,
      );
      expect(
        () => SolvedApiGatewayConfig.parse(
          mode: solvedApiOfficialV4Mode,
          v4ProxyBaseUri: '',
          allowInsecureLoopback: false,
        ),
        throwsFormatException,
      );
    });

    test('rejects unknown or non-canonical mode values', () {
      for (final mode in <String>[
        '',
        'legacy_v3',
        'Legacy-v3',
        'official-V4',
        ' $solvedApiOfficialV4Mode',
        '$solvedApiOfficialV4Mode ',
      ]) {
        expect(
          () => SolvedApiGatewayConfig.parse(
            mode: mode,
            v4ProxyBaseUri: '',
            allowInsecureLoopback: false,
          ),
          throwsFormatException,
          reason: mode,
        );
      }
    });

    test('allows loopback HTTP only when explicitly enabled', () {
      for (final host in ['localhost', '127.0.0.1', '[::1]']) {
        final value = 'http://$host:3000/solved/v4/';
        final config = SolvedApiGatewayConfig.parse(
          mode: solvedApiOfficialV4Mode,
          v4ProxyBaseUri: value,
          allowInsecureLoopback: true,
        );
        expect(config.v4ProxyBaseUri, Uri.parse(value));
        expect(config.usesInsecureV4Loopback, isTrue);
        expect(
          () => SolvedApiGatewayConfig.parse(
            mode: solvedApiOfficialV4Mode,
            v4ProxyBaseUri: value,
            allowInsecureLoopback: false,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => SolvedApiGatewayConfig.parse(
          mode: solvedApiOfficialV4Mode,
          v4ProxyBaseUri: 'http://gateway.example/solved/v4/',
          allowInsecureLoopback: true,
        ),
        throwsFormatException,
      );
    });

    test('does not retain broad loopback permission for HTTPS gateways', () {
      final config = SolvedApiGatewayConfig.parse(
        mode: solvedApiOfficialV4Mode,
        v4ProxyBaseUri: 'https://gateway.example/solved/v4/',
        allowInsecureLoopback: true,
      );

      expect(config.usesInsecureV4Loopback, isFalse);
    });

    test('rejects non-loopback HTTP and malformed gateway boundaries', () {
      const invalidValues = <String>[
        'http://gateway.example/solved/v4/',
        'gateway.example/solved/v4/',
        ' https://gateway.example/solved/v4/',
        'https://user@gateway.example/solved/v4/',
        'https://@gateway.example/solved/v4/',
        'https://solved.ac/solved/v4/',
        'https://api.solved.ac/solved/v4/',
        'https://solved.ac./solved/v4/',
        'https://API.SOLVED.AC./solved/v4/',
        'https://api.solved.ac../solved/v4/',
        'https://gateway.example/solved/v4/?region=kr',
        'https://gateway.example/solved/v4/#fragment',
        'https://gateway.example/solved/v4',
        'https://gateway.example/prefix/solved/v4/',
        'https://gateway.example/solved//v4/',
        'https://gateway.example/%73olved/v4/',
        'https://gateway.example/solved/./v4/',
      ];

      for (final value in invalidValues) {
        expect(
          () => SolvedApiGatewayConfig.parse(
            mode: solvedApiOfficialV4Mode,
            v4ProxyBaseUri: value,
            allowInsecureLoopback: false,
          ),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });
}
