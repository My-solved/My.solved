import 'problem_reports_result.dart';
import 'problem_search_title.dart';

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

/// One month of the viewer's Stardust history.
final class WalletHistoryResult {
  const WalletHistoryResult({required this.month, required this.moves});

  /// Raw served month. It need not equal the requested month.
  final String month;

  /// Moves in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<WalletMove> moves;
}

/// Why Stardust moved.
enum WalletMoveReason {
  migration('migration'),
  welcome('welcome'),
  firstSolve('first_solve'),
  solve('solve'),
  contribute('contribute'),
  shopPurchase('shop_purchase'),
  redeem('redeem'),
  admin('admin');

  const WalletMoveReason(this.value);

  final String value;
}

/// One Stardust move.
final class WalletMove {
  const WalletMove({
    required this.id,
    required this.delta,
    required this.balanceAfter,
    required this.reason,
    required this.at,
    required this.day,
    required this.problem,
    required this.label,
  });

  /// Raw integers. No arithmetic relation between moves is implied.
  final int id;
  final int delta;
  final int balanceAfter;

  final WalletMoveReason reason;

  /// Raw strings. They are not parsed.
  final String at;
  final String? day;

  /// Required nullable problem.
  final WalletMoveProblem? problem;

  /// Raw required nullable label.
  final String? label;
}

/// The problem behind a Stardust move.
final class WalletMoveProblem {
  const WalletMoveProblem({required this.problem, required this.titles});

  /// The seven fields shared exactly with a report's same-problem entry.
  final ProblemReportSameProblem problem;

  /// Titles in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProblemSearchTitle> titles;
}
