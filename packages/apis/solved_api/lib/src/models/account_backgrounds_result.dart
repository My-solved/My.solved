/// Backgrounds the viewer may equip, from the official v4 API.
final class AccountBackgroundsResult {
  const AccountBackgroundsResult({required this.backgrounds});

  /// Backgrounds in wire (picker) order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<AccountBackground> backgrounds;
}

/// One background the viewer may equip.
final class AccountBackground {
  const AccountBackground({
    required this.id,
    required this.key,
    required this.backgroundImageUrl,
    required this.fallbackBackgroundImageUrl,
    required this.thumbnailImageUrl,
    required this.thumbnailPlaceholder,
    required this.isIllust,
    required this.category,
    required this.createdAt,
    required this.acquiredAt,
    required this.ownedUserCount,
  });

  /// Raw integer. The schema declares no bounds.
  final int id;

  final String key;

  /// Raw response values. URI validity is not implied.
  final String backgroundImageUrl;
  final String? fallbackBackgroundImageUrl;
  final String? thumbnailImageUrl;

  /// Raw required nullable placeholder. Its format is not inferred.
  final String? thumbnailPlaceholder;

  final bool isIllust;
  final String category;

  /// Raw strings. They are not parsed or ordered.
  final String createdAt;

  /// Raw required nullable string. Null need not mean the viewer lacks it.
  final String? acquiredAt;

  /// Raw integer. The schema declares no bounds.
  final int ownedUserCount;
}
