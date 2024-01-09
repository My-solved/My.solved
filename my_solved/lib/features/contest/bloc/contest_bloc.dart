import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'contest_event.dart';
part 'contest_state.dart';

class ContestBloc extends Bloc<ContestEvent, ContestState> {
  ContestBloc() : super(ContestInitial()) {
    on<SegmentedControlTapped>(_onSegmentedControlTapped);
  }
}

Future<void> _onSegmentedControlTapped(
  SegmentedControlTapped event,
  Emitter<ContestState> emit,
) async {
  emit(ContestInitial(current: event.index));
}
