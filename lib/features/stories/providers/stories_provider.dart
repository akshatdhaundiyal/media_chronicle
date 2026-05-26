import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../models/story_item.dart';

class StoriesProvider extends ChangeNotifier {
  final List<StoryItem> _stories = [];
  bool _isLoading = false;

  List<StoryItem> get stories => List.unmodifiable(_stories);
  bool get isLoading => _isLoading;

  StoriesProvider() {
    _loadInitialMockData();
  }

  void _loadInitialMockData() {
    _isLoading = true;
    for (var mock in AppConstants.initialMockStories) {
      _stories.add(StoryItem(
        id: mock['id']!,
        title: mock['title']!,
        description: mock['description']!,
        date: DateTime.now().subtract(const Duration(days: 10)),
        coverUrl: mock['coverUrl']!,
      ));
    }
    _isLoading = false;
    notifyListeners();
  }

  void addStory(StoryItem story) {
    _stories.insert(0, story);
    notifyListeners();
  }

  void deleteStory(String id) {
    _stories.removeWhere((story) => story.id == id);
    notifyListeners();
  }
}
