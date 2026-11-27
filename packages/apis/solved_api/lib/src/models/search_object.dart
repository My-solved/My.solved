class SearchObject<T> {
  /// The result count reported by the active API contract.
  final num count;
  final List<T> items;

  const SearchObject({required this.count, required this.items});
}
