import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/llm_helper.dart';
import '../../../core/utils/postgres_sync_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/media_item.dart';
import '../models/album.dart';

part 'gallery_provider.g.dart';

class _VlmTask {
  final MediaItem item;
  final String ollamaUrl;
  final String ollamaModel;
  final String? preIdentifiedFaces;
  final Function(MediaItem)? onComplete;
  final Function(String)? onError;

  _VlmTask({
    required this.item,
    required this.ollamaUrl,
    required this.ollamaModel,
    this.preIdentifiedFaces,
    this.onComplete,
    this.onError,
  });
}

@immutable
class GalleryState {
  final List<MediaItem> items;
  final List<Album> albums;
  final bool isLlmAvailable;
  final List<String> pulledModels;

  const GalleryState({
    required this.items,
    required this.albums,
    required this.isLlmAvailable,
    required this.pulledModels,
  });

  GalleryState copyWith({
    List<MediaItem>? items,
    List<Album>? albums,
    bool? isLlmAvailable,
    List<String>? pulledModels,
  }) {
    return GalleryState(
      items: items ?? this.items,
      albums: albums ?? this.albums,
      isLlmAvailable: isLlmAvailable ?? this.isLlmAvailable,
      pulledModels: pulledModels ?? this.pulledModels,
    );
  }
}

@riverpod
class Gallery extends _$Gallery {
  /// Periodic timer polling the Ollama endpoint to trace server availability states.
  Timer? _llmPoller;
  String? _lastPolledUrl;

  /// Single-threaded sequential VLM queue to avoid resource starvation or server crashes.
  final List<_VlmTask> _vlmQueue = [];
  
  /// Lock guard ensuring only one sequential task is run at a time.
  bool _isProcessingVlm = false;

