import 'dart:convert';
import 'dart:io';

import 'public_contract_capture.dart';

const _captureSource = 'sanitized-public-har';
const _diffSource = 'sanitized-public-capture-diff';
const _redactedValue = '<redacted>';
const _jsonTypeOrder = {
  'object': 0,
  'array': 1,
  'string': 2,
  'integer': 3,
  'number': 4,
  'boolean': 5,
  'null': 6,
};

final RegExp _captureIdPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');
final RegExp _hostnamePattern = RegExp(
  r'^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*'
  r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
);

class PublicContractCaptureSnapshot {
  PublicContractCaptureSnapshot._({
    required this.host,
    required Map<String, PublicContractExchangeSnapshot> exchanges,
  }) : exchanges = Map<String, PublicContractExchangeSnapshot>.unmodifiable(
          exchanges,
        );

  final String host;
  final Map<String, PublicContractExchangeSnapshot> exchanges;
}

class PublicContractExchangeSnapshot {
  PublicContractExchangeSnapshot._({
    required this.id,
    required this.request,
    required this.statusCode,
    required this.responseSchema,
  });

  final String id;
  final PublicContractRequestSnapshot request;
  final int statusCode;
  final Map<String, PublicContractSchemaNode> responseSchema;
}

class PublicContractRequestSnapshot {
  PublicContractRequestSnapshot._({
    required this.method,
    required this.scheme,
    required this.host,
    required this.path,
    required List<PublicContractQuerySnapshot> query,
  }) : query = List<PublicContractQuerySnapshot>.unmodifiable(query);

  final String method;
  final String scheme;
  final String host;
  final String path;
  final List<PublicContractQuerySnapshot> query;

  Map<String, Object?> toJson() => {
        'method': method,
        'scheme': scheme,
        'host': host,
        'path': path,
        'query': [for (final parameter in query) parameter.toJson()],
      };

  bool hasSameContract(PublicContractRequestSnapshot other) =>
      method == other.method &&
      scheme == other.scheme &&
      host == other.host &&
      path == other.path &&
      _listsEqual(query, other.query, (left, right) => left == right);
}

class PublicContractQuerySnapshot {
  const PublicContractQuerySnapshot({
    required this.name,
    required this.valueCount,
  });

  final String name;
  final int valueCount;

  Map<String, Object?> toJson() => {'name': name, 'valueCount': valueCount};

  @override
  bool operator ==(Object other) =>
      other is PublicContractQuerySnapshot &&
      name == other.name &&
      valueCount == other.valueCount;

  @override
  int get hashCode => Object.hash(name, valueCount);
}

class PublicContractSchemaNode {
  PublicContractSchemaNode._({
    required List<String> types,
    required this.presence,
  }) : types = List<String>.unmodifiable(types);

  final List<String> types;
  final String presence;

  Map<String, Object?> toJson() => {
        'types': types,
        'presence': presence,
      };

  bool hasSameContract(PublicContractSchemaNode other) =>
      presence == other.presence &&
      _listsEqual(types, other.types, (left, right) => left == right);
}

class PublicContractCaptureDiff {
  PublicContractCaptureDiff._({
    required this.beforeHost,
    required this.afterHost,
    required this.beforeOperationCount,
    required this.afterOperationCount,
    required List<PublicContractOperationDiff> operations,
  }) : operations = List<PublicContractOperationDiff>.unmodifiable(operations);

  final String beforeHost;
  final String afterHost;
  final int beforeOperationCount;
  final int afterOperationCount;
  final List<PublicContractOperationDiff> operations;

  Map<String, Object?> toJson() {
    var addedOperations = 0;
    var removedOperations = 0;
    var modifiedOperations = 0;
    var responsePathChanges = 0;
    for (final operation in operations) {
      switch (operation.change) {
        case 'added':
          addedOperations++;
        case 'removed':
          removedOperations++;
        case 'modified':
          modifiedOperations++;
      }
      responsePathChanges += operation.responseChanges.length;
    }

    return {
      'schemaVersion': 1,
      'source': _diffSource,
      'before': {'host': beforeHost, 'operationCount': beforeOperationCount},
      'after': {'host': afterHost, 'operationCount': afterOperationCount},
      'summary': {
        'addedOperations': addedOperations,
        'removedOperations': removedOperations,
        'modifiedOperations': modifiedOperations,
        'responsePathChanges': responsePathChanges,
      },
      'operations': [for (final operation in operations) operation.toJson()],
    };
  }
}

