import 'package:user_repository/user_repository.dart';

import 'package:test/test.dart';

void main() {
  group("UserRepository", () {
    late UserRepository userRepository;

    setUp(() {
      userRepository = UserRepository();
    });

    group("constructor", () {
      test("check instance injected", () {
        expect(UserRepository(), isNotNull);
      });
    });

    group("handle", () async {
      var handle = await userRepository.requestHandle();
      expect(handle, isNull);

      await userRepository.login(handle: "w8385");
      handle = await userRepository.requestHandle();
      expect(handle, "w8385");

      await userRepository.logout();
      handle = await userRepository.requestHandle();
      expect(handle, isNull);
    });
  });
}
