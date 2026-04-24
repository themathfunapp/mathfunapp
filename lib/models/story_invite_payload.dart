import 'story_mode.dart';

/// Ebeveyn hikâye önizlemesinden aileye gönderilecek davet için dünya/bölüm kimlikleri.
class StoryInvitePayload {
  final String worldId;
  final String worldNameKey;
  final String chapterId;
  final String chapterNameKey;

  const StoryInvitePayload({
    required this.worldId,
    required this.worldNameKey,
    required this.chapterId,
    required this.chapterNameKey,
  });

  factory StoryInvitePayload.fromWorld(StoryWorld world) {
    if (world.chapters.isNotEmpty) {
      final c = world.chapters.first;
      return StoryInvitePayload(
        worldId: world.id,
        worldNameKey: world.nameKey,
        chapterId: c.id,
        chapterNameKey: c.nameKey,
      );
    }
    return StoryInvitePayload(
      worldId: world.id,
      worldNameKey: world.nameKey,
      chapterId: '${world.id}_activity',
      chapterNameKey: world.nameKey,
    );
  }

  factory StoryInvitePayload.forChapter(StoryWorld world, StoryChapter chapter) {
    return StoryInvitePayload(
      worldId: world.id,
      worldNameKey: world.nameKey,
      chapterId: chapter.id,
      chapterNameKey: chapter.nameKey,
    );
  }
}
