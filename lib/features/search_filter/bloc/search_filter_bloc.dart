import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:solved_api/solved_api.dart';

part 'search_filter_event.dart';
part 'search_filter_state.dart';

class SearchFilterBloc extends Bloc<SearchFilterEvent, SearchFilterState> {
  SearchFilterBloc() : super(SearchFilterState());
}
