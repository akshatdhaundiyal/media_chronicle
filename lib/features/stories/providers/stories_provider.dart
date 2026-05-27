import 'package:flutter/foundation.dart';
import '../models/story_item.dart';

class StoriesProvider extends ChangeNotifier {
  final List<StoryItem> _stories = [];

  List<StoryItem> get stories => List.unmodifiable(_stories);

  StoriesProvider();

  void addStory(StoryItem story) {
    _stories.insert(0, story);
    notifyListeners();
  }

  void deleteStory(String id) {
    _stories.removeWhere((story) => story.id == id);
    notifyListeners();
  }
}
