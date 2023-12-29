import 'organization.dart';

class Organizations {
  final List<Organization> organizations;

  Organizations({
    required this.organizations,
  });

  factory Organizations.fromJson(List<dynamic> json) {
    return Organizations(
      organizations: json
          .map((i) => Organization.fromJson(i))
          .toList()
          .cast<Organization>(),
    );
  }
}
