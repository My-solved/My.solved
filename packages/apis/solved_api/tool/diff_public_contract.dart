import 'dart:io';

import 'src/public_contract_diff.dart';

void main(List<String> arguments) {
  try {
    final options = _parseArguments(arguments);
    final before = readPublicContractCapture(Directory(options.beforePath));
    final after = readPublicContractCapture(Directory(options.afterPath));
    stdout.write(
      prettyPublicContractDiff(diffPublicContractCaptures(before, after)),
    );
  } on FormatException {
    _fail('The capture directories are not valid sanitized captures.');
  } on FileSystemException {
    _fail('Could not read a capture directory.');
  } on Object {
    _fail('Contract diff failed.');
  }
}

void _fail(String message) {
  stderr.writeln(message);
  stderr.writeln(_usage);
  exitCode = 64;
}

class _Options {
  const _Options({required this.beforePath, required this.afterPath});

  final String beforePath;
  final String afterPath;
}

_Options _parseArguments(List<String> arguments) {
  String? beforePath;
  String? afterPath;

  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length) {
      throw const FormatException('Every option must have a value');
    }
    final value = arguments[index + 1];
    if (value.isEmpty) {
      throw const FormatException('Option values must not be empty');
    }
    switch (arguments[index]) {
      case '--before':
        if (beforePath != null) {
          throw const FormatException('--before must not be repeated');
        }
        beforePath = value;
      case '--after':
        if (afterPath != null) {
          throw const FormatException('--after must not be repeated');
        }
        afterPath = value;
      default:
        throw FormatException('Unknown option: ${arguments[index]}');
    }
  }

  if (beforePath == null || afterPath == null) {
    throw const FormatException('--before and --after are required');
  }
  return _Options(beforePath: beforePath, afterPath: afterPath);
}

const _usage = '''
Usage:
  dart run tool/diff_public_contract.dart \\
    --before /path/to/before-capture \\
    --after /path/to/after-capture
''';
