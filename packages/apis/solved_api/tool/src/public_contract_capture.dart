import 'dart:convert';
import 'dart:io';

const _redactedValue = '<redacted>';

final RegExp _captureIdPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');
final RegExp _hostnamePattern = RegExp(
  r'^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*'
  r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
);
final RegExp _publicPathPattern = RegExp(r'^/[A-Za-z0-9._~/-]*$');
final RegExp _publicQueryNamePattern = RegExp(
  r'^[A-Za-z0-9_][A-Za-z0-9_.\-\[\]]{0,127}$',
);
final RegExp _httpHeaderNamePattern = RegExp(
  r"^[!#\$%&'*+\-.^_`|~0-9A-Za-z]+$",
);

bool isPublicCapturePath(String path) => _isPublicPath(path);

bool isPublicCaptureQueryName(String name) =>
    _publicQueryNamePattern.hasMatch(name) && !_isRequestCredentialName(name);

const _requestCredentialNameTokens = {
  'auth',
  'authorization',
  'authentication',
  'oauth',
  'bearer',
  'cookie',
  'credential',
  'csrf',
  'xsrf',
  'code',
  'email',
  'hmac',
  'jwt',
  'key',
  'nonce',
  'password',
  'passwd',
  'proof',
  'refresh',
  'saml',
  'secret',
  'session',
  'sig',
  'signature',
  'sso',
  'ticket',
  'token',
};

const _requestCredentialNameFragments = {
  'accesskey',
  'accesstoken',
  'apikey',
  'authkey',
  'clientid',
  'clientsecret',
  'hmackey',
  'idtoken',
  'privatekey',
  'refreshtoken',
  'samlresponse',
  'signingkey',
};

const _requestCredentialNameStems = {
  'auth',
  'bearer',
  'cookie',
  'credential',
  'csrf',
  'email',
  'hmac',
  'jwt',
  'key',
  'nonce',
  'oauth',
  'password',
  'passwd',
  'proof',
  'refresh',
  'saml',
  'secret',
  'session',
  'sso',
  'ticket',
  'token',
  'xsrf',
};

const _sensitiveResponseNameTokens = {
  'auth',
  'authorization',
  'authentication',
  'oauth',
  'bearer',
  'cookie',
  'credential',
  'csrf',
  'xsrf',
  'email',
  'hmac',
  'jwt',
  'password',
  'passwd',
  'proof',
  'refresh',
  'saml',
  'secret',
  'session',
  'sig',
  'signature',
  'sso',
  'ticket',
  'token',
};

const _sensitiveResponseNameFragments = {
  'accesskey',
  'accesstoken',
  'apikey',
  'authcode',
  'authkey',
  'authtoken',
  'authenticationtoken',
  'authorizationcode',
  'clientsecret',
  'csrftoken',
  'encryptionkey',
  'hmackey',
  'idtoken',
  'oauthcode',
  'passwordhash',
  'privatekey',
  'refreshtoken',
  'samlresponse',
  'secretkey',
  'sessionid',
  'signingkey',
  'xsrftoken',
};

const _sensitiveResponseNameStems = {
  'bearer',
  'cookie',
  'credential',
  'csrf',
  'email',
  'hmac',
  'jwt',
  'oauth',
  'password',
  'passwd',
  'proof',
  'refresh',
  'saml',
  'secret',
  'session',
  'sso',
  'ticket',
  'token',
  'xsrf',
};

const _publicRequestHeaders = {
  'accept',
  'accept-encoding',
  'accept-language',
  'cache-control',
  'connection',
  'dnt',
  'host',
  'if-modified-since',
  'if-none-match',
  'origin',
  'pragma',
  'priority',
  'purpose',
  'range',
  'referer',
  'sec-ch-ua',
  'sec-ch-ua-arch',
  'sec-ch-ua-bitness',
  'sec-ch-ua-full-version',
  'sec-ch-ua-full-version-list',
  'sec-ch-ua-mobile',
  'sec-ch-ua-model',
  'sec-ch-ua-platform',
  'sec-ch-ua-platform-version',
  'sec-fetch-dest',
  'sec-fetch-mode',
  'sec-fetch-site',
  'sec-fetch-user',
  'sec-gpc',
  'sec-purpose',
  'te',
  'upgrade-insecure-requests',
  'user-agent',
};

