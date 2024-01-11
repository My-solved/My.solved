import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:search_repository/search_repository.dart';
import 'package:solved_api/solved_api.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepository;

  SearchBloc({required this.searchRepository}) : super(SearchState()) {
    on<SearchTextFieldOnChanged>(
      (event, emit) => emit(state.copyWith(text: event.text)),
    );
    on<SearchTextFieldOnSummited>((event, emit) async {
      emit(state.copyWith(status: SearchStatus.loading));
      final result = await searchRepository.getSuggestions(event.text);
      await Future.delayed(Duration(seconds: 1));
      emit(state.copyWith(
        status: SearchStatus.success,
        result: result,
      ));
    });
    on<SearchSegmentedControlTapped>(
      (event, emit) => emit(state.copyWith(currentIndex: event.index)),
    );
  }
}
