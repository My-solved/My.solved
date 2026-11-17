import 'dart:convert';
import 'dart:io';

import 'src/public_contract_capture.dart';

void main(List<String> arguments) {
  try {
    final options = _parseArguments(arguments);
    final har = jsonDecode(File(options.inputPath).readAsStringSync());
    final plan = PublicContractCapturePlan.fromJson(
      jsonDecode(File(options.planPath).readAsStringSync()),
    );
    final capture = PublicContractCapture(plan).extract(har);

    writeCapture(capture, Directory(options.outputPath));
    stdout.writeln(
      'Captured ${capture.exchanges.length} public exchanges in '
      '${options.outputPath}.',
    );
    if (capture.skipped.isNotEmpty) {
      stdout.writeln(
        'Skipped entries: '
        '${capture.skipped.entries.map((entry) => '${entry.key.name}=${entry.value}').join(', ')}',
      );
    }
  } on StateError {
    _fail('The HAR does not match the public plan or output is not new.');
  } on FormatException {
    _fail('The HAR or capture plan is not valid supported JSON.');
  } on FileSystemException {
    _fail('Could not read or write a capture file.');
  } on Object {
    _fail('Contract capture failed.');
  }
}

void _fail(String message) {
  stderr.writeln(message);
  stderr.writeln(_usage);
  exitCode = 64;
}

class _Options {
  const _Options({
    required this.inputPath,
    required this.planPath,
    required this.outputPath,
  });

  final String inputPath;
  final String planPath;
  final String outputPath;
}

_Options _parseArguments(List<String> arguments) {
  String? inputPath;
  String? planPath;
  String? outputPath;

  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length) {
      throw const FormatException('Every option must have a value');
    }
    final value = arguments[index + 1];
    switch (arguments[index]) {
      case '--input':
        inputPath = value;
      case '--plan':
        planPath = value;
      case '--output':
        outputPath = value;
      default:
        throw FormatException('Unknown option: ${arguments[index]}');
    }
  }

  if (inputPath == null || planPath == null || outputPath == null) {
    throw const FormatException('--input, --plan, and --output are required');
  }
  return _Options(
    inputPath: inputPath,
    planPath: planPath,
    outputPath: outputPath,
  );
}

const _usage = '''
Usage:
  dart run tool/capture_public_contract.dart \\
    --input /path/to/public.har \\
    --plan /path/to/reviewed-plan.json \\
    --output test/fixtures/public-capture
''';
