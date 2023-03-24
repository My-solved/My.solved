class Contest {
  final String venue;
  final String name;
  final String? url;
  final DateTime startTime;
  final DateTime endTime;

  const Contest({
    required this.venue,
    required this.name,
    required this.url,
    required this.startTime,
    required this.endTime,
  });
}
