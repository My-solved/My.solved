/// Colors exposed by the official v4 problem `viewerFolders` field.
enum ProblemSearchViewerFolderColor {
  red('red'),
  violet('violet'),
  blue('blue'),
  teal('teal'),
  lime('lime'),
  yellow('yellow'),
  orange('orange');

  const ProblemSearchViewerFolderColor(this.value);

  final String value;
}

/// One viewer-folder association from the official v4 problem contract.
final class ProblemSearchViewerFolder {
  const ProblemSearchViewerFolder({
    required this.slug,
    required this.name,
    required this.color,
  });

  final String slug;
  final String name;
  final ProblemSearchViewerFolderColor? color;
}