class PublicContractOperationDiff {
  PublicContractOperationDiff._({
    required this.id,
    required this.change,
    required this.requestChanged,
    required this.beforeRequest,
    required this.afterRequest,
    required this.responseStatusChanged,
    required this.beforeStatusCode,
    required this.afterStatusCode,
    required List<PublicContractResponsePathDiff> responseChanges,
  }) : responseChanges = List<PublicContractResponsePathDiff>.unmodifiable(
          responseChanges,
        );

  final String id;
  final String change;
  final bool requestChanged;
  final PublicContractRequestSnapshot? beforeRequest;
  final PublicContractRequestSnapshot? afterRequest;
  final bool responseStatusChanged;
  final int? beforeStatusCode;
  final int? afterStatusCode;
  final List<PublicContractResponsePathDiff> responseChanges;

  Map<String, Object?> toJson() => {
        'id': id,
        'change': change,
        'request': {
          'changed': requestChanged,
          'before': beforeRequest?.toJson(),
          'after': afterRequest?.toJson(),
        },
        'response': {
          'status': {
            'changed': responseStatusChanged,
            'before': beforeStatusCode,
            'after': afterStatusCode,
          },
          'changes': [for (final change in responseChanges) change.toJson()],
        },
      };
}

class PublicContractResponsePathDiff {
  PublicContractResponsePathDiff._({
    required this.pointer,
    required this.change,
    required this.before,
    required this.after,
  });

  final String pointer;
  final String change;
  final PublicContractSchemaNode? before;
  final PublicContractSchemaNode? after;

  Map<String, Object?> toJson() => {
        'pointer': pointer,
        'change': change,
        'before': before?.toJson(),
        'after': after?.toJson(),
      };
}