class PublicCaptureOperation {
  PublicCaptureOperation._({
    required this.id,
    required this.path,
    required Map<String, List<String>> query,
    required this.statusCode,
  }) : query = Map<String, List<String>>.unmodifiable({
          for (final entry in query.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        });

  final String id;
  final String path;
  final Map<String, List<String>> query;
  final int statusCode;

  String get selectorKey => _selectorKey(path, query, statusCode);
}

class PublicContractCapturePlan {
  PublicContractCapturePlan._({
    required this.host,
    required List<PublicCaptureOperation> operations,
  }) : operations = List<PublicCaptureOperation>.unmodifiable(operations);

  factory PublicContractCapturePlan.fromJson(Object? value) {
    final root = _requiredStringMap(value, 'capture plan');
    _requireExactKeys(
      root,
      const {'schemaVersion', 'host', 'operations'},
      'capture plan',
    );
    if (root['schemaVersion'] != 1) {
      throw const FormatException('Unsupported capture plan schema');
    }

    final host = root['host'];
    if (host is! String ||
        host != host.toLowerCase() ||
        !_hostnamePattern.hasMatch(host)) {
      throw const FormatException('Capture plan host must be exact');
    }

    final rawOperations = root['operations'];
    if (rawOperations is! List || rawOperations.isEmpty) {
      throw const FormatException('Capture plan operations must not be empty');
    }

    final operations = <PublicCaptureOperation>[];
    final ids = <String>{};
    final selectors = <String>{};
    for (final rawOperation in rawOperations) {
      final operation = _parseOperation(rawOperation);
      if (!ids.add(operation.id)) {
        throw const FormatException('Capture operation ids must be unique');
      }
      if (!selectors.add(operation.selectorKey)) {
        throw const FormatException(
          'Capture operation selectors must be unique',
        );
      }
      operations.add(operation);
    }

    return PublicContractCapturePlan._(host: host, operations: operations);
  }

  final String host;
  final List<PublicCaptureOperation> operations;
}

enum CaptureSkipReason {
  invalidEntry,
  unsupportedMethod,
  unsupportedOrigin,
  unplannedRequest,
}

class CapturedExchange {
  const CapturedExchange._({
    required this.id,
    required this.method,
    required this.uri,
    required this.queryParameters,
    required this.statusCode,
    required this.responseJson,
  });

  final String id;
  final String method;
  final Uri uri;
  final Map<String, List<String>> queryParameters;
  final int statusCode;
  final Object? responseJson;

  String get responseFixture => '$id.response.json';

  Map<String, Object?> toManifestJson() => {
        'id': id,
        'request': {
          'method': method,
          'scheme': uri.scheme,
          'host': uri.host,
          'path': uri.path,
          'query': [
            for (final parameter in queryParameters.entries)
              {'name': parameter.key, 'values': parameter.value},
          ],
        },
        'response': {
          'status': statusCode,
          'fixture': responseFixture,
          'topLevelType': switch (responseJson) {
            Map<String, Object?>() => 'object',
            List<Object?>() => 'array',
            _ => 'scalar',
          },
        },
      };
}

class PublicContractCaptureResult {
  PublicContractCaptureResult._({
    required this.host,
    required List<CapturedExchange> exchanges,
    required Map<CaptureSkipReason, int> skipped,
  })  : exchanges = List<CapturedExchange>.unmodifiable(exchanges),
        skipped = Map<CaptureSkipReason, int>.unmodifiable(skipped);

  final String host;
  final List<CapturedExchange> exchanges;
  final Map<CaptureSkipReason, int> skipped;

  Map<String, Object?> toManifestJson() => {
        'schemaVersion': 1,
        'source': 'sanitized-public-har',
        'host': host,
        'exchanges': [
          for (final exchange in exchanges) exchange.toManifestJson(),
        ],
      };
}

class PublicContractCapture {
  const PublicContractCapture(this.plan);

  final PublicContractCapturePlan plan;

