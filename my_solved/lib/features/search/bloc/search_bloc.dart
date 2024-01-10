import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchState()) {
    on<SearchTextFieldOnChanged>(
      (event, emit) => emit(state.copyWith(text: event.text)),
    );
    on<SearchTextFieldOnSummited>((event, emit) async {
      emit(state.copyWith(status: SearchStatus.loading));
      await Future.delayed(Duration(seconds: 1));
      emit(state.copyWith(status: SearchStatus.success));
    });
    on<SearchSegmentedControlTapped>(
      (event, emit) => emit(state.copyWith(currentIndex: event.index)),
    );
  }
}
