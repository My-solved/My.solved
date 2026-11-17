import 'dart:convert';
import 'dart:io';

import 'src/public_contract_capture.dart';

void main(List<String> arguments) {
  try {
    final options = _parseArguments(arguments);
    final input = File(options.inputPath).absolute;
    if (FileSystemEntity.typeSync(input.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FileSystemException('HAR input is not a real file');
    }

    final har = jsonDecode(input.readAsStringSync());
    final result = PublicHarInventory(options.host).inspect(har);
    stdout.write(
      '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
    );
  } on FormatException {
    _fail('The HAR, host, or command options are not valid.');
  } on FileSystemException {
    _fail('Could not read the HAR input.');
  } on Object {
    _fail('Public HAR inventory failed.');
  }
}

void _fail(String message) {
  stderr.writeln(message);
  stderr.writeln(_usage);
  exitCode = 64;
}

class _Options {
  const _Options({required this.inputPath, required this.host});

  final String inputPath;
  final String host;
}

_Options _parseArguments(List<String> arguments) {
  String? inputPath;
  String? host;

  if (arguments.length.isOdd) {
    throw const FormatException('Every option must have a value');
  }
  for (var index = 0; index < arguments.length; index += 2) {
    final value = arguments[index + 1];
    if (value.isEmpty) {
      throw const FormatException('Option values must not be empty');
    }
    switch (arguments[index]) {
      case '--input':
        if (inputPath != null) {
          throw const FormatException('--input must be specified once');
        }
        inputPath = value;
      case '--host':
        if (host != null) {
          throw const FormatException('--host must be specified once');
        }
        host = value;
      default:
        throw FormatException('Unknown option: ${arguments[index]}');
    }
  }

  if (inputPath == null || host == null) {
    throw const FormatException('--input and --host are required');
  }
  return _Options(inputPath: inputPath, host: host);
}

const _usage = '''
Usage:
  dart run tool/inventory_public_har.dart \\
    --input /path/to/signed-out-public.har \\
    --host solved.ac
''';
