/// Version-neutral solved problem count for one profile tier.
class ProfileTierStat {
  const ProfileTierStat({
    required this.tier,
    required this.solvedCount,
  });

  final int tier;
  final int solvedCount;
}
