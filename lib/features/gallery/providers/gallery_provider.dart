import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/utils/llm_helper.dart';
import '../../../core/utils/postgres_sync_service.dart';
import '../models/media_item.dart';
import '../models/album.dart';

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

/// A central state management controller governing the Media archive catalog.
///
/// This provider uses [ChangeNotifier] to reactive-notify subscribers when:
/// 1. Media is imported or deleted from the catalog.
/// 2. Memory folders (Albums) are created or mutated.
/// 3. Local Ollama VLM connections are established or disconnected.
/// 4. Ingestion queues shift analysis states.
class GalleryProvider extends ChangeNotifier {
  /// Internal mutable store of media items.
  final List<MediaItem> _items = [];

  /// Internal mutable store of custom albums.
  final List<Album> _albums = [];

  /// Flag indicating whether the local vision VLM (Ollama) server is active.
  bool _isLlmAvailable = false;
  bool get isLlmAvailable => _isLlmAvailable;

  /// Holds the list of parsed, pulled model configurations retrieved from Ollama.
  List<String> _pulledModels = [];
  List<String> get pulledModels => List.unmodifiable(_pulledModels);

  /// Periodic timer polling the Ollama endpoint to trace server availability states.
  Timer? _llmPoller;
  String? _lastPolledUrl;

  /// Single-threaded sequential VLM queue to avoid resource starvation or server crashes.
  final List<_VlmTask> _vlmQueue = [];
  
  /// Lock guard ensuring only one sequential task is run at a time.
  bool _isProcessingVlm = false;

  /// Read-only unmodifiable views of items and albums to enforce outside immutability.
  List<MediaItem> get items => List.unmodifiable(_items);
  List<Album> get albums => List.unmodifiable(_albums);

  GalleryProvider() {
    // Initiate automatic connection check on localhost standard port.
    checkLlmConnection('http://localhost:11434');
  }

  /// Queries the target endpoint url to retrieve LLM status details.
  Future<void> checkLlmConnection(String endpointUrl) async {
    final status = await LlmHelper.checkLlmAvailability(endpointUrl);
    if (_isLlmAvailable != status) {
      _isLlmAvailable = status;
      notifyListeners();
    }

    if (status) {
      final models = await LlmHelper.getPulledModels(endpointUrl);
      if (!listEquals(_pulledModels, models)) {
        _pulledModels = models;
        notifyListeners();
      }
    } else {
      if (_pulledModels.isNotEmpty) {
        _pulledModels = [];
        notifyListeners();
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

  @override
  void dispose() {
    // Prevent memory leaks by terminating active background poll timers.
    _llmPoller?.cancel();
    super.dispose();
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
    Function(MediaItem)? onAnalyzeComplete,
    Function(String)? onAnalyzeError,
  }) async {
    // 1. Deduplication check using the item's cryptographic SHA-256 hash.
    final isDuplicate = _items.any((existing) => existing.sha256 == item.sha256);
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
    _items.insert(0, initialItem);
    notifyListeners();

    // 3. Queue scheduling for sequential vision VLM inferences.
    if (autoTag && ollamaUrl != null && ollamaModel != null) {
      _vlmQueue.add(_VlmTask(
        item: initialItem,
        ollamaUrl: ollamaUrl,
        ollamaModel: ollamaModel,
        preIdentifiedFaces: preIdentifiedFaces,
        onComplete: onAnalyzeComplete,
        onError: onAnalyzeError,
      ));

      _processVlmQueue();
    } else {
      // Auto-tagging is disabled: import bare media item and sync to database without VLM inferences
      PostgresSyncService().syncMediaItem(initialItem);

      if (onAnalyzeComplete != null) {
        onAnalyzeComplete(initialItem);
      }
      notifyListeners();
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
        final results = await LlmHelper.analyzeImage(
          bytes: bytes,
          modelName: task.ollamaModel,
          endpointUrl: task.ollamaUrl,
          preIdentifiedFaces: task.preIdentifiedFaces,
        );

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

          final index = _items.indexWhere((e) => e.id == item.id);
          if (index != -1) {
            _items[index] = updatedItem;
          }

          // Trigger PostgreSQL Database synchronization with VLM inferences
          PostgresSyncService().syncMediaItem(updatedItem);

          if (task.onComplete != null) {
            task.onComplete!(updatedItem);
          }
          notifyListeners();
        } else {
          // VLM analysis failed/offline. Engage fallback simulator!
          debugPrint('Ollama VLM analysis failed or timed out. Engaging high-fidelity smart visual fallback simulator sequentially.');
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

          final index = _items.indexWhere((e) => e.id == item.id);
          if (index != -1) {
            _items[index] = updatedItem;
          }

          // Trigger PostgreSQL Database synchronization with simulated inferences
          PostgresSyncService().syncMediaItem(updatedItem);

          if (task.onComplete != null) {
            task.onComplete!(updatedItem);
          }
          notifyListeners();

          task.onError?.call(
            'Failed to perform VLM analysis: Local Ollama VLM server at "${task.ollamaUrl}" is offline, unreachable, or the model "${task.ollamaModel}" is not loaded.\n\nSmart visual fallbacks have been automatically engaged to keep your gallery functional!'
          );
        }
      } catch (e) {
        final index = _items.indexWhere((e) => e.id == item.id);
        if (index != -1) {
          _items[index] = _items[index].copyWith(isAnalyzing: false);
        }
        notifyListeners();
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
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      final updatedItem = _items[index].copyWith(isAnalyzing: true);
      _items[index] = updatedItem;
      notifyListeners();

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
    _items.removeWhere((item) => item.id == id);
    // Remove item from any associated albums
    for (int i = 0; i < _albums.length; i++) {
      if (_albums[i].itemIds.contains(id)) {
        final list = List<String>.from(_albums[i].itemIds)..remove(id);
        _albums[i] = _albums[i].copyWith(itemIds: list);
      }
    }
    notifyListeners();
  }

  // --- Folder / Album Management ---
  void createAlbum(String name) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _albums.add(Album(id: newId, name: name, itemIds: []));
    notifyListeners();
  }

  void deleteAlbum(String id) {
    _albums.removeWhere((album) => album.id == id);
    notifyListeners();
  }

  void addItemToAlbum(String albumId, String itemId) {
    final idx = _albums.indexWhere((a) => a.id == albumId);
    if (idx != -1) {
      if (!_albums[idx].itemIds.contains(itemId)) {
        final list = List<String>.from(_albums[idx].itemIds)..add(itemId);
        _albums[idx] = _albums[idx].copyWith(itemIds: list);
        notifyListeners();
      }
    }
  }

  void removeItemFromAlbum(String albumId, String itemId) {
    final idx = _albums.indexWhere((a) => a.id == albumId);
    if (idx != -1) {
      if (_albums[idx].itemIds.contains(itemId)) {
        final list = List<String>.from(_albums[idx].itemIds)..remove(itemId);
        _albums[idx] = _albums[idx].copyWith(itemIds: list);
        notifyListeners();
      }
    }
  }
}
