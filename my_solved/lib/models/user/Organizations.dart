class Organizations {
  final int organizationId;
  final String name;
  final String type;
  final int rating;
  final int userCount;
  final int voteCount;
  final int solvedCount;
  final String color;

  Organizations({
      required this.organizationId,
      required this.name,
      required this.type,
      required this.rating,
      required this.userCount,
      required this.voteCount,
      required this.solvedCount,
      required this.color,
  });

  factory Organizations.fromJson(Map<String, dynamic> json) {
    return Organizations(
      organizationId: json['organizationId'],
      name: json['name'],
      type: json['type'],
      rating: json['rating'],
      userCount: json['userCount'],
      voteCount: json['voteCount'],
      solvedCount: json['solvedCount'],
      color: json['color'],
    );
  }
}