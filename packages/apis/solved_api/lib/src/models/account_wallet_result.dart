/// The viewer's official v4 Stardust wallet.
final class AccountWalletResult {
  const AccountWalletResult({
    required this.stardusts,
    required this.today,
    required this.earnings,
  });

  /// Raw integer balance. The schema declares no bounds.
  final int stardusts;

  final WalletToday today;
  final WalletEarnings earnings;
}

/// Today's capped Stardust earnings.
final class WalletToday {
  const WalletToday({
    required this.day,
    required this.earned,
    required this.cap,
  });

  /// Raw day string. No format or time zone is inferred.
  final String day;

  /// Raw integers. No bounds or relation between them are implied.
  final int earned;
  final int cap;
}

/// Stardust earning rates.
final class WalletEarnings {
  const WalletEarnings({
    required this.firstSolve,
    required this.solve,
    required this.contribute,
    required this.welcomePerSolve,
    required this.welcomeMax,
  });

  /// Raw integers. No bounds or relation between them are implied.
  final int firstSolve;
  final int solve;
  final int contribute;
  final int welcomePerSolve;
  final int welcomeMax;
}
