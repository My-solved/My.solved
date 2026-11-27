import 'bookmark_folders_result.dart';
import 'problem_search_item.dart';

/// One official v4 bookmark folder and a page of its problems.
final class BookmarkFolderDetailResult {
  const BookmarkFolderDetailResult({
    required this.folder,
    required this.isOwner,
    required this.isFavorite,
    required this.levels,
    required this.problems,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final BookmarkFolder folder;

  /// Raw viewer flag. Anonymous requests do not imply a particular value.
  final bool isOwner;

  /// Raw required nullable viewer flag.
  final bool? isFavorite;

  /// Level buckets in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable, as is [problems].
  final List<BookmarkFolderLevel> levels;

  /// Problems in wire order, including duplicates.
  final List<BookmarkFolderProblem> problems;

  /// Raw finite numbers. No bounds or relation to [problems] are implied, and
  /// the response page need not equal the requested page.
  final num total;
  final num page;
  final num pageSize;
}

/// One level bucket of an official v4 bookmark folder.
final class BookmarkFolderLevel {
  const BookmarkFolderLevel({
    required this.level,
    required this.count,
    required this.solved,
  });

  /// Raw finite numbers. The schema declares no bounds or relationships.
  final num level;
  final num count;

  /// Raw required nullable finite number.
  final num? solved;
}

/// One problem in an official v4 bookmark folder.
final class BookmarkFolderProblem {
  const BookmarkFolderProblem({
    required this.problem,
    required this.note,
    required this.addedAt,
  });

  /// The problem, in the exact official v4 problem-search item shape.
  final ProblemSearchItem problem;

  /// Raw required nullable note.
  final String? note;

  /// Raw `date-time` string. It is not parsed or ordered.
  final String addedAt;
}
