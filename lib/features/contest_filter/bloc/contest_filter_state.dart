part of 'contest_filter_bloc.dart';

enum ContestVenue {
  bojOpen("BOJ Open", "BOJ Open"),
  atCoder("AtCoder", "AtCoder"),
  codeForces("Codeforces", "Codeforces"),
  icpc("ICPC", "ICPC"),
  leetCode("LeetCode", "LeetCode"),
  usaco("USACO", "USACO");

  const ContestVenue(this.value, this.displayName);

  final String value;
  final String displayName;

  static List<ContestVenue> get allCases => [
        ContestVenue.bojOpen,
        ContestVenue.atCoder,
        ContestVenue.codeForces,
        ContestVenue.icpc,
        ContestVenue.leetCode,
        ContestVenue.usaco,
      ];
}

@immutable
class ContestFilterState extends Equatable {
  final List<ContestVenue> venues = ContestVenue.allCases;

  @override
  List<Object?> get props => [venues];
}
