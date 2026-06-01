# Milestone Summary: Media Chronicle

This document maintains a high-level summary index of all major achievements, technical audits, and milestones completed in the Media Chronicle repository.

---

## 📅 Milestone Index

### Milestone 1: Initial Scaffolding & Visual Foundation (Completed: May 26, 2026)
*   **Description**: Scaffolded the client-side Flutter application with feature-first folder architecture, Provider state management systems, and the ambient glassmorphic twilight design system.
*   **Design Document**: [01_scaffold_media_chronicle.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/01_scaffold_media_chronicle.md)
*   **Achievements**:
    *   Setup responsive desktop sidebar navigation with session profile metadata, storage meters, and floating menu items.
    *   Implemented compact bottom navigation bar for mobile viewports.
    *   Built custom `MediaHelper` handlers supporting device memory-byte uploads and native file-path reads.
    *   Configured global search query synchronizers filtering stories and gallery assets simultaneously.
    *   Established the premium `Outfit` typography and frosted acrylic card design system.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)
    *   `flutter test` — Clean (Smoke tests pass!)

---

### Milestone 2: YOLO Face Recognition & Online Self-Retraining Engine (Completed: May 27, 2026)
*   **Description**: Built a high-fidelity self-retraining YOLO Face recognition engine featuring glowing interactive face bounding box overlays, age-progression variance validation, 2D vector cluster maps, chronological age timelines, and scrolling backpropagation log terminals.
*   **Design Document**: [02_yolo_self_retraining_face_recognition.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/02_yolo_self_retraining_face_recognition.md)
*   **Achievements**:
    *   Implemented full `YoloFaceProvider` state machine with mock SGD retraining loop.
    *   Engineered responsive floating bounding box overlays using `LayoutBuilder` for pixel-perfect aspect-ratio alignment.
    *   Formed identity timeline galleries showing physical changes over time (childhood → adulthood).
    *   Added low-similarity validations prompting hosts for age progression confirmations on low-confidence matches (>25 embedding distance).
    *   Built custom-painted 2D scatter plot (`YoloEmbeddingsMap`) mapping face vectors with dotted age-progression paths.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)

---

### Milestone 3: Sequential Ingestion Queues & Multi-Select Archive Actions (Completed: May 27, 2026)
*   **Description**: Implemented a robust sequential VLM queue pipeline preventing local Ollama server overloads, coupled with YOLO→VLM prompt sequencing and a premium multi-selection batch action system (Move, Copy, Delete, Re-run VLM).
*   **Design Document**: [03_sequential_queue_multiselect_actions.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/03_sequential_queue_multiselect_actions.md)
*   **Achievements**:
    *   Developed a single-threaded sequential VLM request queue (`_processVlmQueue`) with 90-second timeout and automatic visual fallback on offline states.
    *   Coordinated YOLO synchronous face tagging *first* to feed recognized names into subsequent VLM prompts via `preIdentifiedFaces`.
    *   Formed interactive selection mode in the gallery with checkmark overlays and custom neon borders.
    *   Added Move, Copy, Delete, and Re-run VLM batch action handlers operating on the selection set.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)

---

### Milestone 4: Performance, Lifecycle, & Best Practices Audit (Completed: May 27, 2026)
*   **Description**: Comprehensive refactoring audit resolving controller lifecycle bugs, cursor-jump text input defects, `ScrollController` memory leaks, model immutability violations, repaint boundary inefficiencies, and compiler scoping errors.
*   **Design Document**: [04_architectural_best_practices_refactoring.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/04_architectural_best_practices_refactoring.md)
*   **Achievements**:
    *   Migrated dynamic builder helper methods to class-based `StatelessWidget` and `StatefulWidget` cards across Settings and Gallery screens.
    *   Converted `LlmCard` to `StatefulWidget` to cache inline `TextEditingController`s, resolving typing cursor-jump resets.
    *   Converted `PostgresSyncCard` to `StatefulWidget` to safely manage `ScrollController` initialisation and disposal.
    *   Moved LLM poller initialisation from stateless build scopes into `initState` post-frame callbacks, preventing polling loop re-triggers.
    *   Fixed a nested class scoping syntax error in `gallery_screen.dart` causing 68 compile warnings.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)

---

