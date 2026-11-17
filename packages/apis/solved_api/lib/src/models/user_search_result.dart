import 'user_search_item.dart';

/// The official v4 user-search response.
///
/// [exact] and [items] are kept separate because the API contract does not
/// state whether an exact match is also present in [items].
final class UserSearchResult {
  const UserSearchResult({required this.exact, required this.items});

  final UserSearchItem? exact;
  final List<UserSearchItem> items;
}
