part of 'splash_bloc.dart';

@immutable
abstract class SplashEvent {
  const SplashEvent();
}

class SplashInit extends SplashEvent {
  final BuildContext context;

  const SplashInit({required this.context});
}
