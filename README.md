# 🌌 Media Chronicle

A premium, responsive **Flutter Web** application designed to organize, capture, and archive personal memories, timelines, and media streams in a modern, dark glassmorphic dashboard.

---

## ✨ Design Philosophy & Premium Aesthetics

Media Chronicle is built to stun at first glance, featuring a modern **twilight ambient design system**:
* **Frosted Acrylic Panels**: Semi-transparent, glassmorphic cards using advanced `BackdropFilter` styling and subtle borders (`Color(0x1BFFFFFF)`) for a premium layout.
* **Vibrant Accent Glows**: Ambient neon pink and deep violet lighting circles strategically floating behind workspace elements.
* **Sophisticated Typography**: Uses the geometric Google Font **Outfit** to establish an elegant, high-tech editorial layout.
* **Smooth Transitions**: Micro-animations on tabs, interactive list entries, and responsive state changes.

---

## 🏗️ Architecture & Directory Mapping

The codebase adopts a highly scalable, **feature-first architecture** which splits logic, views, and data models by business domain to ensure clean separation of concerns.

```
lib/
├── main.dart                      # App coordinator & MultiProvider shell setup
├── core/                          # Cross-cutting concerns & shared systems
│   ├── constants/
│   │   └── app_constants.dart     # Central theme colors, spacing tokens, and mock data
│   ├── theme/
│   │   └── app_theme.dart         # Customized dark theme & font declarations
│   └── utils/
│       └── media_helper.dart      # Media capture and local file picking facade
├── features/                      # Domain-specific features
│   ├── stories/                   # Memory Narrative timelines
│   │   ├── models/
│   │   │   └── story_item.dart    # Story structure model
│   │   ├── providers/
│   │   │   └── stories_provider.dart  # Chronological story collection controller
│   │   └── views/
│   │       └── stories_screen.dart # Timeline view and draft dialog
│   ├── gallery/                   # Photo & Video catalog archiving
│   │   ├── models/
│   │   │   ├── media_item.dart    # Individual media element (image/video)
│   │   │   └── detected_face.dart # YOLO detected face coordinates and embeddings
│   │   ├── providers/
│   │   │   ├── gallery_provider.dart  # Media list controller
│   │   │   └── yolo_face_provider.dart # YOLO Face classifier and active-learning trainer
│   │   └── views/
│   │       ├── gallery_screen.dart # Masonry gallery grid, detail lightboxes & bounding box overlays
│   │       └── yolo_face_screen.dart # YOLO Face Hub dashboard with cluster maps & training terminals
│   └── settings/                  # Control Center configurations
│       ├── providers/
│       │   └── settings_provider.dart # Preference & host name state
│       └── views/
│           └── settings_screen.dart # Toggles, profile cards, and storage charts
└── state/
    └── app_state.dart             # Global coordination (current tab selection & search queries)
```

---

## 🛠️ Tech Stack & Key Libraries

* **Framework**: Flutter 3.41+ (Targeted for **Flutter Web** to ensure compile-dependency-free initial testing).
* **State Management**: `provider` (coordinating separate reactive notifier streams via a central `MultiProvider`).
* **Fonts**: `google_fonts` (loading the modern geometric family `Outfit`).
* **Media Handling**:
  * `file_picker` (optimized for memory-byte retrieval under web environments).
  * `image_picker` (providing fallback options for device cameras).

---

## 🌟 Key Application Features

1. **Memory Stories (Timelines)**:
   * Displays narrative memories chronologically with beautiful ambient cover cards.
   * Offers a modular story compiler dialog allowing hosts to publish custom memories.
2. **Media Gallery (Photo Archive)**:
   * Renders media items inside a responsive grid adjusting from 2 to 4 columns depending on browser dimensions.
   * Prompts hosts to browse local files or simulate instant camera captures for mock testing.
   * Includes detailed image preview lightboxes that gracefully dim the active screen.
3. **Workspace Control Center**:
   * Enables hosts to modify display names instantly across the workspace sidebar.
   * Monitors local database synchronization and displays visual clouds quota charts (e.g., 2.4 GB / 15 GB).
   * Switches on/off vibrant twilight theme styles and notifications.
4. **Global Workspace Search**:
   * An integrated search filter located in the header coordinates query values across all providers, filtering both gallery assets and story narratives dynamically in real-time.
5. **YOLO Self-Retraining Face Engine (Active Learning)**:
   * **Responsive Bounding Box Overlays**: Displays glowing neon pink and cyber-cyan overlays on top of media files with clickable regions to label unidentified faces.
   * **SGD Live Trainer Terminal**: A real-time training dashboard showing decreasing loss and increasing accuracy inside a scrolling, retro-style terminal window as the model self-retrains.
   * **Chronological Age Timeline**: Implements beautiful visual galleries for enrolled people, showing their physical changes over the years.
   * **2D Vector Embeddings Cluster Map**: Features a custom-painted interactive 2D coordinate plot mapping face vector groups, linking age progression variations with subtle dotted paths.
   * **Low Similarity & Growth Conflicts**: Handles physical age drift by asking the user to confirm whether a low-confidence match of an existing person is the "Same Person (Age Variant)" or a different identity, triggering customized retraining parameters.

---

## 🚀 Getting Started

### 📋 Prerequisites
* Ensure Flutter SDK is installed and available in your environment path.
* Google Chrome, Microsoft Edge, or a similar modern browser for local web execution.

### 💻 Running the Application
To run the server and host the interactive workspace dashboard locally in your browser:
```bash
flutter run -d chrome
```

### 🧪 Executing Unit & Widget Tests
Run the comprehensive test suite verifying the viewport setups and responsive sidebar elements:
```bash
flutter test
```

### 🔍 Static Code Analysis
Run the strict Flutter linter to verify zero compiler warnings and clean syntax scores:
```bash
flutter analyze
```
> [!NOTE]  
> The codebase has been fully refactored in Milestone 5 to resolve all 12 key architectural audit recommendations, providing a highly decoupled, clean feature-first architecture, immutable data structures, O(1) performance grid rebuild bounds, dry dialog widgets, and extensive testing coverage.

## 🛠️ Key Refactoring Achievements (Milestone 5)

1. **Modular Widget Class Decomposition**: Broken down the monolithic 2,022-line `gallery_screen.dart` into 8 separate single-responsibility sub-widgets under `lib/features/gallery/views/widgets/`.
2. **Lifecycle Stability & StatefulWidget Caching**: Moved LLM poller initialization out of Stateless build bounds into stateful `initState` post-frame callbacks, preventing polling loop re-triggers.
3. **Strict Model Immutability**: Refactored `MediaItem` and `DetectedFace` to have completely final attributes, unmodifiable embedding lists, and copyWith copy handlers.
4. **Selective O(1) Rebuild Bounds**: Integrated `Selector` structures into Gallery cards, preventing generic card updates when face labeling events occur elsewhere.
5. **Robust Test Coverage**: Wrote lightweight unit tests covering all provider state models in `test/providers_unit_test.dart` to guarantee future quality constraints.
