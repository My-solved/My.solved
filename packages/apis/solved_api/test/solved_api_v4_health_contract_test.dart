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

  test('builds the bodyless health check without a query', () {
    final endpoint = contract.health();

    expect(endpoint.direct.path, 'health');
    expect(endpoint.direct.queryParameters, isEmpty);
    expect(endpoint.proxy.path, 'health');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes every exact status and a raw timestamp', () {
    final endpoint = contract.health();
    final actual = endpoint.decode(jsonDecode(fixture('v4/health.json')));

    expect(actual.status, HealthStatus.degraded);
    expect(actual.timestamp, 'not a date');
    expect(HealthStatus.values.map((status) => status.value), [
      'ok',
      'degraded',
      'down',
    ]);
    for (final status in HealthStatus.values) {
      expect(
        endpoint.decode(<String, Object?>{
          'status': status.value,
          'timestamp': '',
        }).status,
        status,
      );
    }
  });

  test('requires both fields with strict types', () {
    final endpoint = contract.health();
    for (final invalid in <Object?>[null, 0, 'ok', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final body in <Map<String, Object?>>[
      {'timestamp': 't'},
      {'status': 'ok'},
      {'status': null, 'timestamp': 't'},
      {'status': 'ok', 'timestamp': null},
      {'status': 'OK', 'timestamp': 't'},
      {'status': 'unknown', 'timestamp': 't'},
      {'status': 'ok', 'timestamp': 0},
    ]) {
      expect(() => endpoint.decode(body), throwsFormatException,
          reason: '$body');
    }
  });
}