  PublicContractCaptureResult extract(Object? har) {
    final entries = _harEntries(har);
    final matches = <String, CapturedExchange>{};
    final skipped = <CaptureSkipReason, int>{};

    void skip(CaptureSkipReason reason) {
      skipped.update(reason, (count) => count + 1, ifAbsent: () => 1);
    }

    for (final rawEntry in entries) {
      final entry = _stringMap(rawEntry);
      final request = _stringMap(entry?['request']);
      final response = _stringMap(entry?['response']);
      final method = request?['method'];
      final rawUrl = request?['url'];
      final status = response?['status'];

      if (entry == null ||
          request == null ||
          response == null ||
          method is! String ||
          rawUrl is! String ||
          status is! int ||
          status < 100 ||
          status > 599) {
        skip(CaptureSkipReason.invalidEntry);
        continue;
      }
      if (method.toUpperCase() != 'GET') {
        skip(CaptureSkipReason.unsupportedMethod);
        continue;
      }

      final uri = Uri.tryParse(rawUrl);
      if (!_hasExpectedOrigin(uri, plan.host)) {
        skip(CaptureSkipReason.unsupportedOrigin);
        continue;
      }

      final operation = _matchingOperation(uri!, status);
      if (operation == null) {
        skip(CaptureSkipReason.unplannedRequest);
        continue;
      }
      if (matches.containsKey(operation.id)) {
        throw StateError('A planned exchange matched more than once');
      }

      _validatePublicRequest(request, uri);
      final responseJson = _readResponseJson(response);
      matches[operation.id] = CapturedExchange._(
        id: operation.id,
        method: 'GET',
        uri: Uri(scheme: 'https', host: plan.host, path: operation.path),
        queryParameters: _redactedQuery(operation.query),
        statusCode: operation.statusCode,
        responseJson: responseJson,
      );
    }

    if (matches.length != plan.operations.length) {
      throw StateError('Every planned exchange must match exactly once');
    }

    return PublicContractCaptureResult._(
      host: plan.host,
      exchanges: [
        for (final operation in plan.operations) matches[operation.id]!,
      ],
      skipped: skipped,
    );
  }