### Milestone 5: Comprehensive Refactoring & Quality Improvements (Completed: May 27, 2026)
*   **Description**: Resolved all 12 key architectural review findings. Decomposed monolithic screen files into high-performance sub-widgets, established full model immutability contracts, unified duplicate dialog classes, isolated repaint bounds with granular `Selector` models, and created a comprehensive provider testing suite.
*   **Design Document**: [04_architectural_best_practices_refactoring.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/04_architectural_best_practices_refactoring.md)
*   **Achievements**:
    *   Broken down the 2,022-line `gallery_screen.dart` into 8 separate sub-widgets inside a dedicated widgets folder.
    *   Implemented unmodifiable lists in model constructors and safe `copyWith` mappings for strict state immutability.
    *   Replaced inline labelling forms with a unified, dual-step `FaceLabelingDialog`.
    *   Integrated O(1) selective `Selector<YoloFaceProvider, List<DetectedFace>>` grid elements to prevent full-screen rebuild cycles.
    *   Created `providers_unit_test.dart` covering all provider classes.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)
    *   `flutter test` — Clean (All provider and widget test suites passed!)

---

### Milestone 6: On-Device Mathematical Machine Learning Engine (Completed: June 1, 2026)
*   **Description**: Transitioned the YOLO face identification engine from a timed visual simulation to a mathematically rigorous, 100% offline, on-device Single-Layer Perceptron (Multi-Class Softmax Classifier / Logistic Regression) head written in pure Dart.
*   **Design Document**: [02_yolo_self_retraining_face_recognition.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/02_yolo_self_retraining_face_recognition.md)
*   **Knowledge Base**: [05_pure_dart_machine_learning.md](file:///d:/lab/projects/media_chronicle/docs/knowledge_base/05_pure_dart_machine_learning.md)
*   **Achievements**:
    *   Designed a standalone `SingleLayerPerceptron` class executing real Multi-Class Softmax predictions in pure Dart with numerical stability guarantees.
    *   Engineered on-device SGD backpropagation computing exact cross-entropy loss derivatives to update weights and biases locally in milliseconds.
    *   Refactored active learning loops to run true inference probabilities, replacing distance-based thresholds with real prediction confidence boundaries (82–88%).
    *   Auto-recognition inference automatically labels unidentified faces and syncs to PostgreSQL.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)
    *   `flutter test` — Clean (All test suites passed!)

---

### Milestone 7: Web Elimination & Native Desktop Migration (Completed: June 1, 2026)
*   **Description**: Migrated Media Chronicle from a Flutter Web target to a Windows-native-only desktop application. Removed all web-specific conditional imports, established direct native PostgreSQL socket connections, integrated real camera capture, and fixed critical async `BuildContext` lifecycle bugs.
*   **Design Document**: [05_native_desktop_migration.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/05_native_desktop_migration.md)
*   **Achievements**:
    *   **Web Elimination**: Deleted `web/` target build configurations and conditional import wrappers (`postgres_connection_stub.dart`, `postgres_connection_real.dart`).
    *   **Direct PostgreSQL Sync**: Implemented native socket connection logic inside `PostgresSyncService` using `package:postgres/postgres.dart`. Configured automatic DDL schema migrations on start-up.
    *   **Native Media Fetching**: Refactored `MediaHelper` to handle null file bytes on desktop platforms with a dynamic `dart:io` fallback for `PlatformFile.path` reads.
    *   **Real Camera Integration**: Replaced simulated camera capturing with real `ImagePicker(source: ImageSource.camera)` native photo byte retrieval.
    *   **Async Lifecycle Bug Fix**: Resolved silent media import hang where `Navigator.pop(context)` was called before async picker completion, unmounting the `BuildContext`. Solution: synchronously capture all providers and scaffold messenger references *before* async gaps.
    *   **Settings Panel**: Added database configuration panel to toggle and input custom PostgreSQL credentials on the fly.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)
    *   `flutter test` — Clean (All test suites passed!)

---

### Milestone 8: Fast-Load Queue & Offline Bypass Optimisation (Completed: June 1, 2026)
*   **Description**: Eliminated the 90-second socket connection timeout delay when the local Ollama VLM server is offline. Implemented intelligent fast-load bypass detection and real-time UI status indicators.
*   **Design Document**: [06_fast_load_bypass.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/06_fast_load_bypass.md)
*   **Achievements**:
    *   **Fast-Load Bypass**: Added intelligent detection inside `_processVlmQueue` that checks `_isLlmAvailable == false` and instantly skips network connection attempts.
    *   **1.2-Second Fallback**: Engaging the high-fidelity smart visual fallback simulator within 1.2 seconds instead of waiting 90 seconds.
    *   **Status Indicators**: Added real-time glowing VLM & YOLO status indicators (red/green) in both the `DashboardHeader` and `SettingsScreen` cards.
    *   **Background Polling**: 8-second periodic polling timer (`Timer.periodic`) checks Ollama endpoint availability and updates the UI reactively.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)

---

