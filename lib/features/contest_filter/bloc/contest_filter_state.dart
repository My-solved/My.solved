part of 'contest_filter_bloc.dart';

enum ContestVenue {
  atCoder("AtCoder", "AtCoder"),
  bojOpen("BOJ Open", "BOJ Open"),
  codeForces("Codeforces", "Codeforces"),
  programmers("Programmers", "Programmers"),
  others("Others", "Others");

  const ContestVenue(this.value, this.displayName);

  final String value;
  final String displayName;

  static List<ContestVenue> get allCases => [
        ContestVenue.atCoder,
        ContestVenue.bojOpen,
        ContestVenue.codeForces,
        ContestVenue.programmers,
        ContestVenue.others,
      ];
}

@immutable
class ContestFilterState extends Equatable {
  final List<ContestVenue> venues = ContestVenue.allCases;

  @override
  List<Object?> get props => [venues];
}
