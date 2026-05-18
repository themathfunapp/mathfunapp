/// Anında Matematik oturumu kaydı sonucu (günlük 2 oyun → 5 altın).
class InstantMathSessionOutcome {
  final bool dailyRewardGranted;
  final int coinsGranted;
  final int sessionsToday;
  final bool rewardAlreadyClaimedToday;

  const InstantMathSessionOutcome({
    required this.dailyRewardGranted,
    required this.coinsGranted,
    required this.sessionsToday,
    required this.rewardAlreadyClaimedToday,
  });
}
