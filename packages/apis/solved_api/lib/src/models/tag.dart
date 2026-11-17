class Tag {
  final String key;
  final bool isMeta;
  final int bojTagId;
  final int problemCount;
  final List<dynamic> displayNames;
  final List<dynamic> aliases;

  const Tag({
    required this.key,
    required this.isMeta,
    required this.bojTagId,
    required this.problemCount,
    required this.displayNames,
    required this.aliases,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      key: json['key'],
      isMeta: json['isMeta'],
      bojTagId: json['bojTagId'],
      problemCount: json['problemCount'],
      displayNames: json['displayNames'],
      aliases: json['aliases'],
    );
  }
}