  @override
  GalleryState build() {
    // Listen to settingsProvider changes to restart poller when url changes
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (previous?.ollamaUrl != next.ollamaUrl) {
        startLlmPoller(next.ollamaUrl);
      }
    });

    // Start poller once on initialization
    Future.microtask(() {
      final currentUrl = ref.read(settingsProvider).ollamaUrl;
      startLlmPoller(currentUrl);
    });

    ref.onDispose(() {
      _llmPoller?.cancel();
    });

    return const GalleryState(
      items: [],
      albums: [],
      isLlmAvailable: false,
      pulledModels: [],
    );
  }

  /// Queries the target endpoint url to retrieve LLM status details.
  Future<void> checkLlmConnection(String endpointUrl) async {
    final status = await LlmHelper.checkLlmAvailability(endpointUrl);
    if (state.isLlmAvailable != status) {
      state = state.copyWith(isLlmAvailable: status);
    }

    if (status) {
      final models = await LlmHelper.getPulledModels(endpointUrl);
      if (!listEquals(state.pulledModels, models)) {
        state = state.copyWith(pulledModels: models);
      }
    } else {
      if (state.pulledModels.isNotEmpty) {
        state = state.copyWith(pulledModels: []);
      }
    }
  }

  /// Spawns a background poller to check connections periodic-style.
  /// 
  /// Guarded to prevent duplicate polls if the URL hasn't changed.
  void startLlmPoller(String url) {
    if (_lastPolledUrl == url && _llmPoller != null && _llmPoller!.isActive) {
      return;
    }
    _lastPolledUrl = url;
    _llmPoller?.cancel();
    
    // Check immediately to update states instantly.
    checkLlmConnection(url);
    
    // Poll every 8 seconds in the background.
    _llmPoller = Timer.periodic(const Duration(seconds: 8), (_) {
      checkLlmConnection(url);
    });
  }

  /// Imports a new media item into the chronological workspace archive.
  ///
  /// **Core Operations**:
  /// 1. **Deduplication Check**: Ensures the self-computed SHA-256 identifier is unique.
  /// 2. **Immutability Mapping**: Spawns an immutable clone with `isAnalyzing: true` during queue ingestion.
  /// 3. **Queue Scheduling**: If `autoTag` is true, sequential VLM analysis is initialized.
  /// 4. **Database Syncing**: Persists imported details directly to Postgres sync logs.
  void addMediaItem(
    MediaItem item, {
    String? ollamaUrl,
    String? ollamaModel,
    bool autoTag = true,
    String? preIdentifiedFaces,
    Function(MediaItem)? onComplete,
    Function(String)? onAnalyzeError,
  }) async {
    // 1. Deduplication check using the item's cryptographic SHA-256 hash.
    final isDuplicate = state.items.any((existing) => existing.sha256 == item.sha256);
    if (isDuplicate) {
      debugPrint('Deduplication BLOCKED: SHA-256 (${item.sha256}) already exists in gallery catalog.');
      onAnalyzeError?.call('Deduplication BLOCKED: This image has already been imported.');
      return;
    }

    // 2. Since MediaItem is immutable, copy and set isAnalyzing flag true if VLM parsing is required.
    final initialItem = autoTag && ollamaUrl != null && ollamaModel != null
        ? item.copyWith(isAnalyzing: true)
        : item;

    // Insert imported item at index 0 (chronological sorting).
    final nextItems = List<MediaItem>.from(state.items)..insert(0, initialItem);
    state = state.copyWith(items: nextItems);

    // 3. Queue scheduling for sequential vision VLM inferences.
    if (autoTag && ollamaUrl != null && ollamaModel != null) {
      _vlmQueue.add(_VlmTask(
        item: initialItem,
        ollamaUrl: ollamaUrl,
        ollamaModel: ollamaModel,
        preIdentifiedFaces: preIdentifiedFaces,
        onComplete: onComplete,
        onError: onAnalyzeError,
      ));

      _processVlmQueue();
    } else {
      // Auto-tagging is disabled: import bare media item and sync to database without VLM inferences
      ref.read(postgresSyncProvider.notifier).syncMediaItem(initialItem);

      if (onComplete != null) {
        onComplete(initialItem);
      }
    }
  }

  /// Sequential loop that processes the VLM queue one request at a time
  Future<void> _processVlmQueue() async {
    if (_isProcessingVlm) return;
    _isProcessingVlm = true;

    while (_vlmQueue.isNotEmpty) {
      final task = _vlmQueue.removeAt(0);
      final item = task.item;
      final bytes = item.bytes ?? Uint8List(0);

      try {
        Map<String, String>? results;
        bool modelExists = false;

        if (state.isLlmAvailable) {
          // Double-check if the selected model actually exists on the local Ollama server.
          // If the pulled list is empty, it could mean a network mismatch, so we only enforce if the list has models.
          modelExists = state.pulledModels.isEmpty || 
                        state.pulledModels.contains(task.ollamaModel) ||
                        state.pulledModels.any((m) => m.toLowerCase() == task.ollamaModel.toLowerCase() ||
                                                 m.toLowerCase().startsWith('${task.ollamaModel.toLowerCase()}:'));

          if (modelExists) {
            results = await LlmHelper.analyzeImage(
              bytes: bytes,
              modelName: task.ollamaModel,
              endpointUrl: task.ollamaUrl,
              preIdentifiedFaces: task.preIdentifiedFaces,
            );
          } else {
            debugPrint('Ollama VLM local warning: Model "${task.ollamaModel}" not found in pulled models list: ${state.pulledModels}');
          }
        }

        if (results != null) {
          final rawTags = results['tags'] ?? '';
          final parsedTags = rawTags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
          
          final updatedItem = item.copyWith(
            isAnalyzing: false,
            face: results['face'],
            place: results['place'],
            dateClue: results['date'],
            group: results['group'],
            shortDescription: results['short_description'],
            longDescription: results['long_description'],
            tags: parsedTags,
          );

          final nextItems = List<MediaItem>.from(state.items);
          final index = nextItems.indexWhere((e) => e.id == item.id);
          if (index != -1) {
            nextItems[index] = updatedItem;
            state = state.copyWith(items: nextItems);
          }

          // Trigger PostgreSQL Database synchronization with VLM inferences
          ref.read(postgresSyncProvider.notifier).syncMediaItem(updatedItem);

          if (task.onComplete != null) {
            task.onComplete!(updatedItem);
          }
        } else {
          // VLM analysis failed/offline. Engage fallback simulator!
          debugPrint('Ollama VLM analysis failed, timed out, or model missing. Engaging high-fidelity smart visual fallback simulator sequentially.');
          final fallbackResults = await LlmHelper.getSmartSimulatedAnalysis(bytes);

          final rawTags = fallbackResults['tags'] ?? '';
          final parsedTags = rawTags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

          final updatedItem = item.copyWith(
            isAnalyzing: false,
            face: fallbackResults['face'],
            place: fallbackResults['place'],
            dateClue: fallbackResults['date'],
            group: fallbackResults['group'],
            shortDescription: fallbackResults['short_description'] ?? 'No summary available.',
            longDescription: fallbackResults['long_description'] ?? 'No detailed description available.',
            tags: parsedTags,
          );

          final nextItems = List<MediaItem>.from(state.items);
          final index = nextItems.indexWhere((e) => e.id == item.id);
          if (index != -1) {
            nextItems[index] = updatedItem;
            state = state.copyWith(items: nextItems);
          }

          // Trigger PostgreSQL Database synchronization with simulated inferences
          ref.read(postgresSyncProvider.notifier).syncMediaItem(updatedItem);

          if (task.onComplete != null) {
            task.onComplete!(updatedItem);
          }

          final isModelMissing = state.isLlmAvailable && !modelExists;
          final errorMsg = isModelMissing
              ? 'Failed to perform VLM analysis: The selected vision model "${task.ollamaModel}" was not found on your local Ollama server.\n\nTo download it, run this command in your terminal:\n> ollama pull ${task.ollamaModel}\n\nSmart visual fallbacks have been automatically engaged to keep your gallery functional!'
              : 'Failed to perform VLM analysis: Local Ollama VLM server at "${task.ollamaUrl}" is offline, unreachable, or still starting up.\n\nSmart visual fallbacks have been automatically engaged to keep your gallery functional!';

          task.onError?.call(errorMsg);
        }
      } catch (e) {
        final nextItems = List<MediaItem>.from(state.items);
        final index = nextItems.indexWhere((e) => e.id == item.id);
        if (index != -1) {
          nextItems[index] = nextItems[index].copyWith(isAnalyzing: false);
          state = state.copyWith(items: nextItems);
        }
        task.onError?.call('An unexpected error occurred during VLM analysis: $e');
      }
    }

    _isProcessingVlm = false;
  }

  /// Re-runs the VLM analysis on an existing media item by adding it to the sequential queue
  void reRunVlm(
    MediaItem item, {
    required String ollamaUrl,
    required String ollamaModel,
    String? preIdentifiedFaces,
    Function(MediaItem)? onComplete,
    Function(String)? onError,
  }) {
    final nextItems = List<MediaItem>.from(state.items);
    final index = nextItems.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      final updatedItem = nextItems[index].copyWith(isAnalyzing: true);
      nextItems[index] = updatedItem;
      state = state.copyWith(items: nextItems);

      _vlmQueue.add(_VlmTask(
        item: updatedItem,
        ollamaUrl: ollamaUrl,
        ollamaModel: ollamaModel,
        preIdentifiedFaces: preIdentifiedFaces,
        onComplete: onComplete,
        onError: onError,
      ));

      _processVlmQueue();
    }
  }

  void deleteMediaItem(String id) {
    final nextItems = List<MediaItem>.from(state.items)..removeWhere((item) => item.id == id);
    
    // Remove item from any associated albums
    final nextAlbums = List<Album>.from(state.albums);
    for (int i = 0; i < nextAlbums.length; i++) {
      if (nextAlbums[i].itemIds.contains(id)) {
        final list = List<String>.from(nextAlbums[i].itemIds)..remove(id);
        nextAlbums[i] = nextAlbums[i].copyWith(itemIds: list);
      }
    }
    state = state.copyWith(items: nextItems, albums: nextAlbums);
  }

  // --- Folder / Album Management ---
  void createAlbum(String name) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final nextAlbums = List<Album>.from(state.albums)..add(Album(id: newId, name: name, itemIds: []));
    state = state.copyWith(albums: nextAlbums);
  }

  void deleteAlbum(String id) {
    final nextAlbums = List<Album>.from(state.albums)..removeWhere((album) => album.id == id);
    state = state.copyWith(albums: nextAlbums);
  }

  void addItemToAlbum(String albumId, String itemId) {
    final nextAlbums = List<Album>.from(state.albums);
    final idx = nextAlbums.indexWhere((a) => a.id == albumId);
    if (idx != -1) {
      if (!nextAlbums[idx].itemIds.contains(itemId)) {
        final list = List<String>.from(nextAlbums[idx].itemIds)..add(itemId);
        nextAlbums[idx] = nextAlbums[idx].copyWith(itemIds: list);
        state = state.copyWith(albums: nextAlbums);
      }
    }
  }

  void removeItemFromAlbum(String albumId, String itemId) {
    final nextAlbums = List<Album>.from(state.albums);
    final idx = nextAlbums.indexWhere((a) => a.id == albumId);
    if (idx != -1) {
      if (nextAlbums[idx].itemIds.contains(itemId)) {
        final list = List<String>.from(nextAlbums[idx].itemIds)..remove(itemId);
        nextAlbums[idx] = nextAlbums[idx].copyWith(itemIds: list);
        state = state.copyWith(albums: nextAlbums);
      }
    }
  }
}
