import 'package:flutter/foundation.dart';

enum AppTab { stories, gallery, settings }

class AppState extends ChangeNotifier {
  AppTab _currentTab = AppTab.stories;
  String _searchQuery = '';

  AppTab get currentTab => _currentTab;
  String get searchQuery => _searchQuery;

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
}