  PublicCaptureOperation? _matchingOperation(Uri uri, int status) {
    final query = _sortedQuery(uri.queryParametersAll);
    for (final operation in plan.operations) {
      if (operation.path == uri.path &&
          operation.statusCode == status &&
          _queryEquals(operation.query, query)) {
        return operation;
      }
    }
    return null;
  }
}

void writeCapture(
  PublicContractCaptureResult capture,
  Directory outputDirectory,
) {
  final output = outputDirectory.absolute;
  if (FileSystemEntity.typeSync(output.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw StateError('Capture output must not already exist');
  }

  final fixtureNames = <String>{};
  for (final exchange in capture.exchanges) {
    if (!_captureIdPattern.hasMatch(exchange.id) ||
        !fixtureNames.add(exchange.responseFixture)) {
      throw StateError('Capture fixture ids must be unique and file-safe');
    }
  }

  final files = <String, String>{
    'manifest.json': _prettyJson(capture.toManifestJson()),
    for (final exchange in capture.exchanges)
      exchange.responseFixture: _prettyJson(exchange.responseJson),
  };

  final parent = output.parent;
  parent.createSync(recursive: true);
  final outputName =
      output.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
  final staging = parent.createTempSync('.$outputName.capture-');
  var published = false;
  try {
    for (final file in files.entries) {
      File('${staging.path}/${file.key}').writeAsStringSync(file.value);
    }

    if (FileSystemEntity.typeSync(output.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw StateError('Capture output appeared while publishing');
    }
    staging.renameSync(output.path);
    published = true;
  } finally {
    if (!published && staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }
  }
}

PublicCaptureOperation _parseOperation(Object? value) {
  final operation = _requiredStringMap(value, 'capture operation');
  _requireExactKeys(
    operation,
    const {'id', 'path', 'query', 'status'},
    'capture operation',
  );

  final id = operation['id'];
  if (id is! String || !_captureIdPattern.hasMatch(id)) {
    throw const FormatException('Capture operation id is invalid');
  }

  final path = operation['path'];
  if (path is! String || !_isPublicPath(path)) {
    throw const FormatException('Capture operation path is invalid');
  }

  final rawQuery = _requiredStringMap(operation['query'], 'operation query');
  final query = <String, List<String>>{};
  for (final entry in rawQuery.entries) {
    if (!_publicQueryNamePattern.hasMatch(entry.key) ||
        _isRequestCredentialName(entry.key)) {
      throw const FormatException('Capture query name is not public-safe');
    }
    final values = entry.value;
    if (values is! List ||
        values.isEmpty ||
        values.any((value) => value is! String)) {
      throw const FormatException(
        'Capture query values must be non-empty string lists',
      );
    }
    query[entry.key] = List<String>.from(values);
  }

  final status = operation['status'];
  if (status is! int || status < 100 || status > 599) {
    throw const FormatException('Capture operation status is invalid');
  }

  return PublicCaptureOperation._(
    id: id,
    path: path,
    query: _sortedQuery(query),
    statusCode: status,
  );
}

void _validatePublicRequest(Map<String, Object?> request, Uri uri) {
  if (request.containsKey('postData')) {
    throw StateError('Planned request contains a body field');
  }

  final headers = _requiredNameValueList(request['headers'], 'headers');
  for (final header in headers) {
    if (!_httpHeaderNamePattern.hasMatch(header.name)) {
      throw const FormatException('HAR header name is malformed');
    }
    final normalizedName = header.name.toLowerCase();
    if (_isRequestCredentialName(header.name) ||
        !_publicRequestHeaders.contains(normalizedName)) {
      throw StateError('Planned request contains a non-public header');
    }
    if (normalizedName == 'host' &&
        !_isExpectedHostHeader(header.value, uri.host)) {
      throw StateError('Planned request Host header contradicts its URL');
    }
  }

  final cookies = _requiredNameValueList(request['cookies'], 'cookies');
  if (cookies.isNotEmpty) {
    throw StateError('Planned request contains cookies');
  }

  final queryString =
      _requiredNameValueList(request['queryString'], 'queryString');
  final harQuery = _nameValueQuery(queryString);
  if (!_queryEquals(harQuery, _sortedQuery(uri.queryParametersAll))) {
    throw const FormatException('HAR query metadata does not match its URL');
  }
  if (harQuery.keys.any(_isRequestCredentialName)) {
    throw StateError('Planned request contains credential query data');
  }
}

Object? _readResponseJson(Map<String, Object?> response) {
  final content = _requiredStringMap(response['content'], 'response content');
  final rawText = content['text'];
  if (rawText is! String || rawText.isEmpty) {
    throw const FormatException('Planned response body is missing');
  }

  final encoding = content['encoding'];
  if (encoding != null && encoding != 'base64') {
    throw const FormatException('Planned response encoding is unsupported');
  }

  final responseText =
      encoding == 'base64' ? utf8.decode(base64Decode(rawText)) : rawText;
  return _redactSensitiveValues(jsonDecode(responseText));
}

List<Object?> _harEntries(Object? har) {
  final root = _requiredStringMap(har, 'HAR root');
  final log = _requiredStringMap(root['log'], 'HAR log');
  final entries = log['entries'];
  if (entries is! List) {
    throw const FormatException('Expected HAR log.entries to be a list');
  }
  return entries.cast<Object?>();
}

Map<String, Object?>? _stringMap(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) return null;
  return Map<String, Object?>.from(value);
}

Map<String, Object?> _requiredStringMap(Object? value, String description) {
  final result = _stringMap(value);
  if (result == null) {
    throw FormatException('$description must be an object');
  }
  return result;
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

class _NameValue {
  const _NameValue(this.name, this.value);

  final String name;
  final String value;
}

List<_NameValue> _requiredNameValueList(Object? value, String description) {
  if (value is! List) {
    throw FormatException('HAR $description must be a list');
  }

  final result = <_NameValue>[];
  for (final rawItem in value) {
    final item = _stringMap(rawItem);
    final name = item?['name'];
    final itemValue = item?['value'];
    if (item == null ||
        name is! String ||
        name.isEmpty ||
        itemValue is! String) {
      throw FormatException('HAR $description entry is malformed');
    }
    result.add(_NameValue(name, itemValue));
  }
  return result;
}

bool _hasExpectedOrigin(Uri? uri, String host) =>
    uri != null &&
    uri.scheme == 'https' &&
    uri.host == host &&
    (!uri.hasPort || uri.port == 443) &&
    uri.userInfo.isEmpty &&
    uri.fragment.isEmpty;

Map<String, List<String>> _nameValueQuery(List<_NameValue> values) {
  final result = <String, List<String>>{};
  for (final item in values) {
    result.putIfAbsent(item.name, () => <String>[]).add(item.value);
  }
  return _sortedQuery(result);
}

Map<String, List<String>> _sortedQuery(Map<String, List<String>> query) => {
      for (final name in query.keys.toList()..sort())
        name: List<String>.from(query[name]!),
    };

Map<String, List<String>> _redactedQuery(
  Map<String, List<String>> query,
) =>
    {
      for (final entry in query.entries)
        entry.key: List.filled(entry.value.length, _redactedValue),
    };

bool _queryEquals(
  Map<String, List<String>> left,
  Map<String, List<String>> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    final other = right[entry.key];
    if (other == null || other.length != entry.value.length) return false;
    for (var index = 0; index < entry.value.length; index++) {
      if (entry.value[index] != other[index]) return false;
    }
  }
  return true;
}

String _selectorKey(
  String path,
  Map<String, List<String>> query,
  int status,
) =>
    jsonEncode([path, _sortedQuery(query), status]);

bool _isPublicPath(String path) {
  if (!_publicPathPattern.hasMatch(path) || path.startsWith('//')) return false;
  final segments = path.split('/').where((segment) => segment.isNotEmpty);
  for (final segment in segments) {
    if (segment == '.' ||
        segment == '..' ||
        _isRequestCredentialName(segment)) {
      return false;
    }
  }
  return true;
}

Iterable<String> _nameTokens(String value) {
  final separated = value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
  return separated
      .toLowerCase()
      .split(RegExp('[^a-z0-9]+'))
      .where((token) => token.isNotEmpty);
}

bool _isRequestCredentialName(String value) {
  final tokens = _nameTokens(value);
  if (tokens.any(_requestCredentialNameTokens.contains)) return true;
  final normalized = value.toLowerCase().replaceAll(
        RegExp('[^a-z0-9]'),
        '',
      );
  return _requestCredentialNameFragments.any(normalized.contains) ||
      _requestCredentialNameStems.any(
        (stem) => normalized.startsWith(stem) || normalized.endsWith(stem),
      );
}

bool _isSensitiveResponseName(String value) {
  final tokens = _nameTokens(value);
  if (tokens.any(_sensitiveResponseNameTokens.contains)) return true;
  final normalized = value.toLowerCase().replaceAll(
        RegExp('[^a-z0-9]'),
        '',
      );
  return _sensitiveResponseNameFragments.any(normalized.contains) ||
      _sensitiveResponseNameStems.any(
        (stem) => normalized.startsWith(stem) || normalized.endsWith(stem),
      );
}

bool _isExpectedHostHeader(String value, String host) {
  final normalized = value.trim().toLowerCase();
  return normalized == host || normalized == '$host:443';
}

Object? _redactSensitiveValues(Object? value) {
  if (value is List) {
    return [for (final item in value) _redactSensitiveValues(item)];
  }
  if (value is Map) {
    final entries = <String, Object?>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    final hasTupleValue = entries.keys.any(
      (key) => key.toLowerCase() == 'value' || key.toLowerCase() == 'values',
    );
    final sensitiveTuple = hasTupleValue &&
        entries.entries
            .where(
              (entry) =>
                  entry.key.toLowerCase() == 'name' ||
                  entry.key.toLowerCase() == 'key',
            )
            .map((entry) => entry.value)
            .whereType<String>()
            .any(_isSensitiveResponseName);

    return {
      for (final entry in entries.entries)
        entry.key: (sensitiveTuple &&
                (entry.key.toLowerCase() == 'name' ||
                    entry.key.toLowerCase() == 'key'))
            ? _redactSensitiveValues(entry.value)
            : _isSensitiveResponseName(entry.key) ||
                    (sensitiveTuple &&
                        (entry.key.toLowerCase() == 'value' ||
                            entry.key.toLowerCase() == 'values'))
                ? _redactedValue
                : _redactSensitiveValues(entry.value),
    };
  }
  return value;
}

String _prettyJson(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';
