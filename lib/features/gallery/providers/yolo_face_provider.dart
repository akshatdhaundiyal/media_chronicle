import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/detected_face.dart';
import '../models/media_item.dart';
import '../../../core/utils/postgres_sync_service.dart';

/// State provider governing YOLO v8 simulated edge face detection.
///
/// Handles active-learning retraining simulations, 2D facial vector similarity clustering,
/// and live scrolling backpropagation training terminals.
class YoloFaceProvider extends ChangeNotifier {
  /// Internal registry of all bounding box faces identified on imported images.
  final List<DetectedFace> _detectedFaces = [];
  
  // Simulated Backpropagation Neural Retraining parameters:
  /// Flag showing if active retraining is underway.
  bool _isTraining = false;

  /// Current retraining epoch counter.
  int _currentEpoch = 0;

  /// Total target training epochs (15) to achieve convergence.
  final int _totalEpochs = 15;

  /// Retraining loss indicator starting at high error rates (~0.85).
  double _currentLoss = 0.85;

  /// Classifier accuracy indicator starting around baseline ~68%.
  double _currentAccuracy = 0.68;

  /// Scrolling training terminal output lines.
  final List<String> _trainingLogs = [];

  // YOLO Edge Model connection status:
  /// Tracks whether the local edge detection model engine is active.
  bool _isYoloAvailable = true;
  bool get isYoloAvailable => _isYoloAvailable;

  /// Enables or disables the edge model execution, notifying interface listeners.
  void setYoloAvailable(bool val) {
    if (_isYoloAvailable != val) {
      _isYoloAvailable = val;
      notifyListeners();
    }
  }

  // Reactive getters exposing read-only lists and metrics:
  List<DetectedFace> get detectedFaces => List.unmodifiable(_detectedFaces);
  bool get isTraining => _isTraining;
  int get currentEpoch => _currentEpoch;
  int get totalEpochs => _totalEpochs;
  double get currentLoss => _currentLoss;
  double get currentAccuracy => _currentAccuracy;
  List<String> get trainingLogs => List.unmodifiable(_trainingLogs);

  /// Filters and exposes distinct enrolled names in alphabetical clusters.
  List<String> get enrolledNames {
    return _detectedFaces
        .where((f) => f.isIdentified && f.name != null)
        .map((f) => f.name!)
        .toSet()
        .toList();
  }

  /// Filters and exposes faces waiting for active user label input.
  List<DetectedFace> get unidentifiedFaces {
    return _detectedFaces.where((f) => !f.isIdentified).toList();
  }

  YoloFaceProvider() {
    _loadInitialMockFaces();
  }

  void _loadInitialMockFaces() {
    // Clean slate: no mock faces are pre-loaded
  }

