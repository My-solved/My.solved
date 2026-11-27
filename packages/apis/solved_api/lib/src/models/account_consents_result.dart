import 'policy_result.dart';

/// Policy versions in force that the viewer has not agreed to.
final class AccountConsentsResult {
  const AccountConsentsResult({required this.pending});

  /// Pending versions in wire order, including duplicates. Empty when the
  /// account is up to date.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<PendingConsent> pending;
}

/// One policy version awaiting the viewer's agreement.
final class PendingConsent {
  const PendingConsent({
    required this.slug,
    required this.version,
    required this.label,
  });

  /// Only [PolicySlug.tos] or [PolicySlug.privacy], as the schema allows.
  final PolicySlug slug;

  /// Raw version and label strings. No format is inferred.
  final String version;
  final String label;
}
