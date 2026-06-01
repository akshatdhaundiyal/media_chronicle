# Design Document: Fast-Load Queue & Offline Bypass Optimisation

## 1. Goal

Eliminate the 90-second socket connection timeout delay experienced when the local Ollama VLM server is offline or unreachable. Implement an intelligent fast-load bypass that detects offline state and immediately engages visual fallback simulators, reducing media import latency from ~90 seconds to ~1.2 seconds.

---

## 2. Technical Architecture & Decisions

### A. The Problem: 90-Second Import Hang

When a user imports a media file with auto-tagging enabled, the `_processVlmQueue` method in `GalleryProvider` attempts to connect to the local Ollama server. If the server is offline, the HTTP client blocks for up to **90 seconds** waiting for the TCP socket to time out before falling back to the simulated analysis.

For users who don't have Ollama running (or during cold boot), every imported image hangs for 90 seconds — making the app feel broken.

### B. Solution: Intelligent Fast-Load Bypass

A background polling system was already checking Ollama availability every 8 seconds via `startLlmPoller()`. The fix leverages this existing `_isLlmAvailable` flag inside the VLM queue processor:

```dart
Future<void> _processVlmQueue() async {
  while (_vlmQueue.isNotEmpty) {
    final task = _vlmQueue.removeAt(0);
    
    Map<String, String>? results;
    
    if (_isLlmAvailable) {
      // Server is known to be online — attempt real VLM analysis
      results = await LlmHelper.analyzeImage(...);
    }
    // If _isLlmAvailable is false, skip the network call entirely
    
    if (results == null) {
      // Engage fallback simulator immediately (~1.2 seconds)
      results = await LlmHelper.getSmartSimulatedAnalysis(bytes);
    }
  }
}
```

**Key insight:** By checking `_isLlmAvailable` *before* attempting the HTTP connection, we skip the 90-second timeout entirely when the server is known to be offline.

### C. Background Availability Poller

The poller runs independently on an 8-second `Timer.periodic` cycle:

```dart
void startLlmPoller(String url) {
  _llmPoller?.cancel();
  checkLlmConnection(url);  // Check immediately
  _llmPoller = Timer.periodic(const Duration(seconds: 8), (_) {
    checkLlmConnection(url);
  });
}
```

`checkLlmConnection()` makes a lightweight HTTP GET to the Ollama `/api/tags` endpoint. If it responds, `_isLlmAvailable = true` and the pulled models list is updated. If it fails, `_isLlmAvailable = false`.

### D. Real-Time UI Status Indicators

Visual status indicators were added to give users immediate feedback on service availability:

*   **Dashboard Header**: Glowing green dot = VLM online; red dot = VLM offline. Same for YOLO edge model.
*   **Settings Screen**: `LlmCard` and `YoloConfigCard` show real-time connection badges that update reactively via `context.watch<GalleryProvider>()` and `context.watch<YoloFaceProvider>()`.

---

## 3. Performance Impact

| Scenario | Before | After |
|----------|--------|-------|
| Import with VLM online | ~4–8s | ~4–8s (unchanged) |
| Import with VLM offline | **~90s** (timeout) | **~1.2s** (instant fallback) |
| Import with VLM offline (5 images batch) | **~7.5 min** | **~6s** |

---

## 4. Verification

*   `flutter analyze` — Clean (No issues found!)
*   Manual testing: With Ollama stopped, importing 5 images completes in ~6 seconds with full simulated metadata.
