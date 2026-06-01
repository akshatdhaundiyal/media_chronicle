# Design Document: Web Elimination & Native Desktop Migration

## 1. Goal

Migrate Media Chronicle from a Flutter Web target application to a **Windows-native-only desktop application**. This involves eliminating all web-specific conditional imports, establishing direct native PostgreSQL socket connections (replacing HTTP proxy workarounds), integrating real system camera capture, refactoring native file I/O for desktop byte-stream reads, and resolving a critical asynchronous `BuildContext` lifecycle bug that silently blocked media imports.

---

## 2. Technical Architecture & Decisions

### A. Web Target Elimination

The original codebase used conditional imports (`postgres_connection_stub.dart` vs `postgres_connection_real.dart`) to abstract platform differences between Web (which cannot use raw TCP sockets) and native desktop. With the migration to Windows-only, all web shims were removed.

**Files deleted:**
*   `web/` — Entire web build target directory.
*   `lib/core/utils/postgres_connection_stub.dart` — Web stub returning no-op connections.
*   `lib/core/utils/postgres_connection_real.dart` — Native real connection wrapper.

**Impact:** The conditional import indirection layer is gone. `PostgresSyncService` now imports `package:postgres/postgres.dart` directly without platform guards.

---

### B. Direct Native PostgreSQL Socket Sync

With web eliminated, `PostgresSyncService` was rewritten to use direct TCP socket connections to a local PostgreSQL server.

**Key implementation details:**
*   **Connection**: Uses `Connection.open(Endpoint(...))` from `package:postgres` for raw socket connections.
*   **Automatic Migrations**: On first connection, the service runs DDL `CREATE TABLE IF NOT EXISTS` statements for:
    *   `media_items` — Stores SHA-256 hashes, VLM metadata, tags, and descriptions.
    *   `yolo_faces` — Stores face bounding boxes, embeddings, identities, and age variants.
*   **Settings Panel**: The `SettingsScreen` was extended with a database configuration panel allowing users to input custom host, port, database name, username, and password at runtime.
*   **Connection Status**: Real-time green/red indicator in the Settings card reflecting connection health.

---

### C. Native Desktop Media Fetching

`MediaHelper.pickMultipleFiles` and `pickFile` were refactored to handle a platform-specific nuance: on native desktop, `file_picker` returns `PlatformFile` objects where `.bytes` is `null` but `.path` is populated (the inverse of web behaviour).

**Solution:**
```dart
// Dynamic fallback: read bytes from file path when .bytes is null (native desktop)
Uint8List? bytes = platformFile.bytes;
if (bytes == null && platformFile.path != null) {
  bytes = File(platformFile.path!).readAsBytesSync();
}
```

This ensures imported media files are always available as byte arrays for SHA-256 hashing, VLM analysis, and thumbnail rendering.

---

### D. Real Camera Integration

The simulated camera capture was replaced with real native camera access:

```dart
final picker = ImagePicker();
final photo = await picker.pickImage(source: ImageSource.camera);
if (photo != null) {
  final bytes = await photo.readAsBytes();
  // Create MediaItem from real camera bytes...
}
```

**Dependencies added:** `image_picker` configured for Windows desktop with camera permissions.

---

### E. Critical Async `BuildContext` Lifecycle Bug Fix

**The Bug:**
After importing files via the upload dialog, imported media items would silently not appear in the gallery grid. No errors were thrown.

**Root Cause Analysis:**
1. `Navigator.pop(context)` was called to dismiss the upload dialog.
2. The async file picker (`FilePicker.platform.pickFiles()`) was still awaiting.
3. When the picker completed, the dialog's `BuildContext` was already unmounted.
4. The guard `if (!context.mounted) return;` evaluated to `false`, skipping all provider calls.
5. Result: files were picked but never added to `GalleryProvider`.

**Solution:**
Synchronously capture all required providers and `ScaffoldMessenger` references **before** any async gaps or dialog pops:

```dart
// BEFORE async gap — capture everything needed
final galleryProv = context.read<GalleryProvider>();
final yoloProv = context.read<YoloFaceProvider>();
final messenger = ScaffoldMessenger.of(context);

Navigator.pop(context); // Safe: providers already captured

// AFTER async gap — use captured references, not context
final files = await FilePicker.platform.pickFiles(...);
galleryProv.addMediaItem(...); // Works even though context is unmounted
```

---

## 3. Verification

*   `flutter analyze` — Clean (No issues found!)
*   `flutter test` — Clean (All test suites passed!)
*   Manual verification: Files imported from native file picker appear in gallery. Camera capture produces real photos. PostgreSQL sync writes appear in the database.
