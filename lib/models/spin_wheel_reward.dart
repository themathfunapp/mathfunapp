/// Şans çarkı ödülü — `BadgeService` ve diğer servisler `game_mechanics` yüklemeden kullanabilsin (Web DDC).
class SpinWheelReward {
  final String id;
  final String name;
  final String emoji;
  final String type; // 'coins', 'xp', 'powerup', 'hint', 'life'
  final int value;
  final double probability; // 0-1 arası

  const SpinWheelReward({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.value,
    required this.probability,
  });

  static List<SpinWheelReward> get defaultRewards => [
        const SpinWheelReward(
          id: 'coins_50',
          name: '50 Altın',
          emoji: '🪙',
          type: 'coins',
          value: 50,
          probability: 0.25,
        ),
        const SpinWheelReward(
          id: 'coins_100',
          name: '100 Altın',
          emoji: '💰',
          type: 'coins',
          value: 100,
          probability: 0.15,
        ),
        const SpinWheelReward(
          id: 'coins_200',
          name: '200 Altın',
          emoji: '💎',
          type: 'coins',
          value: 200,
          probability: 0.05,
        ),
        const SpinWheelReward(
          id: 'stars_5',
          name: '5 Yıldız',
          emoji: '⭐',
          type: 'stars',
          value: 5,
          probability: 0.20,
        ),
        const SpinWheelReward(
          id: 'stars_10',
          name: '10 Yıldız',
          emoji: '🌟',
          type: 'stars',
          value: 10,
          probability: 0.10,
        ),
        const SpinWheelReward(
          id: 'hint_1',
          name: '1 İpucu',
          emoji: '💡',
          type: 'hint',
          value: 1,
          probability: 0.10,
        ),
        const SpinWheelReward(
          id: 'life_1',
          name: '1 Can',
          emoji: '❤️',
          type: 'life',
          value: 1,
          probability: 0.10,
        ),
        const SpinWheelReward(
          id: 'powerup_random',
          name: 'Rastgele Güç',
          emoji: '🎁',
          type: 'powerup',
          value: 1,
          probability: 0.05,
        ),
      ];
}
