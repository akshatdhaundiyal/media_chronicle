import 'package:flutter_test/flutter_test.dart';
import 'package:media_chronicle/state/app_state.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';
import 'package:media_chronicle/features/stories/providers/stories_provider.dart';
import 'package:media_chronicle/features/stories/models/story_item.dart';
import 'package:media_chronicle/features/gallery/providers/gallery_provider.dart';
import 'package:media_chronicle/features/gallery/providers/yolo_face_provider.dart';
import 'package:media_chronicle/features/gallery/models/media_item.dart';

void main() {
  group('AppState Tests', () {
    test('Initial tab should be stories and active filters should be default', () {
      final appState = AppState();
      expect(appState.currentTab, AppTab.stories);
      expect(appState.activeGroupFilter, 'All');
      expect(appState.activeAlbumId, null);
      expect(appState.activeTagFilter, null);
    });

    test('Switching tabs and updating filters should notify', () {
      final appState = AppState();
      appState.changeTab(AppTab.gallery);
      expect(appState.currentTab, AppTab.gallery);

      appState.updateGroupFilter('Nature');
      expect(appState.activeGroupFilter, 'Nature');

      appState.updateAlbumFilter('album123');
      expect(appState.activeAlbumId, 'album123');

      appState.updateTagFilter('John');
      expect(appState.activeTagFilter, 'John');

      appState.clearAllFilters();
      expect(appState.activeGroupFilter, 'All');
      expect(appState.activeAlbumId, null);
      expect(appState.activeTagFilter, null);
    });
  });

  group('SettingsProvider Tests', () {
    test('Initial storage metrics and toggles', () {
      final provider = SettingsProvider();
      expect(provider.darkMode, true);
      expect(provider.enableNotifications, true);
      expect(provider.storageUsedGB, 2.4);
      expect(provider.storageTotalGB, 15.0);
      expect(provider.storageLimit, '2.4 GB / 15 GB');
    });

    test('Simulating storage increase updates metrics and format correctly', () {
      final provider = SettingsProvider();
      provider.simulateStorageIncrease(100.0); // added 100MB
      // 2.4 + 100/1024 = 2.4 + 0.097 = 2.497...
      expect(provider.storageUsedGB, closeTo(2.4976, 0.001));
      expect(provider.storageLimit, '2.5 GB / 15 GB');

      provider.simulateStorageIncrease(20000.0); // exceed limits
      expect(provider.storageUsedGB, 15.0);
      expect(provider.storageLimit, '15.0 GB / 15 GB');
    });
  });

  group('StoriesProvider Tests', () {
    test('Should insert and delete story chronicles', () {
      final provider = StoriesProvider();
      expect(provider.stories.length, 0);

      final story = StoryItem(
        id: 'story1',
        title: 'Trip to Paris',
        description: 'Vibrant cities...',
        date: DateTime.now(),
      );

      provider.addStory(story);
      expect(provider.stories.length, 1);
      expect(provider.stories.first.title, 'Trip to Paris');

      provider.deleteStory('story1');
      expect(provider.stories.length, 0);
    });
  });

  group('GalleryProvider & Immutability Tests', () {
    test('Ingestion, deduplication and album features', () async {
      final provider = GalleryProvider();
      expect(provider.items.length, 0);

      final item = MediaItem(
        id: 'media1',
        title: 'Sunset',
        type: 'image',
        date: DateTime.now(),
        url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
      );

      // Add item (autoTag disabled for synchronous testing)
      provider.addMediaItem(item, autoTag: false);
      expect(provider.items.length, 1);
      expect(provider.items.first.sha256, isNotNull);

      // Deduplication check
      provider.addMediaItem(item, autoTag: false); // try adding again
      expect(provider.items.length, 1); // should still be 1 (blocked duplicate)

      // Album operations
      provider.createAlbum('Vacation');
      expect(provider.albums.length, 1);
      expect(provider.albums.first.name, 'Vacation');

      final albumId = provider.albums.first.id;
      provider.addItemToAlbum(albumId, 'media1');
      expect(provider.albums.first.itemIds.contains('media1'), true);

      provider.removeItemFromAlbum(albumId, 'media1');
      expect(provider.albums.first.itemIds.contains('media1'), false);
    });
  });

  group('YoloFaceProvider Tests', () {
    test('Should register and update identified faces immutably', () {
      final provider = YoloFaceProvider();
      expect(provider.isYoloAvailable, true);

      final item = MediaItem(
        id: 'media1',
        title: 'Sunset Portrait',
        type: 'image',
        date: DateTime.now(),
        url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
      );

      // Run detection to populate faces
      final faces = provider.runYoloDetection(item);
      expect(faces.isNotEmpty, true);

      final face = faces.first;

      // Run manual label update
      provider.labelFace(
        face.id,
        'John Doe',
        isAgeVariant: false,
        parentSha256: item.sha256,
      );

      final updatedFace = provider.detectedFaces.firstWhere((f) => f.id == face.id);
      expect(updatedFace.name, 'John Doe');
      expect(updatedFace.isIdentified, true);
      
      // Verification of unmodifiable embeddings
      expect(() => updatedFace.embedding[0] = 5.0, throwsUnsupportedError);
    });
  });
}
