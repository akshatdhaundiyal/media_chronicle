import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/gallery/models/media_item.dart';
import '../../features/gallery/models/detected_face.dart';

part 'postgres_sync_service.g.dart';

@immutable
class PostgresSyncState {
  final bool isConnected;
  final int syncedRecords;
  final List<String> syncLogs;
  final List<String> syncQueue;

  const PostgresSyncState({
    required this.isConnected,
    required this.syncedRecords,
    required this.syncLogs,
    required this.syncQueue,
  });

  PostgresSyncState copyWith({
    bool? isConnected,
    int? syncedRecords,
    List<String>? syncLogs,
    List<String>? syncQueue,
  }) {
    return PostgresSyncState(
      isConnected: isConnected ?? this.isConnected,
      syncedRecords: syncedRecords ?? this.syncedRecords,
      syncLogs: syncLogs ?? this.syncLogs,
      syncQueue: syncQueue ?? this.syncQueue,
    );
  }
}

@riverpod
class PostgresSync extends _$PostgresSync {
  // Active Connection reference
  Connection? _connection;

  @override
  PostgresSyncState build() {
    // Prevent memory and socket leaks on provider disposal
    ref.onDispose(() {
      _connection?.close();
    });

    return const PostgresSyncState(
      isConnected: false,
      syncedRecords: 0,
      syncLogs: ['[System] PostgreSQL Sync Center ready. Offline queuing active.'],
      syncQueue: [],
    );
  }

  // PostgreSQL Relational Tables Schema Definition (DDL)
  String get sqlSchemaMigration {
    return '''
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
CREATE INDEX IF NOT EXISTS idx_llm_inferences_tags ON llm_inferences USING GIN(tags);

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

  /// Attempts to establish a connection to a real PostgreSQL database server
  Future<void> toggleConnection(
    bool val, {
    String? host,
    int? port,
    String? db,
    String? user,
    String? pass,
    bool? ssl,
  }) async {
    if (val) {
      _addLog('[System] Attempting connection to PostgreSQL...');
      try {
        if (_connection != null) {
          await _connection!.close();
          _connection = null;
        }

        final targetHost = host ?? 'localhost';
        final targetPort = port ?? 5432;
        final targetDb = db ?? 'chronicle';
        final targetUser = user ?? 'postgres';
        final targetPass = pass ?? 'password';
        final targetSsl = ssl ?? false;

        _connection = await Connection.open(
          Endpoint(
            host: targetHost,
            port: targetPort,
            database: targetDb,
            username: targetUser,
            password: targetPass,
          ),
          settings: ConnectionSettings(
            sslMode: targetSsl ? SslMode.require : SslMode.disable,
          ),
        ).timeout(const Duration(seconds: 5));

        state = state.copyWith(isConnected: true);
        _addLog('[Success] PostgreSQL Connection ESTABLISHED!');
        _addLog('[System] Endpoint: $targetHost:$targetPort/$targetDb');
        
        await _runDatabaseMigrations();
      } catch (e) {
        state = state.copyWith(isConnected: false);
        _connection = null;
        _addLog('[Error] PostgreSQL Connection Failed: $e');
      }
    } else {
      state = state.copyWith(isConnected: false);
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }
      _addLog('[System] PostgreSQL Connection PAUSED.');
    }
  }

  /// Runs database table structure migrations automatically upon connecting
  Future<void> _runDatabaseMigrations() async {
    if (_connection == null || !state.isConnected) return;
    
    _addLog('[Execute] Checking database table structure and indexes...');
    try {
      final queries = sqlSchemaMigration
          .split(';')
          .map((q) => q.trim())
          .where((q) => q.isNotEmpty)
          .toList();

      for (final query in queries) {
        if (query.startsWith('--') && !query.contains('\n')) continue;
        await _connection!.execute(query);
      }
      _addLog('[Success] All database tables and indexes verified successfully.');
    } catch (e) {
      _addLog('[Error] Database migration query execution failed: $e');
    }
  }

  /// Registers and processes a PostgreSQL synchronization query block in the background
  void _executeSyncQuery(String sql) {
    if (!state.isConnected || _connection == null) {
      final queue = List<String>.from(state.syncQueue)..add(sql);
      state = state.copyWith(syncQueue: queue);
      _addLog('[Database OFFLINE] Sync query queued: ${sql.split('\n').first}...');
      return;
    }

    _addLog('[Execute] Streaming SQL statement to Postgres...');
    _addLog(sql);
    
    // Run real async db execution
    scheduleMicrotask(() async {
      try {
        if (_connection != null && state.isConnected) {
          await _connection!.execute(sql);
          state = state.copyWith(syncedRecords: state.syncedRecords + 1);
          _addLog('[Success] Database transaction committed! (Row synced successfully)');
        } else {
          final queue = List<String>.from(state.syncQueue)..add(sql);
          state = state.copyWith(syncQueue: queue);
          _addLog('[Database OFFLINE] Connection dropped. Query queued.');
        }
      } catch (e) {
        _addLog('[Error] Execution failed: $e');
      }
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
    if (state.syncQueue.isEmpty || !state.isConnected || _connection == null) return;

    _addLog('[System] Flushing offline synchronized queue (${state.syncQueue.length} statements)...');
    final statements = List<String>.from(state.syncQueue);
    state = state.copyWith(syncQueue: []);
    
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (index >= statements.length || !state.isConnected || _connection == null) {
        timer.cancel();
        return;
      }
      _executeSyncQuery(statements[index++]);
    });
  }

  void _addLog(String log) {
    final newLogs = List<String>.from(state.syncLogs)..add(log);
    if (newLogs.length > 200) {
      newLogs.removeAt(0);
    }
    state = state.copyWith(syncLogs: newLogs);
  }

  void clearLogs() {
    state = state.copyWith(syncLogs: ['[System] PostgreSQL Console terminal reset.']);
  }
}
