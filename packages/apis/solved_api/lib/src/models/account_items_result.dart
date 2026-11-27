import 'profile_activity_result.dart';

/// The items the viewer holds, from the official v4 API.
final class AccountItemsResult {
  const AccountItemsResult({
    required this.items,
    required this.streakThemes,
    required this.vacation,
  });

  /// Items in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<AccountItem> items;

  final AccountStreakThemes streakThemes;

  /// Required nullable vacation, in the exact activity-day vacation shape.
  final ProfileActivityCurrentVacation? vacation;
}

/// Kinds of official v4 account items.
enum AccountItemKind {
  consumable('consumable'),
  equippable('equippable'),
  voucher('voucher'),
  keepsake('keepsake');

  const AccountItemKind(this.value);

  final String value;
}

/// One held item.
final class AccountItem {
  const AccountItem({
    required this.key,
    required this.kind,
    required this.effect,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.units,
    required this.maxUnits,
    required this.usable,
    required this.equipped,
    required this.progress,
    required this.stacks,
  });

  final String key;
  final AccountItemKind kind;

  /// Raw required nullable effect key.
  final String? effect;

  final String name;
  final String description;

  /// Raw response value. URI validity is not implied.
  final String imageUrl;

  /// Raw integers. No relation to each other or to [stacks] is implied.
  final int units;
  final int maxUnits;

  final bool usable;

  /// Raw required nullable flag.
  final bool? equipped;

  /// Required nullable progress.
  final AccountItemProgress? progress;

  /// Stacks in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<AccountItemStack> stacks;
}

/// Collection progress of an item.
final class AccountItemProgress {
  const AccountItemProgress({required this.held, required this.total});

  /// Raw integers. No bounds or relation are implied.
  final int held;
  final int total;
}

/// One stack of an item.
final class AccountItemStack {
  const AccountItemStack({
    required this.units,
    required this.expiresAt,
    required this.day,
    required this.usable,
    required this.counted,
  });

  /// Raw integer. The schema declares no bounds.
  final int units;

  /// Raw required nullable strings. They are not parsed.
  final String? expiresAt;
  final String? day;

  final bool usable;
  final bool counted;
}

/// The viewer's streak themes.
final class AccountStreakThemes {
  const AccountStreakThemes({required this.equipped, required this.owned});

  /// Raw equipped theme key. It need not appear in [owned].
  final String equipped;

  /// Owned themes in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<OwnedStreakTheme> owned;
}

/// One owned streak theme.
final class OwnedStreakTheme {
  const OwnedStreakTheme({required this.theme, required this.acquiredAt});

  final String theme;

  /// Raw required nullable string. It is not parsed.
  final String? acquiredAt;
}
