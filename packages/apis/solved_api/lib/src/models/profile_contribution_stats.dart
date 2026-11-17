/// Version-neutral contribution summary from the v4 reputation endpoint.
class ProfileContributionStats {
  const ProfileContributionStats({
    required this.reputation,
    required this.scoringCount,
    required this.helpfulCount,
    required this.vouchedCount,
  });

  final int reputation;
  final int scoringCount;
  final int helpfulCount;
  final int vouchedCount;
}
