import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@immutable
class SettingsState {
  final String username;
  final String profileImage;
  final bool darkMode;
  final bool gridMode;
  final bool enableNotifications;
  final double storageUsedGB;
  final double storageTotalGB;
  final String ollamaUrl;
  final String ollamaModel;
  final bool autoTagEnabled;
  final bool yoloIndependent;
  final String postgresHost;
  final int postgresPort;
  final String postgresDatabase;
  final String postgresUser;
  final String postgresPassword;
  final bool postgresSsl;

  const SettingsState({
    required this.username,
    required this.profileImage,
    required this.darkMode,
    required this.gridMode,
    required this.enableNotifications,
    required this.storageUsedGB,
    required this.storageTotalGB,
    required this.ollamaUrl,
    required this.ollamaModel,
    required this.autoTagEnabled,
    required this.yoloIndependent,
    required this.postgresHost,
    required this.postgresPort,
    required this.postgresDatabase,
    required this.postgresUser,
    required this.postgresPassword,
    required this.postgresSsl,
  });

  String get storageLimit => '${storageUsedGB.toStringAsFixed(1)} GB / ${storageTotalGB.toStringAsFixed(0)} GB';

  SettingsState copyWith({
    String? username,
    String? profileImage,
    bool? darkMode,
    bool? gridMode,
    bool? enableNotifications,
    double? storageUsedGB,
    double? storageTotalGB,
    String? ollamaUrl,
    String? ollamaModel,
    bool? autoTagEnabled,
    bool? yoloIndependent,
    String? postgresHost,
    int? postgresPort,
    String? postgresDatabase,
    String? postgresUser,
    String? postgresPassword,
    bool? postgresSsl,
  }) {
    return SettingsState(
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      darkMode: darkMode ?? this.darkMode,
      gridMode: gridMode ?? this.gridMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      storageUsedGB: storageUsedGB ?? this.storageUsedGB,
      storageTotalGB: storageTotalGB ?? this.storageTotalGB,
      ollamaUrl: ollamaUrl ?? this.ollamaUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      autoTagEnabled: autoTagEnabled ?? this.autoTagEnabled,
      yoloIndependent: yoloIndependent ?? this.yoloIndependent,
      postgresHost: postgresHost ?? this.postgresHost,
      postgresPort: postgresPort ?? this.postgresPort,
      postgresDatabase: postgresDatabase ?? this.postgresDatabase,
      postgresUser: postgresUser ?? this.postgresUser,
      postgresPassword: postgresPassword ?? this.postgresPassword,
      postgresSsl: postgresSsl ?? this.postgresSsl,
    );
  }
}

@riverpod
class Settings extends _$Settings {
  @override
  SettingsState build() {
    return const SettingsState(
      username: 'Alex Chronicle',
      profileImage: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=150&auto=format&fit=crop',
      darkMode: true,
      gridMode: true,
      enableNotifications: true,
      storageUsedGB: 2.4,
      storageTotalGB: 15.0,
      ollamaUrl: 'http://localhost:11434',
      ollamaModel: '',
      autoTagEnabled: true,
      yoloIndependent: false,
      postgresHost: 'localhost',
      postgresPort: 5432,
      postgresDatabase: 'chronicle',
      postgresUser: 'postgres',
      postgresPassword: 'password',
      postgresSsl: false,
    );
  }

  void updateUsername(String newName) {
    state = state.copyWith(username: newName);
  }

  void toggleDarkMode(bool val) {
    state = state.copyWith(darkMode: val);
  }

  void toggleLayoutMode() {
    state = state.copyWith(gridMode: !state.gridMode);
  }

  void toggleNotifications(bool val) {
    state = state.copyWith(enableNotifications: val);
  }

  void simulateStorageIncrease(double addedMb) {
    double nextGB = state.storageUsedGB + addedMb / 1024.0;
    if (nextGB > state.storageTotalGB) {
      nextGB = state.storageTotalGB;
    }
    state = state.copyWith(storageUsedGB: nextGB);
  }

  void updateOllamaUrl(String newUrl) {
    state = state.copyWith(ollamaUrl: newUrl);
  }

  void updateOllamaModel(String newModel) {
    state = state.copyWith(ollamaModel: newModel);
  }

  void toggleAutoTag(bool val) {
    state = state.copyWith(autoTagEnabled: val);
  }

  void toggleYoloIndependent(bool val) {
    state = state.copyWith(yoloIndependent: val);
  }

  void updatePostgresHost(String host) {
    state = state.copyWith(postgresHost: host);
  }

  void updatePostgresPort(int port) {
    state = state.copyWith(postgresPort: port);
  }

  void updatePostgresDatabase(String db) {
    state = state.copyWith(postgresDatabase: db);
  }

  void updatePostgresUser(String user) {
    state = state.copyWith(postgresUser: user);
  }

  void updatePostgresPassword(String password) {
    state = state.copyWith(postgresPassword: password);
  }

  void togglePostgresSsl(bool val) {
    state = state.copyWith(postgresSsl: val);
  }
}
