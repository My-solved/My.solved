import 'official_user_profile.dart';

/// The viewer's appealable or appealed bans, from the official v4 API.
final class AccountBansResult {
  const AccountBansResult({required this.items});

  /// Bans in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<AccountBan> items;
}

/// One of the viewer's bans.
final class AccountBan {
  const AccountBan({
    required this.ban,
    required this.id,
    required this.appealable,
    required this.appeal,
  });

  /// The four fields shared exactly with a public-profile ban.
  final OfficialUserProfileBan ban;

  /// Raw integer. The schema declares no bounds.
  final int id;

  /// Raw flag. No relation to [appeal] is implied.
  final bool appealable;

  /// Required nullable appeal.
  final BanAppeal? appeal;
}

/// Review status of a ban appeal.
enum BanAppealStatus {
  pending('pending'),
  granted('granted'),
  denied('denied');

  const BanAppealStatus(this.value);

  final String value;
}

/// The viewer's appeal against a ban.
final class BanAppeal {
  const BanAppeal({
    required this.status,
    required this.text,
    required this.appealedAt,
    required this.response,
  });

  final BanAppealStatus status;
  final String text;

  /// Raw string. It is not parsed.
  final String appealedAt;

  /// Raw required nullable staff response.
  final String? response;
}
