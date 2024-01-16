import 'package:boj_api/boj_api.dart';
import 'package:contest_repository/contest_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_solved/features/contest_filter/bloc/contest_filter_bloc.dart';

part 'contest_event.dart';
part 'contest_state.dart';

class ContestBloc extends Bloc<ContestEvent, ContestState> {
  final ContestRepository contestRepository;

  ContestBloc({required this.contestRepository})
      : super(ContestState(
          filters: {
            ContestVenue.atCoder: true,
            ContestVenue.bojOpen: true,
            ContestVenue.codeForces: true,
            ContestVenue.programmers: true,
            ContestVenue.others: true,
          },
        )) {
    on<InitContest>((event, emit) async {
      emit(state.copyWith(status: ContestStatus.loading));

      try {
        final result = await contestRepository.getContests();
        final endedContests = result[ContestType.ended];
        final ongoingContests = result[ContestType.ongoing];
        final upcomingContests = result[ContestType.upcoming];

        emit(state.copyWith(
          status: ContestStatus.success,
          endedContests: endedContests,
          ongoingContests: ongoingContests,
          upcomingContests: upcomingContests,
        ));
      } catch (e) {
        emit(state.copyWith(status: ContestStatus.failure));
      }
    });
    on<SegmentedControlTapped>(
      (event, emit) => emit(state.copyWith(currentIndex: event.index)),
    );
    on<ContestFilterToggleTapped>((event, emit) {
      emit(state.copyWith(status: ContestStatus.loading));

      var filters = state.filters;
      final current = filters[event.venue] ?? true;
      current ? filters[event.venue] = false : filters[event.venue] = true;

      emit(state.copyWith(status: ContestStatus.success, filters: filters));
    });
  }
}
