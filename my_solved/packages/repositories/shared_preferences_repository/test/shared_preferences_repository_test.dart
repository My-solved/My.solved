import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences_repository/shared_preferences_repository.dart';

void main() {
  group("UserRepository", () {
    late SharedPreferencesRepository sharedPreferencesRepository;

    setUp(() {
      sharedPreferencesRepository = SharedPreferencesRepository();
    });

    group("constructor", () {
      test("check instance injected", () {
        expect(SharedPreferencesRepository(), isNotNull);
      });
    });

    group("handle", () async {
      var handle = await sharedPreferencesRepository.requestHandle();
      expect(handle, isNull);

      await sharedPreferencesRepository.login(handle: "w8385");
      handle = await sharedPreferencesRepository.requestHandle();
      expect(handle, "w8385");

      await sharedPreferencesRepository.logout();
      handle = await sharedPreferencesRepository.requestHandle();
      expect(handle, isNull);
    });
  });
}
