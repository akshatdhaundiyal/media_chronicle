import 'package:flutter/foundation.dart';

/// Central state provider governing application preferences and LLM/YOLO service URLs.
///
/// This state controller manages:
/// 1. Profile metadata (Username, profile image source).
/// 2. General UX switches (Dark mode toggle, notification permissions).
/// 3. In-Memory storage tracking (Simulating growth up to 15.0 GB limits).
/// 4. Local Ollama VLM connections (Server URL, active vision model name).
class SettingsProvider extends ChangeNotifier {
  /// Username displayed globally on the responsive dashboard sidebar and settings panels.
  String _username = 'Alex Chronicle';

  /// Standard placeholder image source representing the active profile avatar.
  final String _profileImage = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=150&auto=format&fit=crop';
  
  /// Switches Scaffold visual background configurations.
  bool _darkMode = true;

  /// View configuration tracking (Grid view list vs chronological timelines).
  bool _gridMode = true;

  /// Enables or disables display notifications and status alerts.
  bool _enableNotifications = true;

  /// Represents current memory allocation used in Gigabytes.
  double _storageUsedGB = 2.4;

  /// System-allocated max size limit for this client (15.0 GB free-tier limit).
  final double _storageTotalGB = 15.0;

  // Local Vision LLM / Gemma 4 Configurations
  /// Target host URL for the local Ollama vision LLM server.
  String _ollamaUrl = 'http://localhost:11434';

  /// Active vision VLM model parsed during image ingestions.
  String _ollamaModel = 'gemma4';

  /// Flag indicating whether automated VLM analysis executes upon image import.
  bool _autoTagEnabled = true;

  /// Flag governing independent YOLO executions (skipping subsequent VLM loops).
  bool _yoloIndependent = false;

  // Reactive getters exposing state properties:
  String get username => _username;
  String get profileImage => _profileImage;
  bool get darkMode => _darkMode;
  bool get gridMode => _gridMode;
  bool get enableNotifications => _enableNotifications;
  double get storageUsedGB => _storageUsedGB;
  double get storageTotalGB => _storageTotalGB;

  /// Returns a clean formatted indicator string tracking active storage limits.
  String get storageLimit => '${_storageUsedGB.toStringAsFixed(1)} GB / ${_storageTotalGB.toStringAsFixed(0)} GB';

  // Local LLM / VLM Getters
  String get ollamaUrl => _ollamaUrl;
  String get ollamaModel => _ollamaModel;
  bool get autoTagEnabled => _autoTagEnabled;
  bool get yoloIndependent => _yoloIndependent;

  /// Updates global profile display name.
  void updateUsername(String newName) {
    _username = newName;
    notifyListeners();
  }

  /// Toggles twilight vs custom scaffolding colors.
  void toggleDarkMode(bool val) {
    _darkMode = val;
    notifyListeners();
  }

  /// Toggles between grid layouts and standard flows.
  void toggleLayoutMode() {
    _gridMode = !_gridMode;
    notifyListeners();
  }

  /// Activates or silences desktop system alerts.
  void toggleNotifications(bool val) {
    _enableNotifications = val;
    notifyListeners();
  }

  /// Simulates memory sync consumption increases when clicking "Sync Now".
  ///
  /// Increments internal doubles and prevents values from exceeding 15.0 GB limits.
  void simulateStorageIncrease(double addedMb) {
    _storageUsedGB += addedMb / 1024.0;
    if (_storageUsedGB > _storageTotalGB) {
      _storageUsedGB = _storageTotalGB;
    }
    notifyListeners();
  }

  // Local LLM / VLM Setters
  /// Modifies local vision host server endpoint URL.
  void updateOllamaUrl(String newUrl) {
    _ollamaUrl = newUrl;
    notifyListeners();
  }

  /// Modifies active VLM inference model.
  void updateOllamaModel(String newModel) {
    _ollamaModel = newModel;
    notifyListeners();
  }

  /// Modifies automated vision tagging status flags.
  void toggleAutoTag(bool val) {
    _autoTagEnabled = val;
    notifyListeners();
  }

  /// Toggles standalone YOLO execution modes.
  void toggleYoloIndependent(bool val) {
    _yoloIndependent = val;
    notifyListeners();
  }
}
