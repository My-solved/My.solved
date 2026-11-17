/// Version-neutral badge image data consumed by profile surfaces.
///
/// This model represents the selected badge asset used by profile surfaces.
class ProfileBadgeAsset {
  const ProfileBadgeAsset({
    this.key,
    this.name,
    required this.imageUrl,
  });

  final String? key;
  final String? name;
  final String imageUrl;
}
