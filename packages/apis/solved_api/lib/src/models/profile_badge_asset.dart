/// Version-neutral badge image data consumed by profile surfaces.
///
/// The complete `Badge` model remains available for badge inventory responses;
/// this smaller model represents the selected badge asset used by the home UI.
class ProfileBadgeAsset {
  const ProfileBadgeAsset({required this.imageUrl});

  final String imageUrl;
}
