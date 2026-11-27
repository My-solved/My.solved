/// The help center's published documents as a tree, from the official v4 API.
final class HelpTreeResult {
  const HelpTreeResult({required this.items});

  /// Root nodes in wire (reading) order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable at every depth.
  final List<HelpTreeNode> items;
}

/// One help document node.
final class HelpTreeNode {
  const HelpTreeNode({
    required this.path,
    required this.title,
    required this.hasPage,
    required this.children,
  });

  /// Raw response path. No request-side path pattern is applied.
  final String path;
  final String title;

  /// Whether this node has a page of its own.
  final bool hasPage;

  /// Child nodes in wire order. No relation between a child path and its
  /// parent path is inferred.
  final List<HelpTreeNode> children;
}
