import 'problem_search_viewer_folder.dart';

/// One page of official v4 bookmark folders.
final class BookmarkFoldersResult {
  const BookmarkFoldersResult({
    required this.folders,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  /// Folders in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<BookmarkFolder> folders;

  /// Raw finite numbers. No bounds or relation to [folders] are implied, and
  /// the response page need not equal the requested page.
  final num total;
  final num page;
  final num pageSize;
}

/// Visibility of an official v4 bookmark folder.
enum BookmarkFolderVisibility {
  private('private'),
  unlisted('unlisted'),
  public('public');

  const BookmarkFolderVisibility(this.value);

  final String value;
}

/// One official v4 bookmark folder summary.
final class BookmarkFolder {
  const BookmarkFolder({
    required this.slug,
    required this.name,
    required this.description,
    required this.color,
    required this.visibility,
    required this.problemCount,
    required this.favoriteCount,
    required this.solvedCount,
    required this.owner,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Raw response slug. No request-side slug pattern is applied.
  final String slug;
  final String name;
  final String description;

  /// Required nullable color in the exact viewer-folder color set.
  final ProblemSearchViewerFolderColor? color;

  final BookmarkFolderVisibility visibility;

  /// Raw finite counts. The schema declares no bounds or relationships.
  final num problemCount;
  final num favoriteCount;

  /// Raw required nullable finite count.
  final num? solvedCount;

  final BookmarkFolderOwner owner;

  /// Raw `date-time` strings. They are not parsed or ordered.
  final String createdAt;
  final String updatedAt;
}

/// The owner of an official v4 bookmark folder.
final class BookmarkFolderOwner {
  const BookmarkFolderOwner({
    required this.id,
    required this.handle,
    required this.tier,
    required this.profileImageUrl,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String handle;

  /// Required nullable official tier. Non-null values are in the range 0..31.
  final int? tier;

  /// Raw required nullable response value. URI validity is not implied.
  final String? profileImageUrl;
}

/// The viewer's own bookmark folders, for the add-to-folder menu.
final class AccountBookmarkFoldersResult {
  const AccountBookmarkFoldersResult({required this.folders});

  /// Folders in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<AccountBookmarkFolder> folders;
}

/// One of the viewer's own bookmark folders.
final class AccountBookmarkFolder {
  const AccountBookmarkFolder({
    required this.folder,
    required this.containsProblem,
  });

  /// The fields shared exactly with a public bookmark folder.
  final BookmarkFolder folder;

  /// Raw flag. No meaning is inferred when no problem was requested.
  final bool containsProblem;
}
