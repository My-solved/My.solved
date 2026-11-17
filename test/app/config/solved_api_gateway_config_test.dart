import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_solved/app/config/solved_api_gateway_config.dart';

void main() {
  group('SolvedApiGatewayConfig', () {
    test('keeps v4 disabled when the compile-time value is missing', () {
      final config = SolvedApiGatewayConfig.parse(
        '',
        allowInsecureLoopback: false,
      );
      final client = config.createClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(config.hasV4Gateway, isFalse);
      expect(config.v4ProxyBaseUri, isNull);
      expect(() => client.v4SearchTags('dp'), throwsStateError);
    });

    test('injects a configured HTTPS gateway into v4 requests', () async {
      Uri? requestedUri;
      final config = SolvedApiGatewayConfig.parse(
        'https://gateway.example/solved/v4/',
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

      expect(config.hasV4Gateway, isTrue);
      expect(result.items, isEmpty);
      expect(requestedUri, Uri.parse('https://gateway.example/solved/v4/tags'));
    });

    test('closes legacy transport when a v4 gateway is configured', () {
      var requestCount = 0;
      final config = SolvedApiGatewayConfig.parse(
        'https://gateway.example/solved/v4/',
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

    test('allows loopback HTTP only when explicitly enabled', () {
      for (final host in ['localhost', '127.0.0.1', '[::1]']) {
        final value = 'http://$host:3000/solved/v4/';
        expect(
          SolvedApiGatewayConfig.parse(
            value,
            allowInsecureLoopback: true,
          ).v4ProxyBaseUri,
          Uri.parse(value),
        );
        expect(
          () =>
              SolvedApiGatewayConfig.parse(value, allowInsecureLoopback: false),
          throwsFormatException,
        );
      }
      expect(
        () => SolvedApiGatewayConfig.parse(
          'http://gateway.example/solved/v4/',
          allowInsecureLoopback: true,
        ),
        throwsFormatException,
      );
    });

    test('rejects non-loopback HTTP and malformed gateway boundaries', () {
      const invalidValues = <String>[
        'http://gateway.example/solved/v4/',
        'gateway.example/solved/v4/',
        ' https://gateway.example/solved/v4/',
        'https://user@gateway.example/solved/v4/',
        'https://@gateway.example/solved/v4/',
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
          () =>
              SolvedApiGatewayConfig.parse(value, allowInsecureLoopback: false),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });
}
