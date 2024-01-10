class ArenaContest {
  final int arenaId;
  final int arenaDisplayId;
  final String? divisionDisplayName;
  final String? divisionShortDisplayName;
  final bool arenaIdFixed;
  final int? arenaBojContestId;
  final String title;
  final bool isGrandArena;
  final int grandArenaId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime registerEndTime;
  final int ratedRangeStart;
  final int ratedRangeEnd;
  final bool isRated;
  final int ratedContestants;
  final int totalContestants;
  final bool isScoreBased;
  final bool isLevelSorted;
  final bool givesLanguageBonus;
  final int penaltyMinutes;
  final String? bojNoticeLink;
  final bool registrationOpen;
  final bool needsApproval;
  final bool needsAclToRegister;
  final bool cancellationDisabled;
  final List<String> languages;

  const ArenaContest({
    required this.arenaId,
    required this.arenaDisplayId,
    required this.divisionDisplayName,
    required this.divisionShortDisplayName,
    required this.arenaIdFixed,
    required this.arenaBojContestId,
    required this.title,
    required this.isGrandArena,
    required this.grandArenaId,
    required this.startTime,
    required this.endTime,
    required this.registerEndTime,
    required this.ratedRangeStart,
    required this.ratedRangeEnd,
    required this.isRated,
    required this.ratedContestants,
    required this.totalContestants,
    required this.isScoreBased,
    required this.isLevelSorted,
    required this.givesLanguageBonus,
    required this.penaltyMinutes,
    required this.bojNoticeLink,
    required this.registrationOpen,
    required this.needsApproval,
    required this.needsAclToRegister,
    required this.cancellationDisabled,
    required this.languages,
  });

  factory ArenaContest.fromJson(Map<String, dynamic> json) {
    return ArenaContest(
      arenaId: json['arenaId'],
      arenaDisplayId: json['arenaDisplayId'],
      divisionDisplayName: json['divisionDisplayName'],
      divisionShortDisplayName: json['divisionShortDisplayName'],
      arenaIdFixed: json['arenaIdFixed'],
      arenaBojContestId: json['arenaBojContestId'],
      title: json['title'],
      isGrandArena: json['isGrandArena'],
      grandArenaId: json['grandArenaId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      registerEndTime: DateTime.parse(json['registerEndTime']),
      ratedRangeStart: json['ratedRangeStart'],
      ratedRangeEnd: json['ratedRangeEnd'],
      isRated: json['isRated'],
      ratedContestants: json['ratedContestants'],
      totalContestants: json['totalContestants'],
      isScoreBased: json['isScoreBased'],
      isLevelSorted: json['isLevelSorted'],
      givesLanguageBonus: json['givesLanguageBonus'],
      penaltyMinutes: json['penaltyMinutes'],
      bojNoticeLink: json['bojNoticeLink'],
      registrationOpen: json['registrationOpen'],
      needsApproval: json['needsApproval'],
      needsAclToRegister: json['needsAclToRegister'],
      cancellationDisabled: json['cancellationDisabled'],
      languages: List<String>.from(json['languages'].map((x) => x)),
    );
  }
}
