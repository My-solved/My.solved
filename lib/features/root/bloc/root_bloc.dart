import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'root_event.dart';
part 'root_state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  RootBloc() : super(RootInitial()) {
    on<VersionInfoInit>(_onInitVersion);
    on<NavigationBarItemTapped>(_onItemTapped);
  }

  Future<void> _onInitVersion(
    VersionInfoInit event,
    Emitter<RootState> emit,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();
    emit(RootSuccess(tabIndex: state.tabIndex, version: packageInfo.version));
  }

  void _onItemTapped(
    NavigationBarItemTapped event,
    Emitter<RootState> emit,
  ) {
    emit(state.copyWith(tabIndex: event.tabIndex));
  }
}
