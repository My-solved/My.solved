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

  test('builds the help tree with an omitted or explicit language', () {
    final omitted = contract.helpTree();

    expect(omitted.direct.path, 'posts/help');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(
      contract.helpTree(language: '').direct.queryParameters,
      {'lang': ''},
    );
    expect(
      contract
          .helpTree(language: List.filled(16, '🌏').join())
          .direct
          .queryParameters['lang']!
          .runes,
      hasLength(16),
    );
    expect(
      () => contract.helpTree(language: List.filled(17, 'a').join()),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'language'),
      ),
    );
  });

  test('decodes the recursive tree in wire order without inference', () {
    final actual = contract.helpTree().decode(
          jsonDecode(fixture('v4/help_tree.json')),
        );

    expect(actual.items.map((node) => node.path), ['a', 'other', 'a']);
    final root = actual.items.first;
    expect(root.title, '');
    expect(root.hasPage, isFalse);
    expect(root.children.map((node) => node.path), [
      'a/b',
      'not/a/child',
      'a/b',
    ]);
    expect(root.children.first.title, '한 글');
    expect(root.children.first.hasPage, isTrue);
    expect(root.children.first.children, isEmpty);
    expect(root.children[1].children.single.path, 'deep');
    expect(root.children[1].children.single.children, isEmpty);
    expect(actual.items[1].children, isEmpty);
  });

  test('requires every field at every depth', () {
    final endpoint = contract.helpTree();
    for (final invalid in <Object?>[null, 0, 'tree', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    expect(
      () => endpoint.decode(<String, Object?>{}),
      throwsFormatException,
    );
    expect(
      endpoint.decode(<String, Object?>{'items': <Object?>[]}).items,
      isEmpty,
    );
    for (final field in ['path', 'title', 'hasPage', 'children']) {
      for (final depth in [0, 1, 2]) {
        for (final invalid in <Object?>[_missing, null, 1.5]) {
          final body = _response();
          final node = _nodeAt(body, depth);
          if (identical(invalid, _missing)) {
            node.remove(field);
          } else {
            node[field] = invalid;
          }
          expect(
            () => endpoint.decode(body),
            throwsFormatException,
            reason: '$field at depth $depth = $invalid',
          );
        }
      }
    }
    final notObject = _response();
    ((notObject['items'] as List).first as Map)['children'] = <Object?>[0];
    expect(() => endpoint.decode(notObject), throwsFormatException);
  });

  test('eagerly snapshots unmodifiable lists at every depth', () {
    final body = _response();
    final rootItems = body['items'] as List<dynamic>;
    final children =
        (rootItems.first as Map<String, dynamic>)['children'] as List;
    final grandchildren =
        (children[1] as Map<String, dynamic>)['children'] as List<dynamic>;
    final actual = contract.helpTree().decode(body);
    grandchildren.clear();
    children.clear();
    rootItems.clear();

    expect(actual.items, hasLength(3));
    expect(actual.items.first.children, hasLength(3));
    expect(actual.items.first.children[1].children, hasLength(1));
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(() => actual.items.first.children.clear(), throwsUnsupportedError);
    expect(
      () => actual.items.first.children[1].children.clear(),
      throwsUnsupportedError,
    );
  });
}

const _missing = Object();

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/help_tree.json')) as Map<String, dynamic>;

Map<String, dynamic> _nodeAt(Map<String, dynamic> body, int depth) {
  var node = (body['items'] as List<dynamic>).first as Map<String, dynamic>;
  for (var level = 0; level < depth; level++) {
    node = (node['children'] as List<dynamic>)[level == 0 ? 1 : 0]
        as Map<String, dynamic>;
  }
  return node;
}