### Milestone 9: Project-Wide Code Modularisation (Completed: June 1, 2026)
*   **Description**: Decompiled three monolithic screen files (`yolo_face_screen.dart`, `settings_screen.dart`, `stories_screen.dart`) into 14 decoupled, single-responsibility sub-widgets with extensive inline documentation.
*   **Design Document**: [07_code_modularisation.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/07_code_modularisation.md)
*   **Achievements**:
    *   **YOLO Face Hub** — Extracted 4 sub-widgets:
        *   `yolo_embeddings_map.dart` — Custom 2D scatter plot with `CustomPainter`, animated cluster nodes, and identity-linked dotted paths.
        *   `yolo_retraining_terminal.dart` — Auto-scrolling backpropagation terminal with monospace log rendering.
        *   `yolo_enrolled_timeline.dart` — Chronological age progression galleries per enrolled identity.
        *   `yolo_unidentified_queue.dart` — Active labelling queue with face thumbnails and label triggers.
    *   **Settings Screen** — Extracted 6 card widgets:
        *   `profile_card.dart`, `llm_card.dart`, `yolo_config_card.dart`, `postgres_sync_card.dart`, `storage_card.dart`, `toggle_card.dart`.
    *   **Stories Screen** — Extracted 4 child widgets:
        *   `story_card.dart`, `stories_empty_state.dart`, `create_story_dialog.dart`, `story_detail_dialog.dart`.
    *   Reduced parent screen files to clean structural layout shells (~50–100 lines each).
    *   Added premium, high-fidelity inline documentation to all 5 YOLO/Settings widgets.
*   **Audits**:
    *   `flutter analyze` — Clean (No issues found!)
    *   `flutter test` — Clean (All test suites passed, 100% success!)

---

### Milestone 10: Python YOLO Training Pipeline & Experimentation Notebook (Completed: June 1, 2026)
*   **Description**: Created a complete, modular Python pipeline for real YOLOv8 face-detection training, inference, evaluation, data preparation, and model export. All scripts use PEP 723 inline script metadata for zero-config `uv run` execution with isolated ephemeral environments. Includes a 9-section Jupyter notebook for interactive experimentation.
*   **Design Document**: [08_python_yolo_pipeline.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/08_python_yolo_pipeline.md)
*   **Achievements**:
    *   **Shared Utilities** (`scripts/utils/`):
        *   `config.py` — Centralised `YoloConfig` dataclass with YAML → environment variable → CLI flag override cascade and automatic project root resolution.
        *   `logging_setup.py` — Idempotent logging factory with Rich console output and rotating file handler (10 MB, 5 backups).
        *   `data_transforms.py` — Albumentations augmentation pipeline builder and annotation format converters (COCO ↔ YOLO ↔ Pascal VOC).
    *   **Pipeline Scripts** (PEP 723 inline metadata):
        *   `yolo_train.py` — Training entrypoint with CLI args, dataset validation, structured JSON stdout streaming for the Flutter `YoloRetrainingTerminal` widget, and Ultralytics training orchestrator.
        *   `yolo_detect.py` — Face-detection inference on single files, directories, or glob patterns. Outputs annotated images and/or JSON results.
        *   `yolo_evaluate.py` — Model evaluation with mAP@50, mAP@50-95, precision, recall, per-class metrics, and confusion matrix generation.
        *   `yolo_data_prep.py` — Sub-command CLI for dataset scaffolding, train/val splitting, COCO/VOC→YOLO annotation conversion, offline augmentation, and dataset statistics.
        *   `yolo_export.py` — Model export to ONNX, TorchScript, TFLite, CoreML, OpenVINO, and TensorRT formats.
    *   **Configuration**: `yolo_config.yaml` with documented hyperparameter defaults.
    *   **Documentation**: `scripts/README.md` with quick-start guide, script overview, and Flutter integration instructions.
    *   **Experimentation Notebook** (`experiments/yolo_pipeline.ipynb`):
        *   §1 Environment setup & configuration
        *   §2 Dataset preparation & exploration with bbox visualisation
        *   §3 Augmentation pipeline preview (8 variants side-by-side)
        *   §4 Model training with live progress
        *   §5 Training metrics visualisation (loss/mAP/precision/recall curves from CSV)
        *   §6 Formal model evaluation
        *   §7 Inference & detection visualisation with drawn bounding boxes
        *   §8 Model export (ONNX)
        *   §9 Embedding cluster analysis, softmax classifier training, and decision boundary visualisation (mirrors Dart `SingleLayerPerceptron`)
    *   **Flutter Integration**: Scripts emit JSON events (`train_start`, `epoch_end`, `train_end`, `detection_complete`, `evaluation_complete`, `export_complete`) to stdout, consumed by `Process.start('uv', ['run', ...])` in the Dart app.
    *   **Updated `.gitignore`** for `runs/`, `datasets/`, `__pycache__/`, `.ipynb_checkpoints/`.
*   **Audits**:
    *   All scripts syntactically valid with PEP 723 metadata.
    *   Flutter codebase unaffected — `flutter analyze` clean.

---

## 📊 Milestone Timeline

