/// Severity values exposed by official v4 problem-search diagnostics.
enum ProblemSearchDiagnosticSeverity {
  error('error'),
  warning('warning');

  const ProblemSearchDiagnosticSeverity(this.value);

  final String value;
}

/// Codes exposed by official v4 problem-search diagnostics.
enum ProblemSearchDiagnosticCode {
  unknownFilter('unknown-filter'),
  unimplementedFilter('unimplemented-filter'),
  emptyValue('empty-value'),
  invalidValue('invalid-value'),
  unknownLang('unknown-lang'),
  invalidBoolean('invalid-boolean'),
  unclosedQuote('unclosed-quote'),
  unmatchedParen('unmatched-paren'),
  danglingOperator('dangling-operator'),
  ignoredInput('ignored-input'),
  unknownHandle('unknown-handle'),
  unknownTag('unknown-tag'),
  meWithoutViewer('me-without-viewer');

  const ProblemSearchDiagnosticCode(this.value);

  final String value;
}

/// One parser diagnostic returned by the official v4 problem search.
final class ProblemSearchDiagnostic {
  const ProblemSearchDiagnostic({
    required this.start,
    required this.end,
    required this.severity,
    required this.code,
    required this.messageKey,
    required this.message,
    required this.data,
  });

  final num start;
  final num end;
  final ProblemSearchDiagnosticSeverity severity;
  final ProblemSearchDiagnosticCode code;
  final String messageKey;
  final String message;

  /// Raw string metadata, or `null` when the optional wire field was absent.
  ///
  /// Decoder-produced maps are unmodifiable. An empty map is authoritative.
  final Map<String, String>? data;
}