  /// Evaluates and registers a new media item's face properties.
  /// Simulates running a YOLO v8 feature detection model.
  List<DetectedFace> runYoloDetection(MediaItem item, {Function(String)? onError}) {
    if (!_isYoloAvailable) {
      _trainingLogs.add('[YOLO v8 Error] Core processor offline. Detection request aborted for: ${item.title}');
      notifyListeners();
      onError?.call('YOLO face recognition processor is offline. Face bounding boxes could not be analyzed.');
      return [];
    }


    final random = Random(item.id.hashCode);
    final detected = <DetectedFace>[];
    
    // Determine number of faces to detect based on VLM tags, title, or high-probability random seeds
    int faceCount = 0;
    final lowerTitle = item.title.toLowerCase();
    
    if (item.face != null && !item.face!.contains('none') && item.face!.isNotEmpty) {
      faceCount = item.face!.contains('two') || item.face!.contains('group') ? 2 : 1;
    } else if (lowerTitle.contains('portrait') || 
               lowerTitle.contains('selfie') || 
               lowerTitle.contains('face') || 
               lowerTitle.contains('friend') || 
               lowerTitle.contains('people') || 
               lowerTitle.contains('gathering') ||
               lowerTitle.contains('specimen') ||
               lowerTitle.contains('shot')) {
      faceCount = lowerTitle.contains('friend') || lowerTitle.contains('people') || lowerTitle.contains('gathering') ? 2 : 1;
    } else {
      // General case: 85% probability to detect a face, making the YOLO detection highly active
      if (random.nextDouble() < 0.85) {
        faceCount = random.nextBool() ? 1 : 2;
      }
    }

    for (int i = 0; i < faceCount; i++) {
      final faceId = 'face_${item.id}_$i';
      
      // Calculate random relative bounding box
      final x = 0.1 + random.nextDouble() * 0.5;
      final y = 0.1 + random.nextDouble() * 0.4;
      final width = 0.15 + random.nextDouble() * 0.15;
      final height = 0.2 + random.nextDouble() * 0.15;

      // Generate a face feature embedding in 2D space
      // Let's decide if this face is close to a known cluster
      double embX, embY;
      String? recognizedName;
      bool isIdentified = false;
      String? ageVariant;

      final clusterRoll = random.nextDouble();
      if (clusterRoll < 0.3 && enrolledNames.isNotEmpty) {
        // High confidence matching with John (cluster near 20, 30)
        recognizedName = 'John';
        isIdentified = true;
        ageVariant = 'Auto-Recognized (91.4%)';
        embX = 20.0 + (random.nextDouble() - 0.5) * 6;
        embY = 30.0 + (random.nextDouble() - 0.5) * 6;
      } else if (clusterRoll < 0.55 && enrolledNames.contains('Sarah')) {
        // High confidence matching with Sarah (cluster near 70, 80)
        recognizedName = 'Sarah';
        isIdentified = true;
        ageVariant = 'Auto-Recognized (89.7%)';
        embX = 70.0 + (random.nextDouble() - 0.5) * 6;
        embY = 80.0 + (random.nextDouble() - 0.5) * 6;
      } else {
        // New features, isolated point (needs manual label assignment)
        embX = 10.0 + random.nextDouble() * 80.0;
        embY = 10.0 + random.nextDouble() * 80.0;
      }

      final face = DetectedFace(
        id: faceId,
        mediaItemId: item.id,
        mediaItemSha256: item.sha256,
        x: x,
        y: y,
        width: width,
        height: height,
        name: recognizedName,
        isIdentified: isIdentified,
        ageVariant: ageVariant,
        embedding: [embX, embY],
      );

      _detectedFaces.add(face);
      detected.add(face);
      
      // Sync newly detected face to PostgreSQL yolo_faces table
      PostgresSyncService().syncYoloFace(face, item.sha256);
    }
    
    notifyListeners();
    return detected;
  }

  /// Calculates visual similarity (Euclidean distance) between two face embeddings.
  /// Distance less than 15 implies very high similarity (same age group).
  /// Distance > 25 implies significant difference (face aged or different person).
  double getEmbeddingDistance(List<double> emb1, List<double> emb2) {
    if (emb1.length < 2 || emb2.length < 2) return 100.0;
    final dx = emb1[0] - emb2[0];
    final dy = emb1[1] - emb2[1];
    return sqrt(dx * dx + dy * dy);
  }

