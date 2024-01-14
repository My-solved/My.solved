import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'root_state.dart';
part 'root_event.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final String handle;

  RootBloc({required this.handle}) : super(RootState(handle: handle)) {
    on<NavigationBarItemTapped>(
      (event, emit) => emit(state.copyWith(tabIndex: event.tabIndex)),
    );
  }
}
