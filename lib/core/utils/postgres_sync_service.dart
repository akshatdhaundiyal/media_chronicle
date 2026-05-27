import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/gallery/models/media_item.dart';
import '../../features/gallery/models/detected_face.dart';

class PostgresSyncService extends ChangeNotifier {
  static final PostgresSyncService _instance = PostgresSyncService._internal();
  factory PostgresSyncService() => _instance;
  PostgresSyncService._internal();

  // Status variables
  bool _isConnected = true;
  int _syncedRecords = 0;
  final List<String> _syncLogs = [];
  final List<String> _syncQueue = [];

  // Getters
  bool get isConnected => _isConnected;
  int get syncedRecords => _syncedRecords;
  List<String> get syncLogs => List.unmodifiable(_syncLogs);
  List<String> get syncQueue => List.unmodifiable(_syncQueue);

  // PostgreSQL Relational Tables Schema Definition (DDL)
  String get sqlSchemaMigration {
    return '''
-- ==========================================================
-- PostgreSQL Schema Migration: Media Chronicle AI Database
-- Target Engine: PostgreSQL 14+
-- ==========================================================

-- 1. Base Media Archive Table
CREATE TABLE IF NOT EXISTS media_items (
    id VARCHAR(64) PRIMARY KEY,      -- Cryptographic SHA-256 Hash Identifier
    title VARCHAR(255) NOT NULL,     -- File name or simulated shot title
    type VARCHAR(10) NOT NULL,       -- 'image' or 'video'
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indexing for optimized base queries
CREATE INDEX IF NOT EXISTS idx_media_items_upload_date ON media_items(upload_date DESC);

-- 2. Local LLM Vision Inferences Table
CREATE TABLE IF NOT EXISTS llm_inferences (
    media_item_id VARCHAR(64) REFERENCES media_items(id) ON DELETE CASCADE PRIMARY KEY,
    face_description TEXT,
    place_description TEXT,
    date_clue TEXT,
    group_category VARCHAR(50),
    short_description TEXT,
    long_description TEXT,
    tags TEXT[] NOT NULL,           -- Postgres Text Array for keywords
    inference_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indexing for semantic text search and filtering
CREATE INDEX IF NOT EXISTS idx_llm_inferences_group ON llm_inferences(group_category);
CREATE INDEX IF NOT EXISTS idx_llm_inferences_tags ON llm_inferences USING gin(tags);

-- 3. YOLO Detected Faces Table
CREATE TABLE IF NOT EXISTS yolo_faces (
    id VARCHAR(64) PRIMARY KEY,      -- Unique Face Object Identifier
    media_item_id VARCHAR(64) REFERENCES media_items(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255),              -- Labeled identity (null if unidentified)
    is_identified BOOLEAN DEFAULT FALSE NOT NULL,
    age_variant VARCHAR(100),       -- Chronological age progression category
    bounding_box_x DOUBLE PRECISION NOT NULL,  -- Relative x percentage (0.0-1.0)
    bounding_box_y DOUBLE PRECISION NOT NULL,  -- Relative y percentage (0.0-1.0)
    bounding_box_w DOUBLE PRECISION NOT NULL,  -- Relative width percentage (0.0-1.0)
    bounding_box_h DOUBLE PRECISION NOT NULL,  -- Relative height percentage (0.0-1.0)
    embedding_vector DOUBLE PRECISION[] NOT NULL, -- 2D YOLO Dense Feature Embeddings
    enrolled_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indexing for rapid sub-bounding and cluster queries
CREATE INDEX IF NOT EXISTS idx_yolo_faces_media_item ON yolo_faces(media_item_id);
CREATE INDEX IF NOT EXISTS idx_yolo_faces_name ON yolo_faces(name) WHERE is_identified = TRUE;
''';
  }

  void toggleConnection(bool val) {
    _isConnected = val;
    _addLog('[System] PostgreSQL Connection ${val ? "RESTORED" : "PAUSED"} - Endpoint: localhost:5432/chronicle');
    notifyListeners();
  }

