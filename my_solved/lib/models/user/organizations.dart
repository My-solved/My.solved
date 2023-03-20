import 'organization.dart';

class Organizations {
  final List<Organization> organizations;

  Organizations({
    required this.organizations,
  });

  factory Organizations.fromJson(List<dynamic> json) {
    List<Organization> organizations = <Organization>[];
    organizations = json.map((i) => Organization.fromJson(i)).toList();

    return Organizations(
      organizations: organizations,
    );
  }
}
