class Grass {
  final int day;
  final int month;
  final int year;
  final int solvedCount;
  final bool isSolved;
  final bool isFrozen;
  final bool isRepaired;

  const Grass(
      {required this.day,
      required this.month,
      required this.year,
      required this.solvedCount,
      required this.isSolved,
      required this.isFrozen,
      required this.isRepaired});

  factory Grass.fromJson(Map<String, dynamic> json) {
    final int year = int.parse(json['date'].split('-')[0]);
    final int month = int.parse(json['date'].split('-')[1]);
    final int day = int.parse(json['date'].split('-')[2]);

    int solvedCount;
    bool isSolved;
    if (json['value'].runtimeType == int) {
      solvedCount = json['value'];
      isSolved = true;
    } else {
      solvedCount = 0;
      isSolved = false;
    }

    final bool isFrozen = json['value'] == 'frozen';
    final bool isRepaired = json['value'] == 'repaired';

    return Grass(
      year: year,
      month: month,
      day: day,
      solvedCount: solvedCount,
      isSolved: isSolved,
      isFrozen: isFrozen,
      isRepaired: isRepaired,
    );
  }
}
