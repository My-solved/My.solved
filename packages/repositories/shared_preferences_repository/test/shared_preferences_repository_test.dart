import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("SharedPreferencesRepository", () {
    late SharedPreferencesRepository sharedPreferencesRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sharedPreferencesRepository = SharedPreferencesRepository();
    });

    group("constructor", () {
      test("check instance injected", () {
        expect(SharedPreferencesRepository(), isNotNull);
      });
    });

    group("handle", () {
      test("stores and removes the handle", () async {
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
  });
}
