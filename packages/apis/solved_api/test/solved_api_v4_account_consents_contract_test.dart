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

  test('builds the bodyless viewer consents endpoint', () {
    final endpoint = contract.accountConsents();
    expect(endpoint.proxy.path, 'account/consents');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes pending consents in wire order', () {
    final actual = contract.accountConsents().decode(
          jsonDecode(fixture('v4/account_consents.json')),
        );

    expect(actual.pending.map((consent) => consent.slug), [
      PolicySlug.tos,
      PolicySlug.privacy,
      PolicySlug.tos,
    ]);
    expect(actual.pending.first.version, '20240714');
    expect(actual.pending.first.label, 'v3');
    expect(actual.pending[1].version, '');
    expect(
      contract
          .accountConsents()
          .decode(<String, Object?>{'pending': <Object?>[]}).pending,
      isEmpty,
    );
  });

  test('accepts only the two documented slugs and strict strings', () {
    final endpoint = contract.accountConsents();
    for (final invalid in <Object?>[null, 0, 'pending', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    expect(
      () => endpoint.decode(<String, Object?>{}),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(<String, Object?>{'pending': null}),
      throwsFormatException,
    );
    for (final slug in <Object?>[
      'rules',
      'guideline',
      'tos_recurring',
      'TOS',
      '',
      null,
      0,
    ]) {
      final body = _response();
      _first(body)['slug'] = slug;
      expect(() => endpoint.decode(body), throwsFormatException,
          reason: '$slug');
    }
    for (final field in ['slug', 'version', 'label']) {
      final missing = _response();
      _first(missing).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
      final wrong = _response();
      _first(wrong)[field] = field == 'slug' ? false : 1;
      expect(() => endpoint.decode(wrong), throwsFormatException);
    }
  });

  test('eagerly snapshots an ordered unmodifiable list', () {
    final endpoint = contract.accountConsents();
    final body = _response();
    final pending = body['pending'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body)['label'] = 'changed';
    pending.clear();

    expect(actual.pending, hasLength(3));
    expect(actual.pending.first.label, 'v3');
    expect(() => actual.pending.clear(), throwsUnsupportedError);
  });
}

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_consents.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['pending'] as List<dynamic>).first as Map<String, dynamic>;
