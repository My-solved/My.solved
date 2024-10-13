part of 'contest_filter_bloc.dart';

enum ContestVenue {
  bojOpen("BOJ Open", "BOJ Open"),
  atCoder("AtCoder", "AtCoder"),
  codeForces("Codeforces", "Codeforces"),
  olympiad("Olympiad", "Olympiad"),
  google("Google", "Google"),
  facebook("Facebook", "Facebook"),
  icpc("ICPC", "ICPC"),
  scpc("SCPC", "SCPC"),
  codeChef("CodeChef", "CodeChef"),
  topCoder("TopCoder", "TopCoder"),
  programmers("Programmers", "Programmers");

  const ContestVenue(this.value, this.displayName);

  final String value;
  final String displayName;

  static List<ContestVenue> get allCases => [
        ContestVenue.bojOpen,
        ContestVenue.atCoder,
        ContestVenue.codeForces,
        ContestVenue.olympiad,
        ContestVenue.google,
        ContestVenue.facebook,
        ContestVenue.icpc,
        ContestVenue.scpc,
        ContestVenue.codeChef,
        ContestVenue.topCoder,
        ContestVenue.programmers,
      ];
}

@immutable
class ContestFilterState extends Equatable {
  final List<ContestVenue> venues = ContestVenue.allCases;

  @override
  List<Object?> get props => [venues];
}
