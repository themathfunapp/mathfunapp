/// Sonsuz mod günlük 5 dakika oyun → 5 altın (çıkışta).
class EndlessDailyRewardOutcome {
  final bool rewardGranted;
  final int coinsGranted;

  const EndlessDailyRewardOutcome({
    required this.rewardGranted,
    required this.coinsGranted,
  });
}
