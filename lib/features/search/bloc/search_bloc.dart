import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_solved/features/search_filter/bloc/search_filter_bloc.dart';
import 'package:search_repository/search_repository.dart';
import 'package:solved_api/solved_api.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepository;

  SearchBloc({required this.searchRepository})
      : super(
          SearchState(
            sort: SearchSortMethod.id,
            direction: SearchDirection.asc,
            showSolvedProblem: true,
          ),
        ) {
    on<SearchTextFieldOnChanged>(
      (event, emit) => emit(state.copyWith(
        status: SearchStatus.initial,
        text: event.text,
      )),
    );
    on<SearchTextFieldOnSummited>((event, emit) async {
      if (event.text.isNotEmpty) {
        emit(state.copyWith(status: SearchStatus.loading));

        try {
          final problems = await searchRepository.getProblems(
            event.text,
            null,
            state.sort.value,
            state.direction.value,
          );
          final users = await searchRepository.getUsers(event.text, null);
          final tags = await searchRepository.getTags(event.text, null);

          emit(state.copyWith(
            status: SearchStatus.success,
            problems: problems,
            users: users,
            tags: tags,
          ));
        } catch (e) {
          emit(state.copyWith(status: SearchStatus.failure));
        }
      }
    });
    on<SearchSegmentedControlTapped>(
      (event, emit) => emit(state.copyWith(currentIndex: event.index)),
    );
    on<SearchFilterSortMethodSelected>((event, emit) {
      emit(state.copyWith(sort: event.sort, status: SearchStatus.success));
    });
    on<SearchFilterDirectionSelected>(
      (event, emit) => emit(state.copyWith(direction: event.direction)),
    );
    on<SearchFilterShowSolvedProblemChanged>(
      (event, emit) => emit(state.copyWith(showSolvedProblem: event.isOn)),
    );
  }
}
