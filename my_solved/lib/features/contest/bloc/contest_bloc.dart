import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'contest_event.dart';
part 'contest_state.dart';

class ContestBloc extends Bloc<ContestEvent, ContestState> {
  ContestBloc() : super(ContestState()) {
    on<InitContest>((event, emit) async {
      await Future.delayed(Duration(seconds: 1));
      emit(state.copyWith(status: ContestStatus.success));
    });
    on<SegmentedControlTapped>(
      (event, emit) => emit(state.copyWith(currentIndex: event.index)),
    );
  }
}
