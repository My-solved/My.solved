import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_solved/features/search_filter/bloc/search_filter_bloc.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:solved_api/solved_api.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepository;
  final SharedPreferencesRepository sharedPreferencesRepository;

  SearchBloc(
      {required this.searchRepository,
      required this.sharedPreferencesRepository})
      : super(
          SearchState(
            sort: SearchSortMethod.id,
            direction: SearchDirection.asc,
            showSolvedProblem: true,
          ),
        ) {
    on<SearchInit>(_onInit);
    on<SearchTextFieldOnChanged>(_searchTextFieldOnChanged);
    on<SearchTextFieldOnSummited>(_searchTextFieldOnSummited);
    on<SearchSegmentedControlTapped>(_searchSegmentedControlTapped);
    on<SearchFilterSortMethodSelected>(_searchFilterSortMethodSelected);
    on<SearchFilterDirectionSelected>(_searchFilterDirectionSelected);
    on<SearchFilterShowSolvedProblemChanged>(
        _searchFilterShowSolvedProblemChanged);
    on<SearchFilterShowProblemTagChanged>(_searchFilterShowProblemTagChanged);
    on<SearchFilterRandomRerolled>(_searchFilterRandomRerolled);
  }

  Future<void> _onInit(SearchInit event, Emitter<SearchState> emit) async {
    emit(state.copyWith(status: SearchStatus.loading));

    try {
      final handle = await sharedPreferencesRepository.requestHandle();
      final query =
          '${state.text} ${state.showSolvedProblem ? '-s@$handle' : ''}';
      final problems = await searchRepository.getProblems(
          query, null, state.sort.value, state.direction.value);
      final users = await searchRepository.getUsers(state.text, null);
      final tags = await searchRepository.getTags(state.text, null);

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

  Future<void> _searchTextFieldOnChanged(
    SearchTextFieldOnChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(
      status: SearchStatus.initial,
      text: event.text,
    ));
  }

  Future<void> _searchTextFieldOnSummited(
      SearchTextFieldOnSummited event, Emitter<SearchState> emit) async {
    if (event.text.isEmpty) {
      emit(state.copyWith(status: SearchStatus.initial));
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading));

    try {
      final handle = await sharedPreferencesRepository.requestHandle();
      final query =
          '${state.text} ${state.showSolvedProblem ? '-s@$handle' : ''}';
      final problems = await searchRepository.getProblems(
          query, null, state.sort.value, state.direction.value);
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

  Future<void> _searchSegmentedControlTapped(
    SearchSegmentedControlTapped event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(currentIndex: event.index));
  }

  Future<void> _searchFilterSortMethodSelected(
    SearchFilterSortMethodSelected event,
    Emitter<SearchState> emit,
  ) async {
    final handle = await sharedPreferencesRepository.requestHandle();
    final query =
        '${state.text} ${state.showSolvedProblem ? '-s@$handle' : ''}';
    final problems = await searchRepository.getProblems(
        query, null, event.sort.value, state.direction.value);

    emit(state.copyWith(
        problems: problems, sort: event.sort, status: SearchStatus.success));
  }

  Future<void> _searchFilterDirectionSelected(
    SearchFilterDirectionSelected event,
    Emitter<SearchState> emit,
  ) async {
    final handle = await sharedPreferencesRepository.requestHandle();
    final query =
        '${state.text} ${state.showSolvedProblem ? '-s@$handle' : ''}';
    final problems = await searchRepository.getProblems(
        query, null, state.sort.value, event.direction.value);

    emit(state.copyWith(
        problems: problems,
        direction: event.direction,
        status: SearchStatus.success));
  }

  Future<void> _searchFilterShowSolvedProblemChanged(
    SearchFilterShowSolvedProblemChanged event,
    Emitter<SearchState> emit,
  ) async {
    final handle = await sharedPreferencesRepository.requestHandle();
    final query = '${state.text} ${event.isOn ? '-s@$handle' : ''}';
    final problems = await searchRepository.getProblems(
        query, null, state.sort.value, state.direction.value);

    emit(state.copyWith(
        problems: problems,
        showSolvedProblem: event.isOn,
        status: SearchStatus.success));
  }

  Future<void> _searchFilterShowProblemTagChanged(
    SearchFilterShowProblemTagChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(
        showProblemTag: event.isOn, status: SearchStatus.success));
  }

  Future<void> _searchFilterRandomRerolled(
    SearchFilterRandomRerolled event,
    Emitter<SearchState> emit,
  ) async {
    final handle = await sharedPreferencesRepository.requestHandle();
    final query =
        '${state.text} ${state.showSolvedProblem ? '-s@$handle' : ''}';
    final problems = await searchRepository.getProblems(
      query,
      null,
      'random',
      state.direction.value,
    );
    emit(state.copyWith(
        sort: SearchSortMethod.random,
        problems: problems,
        status: SearchStatus.success));
  }
}
