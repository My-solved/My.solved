import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'root_state.dart';
part 'root_event.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final String handle;

  RootBloc({required this.handle})
      : super(RootInitial(handle: handle, tabIndex: 0)) {
    on<NavigationBarItemTapped>(_onNavigationBarItemTppaed);
  }

  void _onNavigationBarItemTppaed(
    NavigationBarItemTapped event,
    Emitter<RootState> emit,
  ) {
    emit(RootInitial(handle: handle, tabIndex: event.tabIndex));
  }
}
