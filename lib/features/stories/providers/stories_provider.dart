import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/story_item.dart';

part 'stories_provider.g.dart';

@riverpod
class Stories extends _$Stories {
  @override
  List<StoryItem> build() {
    return const [];
  }

  void addStory(StoryItem story) {
    state = [story, ...state];
  }

  void deleteStory(String id) {
    state = state.where((story) => story.id != id).toList();
  }
}
