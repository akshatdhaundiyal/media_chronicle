import 'package:flutter/foundation.dart';

enum AppTab { stories, gallery, explorer, settings, yolo }

class AppState extends ChangeNotifier {
  AppTab _currentTab = AppTab.stories;
  String _searchQuery = '';
  String _activeGroupFilter = 'All';
  String? _activeTagFilter;
  String? _activeAlbumId;

  AppTab get currentTab => _currentTab;
  String get searchQuery => _searchQuery;
  String get activeGroupFilter => _activeGroupFilter;
  String? get activeTagFilter => _activeTagFilter;
  String? get activeAlbumId => _activeAlbumId;

  void changeTab(AppTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateGroupFilter(String filter) {
    if (_activeGroupFilter != filter) {
      _activeGroupFilter = filter;
      _activeAlbumId = null; // Clear album filter if group category changes
      _activeTagFilter = null; // Clear tag filter if category changes
      notifyListeners();
    }
  }

  void updateTagFilter(String? tag) {
    if (_activeTagFilter != tag) {
      _activeTagFilter = tag;
      notifyListeners();
    }
  }

  void updateAlbumFilter(String? albumId) {
    if (_activeAlbumId != albumId) {
      _activeAlbumId = albumId;
      _activeGroupFilter = 'All'; // Reset group filter if active album selected
      _activeTagFilter = null; // Reset tag filter
      notifyListeners();
    }
  }

  void clearAllFilters() {
    _activeGroupFilter = 'All';
    _activeTagFilter = null;
    _activeAlbumId = null;
    _searchQuery = '';
    notifyListeners();
  }
}
