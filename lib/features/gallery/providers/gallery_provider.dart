import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../models/media_item.dart';

class GalleryProvider extends ChangeNotifier {
  final List<MediaItem> _items = [];
  bool _isLoading = false;

  List<MediaItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  GalleryProvider() {
    _loadInitialMockData();
  }

  void _loadInitialMockData() {
    _isLoading = true;
    for (var mock in AppConstants.initialMockGallery) {
      _items.add(MediaItem(
        id: mock['id']!,
        url: mock['url']!,
        title: mock['title']!,
        type: mock['type']!,
        date: DateTime.now().subtract(const Duration(days: 30)), // Mock past date
      ));
    }
    _isLoading = false;
    notifyListeners();
  }

  void addMediaItem(MediaItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void deleteMediaItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
