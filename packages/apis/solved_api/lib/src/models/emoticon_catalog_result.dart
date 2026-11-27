/// The official v4 emoticon catalog with the viewer's ownership flags.
final class EmoticonCatalogResult {
  const EmoticonCatalogResult({required this.items});

  /// Items in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<EmoticonCatalogItem> items;
}

/// One emoticon in the official v4 catalog.
final class EmoticonCatalogItem {
  const EmoticonCatalogItem({
    required this.key,
    required this.url,
    required this.category,
    required this.displayName,
    required this.owned,
  });

  final String key;

  /// Raw response value. URI validity is not implied.
  final String url;

  final String category;

  /// Raw required nullable display name.
  final String? displayName;

  final bool owned;
}