PublicContractCaptureSnapshot readPublicContractCapture(
  Directory captureDirectory,
) {
  final directory = captureDirectory.absolute;
  if (FileSystemEntity.typeSync(directory.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw const FormatException('Capture input must be a real directory');
  }

  final manifestFile = File('${directory.path}/manifest.json');
  if (FileSystemEntity.typeSync(manifestFile.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw const FormatException('Capture manifest must be a real file');
  }

  final manifest = _requiredStringMap(
    jsonDecode(manifestFile.readAsStringSync()),
    'capture manifest',
  );
  _requireExactKeys(
      manifest,
      const {
        'schemaVersion',
        'source',
        'host',
        'exchanges',
      },
      'capture manifest');
  if (manifest['schemaVersion'] != 1 || manifest['source'] != _captureSource) {
    throw const FormatException('Unsupported capture manifest schema');
  }

  final host = manifest['host'];
  if (host is! String ||
      host != host.toLowerCase() ||
      !_hostnamePattern.hasMatch(host)) {
    throw const FormatException('Capture manifest host is invalid');
  }

  final rawExchanges = manifest['exchanges'];
  if (rawExchanges is! List || rawExchanges.isEmpty) {
    throw const FormatException('Capture manifest exchanges must not be empty');
  }

  final exchanges = <String, PublicContractExchangeSnapshot>{};
  final expectedFiles = <String>{manifestFile.absolute.path};
  for (final rawExchange in rawExchanges) {
    final parsed = _readExchange(directory, host, rawExchange);
    if (exchanges.containsKey(parsed.exchange.id)) {
      throw const FormatException('Capture exchange ids must be unique');
    }
    exchanges[parsed.exchange.id] = parsed.exchange;
    expectedFiles.add(parsed.fixtureFile.absolute.path);
  }

  final actualFiles = <String>{};
  for (final entity in directory.listSync(followLinks: false)) {
    if (FileSystemEntity.typeSync(entity.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FormatException('Capture directory has a non-file entry');
    }
    actualFiles.add(entity.absolute.path);
  }
  if (!_setsEqual(actualFiles, expectedFiles)) {
    throw const FormatException('Capture directory has unknown files');
  }

  return PublicContractCaptureSnapshot._(host: host, exchanges: exchanges);
}

PublicContractCaptureDiff diffPublicContractCaptures(
  PublicContractCaptureSnapshot before,
  PublicContractCaptureSnapshot after,
) {
  final ids = {...before.exchanges.keys, ...after.exchanges.keys}.toList()
    ..sort();
  final operations = <PublicContractOperationDiff>[];

  for (final id in ids) {
    final beforeExchange = before.exchanges[id];
    final afterExchange = after.exchanges[id];
    final responseChanges = _diffResponseSchemas(
      beforeExchange?.responseSchema,
      afterExchange?.responseSchema,
    );
    final requestChanged = beforeExchange == null ||
        afterExchange == null ||
        !beforeExchange.request.hasSameContract(afterExchange.request);
    final responseStatusChanged = beforeExchange == null ||
        afterExchange == null ||
        beforeExchange.statusCode != afterExchange.statusCode;

    if (!requestChanged && !responseStatusChanged && responseChanges.isEmpty) {
      continue;
    }

    operations.add(
      PublicContractOperationDiff._(
        id: id,
        change: switch ((beforeExchange, afterExchange)) {
          (null, _) => 'added',
          (_, null) => 'removed',
          _ => 'modified',
        },
        requestChanged: requestChanged,
        beforeRequest: beforeExchange?.request,
        afterRequest: afterExchange?.request,
        responseStatusChanged: responseStatusChanged,
        beforeStatusCode: beforeExchange?.statusCode,
        afterStatusCode: afterExchange?.statusCode,
        responseChanges: responseChanges,
      ),
    );
  }

  return PublicContractCaptureDiff._(
    beforeHost: before.host,
    afterHost: after.host,
    beforeOperationCount: before.exchanges.length,
    afterOperationCount: after.exchanges.length,
    operations: operations,
  );
}

String prettyPublicContractDiff(PublicContractCaptureDiff diff) =>
    '${const JsonEncoder.withIndent('  ').convert(diff.toJson())}\n';

({PublicContractExchangeSnapshot exchange, File fixtureFile}) _readExchange(
  Directory directory,
  String manifestHost,
  Object? value,
) {
  final exchange = _requiredStringMap(value, 'capture exchange');
  _requireExactKeys(
      exchange,
      const {
        'id',
        'request',
        'response',
      },
      'capture exchange');

  final id = exchange['id'];
  if (id is! String || !_captureIdPattern.hasMatch(id)) {
    throw const FormatException('Capture exchange id is invalid');
  }

  final request = _readRequest(exchange['request'], manifestHost);
  final response = _requiredStringMap(exchange['response'], 'response');
  _requireExactKeys(
      response,
      const {
        'status',
        'fixture',
        'topLevelType',
      },
      'response');

  final status = response['status'];
  if (status is! int || status < 100 || status > 599) {
    throw const FormatException('Capture response status is invalid');
  }

  final fixture = response['fixture'];
  if (fixture != '$id.response.json') {
    throw const FormatException('Capture response fixture is invalid');
  }
  final fixtureFile = File('${directory.path}/$fixture');
  if (FileSystemEntity.typeSync(fixtureFile.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw const FormatException('Capture response fixture must be a real file');
  }

  final fixtureJson = jsonDecode(fixtureFile.readAsStringSync());
  final topLevelType = response['topLevelType'];
  if (topLevelType is! String ||
      !const {'object', 'array', 'scalar'}.contains(topLevelType) ||
      topLevelType != _topLevelType(fixtureJson)) {
    throw const FormatException('Capture response type does not match fixture');
  }

  return (
    exchange: PublicContractExchangeSnapshot._(
      id: id,
      request: PublicContractRequestSnapshot._(
        method: request.method,
        scheme: request.scheme,
        host: request.host,
        path: request.path,
        query: request.query,
      ),
      statusCode: status,
      responseSchema: _inventoryResponseSchema(fixtureJson),
    ),
    fixtureFile: fixtureFile,
  );
}

({
  String method,
  String scheme,
  String host,
  String path,
  List<PublicContractQuerySnapshot> query,
}) _readRequest(Object? value, String manifestHost) {
  final request = _requiredStringMap(value, 'request');
  _requireExactKeys(
      request,
      const {
        'method',
        'scheme',
        'host',
        'path',
        'query',
      },
      'request');
  if (request['method'] != 'GET' ||
      request['scheme'] != 'https' ||
      request['host'] != manifestHost) {
    throw const FormatException('Capture request origin is invalid');
  }

  final path = request['path'];
  if (path is! String || !isPublicCapturePath(path)) {
    throw const FormatException('Capture request path is invalid');
  }

  final rawQuery = request['query'];
  if (rawQuery is! List) {
    throw const FormatException('Capture request query must be a list');
  }
  final query = <PublicContractQuerySnapshot>[];
  String? previousName;
  for (final rawParameter in rawQuery) {
    final parameter = _requiredStringMap(rawParameter, 'query parameter');
    _requireExactKeys(parameter, const {'name', 'values'}, 'query parameter');
    final name = parameter['name'];
    final values = parameter['values'];
    if (name is! String ||
        !isPublicCaptureQueryName(name) ||
        previousName != null && previousName.compareTo(name) >= 0 ||
        values is! List ||
        values.isEmpty ||
        values.any((value) => value != _redactedValue)) {
      throw const FormatException('Capture query parameter is invalid');
    }
    query.add(
      PublicContractQuerySnapshot(name: name, valueCount: values.length),
    );
    previousName = name;
  }

  return (
    method: 'GET',
    scheme: 'https',
    host: manifestHost,
    path: path,
    query: query,
  );
}

Map<String, PublicContractSchemaNode> _inventoryResponseSchema(Object? value) {
  final nodes = <String, _MutableSchemaNode>{};
  final objectCounts = <String, int>{};
  final arrayItemCounts = <String, int>{};

  void visit(Object? current, String pointer) {
    final node = nodes.putIfAbsent(pointer, _MutableSchemaNode.new);
    node.types.add(_jsonType(current));
    node.observed++;

    if (current is Map) {
      objectCounts.update(pointer, (count) => count + 1, ifAbsent: () => 1);
      final entries = current.entries.toList()
        ..sort(
          (left, right) => left.key.toString().compareTo(right.key.toString()),
        );
      for (final entry in entries) {
        visit(
          entry.value,
          '$pointer/${_escapePointerSegment(entry.key.toString())}',
        );
      }
    } else if (current is List) {
      arrayItemCounts.update(
        pointer,
        (count) => count + current.length,
        ifAbsent: () => current.length,
      );
      for (final item in current) {
        visit(item, '$pointer/*');
      }
    }
  }

  visit(value, '');
  final result = <String, PublicContractSchemaNode>{};
  final pointers = nodes.keys.toList()..sort();
  for (final pointer in pointers) {
    final mutable = nodes[pointer]!;
    final opportunities = pointer.isEmpty
        ? 1
        : pointer.endsWith('/*')
            ? arrayItemCounts[_parentPointer(pointer)]!
            : objectCounts[_parentPointer(pointer)]!;
    result[pointer] = PublicContractSchemaNode._(
      types: mutable.types.toList()
        ..sort((left, right) =>
            _jsonTypeOrder[left]!.compareTo(_jsonTypeOrder[right]!)),
      presence: mutable.observed == opportunities ? 'required' : 'optional',
    );
  }
  return Map<String, PublicContractSchemaNode>.unmodifiable(result);
}

List<PublicContractResponsePathDiff> _diffResponseSchemas(
  Map<String, PublicContractSchemaNode>? before,
  Map<String, PublicContractSchemaNode>? after,
) {
  final pointers = {...?before?.keys, ...?after?.keys}.toList()..sort();
  final changes = <PublicContractResponsePathDiff>[];
  for (final pointer in pointers) {
    final beforeNode = before?[pointer];
    final afterNode = after?[pointer];
    if (beforeNode != null &&
        afterNode != null &&
        beforeNode.hasSameContract(afterNode)) {
      continue;
    }
    changes.add(
      PublicContractResponsePathDiff._(
        pointer: pointer,
        change: switch ((beforeNode, afterNode)) {
          (null, _) => 'added',
          (_, null) => 'removed',
          _ => 'modified',
        },
        before: beforeNode,
        after: afterNode,
      ),
    );
  }
  return changes;
}

class _MutableSchemaNode {
  final Set<String> types = {};
  int observed = 0;
}

String _jsonType(Object? value) => switch (value) {
      null => 'null',
      bool() => 'boolean',
      int() => 'integer',
      double() => 'number',
      String() => 'string',
      List() => 'array',
      Map() => 'object',
      _ => throw const FormatException('Fixture contains unsupported JSON'),
    };

String _topLevelType(Object? value) => switch (value) {
      Map() => 'object',
      List() => 'array',
      _ => 'scalar',
    };

String _escapePointerSegment(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1').replaceAll('*', '~2');

String _parentPointer(String pointer) {
  final separator = pointer.lastIndexOf('/');
  if (separator < 0) {
    throw const FormatException('Schema pointer has no parent');
  }
  return pointer.substring(0, separator);
}

Map<String, Object?> _requiredStringMap(Object? value, String description) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$description must be an object');
  }
  return Map<String, Object?>.from(value);
}

void _requireExactKeys(
  Map<String, Object?> value,
  Set<String> expected,
  String description,
) {
  if (value.length != expected.length || !value.keys.every(expected.contains)) {
    throw FormatException('$description has unsupported fields');
  }
}

bool _setsEqual<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

bool _listsEqual<T>(
  List<T> left,
  List<T> right,
  bool Function(T left, T right) equals,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (!equals(left[index], right[index])) return false;
  }
  return true;
}
