import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  String _username = 'Alex Chronicle';
  final String _profileImage = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=150&auto=format&fit=crop';
  bool _darkMode = true;
  bool _gridMode = true;
  bool _enableNotifications = true;
  String _storageLimit = '2.4 GB / 15 GB';

  String get username => _username;
  String get profileImage => _profileImage;
  bool get darkMode => _darkMode;
  bool get gridMode => _gridMode;
  bool get enableNotifications => _enableNotifications;
  String get storageLimit => _storageLimit;

  void updateUsername(String newName) {
    _username = newName;
    notifyListeners();
  }

  void toggleDarkMode(bool val) {
    _darkMode = val;
    notifyListeners();
  }

  void toggleLayoutMode() {
    _gridMode = !_gridMode;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    _enableNotifications = val;
    notifyListeners();
  }

  void simulateStorageIncrease(double addedMb) {
    // Just a mock display adjustment
    _storageLimit = '2.5 GB / 15 GB';
    notifyListeners();
  }
}
