import 'problem_search_diagnostic.dart';

/// Diagnostics returned without executing an official v4 problem search.
final class ProblemSearchAnalysisResult {
  const ProblemSearchAnalysisResult({required this.diagnostics});

  /// Diagnostics in wire order.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<ProblemSearchDiagnostic> diagnostics;
}
