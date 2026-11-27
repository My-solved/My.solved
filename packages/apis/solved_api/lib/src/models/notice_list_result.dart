/// One page of the official v4 notice board.
final class NoticeListResult {
  const NoticeListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  /// Notices in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<NoticeListItem> items;

  /// Raw integers. No bounds or relation to [items] are implied, and the
  /// response page need not equal the requested page.
  final int total;
  final int page;
  final int perPage;
}

/// One notice summary from the official v4 notice board.
final class NoticeListItem {
  const NoticeListItem({
    required this.path,
    required this.language,
    required this.title,
    required this.summary,
    required this.publishedAt,
    required this.pinned,
    required this.isNew,
    required this.coverImageUrl,
  });

  /// Raw post path. No request-side slug pattern is applied.
  final String path;

  /// Raw served language. It need not equal the requested language.
  final String language;

  final String title;

  /// Raw required nullable summary.
  final String? summary;

  /// Raw string. It is not parsed or ordered.
  final String publishedAt;

  final bool pinned;
  final bool isNew;

  /// Raw required nullable value. URI validity is not implied.
  final String? coverImageUrl;
}