  /// Checks if labeling a face as [name] should trigger an age-variant warning
  /// due to low similarity with previously enrolled faces under the same name.
  bool checkShouldPromptAgeVariant(String faceId, String name) {
    final faceToLabel = _detectedFaces.firstWhere((f) => f.id == faceId);
    final existingFacesForPerson = _detectedFaces
        .where((f) => f.isIdentified && f.name?.toLowerCase() == name.toLowerCase())
        .toList();

    if (existingFacesForPerson.isEmpty) return false;

    // Check distance to closest enrolled face
    double minDistance = double.infinity;
    for (final enrolled in existingFacesForPerson) {
      final dist = getEmbeddingDistance(faceToLabel.embedding, enrolled.embedding);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    // If similarity distance is large (> 25), it means facial traits differ significantly
    // (Simulating how a face changes as one grows up and ages)
    return minDistance > 25.0;
  }

  /// Labels an unrecognized face and registers it as a named identity.
  ///
  /// **Core Operations**:
  /// 1. **Variant Categorization**: Configures the face with an age stage (e.g. Later Stage, Adult Stage) if
  ///    `isAgeVariant` is checked, or assigns a unique suffix (e.g., John (2)) to avoid name collisions.
  /// 2. **Cluster Vector Shifting**: Repositions the 2D facial vector coordinate to be 60% closer to the
  ///    target identity cluster center. This updates the custom-painted embeddings chart immediately.
  /// 3. **Database Syncing**: Manually pushes identified face fields to PostgreSQL sync logs.
  /// 4. **Neural Retraining Initiation**: Automatically spins up the simulated SGD active learning loop.
  void labelFace(String faceId, String name, {required bool isAgeVariant, required String parentSha256}) {
    final idx = _detectedFaces.indexWhere((f) => f.id == faceId);
    if (idx != -1) {
      final face = _detectedFaces[idx];
      
      // 1. Choose or auto-generate age variant stage details.
      String variant = 'Initial Profile';
      if (isAgeVariant) {
        final existingCount = _detectedFaces
            .where((f) => f.isIdentified && f.name?.toLowerCase() == name.toLowerCase())
            .length;
        if (existingCount == 1) {
          variant = 'Later Stage (Growth)';
        } else if (existingCount == 2) {
          variant = 'Adult Stage';
        } else {
          variant = 'Age Progression Stage ${existingCount + 1}';
        }
      } else {
        // Suffix mapping if they share the same base name but represent different entities entirely.
        final exists = _detectedFaces.any((f) => f.isIdentified && f.name?.toLowerCase() == name.toLowerCase());
        if (exists) {
          name = '$name (${_getNextSuffix(name)})';
        }
      }

      // 2. Cluster Vector Shifting: Map coordinates closer to the respective identity groups.
      double targetX = 50.0;
      double targetY = 50.0;

      if (name.toLowerCase().startsWith('john')) {
        targetX = 20.0;
        targetY = 30.0;
      } else if (name.toLowerCase().startsWith('sarah')) {
        targetX = 70.0;
        targetY = 80.0;
      } else {
        // Determine a deterministic pseudo-random cluster center for new identities.
        final rand = Random(name.hashCode);
        targetX = 15.0 + rand.nextDouble() * 70.0;
        targetY = 15.0 + rand.nextDouble() * 70.0;
      }

      // Shift coordinate coordinates 60% closer to their cluster anchor.
      final newEmbX = face.embedding[0] + (targetX - face.embedding[0]) * 0.6;
      final newEmbY = face.embedding[1] + (targetY - face.embedding[1]) * 0.6;

      final updatedFace = face.copyWith(
        name: name,
        isIdentified: true,
        ageVariant: variant,
        embedding: [newEmbX, newEmbY],
      );
      
      _detectedFaces[idx] = updatedFace;
      notifyListeners();
      
      // 3. PostgreSQL manual sync registration.
      PostgresSyncService().syncYoloFace(updatedFace, parentSha256);
      
      // 4. Retraining initiation: Trigger backpropagation epochs.
      retrainModel();
    }
  }

  /// Calculates unique integer suffixes for identity duplicates.
  int _getNextSuffix(String name) {
    final regex = RegExp('^${RegExp.escape(name)} \\((\\d+)\\)\$', caseSensitive: false);
    int maxSuffix = 1;
    for (final face in _detectedFaces) {
      if (face.name != null) {
        final match = regex.firstMatch(face.name!);
        if (match != null) {
          final val = int.tryParse(match.group(1) ?? '1') ?? 1;
          if (val > maxSuffix) {
            maxSuffix = val;
          }
        }
      }
    }
    return maxSuffix + 1;
  }

  /// Triggers a highly premium, simulated neural network backpropagation training loop.
  /// Shows progressive loss reduction and accuracy improvement in the UI.
  void retrainModel() {
    if (_isTraining) return;

    _isTraining = true;
    _currentEpoch = 0;
    _trainingLogs.clear();
    _trainingLogs.add('[YOLO v8 active-learning] Initializing fine-tuning layers...');
    _trainingLogs.add('[YOLO v8 active-learning] Loading ${enrolledNames.length} enrolled identities with ${_detectedFaces.where((f)=>f.isIdentified).length} training frames...');
    _trainingLogs.add('[YOLO v8 active-learning] SGD Optimizer loaded (lr=0.005, momentum=0.9)');
    notifyListeners();

    double loss = 0.72 + (Random().nextDouble() * 0.15);
    double acc = 0.70 + (Random().nextDouble() * 0.08);

    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      _currentEpoch++;
      
      // Train calculation step
      loss -= (loss * 0.16) + (Random().nextDouble() * 0.02);
      if (loss < 0.01) loss = 0.008 + Random().nextDouble() * 0.003;

      acc += ((1.0 - acc) * 0.18) + (Random().nextDouble() * 0.01);
      if (acc > 0.99) acc = 0.985 + Random().nextDouble() * 0.01;

      _currentLoss = loss;
      _currentAccuracy = acc;

      _trainingLogs.add(
        'Epoch $_currentEpoch/$_totalEpochs - learning_rate: 0.005 - loss: ${loss.toStringAsFixed(4)} - training_accuracy: ${(acc * 100).toStringAsFixed(1)}%'
      );

      // Trigger automatic recognition matching for remaining unidentified faces!
      // (As the model retrains, it gets smart enough to auto-classify similar faces!)
      if (_currentEpoch == _totalEpochs ~/ 2) {
        _trainingLogs.add('[YOLO v8 active-learning] Mid-checkpoint: validating unidentified queue...');
        _evaluateRemainingUnidentifiedQueue();
      }

      notifyListeners();

      if (_currentEpoch >= _totalEpochs) {
        timer.cancel();
        _isTraining = false;
        _trainingLogs.add('[YOLO v8 active-learning] Training completed! Weights successfully updated.');
        _trainingLogs.add('[YOLO v8 active-learning] Target validation map synced to edge processor.');
        
        // Final evaluation sweep
        _evaluateRemainingUnidentifiedQueue(finalSweep: true);
        notifyListeners();
      }
    });
  }

  void _evaluateRemainingUnidentifiedQueue({bool finalSweep = false}) {
    final unIdentified = unidentifiedFaces;
    if (unIdentified.isEmpty) return;

    final random = Random();
    int count = 0;

    for (final face in unIdentified) {
      // Find the closest enrolled center
      for (final name in enrolledNames) {
        final enrolledForName = _detectedFaces
            .where((f) => f.isIdentified && f.name == name)
            .toList();

        for (final enrolled in enrolledForName) {
          final dist = getEmbeddingDistance(face.embedding, enrolled.embedding);
          
          // As model learns, the threshold gets wider (better generalization)
          final threshold = finalSweep ? 18.0 : 12.0;

          if (dist < threshold) {
            // Auto-recognize this face!
            final idx = _detectedFaces.indexWhere((f) => f.id == face.id);
            if (idx != -1) {
              _detectedFaces[idx] = face.copyWith(
                name: name,
                isIdentified: true,
                ageVariant: 'Auto-Recognized (${(85.0 + random.nextDouble() * 13).toStringAsFixed(1)}%)',
              );
              final updated = _detectedFaces[idx];
              _trainingLogs.add('[Model Inference SUCCESS] Auto-classified ${face.id.substring(0, min(8, face.id.length))} as "$name"');
              count++;
              
              // Sync background auto-recognized face to PostgreSQL yolo_faces table
              PostgresSyncService().syncYoloFace(updated, face.mediaItemSha256 ?? 'sha256_mock_${face.mediaItemId}');
              break;
            }
          }
        }
        if (face.isIdentified) break;
      }
    }

    if (count > 0) {
      notifyListeners();
    }
  }

  List<DetectedFace> getFacesForMediaItem(String mediaItemId) {
    return _detectedFaces.where((f) => f.mediaItemId == mediaItemId).toList();
  }
}
