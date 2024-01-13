part of 'contest_filter_bloc.dart';

enum ContestVenues {
  atCoder("", "AtCoder"),
  bojOpen("", "BOJ Open"),
  codeForces("", "Codeforces"),
  programmers("", "Programmers"),
  others("", "Others");

  const ContestVenues(this.value, this.displayName);

  final String value;
  final String displayName;

  static List<ContestVenues> get allCases => [
        ContestVenues.atCoder,
        ContestVenues.bojOpen,
        ContestVenues.codeForces,
        ContestVenues.programmers,
        ContestVenues.others,
      ];
}

@immutable
class ContestFilterState extends Equatable {
  final List<ContestVenues> venues = ContestVenues.allCases;

  @override
  List<Object?> get props => [venues];
}
