import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'contest_filter_event.dart';
part 'contest_filter_state.dart';

class ContestFilterBloc extends Bloc<ContestFilterEvent, ContestFilterState> {
  ContestFilterBloc() : super(ContestFilterState());
}
