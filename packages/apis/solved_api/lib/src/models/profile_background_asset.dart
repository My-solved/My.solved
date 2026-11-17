/// Version-neutral background image data consumed by profile surfaces.
///
/// API contracts normalize their wire-specific background fields into this
/// model so UI code does not depend on solved.ac response keys.
class ProfileBackgroundAsset {
  const ProfileBackgroundAsset({
    required this.imageUrl,
    required this.fallbackImageUrl,
  });

  final String imageUrl;
  final String? fallbackImageUrl;
}
