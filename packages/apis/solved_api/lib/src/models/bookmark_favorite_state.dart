/// Whether the viewer favorites a folder, and the folder's favorite count,
/// after a favorite change.
final class BookmarkFavoriteState {
  const BookmarkFavoriteState({
    required this.isFavorite,
    required this.favoriteCount,
  });

  final bool isFavorite;

  /// Raw finite number. No relation to [isFavorite] is inferred.
  final num favoriteCount;
}
