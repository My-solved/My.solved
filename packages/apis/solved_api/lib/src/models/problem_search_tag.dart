/// One tag entry from the official v4 problem contract.
final class ProblemSearchTag {
  const ProblemSearchTag({
    required this.id,
    required this.key,
    required this.isMeta,
  });

  final num id;
  final String key;
  final bool isMeta;
}
