/// A solved.ac source identifier resolved from an external judge identifier.
final class SourceLookupResult {
  const SourceLookupResult({required this.id});

  /// Raw solved.ac identifier. The schema declares a number without bounds.
  final num id;
}
