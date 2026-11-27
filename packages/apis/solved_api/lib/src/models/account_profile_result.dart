/// The viewer's own editable profile, from the official v4 API.
final class AccountProfileResult {
  const AccountProfileResult({required this.profile});

  final AccountProfile profile;
}

/// Every editable profile field beside its visibility flag.
///
/// Documented response bounds are enforced. No relation between a field and
/// its visibility flag is inferred.
final class AccountProfile {
  const AccountProfile({
    required this.bio,
    required this.profileImageUrl,
    required this.countryCode,
    required this.showCountry,
    required this.gender,
    required this.customGender,
    required this.pronouns,
    required this.showPronouns,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    required this.showBirthday,
    required this.showBirthYear,
    required this.name,
    required this.nameNative,
    required this.showName,
    required this.showDiscord,
    required this.showIcpc,
    required this.backgroundId,
  });

  /// Raw required nullable bio of at most 2000 code points.
  final String? bio;

  /// Raw required nullable value of at most 1024 code points. URI validity
  /// is not implied.
  final String? profileImageUrl;

  /// Required nullable two uppercase ASCII letters. No ISO list is applied.
  final String? countryCode;

  final bool showCountry;

  /// Raw gender code: exactly 0, 1, 2, or 9. No label is inferred.
  final num gender;

  /// Raw required nullable strings of at most 64 code points.
  final String? customGender;
  final String? pronouns;

  final bool showPronouns;

  /// Required nullable year from 1900 through 2100.
  final int? birthYear;

  /// Required nullable month from 1 through 12.
  final int? birthMonth;

  /// Required nullable day from 1 through 31. Calendar validity is not
  /// implied.
  final int? birthDay;

  final bool showBirthday;
  final bool showBirthYear;

  /// Raw required nullable names of at most 128 code points.
  final String? name;
  final String? nameNative;

  final bool showName;
  final bool showDiscord;
  final bool showIcpc;

  /// Raw required nullable integer. The schema declares no bounds.
  final int? backgroundId;
}
