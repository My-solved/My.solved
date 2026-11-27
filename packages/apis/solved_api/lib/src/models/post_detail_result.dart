/// The board of an official v4 post.
enum PostBoard {
  notice('notice'),
  help('help');

  const PostBoard(this.value);

  final String value;
}

/// One official v4 post, shared by the notice board and the help center.
final class PostDetailResult {
  const PostDetailResult({
    required this.board,
    required this.path,
    required this.language,
    required this.languages,
    required this.title,
    required this.summary,
    required this.content,
    required this.publishedAt,
    required this.updatedAt,
    required this.pinned,
    required this.coverImageUrl,
    required this.basisDate,
    required this.breadcrumbs,
    required this.previous,
    required this.next,
  });

  final PostBoard board;

  /// Raw post path. No request-side slug pattern is applied.
  final String path;

  /// Raw served language. It need not equal the requested language.
  final String language;

  /// Raw available languages in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable, as is [breadcrumbs].
  final List<String> languages;

  final String title;

  /// Raw required nullable summary.
  final String? summary;

  /// The raw document object, recursively source-isolated and unmodifiable.
  ///
  /// The schema only requires `type: "doc"` and, when present, an array
  /// `content`. Every other key and node is kept as opaque JSON.
  final Map<String, Object?> content;

  /// Raw strings. They are not parsed or ordered.
  final String publishedAt;
  final String updatedAt;

  final bool pinned;

  /// Raw required nullable value. URI validity is not implied.
  final String? coverImageUrl;

  /// Raw required nullable string. It is not parsed.
  final String? basisDate;

  final List<PostLink> breadcrumbs;

  /// Required nullable neighbors. No ordering is implied.
  final PostLink? previous;
  final PostLink? next;
}

/// A titled link to another official v4 post.
final class PostLink {
  const PostLink({required this.path, required this.title});

  /// Raw post path.
  final String path;

  final String title;
}
