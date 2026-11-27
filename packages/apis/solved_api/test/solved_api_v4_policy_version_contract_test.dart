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

  test('accepts exactly the label and day reference patterns', () {
    for (final ref in [
      'v0',
      'v3',
      'v999',
      'v007',
      'beta',
      '20240714',
      '00000000',
      '99999999',
    ]) {
      final endpoint = contract.policyVersion(PolicySlug.privacy, ref);
      expect(endpoint.direct.path, 'policies/privacy/$ref', reason: ref);
      expect(endpoint.direct.queryParameters, isEmpty);
      expect(endpoint.proxy.path, endpoint.direct.path);
    }
    expect(
      contract
          .policyVersion(PolicySlug.tosRecurring, 'v1', language: '')
          .direct
          .queryParameters,
      {'lang': ''},
    );
  });

  test('rejects references outside the official patterns', () {
    for (final ref in [
      '',
      'v',
      'v1000',
      'V3',
      'Beta',
      'beta1',
      'v3.1',
      '2024071',
      '202407141',
      '2024-07-14',
      '２０２４０７１４',
      'v3\n',
      '20240714\n',
      '../v3',
    ]) {
      expect(
        () => contract.policyVersion(PolicySlug.tos, ref),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'ref')
              .having((error) => error.invalidValue, 'invalidValue', ref),
        ),
        reason: ref,
      );
    }
    expect(
      () => contract.policyVersion(
        PolicySlug.tos,
        'v1',
        language: List.filled(17, 'a').join(),
      ),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'language'),
      ),
    );
  });

  test('decodes with the shared strict policy decoder', () {
    final endpoint = contract.policyVersion(PolicySlug.tos, 'v1');
    final actual = endpoint.decode(jsonDecode(fixture('v4/policy.json')));

    expect(actual.slug, PolicySlug.privacy);
    expect(actual.content, isA<PolicyMarkdownContent>());
    expect(actual.versions, hasLength(3));
    expect(() => actual.versions.clear(), throwsUnsupportedError);
    final body = jsonDecode(fixture('v4/policy.json')) as Map<String, dynamic>;
    expect(
      () => endpoint.decode(Map<String, dynamic>.of(body)..remove('revisedAt')),
      throwsFormatException,
    );
  });
}
