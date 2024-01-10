import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'contest_event.dart';
part 'contest_state.dart';

class ContestBloc extends Bloc<ContestEvent, ContestState> {
  ContestBloc() : super(ContestInitial()) {
    on<InitContest>(_onContestInit);
    on<SegmentedControlTapped>(_onSegmentedControlTapped);
  }
}

Future<void> _onContestInit(
  InitContest event,
  Emitter<ContestState> emit,
) async {
  Future.delayed(Duration(seconds: 1));
  emit(ContestSuccess(processingContest: [], expiredContest: []));
}

Future<void> _onSegmentedControlTapped(
  SegmentedControlTapped event,
  Emitter<ContestState> emit,
) async {
  emit(ContestInitial(current: event.index));
  Future.delayed(Duration(seconds: 1));
  emit(ContestSuccess(
    current: event.index,
    processingContest: [],
    expiredContest: [],
  ));
}
