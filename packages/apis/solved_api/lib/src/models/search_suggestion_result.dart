/// The complete response from the official v4 search-suggestion endpoint.
final class SearchSuggestionResult {
  const SearchSuggestionResult({required this.suggestions});

  final List<SearchSuggestionItem> suggestions;
}

/// One value offered for an official v4 search filter.
final class SearchSuggestionItem {
  const SearchSuggestionItem({
    required this.value,
    required this.detail,
    required this.tier,
  });

  final String value;
  final String? detail;
  final int? tier;
}
