import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_chronicle/state/app_state.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';
import 'package:media_chronicle/features/stories/providers/stories_provider.dart';
import 'package:media_chronicle/features/stories/models/story_item.dart';
import 'package:media_chronicle/features/gallery/providers/gallery_provider.dart';
import 'package:media_chronicle/features/gallery/providers/yolo_face_provider.dart';
import 'package:media_chronicle/features/gallery/models/media_item.dart';
import 'package:media_chronicle/core/utils/postgres_sync_service.dart';

void main() {
  group('AppState Tests', () {
    test('Initial tab should be stories and active filters should be default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);
      expect(state.currentTab, AppTab.stories);
      expect(state.activeGroupFilter, 'All');
      expect(state.activeAlbumId, null);
      expect(state.activeTagFilter, null);
    });

    test('Switching tabs and updating filters should notify', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);

      notifier.changeTab(AppTab.gallery);
      expect(container.read(appStateProvider).currentTab, AppTab.gallery);

      notifier.updateGroupFilter('Nature');
      expect(container.read(appStateProvider).activeGroupFilter, 'Nature');

      notifier.updateAlbumFilter('album123');
      expect(container.read(appStateProvider).activeAlbumId, 'album123');

      notifier.updateTagFilter('John');
      expect(container.read(appStateProvider).activeTagFilter, 'John');

      notifier.clearAllFilters();
      expect(container.read(appStateProvider).activeGroupFilter, 'All');
      expect(container.read(appStateProvider).activeAlbumId, null);
      expect(container.read(appStateProvider).activeTagFilter, null);
    });
  });

  group('SettingsProvider Tests', () {
    test('Initial storage metrics and toggles', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsProvider);
      expect(state.darkMode, true);
      expect(state.enableNotifications, true);
      expect(state.storageUsedGB, 2.4);
      expect(state.storageTotalGB, 15.0);
      expect(state.storageLimit, '2.4 GB / 15 GB');
    });

    test('Simulating storage increase updates metrics and format correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      notifier.simulateStorageIncrease(100.0); // added 100MB
      // 2.4 + 100/1024 = 2.4 + 0.097 = 2.497...
      expect(container.read(settingsProvider).storageUsedGB, closeTo(2.4976, 0.001));
      expect(container.read(settingsProvider).storageLimit, '2.5 GB / 15 GB');

      notifier.simulateStorageIncrease(20000.0); // exceed limits
      expect(container.read(settingsProvider).storageUsedGB, 15.0);
      expect(container.read(settingsProvider).storageLimit, '15.0 GB / 15 GB');
    });
  });

  group('StoriesProvider Tests', () {
    test('Should insert and delete story chronicles', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(storiesProvider).length, 0);

      final story = StoryItem(
        id: 'story1',
        title: 'Trip to Paris',
        description: 'Vibrant cities...',
        date: DateTime.now(),
      );

      final notifier = container.read(storiesProvider.notifier);
      notifier.addStory(story);
      expect(container.read(storiesProvider).length, 1);
      expect(container.read(storiesProvider).first.title, 'Trip to Paris');

      notifier.deleteStory('story1');
      expect(container.read(storiesProvider).length, 0);
    });
  });

  group('GalleryProvider & Immutability Tests', () {
    test('Ingestion, deduplication and album features', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sub = container.listen(galleryProvider, (previous, next) {});
      addTearDown(sub.close);

      final notifier = container.read(galleryProvider.notifier);
      expect(container.read(galleryProvider).items.length, 0);

      final item = MediaItem(
        id: 'media1',
        title: 'Sunset',
        type: 'image',
        date: DateTime.now(),
        url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
      );

      // Add item (autoTag disabled for synchronous testing)
      notifier.addMediaItem(item, autoTag: false);
      expect(container.read(galleryProvider).items.length, 1);
      expect(container.read(galleryProvider).items.first.sha256, isNotNull);

      // Deduplication check
      notifier.addMediaItem(item, autoTag: false); // try adding again
      expect(container.read(galleryProvider).items.length, 1); // should still be 1 (blocked duplicate)

      // Album operations
      notifier.createAlbum('Vacation');
      expect(container.read(galleryProvider).albums.length, 1);
      expect(container.read(galleryProvider).albums.first.name, 'Vacation');

      final albumId = container.read(galleryProvider).albums.first.id;
      notifier.addItemToAlbum(albumId, 'media1');
      expect(container.read(galleryProvider).albums.first.itemIds.contains('media1'), true);

      notifier.removeItemFromAlbum(albumId, 'media1');
      expect(container.read(galleryProvider).albums.first.itemIds.contains('media1'), false);
    });
  });

  group('PostgresSync Tests', () {
    test('Initial connection state and toggle connection', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sub = container.listen(postgresSyncProvider, (previous, next) {});
      addTearDown(sub.close);

      final state = container.read(postgresSyncProvider);
      expect(state.isConnected, false);
      expect(state.syncedRecords, 0);

      final notifier = container.read(postgresSyncProvider.notifier);
      // Toggle connection to false should succeed in resetting connection
      await notifier.toggleConnection(false);
      expect(container.read(postgresSyncProvider).isConnected, false);

      // Toggle connection to true with invalid host should log failure and stay disconnected
      await notifier.toggleConnection(true, host: 'invalid-host-for-test');
      expect(container.read(postgresSyncProvider).isConnected, false);
      expect(container.read(postgresSyncProvider).syncLogs.any((log) => log.contains('Connection Failed')), true);
    });
  });

  group('YoloFace Tests', () {
    test('Should register and update identified faces immutably', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(yoloFaceProvider.notifier);
      expect(container.read(yoloFaceProvider).isYoloAvailable, true);

      final item = MediaItem(
        id: 'media1',
        title: 'Sunset Portrait',
        type: 'image',
        date: DateTime.now(),
        url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
      );

      // Run detection to populate faces
      final faces = notifier.runYoloDetection(item);
      expect(faces.isNotEmpty, true);

      final face = faces.first;

      // Run manual label update
      notifier.labelFace(
        face.id,
        'John Doe',
        isAgeVariant: false,
        parentSha256: item.sha256,
      );

      final updatedFace = container.read(yoloFaceProvider).detectedFaces.firstWhere((f) => f.id == face.id);
      expect(updatedFace.name, 'John Doe');
      expect(updatedFace.isIdentified, true);
      
      // Verification of unmodifiable embeddings
      expect(() => updatedFace.embedding[0] = 5.0, throwsUnsupportedError);
    });
  });
}
