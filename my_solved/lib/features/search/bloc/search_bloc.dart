import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

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
  emit(SearchLoading(text: event.text));
  Future.delayed(Duration(seconds: 1));
  emit(SearchSuccess(text: ""));
  // emit(SearchFailure(text: "", errorMessage: "네트워크 에러"));
}
