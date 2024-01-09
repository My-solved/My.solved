import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial(text: "")) {
    on<SearchTextFieldOnChanged>(_onChangeSearchTextField);
    on<SearchTextFieldOnSummited>(_onSummmitSearchTextField);
  }
}

Future<void> _onChangeSearchTextField(
  SearchTextFieldOnChanged event,
  Emitter<SearchState> emit,
) async {
  emit(SearchInitial(text: event.text));
}

Future<void> _onSummmitSearchTextField(
  SearchTextFieldOnSummited event,
  Emitter<SearchState> emit,
) async {
  emit(SearchInitial(text: event.text));
}
