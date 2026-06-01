# Design Document: Project-Wide Code Modularisation

## 1. Goal

Decompile three monolithic screen files (`yolo_face_screen.dart`, `settings_screen.dart`, `stories_screen.dart`) into 14 decoupled, single-responsibility sub-widgets. Each extracted widget is a standalone class with focused state dependencies, enabling independent testing, `const` constructor optimisations, and isolated repaint scopes.

---

## 2. Technical Architecture & Decisions

### A. Decomposition Strategy

The modularisation follows a systematic approach:
1. **Identify logical UI regions** — each distinct card, panel, or dialog is a decomposition candidate.
2. **Extract into class-based widgets** — move the widget tree and any local state into a new file under `widgets/`.
3. **Minimise parent coupling** — the parent screen file becomes a thin layout shell that imports and arranges child widgets.
4. **Preserve provider dependencies** — each widget declares its own `context.watch<T>()` calls, scoping reactivity to exactly the data it needs.

### B. Phase 1: YOLO Face Hub (`yolo_face_screen.dart`)

**Before:** Single 600+ line file containing the embeddings map, training terminal, enrolled timeline, unidentified queue, and all supporting UI logic.

**After:** 5 files:

| Widget | Type | Responsibility |
|--------|------|---------------|
| `yolo_embeddings_map.dart` | `StatelessWidget` + `CustomPainter` | 2D scatter plot with animated cluster nodes, identity-coloured dots, and dotted age-progression path connectors. Handles hover tooltips and click-to-select interactions. |
| `yolo_retraining_terminal.dart` | `StatefulWidget` | Auto-scrolling monospace terminal rendering epoch-by-epoch SGD loss/accuracy logs. Uses a `ScrollController` with post-frame auto-scroll to bottom. |
| `yolo_enrolled_timeline.dart` | `StatelessWidget` | Horizontal card galleries grouped by enrolled identity, showing chronological face variation thumbnails with age-variant labels. |
| `yolo_unidentified_queue.dart` | `StatelessWidget` | Active learning face list with circular thumbnails, "Label" action buttons, and inline face-count badges. Triggers the `FaceLabelingDialog`. |
| `yolo_face_screen.dart` | `StatelessWidget` | **Layout shell only** — arranges the 4 child widgets in a responsive `Row`/`Column` grid with metric HUD cards. Reduced from ~600 lines to ~228 lines. |

### C. Phase 2: Settings Screen (`settings_screen.dart`)

**Before:** Single 500+ line file with 6 inline card builder methods.

**After:** 7 files:

| Widget | Type | Responsibility |
|--------|------|---------------|
| `profile_card.dart` | `StatelessWidget` | User avatar, display name, and profile editing. |
| `llm_card.dart` | `StatefulWidget` | Ollama URL/model text inputs with cached `TextEditingController`s, connection status badge, and model dropdown. |
| `yolo_config_card.dart` | `StatelessWidget` | YOLO edge model toggle and status indicator. |
| `postgres_sync_card.dart` | `StatefulWidget` | PostgreSQL connection config, credential inputs, and auto-scrolling SQL migration log terminal. |
| `storage_card.dart` | `StatelessWidget` | Visual storage quota chart (used/total with progress bar). |
| `toggle_card.dart` | `StatelessWidget` | Dark mode and notification preference toggles. |
| `settings_screen.dart` | `StatelessWidget` | **Layout shell only** — simple `ListView` importing all card widgets. |

### D. Phase 3: Stories Screen (`stories_screen.dart`)

**Before:** Single 400+ line file with inline story cards, empty state, and dialog builders.

**After:** 5 files:

| Widget | Type | Responsibility |
|--------|------|---------------|
| `story_card.dart` | `StatelessWidget` | Individual story card with cover image, title, date, and tap-to-detail handler. |
| `stories_empty_state.dart` | `StatelessWidget` | Illustrated empty state with "Create your first story" call-to-action. |
| `create_story_dialog.dart` | `StatefulWidget` | Story creation form dialog with title, description, and cover image picker. |
| `story_detail_dialog.dart` | `StatelessWidget` | Full-screen story detail overlay with cover image and narrative content. |
| `stories_screen.dart` | `StatelessWidget` | **Layout shell only** — arranges story cards in a grid and shows the empty state when appropriate. |

---

## 3. Documentation Standards

All extracted YOLO and Settings widgets received premium inline documentation following this pattern:

```dart
/// ─── YoloRetrainingTerminal ────────────────────────────────────────
///
/// A live, auto-scrolling terminal console that renders epoch-by-epoch
/// SGD backpropagation training logs from the [YoloFaceProvider].
///
/// **Architecture:**
/// This widget is a [StatefulWidget] because it owns a [ScrollController]
/// that must be initialised once in [initState] and disposed in [dispose]
/// to prevent memory leaks.
///
/// **Data Flow:**
/// [YoloFaceProvider.trainingLogs] → [ListView.builder] → auto-scroll
///
/// **Visual Design:**
/// Monospace font on a dark card background with cyan-tinted log lines.
/// ────────────────────────────────────────────────────────────────────
```

---

## 4. Directory Structure After Modularisation

```
lib/features/
├── gallery/views/
│   ├── yolo_face_screen.dart           # Layout shell (~228 lines)
│   └── widgets/
│       └── yolo/
│           ├── yolo_embeddings_map.dart
│           ├── yolo_enrolled_timeline.dart
│           ├── yolo_retraining_terminal.dart
│           └── yolo_unidentified_queue.dart
├── settings/views/
│   ├── settings_screen.dart            # Layout shell
│   └── widgets/
│       ├── profile_card.dart
│       ├── llm_card.dart
│       ├── yolo_config_card.dart
│       ├── postgres_sync_card.dart
│       ├── storage_card.dart
│       └── toggle_card.dart
└── stories/views/
    ├── stories_screen.dart             # Layout shell
    └── widgets/
        ├── story_card.dart
        ├── stories_empty_state.dart
        ├── create_story_dialog.dart
        └── story_detail_dialog.dart
```

---

## 5. Verification

*   `flutter analyze` — Clean (No issues found!)
*   `flutter test` — Clean (All test suites passed, 100% success!)
*   All existing functionality preserved — no regressions detected.
