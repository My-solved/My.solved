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

  int _requestGeneration = 0;
  SearchSortMethod _committedSort = SearchSortMethod.id;
  SearchDirection _committedDirection = SearchDirection.asc;
  bool _committedShowSolvedProblem = true;

  SearchBloc({
    required this.searchRepository,
    required this.sharedPreferencesRepository,
  }) : super(
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
      _searchFilterShowSolvedProblemChanged,
    );
    on<SearchFilterShowProblemTagChanged>(_searchFilterShowProblemTagChanged);
    on<SearchFilterRandomRerolled>(_searchFilterRandomRerolled);
  }

  Future<void> _onInit(SearchInit event, Emitter<SearchState> emit) async {
    await _loadSearch(state.text, emit);
  }

  Future<void> _searchTextFieldOnChanged(
    SearchTextFieldOnChanged event,
    Emitter<SearchState> emit,
  ) async {
    _requestGeneration++;
    emit(
      state.copyWith(
        status: SearchStatus.initial,
        text: event.text,
        sort: _committedSort,
        direction: _committedDirection,
        showSolvedProblem: _committedShowSolvedProblem,
      ),
    );
  }

  Future<void> _searchTextFieldOnSummited(
    SearchTextFieldOnSummited event,
    Emitter<SearchState> emit,
  ) async {
    if (event.text.isEmpty) {
      _requestGeneration++;
      emit(
        state.copyWith(
          status: SearchStatus.initial,
          text: event.text,
          sort: _committedSort,
          direction: _committedDirection,
          showSolvedProblem: _committedShowSolvedProblem,
        ),
      );
      return;
    }

    await _loadSearch(event.text, emit);
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
    await _reloadProblems(emit, sort: event.sort);
  }

  Future<void> _searchFilterDirectionSelected(
    SearchFilterDirectionSelected event,
    Emitter<SearchState> emit,
  ) async {
    await _reloadProblems(emit, direction: event.direction);
  }

  Future<void> _searchFilterShowSolvedProblemChanged(
    SearchFilterShowSolvedProblemChanged event,
    Emitter<SearchState> emit,
  ) async {
    await _reloadProblems(emit, showSolvedProblem: event.isOn);
  }

  Future<void> _searchFilterShowProblemTagChanged(
    SearchFilterShowProblemTagChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(
      state.copyWith(
        showProblemTag: event.isOn,
        status: state.status.isLoading
            ? SearchStatus.loading
            : SearchStatus.success,
      ),
    );
  }

  Future<void> _searchFilterRandomRerolled(
    SearchFilterRandomRerolled event,
    Emitter<SearchState> emit,
  ) async {
    await _reloadProblems(emit, sort: SearchSortMethod.random);
  }

  Future<void> _loadSearch(String text, Emitter<SearchState> emit) async {
    final requestGeneration = ++_requestGeneration;
    final sort = state.sort;
    final direction = state.direction;
    final showSolvedProblem = state.showSolvedProblem;

    emit(state.copyWith(status: SearchStatus.loading, text: text));

    try {
      final handle = await sharedPreferencesRepository.requestHandle();
      if (!_isCurrent(requestGeneration)) return;

      final results = await Future.wait<SearchObject>([
        searchRepository.getProblems(
          _problemQuery(text, showSolvedProblem, handle),
          null,
          sort.value,
          direction.value,
        ),
        searchRepository.getUsers(text, null),
        searchRepository.getTags(text, null),
      ], eagerError: true);
      if (!_isCurrent(requestGeneration)) return;

      _commitFilters(sort, direction, showSolvedProblem);
      emit(
        state.copyWith(
          status: SearchStatus.success,
          text: text,
          problems: results[0],
          users: results[1],
          tags: results[2],
        ),
      );
    } catch (_) {
      if (_isCurrent(requestGeneration)) {
        emit(_failureState());
      }
    }
  }

  Future<void> _reloadProblems(
    Emitter<SearchState> emit, {
    SearchSortMethod? sort,
    SearchDirection? direction,
    bool? showSolvedProblem,
  }) async {
    final requestGeneration = ++_requestGeneration;
    final nextSort = sort ?? state.sort;
    final nextDirection = direction ?? state.direction;
    final nextShowSolvedProblem = showSolvedProblem ?? state.showSolvedProblem;
    final text = state.text;

    emit(
      state.copyWith(
        status: SearchStatus.loading,
        sort: nextSort,
        direction: nextDirection,
        showSolvedProblem: nextShowSolvedProblem,
      ),
    );

    try {
      final handle = await sharedPreferencesRepository.requestHandle();
      if (!_isCurrent(requestGeneration)) return;

      final problems = await searchRepository.getProblems(
        _problemQuery(text, nextShowSolvedProblem, handle),
        null,
        nextSort.value,
        nextDirection.value,
      );
      if (!_isCurrent(requestGeneration)) return;

      _commitFilters(nextSort, nextDirection, nextShowSolvedProblem);
      emit(
        state.copyWith(
          status: SearchStatus.success,
          problems: problems,
          sort: nextSort,
          direction: nextDirection,
          showSolvedProblem: nextShowSolvedProblem,
        ),
      );
    } catch (_) {
      if (_isCurrent(requestGeneration)) {
        emit(_failureState());
      }
    }
  }

  void _commitFilters(
    SearchSortMethod sort,
    SearchDirection direction,
    bool showSolvedProblem,
  ) {
    _committedSort = sort;
    _committedDirection = direction;
    _committedShowSolvedProblem = showSolvedProblem;
  }

  SearchState _failureState() {
    return state.copyWith(
      status: SearchStatus.failure,
      sort: _committedSort,
      direction: _committedDirection,
      showSolvedProblem: _committedShowSolvedProblem,
    );
  }

  bool _isCurrent(int requestGeneration) {
    return requestGeneration == _requestGeneration;
  }

  String _problemQuery(String text, bool showSolvedProblem, String? handle) {
    if (!showSolvedProblem || handle == null || handle.isEmpty) return text;
    if (text.isEmpty) return '-s@$handle';
    return '$text -s@$handle';
  }
}
