import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _sourceUrl = 'https://backstage.solved.ac/api/v4/openapi';
const _maximumDocumentBytes = 2 * 1024 * 1024;

const _relevantPaths = <String>[
  '/api/v4/affiliations/{id}',
  '/api/v4/bookmarks',
  '/api/v4/health',
  '/api/v4/me',
  '/api/v4/oauth/token',
  '/api/v4/posts/help/page',
  '/api/v4/posts/notice',
  '/api/v4/posts/notice/{slug}',
  '/api/v4/problems',
  '/api/v4/problems/{problemId}',
  '/api/v4/problems/{problemId}/reports',
  '/api/v4/problems/{problemId}/votes',
  '/api/v4/problems/{problemId}/votes/summary',
  '/api/v4/rankings/affiliation-board',
  '/api/v4/rankings/affiliations',
  '/api/v4/rankings/affiliations/{affiliationId}',
  '/api/v4/rankings/regions',
  '/api/v4/rankings/regions/{countryCode}',
  '/api/v4/rankings/tags',
  '/api/v4/rankings/tags/{key}',
  '/api/v4/rankings/users',
  '/api/v4/rankings/users/search',
  '/api/v4/search/analyze',
  '/api/v4/search/random-problem',
  '/api/v4/search/suggest',
  '/api/v4/site/stats',
  '/api/v4/sources',
  '/api/v4/sources/contests/{id}',
  '/api/v4/sources/groups/{id}',
  '/api/v4/sources/oj/{ojId}/contests/{nativeId}',
  '/api/v4/sources/oj/{ojId}/groups/{nativeId}',
  '/api/v4/tags',
  '/api/v4/tags/{key}',
  '/api/v4/users/{handle}',
  '/api/v4/users/{handle}/achievements',
  '/api/v4/users/{handle}/achievements/summary',
  '/api/v4/users/{handle}/badge-stand',
  '/api/v4/users/{handle}/bookmarks',
  '/api/v4/users/{handle}/bookmarks/{slug}',
  '/api/v4/users/{handle}/collection',
  '/api/v4/users/{handle}/activity/days',
  '/api/v4/users/{handle}/activity/feed',
  '/api/v4/users/{handle}/contributions',
  '/api/v4/users/{handle}/reputation',
  '/api/v4/users/{handle}/reputation/log',
  '/api/v4/users/{handle}/rating/history',
  '/api/v4/users/{handle}/tags/{key}/histogram',
  '/api/v4/achievements',
  '/api/v4/achievements/for-problem/{problemId}',
  '/api/v4/achievements/items/{kind}/{key}',
  '/api/v4/achievements/items/{kind}/{key}/holders',
];

Future<void> main(List<String> arguments) async {
  http.Client? client;
  try {
    final outputPath = _parseOutputPath(arguments);
    client = http.Client();
    final response = await client.get(
      Uri.parse(_sourceUrl),
      headers: const {'accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('OpenAPI download returned ${response.statusCode}');
    }
    if (response.bodyBytes.length > _maximumDocumentBytes) {
      throw const FormatException('OpenAPI document exceeds the size limit');
    }

    final source = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map,
    );
    final snapshot = _buildSnapshot(source);
    final output = File(outputPath);
    output.parent.createSync(recursive: true);
    final staged = File('$outputPath.tmp');
    final encoded = const JsonEncoder.withIndent('  ').convert(snapshot);
    staged.writeAsStringSync('$encoded\n');
    staged.renameSync(outputPath);
    stdout.writeln('Wrote official v4 contract snapshot to $outputPath.');
  } on TimeoutException {
    _fail('The official OpenAPI download timed out.');
  } on FormatException catch (error) {
    _fail('The official OpenAPI document is unsupported: ${error.message}');
  } on FileSystemException {
    _fail('Could not write the contract snapshot.');
  } on http.ClientException {
    _fail('Could not download the official OpenAPI document.');
  } on HttpException catch (error) {
    _fail(error.message);
  } finally {
    client?.close();
  }
}

Map<String, dynamic> _buildSnapshot(Map<String, dynamic> source) {
  if (source['openapi'] != '3.1.0') {
    throw FormatException('expected OpenAPI 3.1.0, got ${source['openapi']}');
  }
  final servers = List<dynamic>.from(source['servers'] as List);
  if (!servers.any(
    (server) => server is Map && server['url'] == 'https://solved.ac',
  )) {
    throw const FormatException('the solved.ac production server is missing');
  }

  final paths = Map<String, dynamic>.from(source['paths'] as Map);
  final allPaths = paths.keys.toList()..sort();
  final selectedPaths = <String, dynamic>{};
  for (final path in _relevantPaths) {
    final value = paths[path];
    if (value == null) {
      throw FormatException('required path is missing: $path');
    }
    selectedPaths[path] = value;
  }

  return {
    'source': _sourceUrl,
    'openapi': source['openapi'],
    'info': source['info'],
    'servers': servers,
    'security': source['security'],
    'securitySchemes': (source['components'] as Map?)?['securitySchemes'],
    'allPaths': allPaths,
    'paths': selectedPaths,
  };
}

String _parseOutputPath(List<String> arguments) {
  if (arguments.length != 2 || arguments.first != '--output') {
    throw const FormatException('--output is required exactly once');
  }
  final outputPath = arguments.last.trim();
  if (outputPath.isEmpty) {
    throw const FormatException('--output must not be empty');
  }
  return outputPath;
}

Never _fail(String message) {
  stderr.writeln(message);
  stderr.writeln(_usage);
  exit(64);
}

const _usage = '''
Usage:
  dart run tool/fetch_official_v4_contract.dart \\
    --output test/fixtures/v4/official_openapi_contract.json
''';
