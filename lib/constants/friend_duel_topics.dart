import '../models/game_mechanics.dart';

/// Arkadaşla yarış / düello — yalnızca bu konular.
const List<TopicType> kFriendDuelTopicTypes = [
  TopicType.counting,
  TopicType.addition,
  TopicType.subtraction,
  TopicType.multiplication,
  TopicType.geometry,
];

bool isFriendDuelTopic(TopicType topic) =>
    kFriendDuelTopicTypes.contains(topic);
