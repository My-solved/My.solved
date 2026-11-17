class UserSearchItem {
  const UserSearchItem({
    required this.handle,
    required this.profileImageUrl,
    required this.tier,
  });

  final String handle;
  final String? profileImageUrl;
  final int tier;
}
