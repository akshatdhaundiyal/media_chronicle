import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_state.g.dart';

enum AppTab { stories, gallery, explorer, settings, yolo }

@immutable
class AppStateData {
  final AppTab currentTab;
  final String searchQuery;
  final String activeGroupFilter;
  final String? activeTagFilter;
  final String? activeAlbumId;

  const AppStateData({
    required this.currentTab,
    required this.searchQuery,
    required this.activeGroupFilter,
    this.activeTagFilter,
    this.activeAlbumId,
  });

  AppStateData copyWith({
    AppTab? currentTab,
    String? searchQuery,
    String? activeGroupFilter,
    String? activeTagFilter,
    String? activeAlbumId,
    bool clearTag = false,
    bool clearAlbum = false,
  }) {
    return AppStateData(
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      activeGroupFilter: activeGroupFilter ?? this.activeGroupFilter,
      activeTagFilter: clearTag ? null : (activeTagFilter ?? this.activeTagFilter),
      activeAlbumId: clearAlbum ? null : (activeAlbumId ?? this.activeAlbumId),
    );
  }
}

@riverpod
class AppState extends _$AppState {
  @override
  AppStateData build() {
    return const AppStateData(
      currentTab: AppTab.stories,
      searchQuery: '',
      activeGroupFilter: 'All',
    );
  }

  void changeTab(AppTab tab) {
    if (state.currentTab != tab) {
      state = state.copyWith(currentTab: tab);
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateGroupFilter(String filter) {
    if (state.activeGroupFilter != filter) {
      state = state.copyWith(
        activeGroupFilter: filter,
        clearAlbum: true,
        clearTag: true,
      );
    }
  }

  void updateTagFilter(String? tag) {
    if (state.activeTagFilter != tag) {
      state = state.copyWith(
        activeTagFilter: tag,
        clearTag: tag == null,
      );
    }
  }

  void updateAlbumFilter(String? albumId) {
    if (state.activeAlbumId != albumId) {
      state = state.copyWith(
        activeAlbumId: albumId,
        activeGroupFilter: 'All',
        clearAlbum: albumId == null,
        clearTag: true,
      );
    }
  }

  void clearAllFilters() {
    state = AppStateData(
      currentTab: state.currentTab,
      searchQuery: '',
      activeGroupFilter: 'All',
      activeTagFilter: null,
      activeAlbumId: null,
    );
  }
}
