class SearchSuggestion {
  final List<dynamic> autocomplete;
  final List<dynamic> problems;
  final int problemCount;
  final List<dynamic> users;
  final int userCount;
  final List<dynamic> tags;
  final int tagCount;

  const SearchSuggestion({
    required this.autocomplete,
    required this.problems,
    required this.problemCount,
    required this.users,
    required this.userCount,
    required this.tags,
    required this.tagCount,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      autocomplete: json['autocomplete'],
      problems: json['problems'],
      problemCount: json['problemCount'],
      users: json['users'],
      userCount: json['userCount'],
      tags: json['tags'],
      tagCount: json['tagCount'],
    );
  }
}