```mermaid
gantt
    title Media Chronicle Development Timeline
    dateFormat YYYY-MM-DD
    axisFormat %b %d

    section Foundation
    M1 - Scaffolding & Visual Foundation     :done, m1, 2026-05-26, 1d
    M2 - YOLO Face Recognition Engine        :done, m2, 2026-05-27, 1d
    M3 - Sequential Queues & Multi-Select    :done, m3, 2026-05-27, 1d

    section Quality & Performance
    M4 - Performance & Lifecycle Audit       :done, m4, 2026-05-27, 1d
    M5 - Comprehensive Refactoring           :done, m5, 2026-05-27, 1d

    section Native Desktop Migration
    M6 - On-Device ML Engine                 :done, m6, 2026-06-01, 1d
    M7 - Web Elimination & Native Migration  :done, m7, 2026-06-01, 1d
    M8 - Fast-Load & Offline Bypass          :done, m8, 2026-06-01, 1d

    section Modularisation & Python
    M9 - Project-Wide Modularisation         :done, m9, 2026-06-01, 1d
    M10 - Python YOLO Pipeline               :done, m10, 2026-06-01, 1d
```

---

## 📁 Current Project Structure

```
media_chronicle/
├── lib/
│   ├── main.dart                          # App coordinator & MultiProvider shell
│   ├── core/
│   │   ├── constants/app_constants.dart   # Theme tokens, spacing, mock data
│   │   ├── theme/app_theme.dart           # Dark theme & font declarations
│   │   └── utils/
│   │       ├── llm_helper.dart            # Ollama VLM HTTP client
│   │       ├── media_helper.dart          # Native file picking & camera facade
│   │       └── postgres_sync_service.dart # Direct PostgreSQL socket sync
│   ├── features/
│   │   ├── gallery/
│   │   │   ├── models/
│   │   │   │   ├── media_item.dart        # Immutable media element + SHA-256
│   │   │   │   ├── detected_face.dart     # Face bbox, embeddings, identity
│   │   │   │   └── album.dart             # Memory folder container
│   │   │   ├── providers/
│   │   │   │   ├── gallery_provider.dart   # Media catalog + VLM queue
│   │   │   │   └── yolo_face_provider.dart # YOLO detection + SingleLayerPerceptron
│   │   │   └── views/
│   │   │       ├── gallery_screen.dart     # Masonry grid, lightboxes, uploads
│   │   │       ├── yolo_face_screen.dart   # YOLO Hub layout shell
│   │   │       └── widgets/
│   │   │           ├── gallery_card.dart
│   │   │           └── yolo/
│   │   │               ├── yolo_embeddings_map.dart
│   │   │               ├── yolo_enrolled_timeline.dart
│   │   │               ├── yolo_retraining_terminal.dart
│   │   │               └── yolo_unidentified_queue.dart
│   │   ├── settings/
│   │   │   ├── providers/settings_provider.dart
│   │   │   └── views/
│   │   │       ├── settings_screen.dart    # ListView shell
│   │   │       └── widgets/
│   │   │           ├── profile_card.dart
│   │   │           ├── llm_card.dart
│   │   │           ├── yolo_config_card.dart
│   │   │           ├── postgres_sync_card.dart
│   │   │           ├── storage_card.dart
│   │   │           └── toggle_card.dart
│   │   └── stories/
│   │       ├── models/story_item.dart
│   │       ├── providers/stories_provider.dart
│   │       └── views/
│   │           ├── stories_screen.dart     # Coordinator shell
│   │           └── widgets/
│   │               ├── story_card.dart
│   │               ├── stories_empty_state.dart
│   │               ├── create_story_dialog.dart
│   │               └── story_detail_dialog.dart
│   └── state/app_state.dart               # Global tab & search coordination
├── scripts/                               # Python YOLO pipeline
│   ├── yolo_train.py                      # Training entrypoint
│   ├── yolo_detect.py                     # Inference runner
│   ├── yolo_evaluate.py                   # Validation metrics
│   ├── yolo_export.py                     # Model format export
│   ├── yolo_data_prep.py                  # Dataset preparation CLI
│   ├── yolo_config.yaml                   # Default hyperparameters
│   ├── README.md                          # Usage guide
│   └── utils/
│       ├── __init__.py
│       ├── config.py                      # YoloConfig dataclass
│       ├── logging_setup.py               # Rich + rotating file logger
│       └── data_transforms.py             # Augmentation + format converters
├── experiments/
│   └── yolo_pipeline.ipynb                # Interactive experimentation notebook
├── docs/
│   ├── design_docs/                       # Milestone design documents
│   └── knowledge_base/                    # Technical lessons learned
├── test/                                  # Flutter unit & widget tests
├── windows/                               # Native Windows runner
└── pubspec.yaml
```
