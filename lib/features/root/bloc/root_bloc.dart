import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'root_event.dart';
part 'root_state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final String handle;

  RootBloc({required this.handle}) : super(RootState(handle: handle)) {
    on<VersionInfoInit>(
      (event, emit) async {
        final packageInfo = await PackageInfo.fromPlatform();
        emit(state.copyWith(version: packageInfo.version));
      },
    );
    on<NavigationBarItemTapped>(
      (event, emit) => emit(state.copyWith(tabIndex: event.tabIndex)),
    );
  }
}
