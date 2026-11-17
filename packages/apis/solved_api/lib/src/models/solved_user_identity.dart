/// Stable solved.ac account identity returned for an authenticated user.
///
/// The numeric account ID does not change; the handle can change.
final class SolvedUserIdentity {
  const SolvedUserIdentity({required this.id, required this.handle});

  final num id;
  final String handle;
}
