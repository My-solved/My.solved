import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_solved/features/login/bloc/login_bloc.dart';
import 'package:solved_api/solved_api.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  test('emits loading then success for an existing user', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(_userResponse), 200),
    );
    final bloc = _createLoginBloc(client);
    addTearDown(() async {
      await bloc.close();
      client.close();
    });

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        const LoginLoading(handle: 'w8385'),
        const LoginSuccess(handle: 'w8385'),
      ]),
    );

    bloc.add(LoginButtonTapped(handle: 'w8385'));

    await states;
  });

  test('emits loading then failure when the user request fails', () async {
    final client = MockClient((_) async => http.Response('not found', 404));
    final bloc = _createLoginBloc(client);
    addTearDown(() async {
      await bloc.close();
      client.close();
    });

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        const LoginLoading(handle: 'missing'),
        const LoginFailure(handle: '', errorMessage: 'User not found'),
      ]),
    );

    bloc.add(LoginButtonTapped(handle: 'missing'));

    await states;
  });
}

LoginBloc _createLoginBloc(http.Client client) {
  final apiClient = SolvedApiClient(httpClient: client, useProxy: false);
  return LoginBloc(
    userRepository: UserRepository(solvedApiClient: apiClient),
  );
}

final _userResponse = <String, Object?>{
  'handle': 'w8385',
  'bio': null,
  'badgeId': null,
  'backgroundId': 'default',
  'profileImageUrl': null,
  'solvedCount': 1,
  'voteCount': 0,
  'class': 1,
  'classDecoration': 'none',
  'rivalCount': 0,
  'reverseRivalCount': 0,
  'tier': 1,
  'rating': 1,
  'ratingByProblemsSum': 1,
  'ratingByClass': 0,
  'ratingBySolvedCount': 0,
  'ratingByVoteCount': 0,
  'maxStreak': 1,
  'coins': 0,
  'stardusts': 0,
  'joinedAt': '2020-01-01T00:00:00.000Z',
  'bannedUntil': '1970-01-01T00:00:00.000Z',
  'proUntil': '1970-01-01T00:00:00.000Z',
  'rank': 1,
};