  /// Registers and processes a PostgreSQL synchronization query block in the background
  void _executeSyncQuery(String sql) {
    if (!_isConnected) {
      _syncQueue.add(sql);
      _addLog('[Database OFFLINE] Sync query queued: ${sql.split('\n').first}...');
      notifyListeners();
      return;
    }

    _addLog('[Execute] Streaming SQL statement to Postgres...');
    _addLog(sql);
    
    // Simulate slight database insertion network roundtrip latency
    Timer(const Duration(milliseconds: 400), () {
      _syncedRecords++;
      _addLog('[Success] Database transaction committed! (Row synced successfully)');
      notifyListeners();
    });
  }

  /// Syncs an uploaded MediaItem (Base Table + LLM Inferences)
  void syncMediaItem(MediaItem item) {
    final cleanTitle = item.title.replaceAll("'", "''");
    final cleanFace = (item.face ?? 'none').replaceAll("'", "''");
    final cleanPlace = (item.place ?? 'unknown').replaceAll("'", "''");
    final cleanDateClue = (item.dateClue ?? 'unknown').replaceAll("'", "''");
    final cleanShort = (item.shortDescription ?? 'No summary available.').replaceAll("'", "''");
    final cleanLong = (item.longDescription ?? 'No detailed description available.').replaceAll("'", "''");

    // Format array format tags e.g. ARRAY['tag1', 'tag2']
    final formattedTags = item.tags.isEmpty 
        ? "ARRAY[]::TEXT[]"
        : "ARRAY[${item.tags.map((t) => "'${t.replaceAll("'", "''")}'").join(', ')}]";

    final sha256 = item.sha256;

    // 1. Insert Base Media Query
    final sqlMedia = '''
INSERT INTO media_items (id, title, type, upload_date)
VALUES ('$sha256', '$cleanTitle', '${item.type}', '${item.date.toIso8601String()}')
ON CONFLICT (id) DO NOTHING;''';

    // 2. Insert Enriched VLM Inference Query
    final sqlInference = '''
INSERT INTO llm_inferences (media_item_id, face_description, place_description, date_clue, group_category, short_description, long_description, tags, inference_date)
VALUES ('$sha256', '$cleanFace', '$cleanPlace', '$cleanDateClue', '${item.group ?? "Objects"}', '$cleanShort', '$cleanLong', $formattedTags, CURRENT_TIMESTAMP)
ON CONFLICT (media_item_id) DO UPDATE SET 
    short_description = EXCLUDED.short_description,
    long_description = EXCLUDED.long_description,
    tags = EXCLUDED.tags;''';

    _executeSyncQuery(sqlMedia);
    _executeSyncQuery(sqlInference);
  }

  /// Syncs a single YOLO face detection/label annotation
  void syncYoloFace(DetectedFace face, String mediaItemSha256) {
    final cleanName = face.name == null ? 'NULL' : "'${face.name!.replaceAll("'", "''")}'";
    final cleanVariant = face.ageVariant == null ? 'NULL' : "'${face.ageVariant!.replaceAll("'", "''")}'";
    final vectorStr = 'ARRAY[${face.embedding.join(', ')}]';

    final sqlFace = '''
INSERT INTO yolo_faces (id, media_item_id, name, is_identified, age_variant, bounding_box_x, bounding_box_y, bounding_box_w, bounding_box_h, embedding_vector)
VALUES ('${face.id}', '$mediaItemSha256', $cleanName, ${face.isIdentified}, $cleanVariant, ${face.x}, ${face.y}, ${face.width}, ${face.height}, $vectorStr)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    is_identified = EXCLUDED.is_identified,
    age_variant = EXCLUDED.age_variant;''';

    _executeSyncQuery(sqlFace);
  }

  /// Retries flushing any offline-queued statements when Postgres reconnects
  void processSyncQueue() {
    if (_syncQueue.isEmpty || !_isConnected) return;

    _addLog('[System] Flushing offline synchronized queue (${_syncQueue.length} statements)...');
    final statements = List<String>.from(_syncQueue);
    _syncQueue.clear();
    
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (index >= statements.length) {
        timer.cancel();
        notifyListeners();
        return;
      }
      _executeSyncQuery(statements[index++]);
    });
  }

  void _addLog(String log) {
    _syncLogs.add(log);
    // Keep max logs to prevent memory leaks
    if (_syncLogs.length > 200) {
      _syncLogs.removeAt(0);
    }
  }

  void clearLogs() {
    _syncLogs.clear();
    _syncLogs.add('[System] PostgreSQL Console terminal reset.');
    notifyListeners();
  }
}
