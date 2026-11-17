class UserSearchItem {
  const UserSearchItem({
    required this.handle,
    required this.profileImageUrl,
    required this.tier,
  });

  final String handle;
  final String? profileImageUrl;
  final int tier;

  factory UserSearchItem.fromJson(Map<String, dynamic> json) {
    return UserSearchItem(
      handle: json['handle'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      tier: json['tier'] as int,
    );
  }
}
