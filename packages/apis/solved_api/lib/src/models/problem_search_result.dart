import 'problem_search_diagnostic.dart';
import 'problem_search_item.dart';
import 'search_object.dart';

/// An official v4 problem-search result with version-specific metadata.
final class ProblemSearchResult extends SearchObject<ProblemSearchItem> {
  const ProblemSearchResult({
    required super.count,
    required super.items,
    required this.page,
    required this.pageSize,
    required this.diagnostics,
    required this.seed,
  });

  /// Raw response page number.
  ///
  /// The response schema does not impose the integer or lower-bound rule used
  /// by the request parameter.
  final num page;

  /// Raw response page size, without assuming the documented default is fixed.
  final num pageSize;

  /// Parser diagnostics, or `null` when the optional wire field was absent.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<ProblemSearchDiagnostic>? diagnostics;

  /// Response seed, or `null` when the optional wire field was absent.
  ///
  /// Response values are preserved without applying request-side length rules.
  final String? seed;
}
