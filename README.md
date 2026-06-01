# 🌌 Media Chronicle

A premium, responsive native **Windows Desktop** application designed to organize, capture, and archive personal memories, timelines, and media streams in a modern, dark glassmorphic offline-first dashboard — powered by on-device YOLO face detection, real-time neural retraining, and a modular Python ML pipeline.

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
media_chronicle/
├── lib/
│   ├── main.dart                          # App coordinator & MultiProvider shell
│   ├── core/
│   │   ├── constants/app_constants.dart   # Theme tokens, spacing, mock data
│   │   ├── theme/app_theme.dart           # Dark theme & font declarations
│   │   └── utils/
│   │       ├── llm_helper.dart            # Ollama VLM HTTP client & fallback simulator
│   │       ├── media_helper.dart          # Native file picking & camera facade
│   │       └── postgres_sync_service.dart # Direct native PostgreSQL socket sync + DDL migrations
│   ├── features/
│   │   ├── gallery/
│   │   │   ├── models/
│   │   │   │   ├── media_item.dart        # Immutable media element with SHA-256 hashing
│   │   │   │   ├── detected_face.dart     # Face bbox, 2D embeddings, identity, age variant
│   │   │   │   └── album.dart             # Memory folder container
│   │   │   ├── providers/
│   │   │   │   ├── gallery_provider.dart   # Media catalog + sequential VLM queue
│   │   │   │   └── yolo_face_provider.dart # YOLO detection + SingleLayerPerceptron classifier
│   │   │   └── views/
│   │   │       ├── gallery_screen.dart     # Masonry grid, lightboxes, uploads
│   │   │       ├── yolo_face_screen.dart   # YOLO Hub layout shell
│   │   │       └── widgets/
│   │   │           ├── gallery_card.dart
│   │   │           └── yolo/
│   │   │               ├── yolo_embeddings_map.dart     # Custom 2D scatter plot
│   │   │               ├── yolo_enrolled_timeline.dart  # Chronological age galleries
│   │   │               ├── yolo_retraining_terminal.dart # SGD log terminal
│   │   │               └── yolo_unidentified_queue.dart # Active labelling queue
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
├── scripts/                               # Python YOLO pipeline (uv run)
│   ├── yolo_train.py                      # Training entrypoint
│   ├── yolo_detect.py                     # Inference runner
│   ├── yolo_evaluate.py                   # Validation metrics
│   ├── yolo_export.py                     # Model format export (ONNX, TFLite, etc.)
│   ├── yolo_data_prep.py                  # Dataset preparation CLI
│   ├── yolo_config.yaml                   # Default hyperparameters
│   ├── README.md                          # Python pipeline usage guide
│   └── utils/                             # Shared Python utilities
│       ├── __init__.py
│       ├── config.py                      # YoloConfig dataclass
│       ├── logging_setup.py               # Rich + rotating file logger
│       └── data_transforms.py             # Augmentation + format converters
├── experiments/
│   └── yolo_pipeline.ipynb                # Interactive ML experimentation notebook
├── docs/
│   ├── design_docs/                       # Milestone design documents (see below)
│   └── knowledge_base/                    # Technical lessons learned (see below)
├── test/                                  # Flutter unit & widget tests
├── windows/                               # Native Windows runner
├── pyproject.toml                         # Centralized Python workspace config (non-package uv sync)
└── pubspec.yaml                           # Flutter project configuration
```

---

## 🛠️ Tech Stack & Key Libraries

### Flutter Desktop Application
* **Framework**: Flutter 3.41+ (targeted for **Windows Desktop** native platform).
* **Database Sync**: `postgres` (direct local TCP socket connection with automated DDL migrations).
* **State Management**: `provider` (coordinating separate reactive notifier streams via a central `MultiProvider`).
* **Fonts**: `google_fonts` (loading the modern geometric family `Outfit`).
* **Media Handling**:
  * `file_picker` (optimised for desktop file-path stream reads with `dart:io` fallback).
  * `image_picker` (integrated for native system camera snapshots).
* **Machine Learning**: Pure Dart `SingleLayerPerceptron` — Multi-Class Softmax Classifier with real SGD backpropagation for on-device face recognition.

### Python YOLO Pipeline & Workspace
* **ML Framework**: Ultralytics YOLOv8 (training, inference, evaluation, export).
* **Dependency & Environment Management**: Dual-mode **uv** system:
  * *Standalone Execution (Flutter production)*: Uses PEP 723 inline script metadata for dynamic environment creation on-demand.
  * *Local Development (Jupyter/IDE)*: Uses a centralized, optimized non-package `pyproject.toml` configuration (`uv sync` installs a unified `.venv` kernel).
* **Performance Enhancements**: Headless opencv (`opencv-python-headless`) configuration strips out redundant desktop GUI shims, reducing startup latency and memory usage. Heavy notebook graphing libraries are decoupled into isolated dev groups.
* **Augmentation**: Albumentations (geometric + photometric transforms with bbox consistency).
* **Logging**: Rich (colour-coded console output) + Python `logging` (rotating file handler).
* **Notebook**: Jupyter (9-section comprehensive visual and cluster experimentation environment).

---

## 🌟 Key Application Features

### 1. Memory Stories (Timelines)
*   Displays narrative memories chronologically with beautiful ambient cover cards.
*   Offers a modular story compiler dialog allowing hosts to publish custom memories.

### 2. Media Gallery (Photo Archive)
*   Renders media items inside a responsive grid adjusting from 2 to 4 columns depending on viewport dimensions.
*   Supports local file browsing and real native camera capture.
*   Includes detailed image preview lightboxes with floating YOLO face bounding box overlays.
*   SHA-256 deduplication prevents duplicate imports.

### 3. Workspace Control Center
*   Enables hosts to modify display names instantly across the workspace sidebar.
*   Monitors local database synchronisation with real-time SQL migration logs.
*   Configures Ollama VLM server URL, vision model, and YOLO edge model settings.
*   Displays visual storage quota charts (e.g., 2.4 GB / 15 GB).
*   Switches on/off twilight theme styles and notifications.

### 4. Global Workspace Search
*   An integrated search filter in the header coordinates query values across all providers, filtering both gallery assets and story narratives dynamically in real-time.

### 5. YOLO Face Recognition & Active Learning Engine
*   **Responsive Bounding Box Overlays**: Glowing neon cyan (recognised) and rose pink (unknown) overlays on media detail views with clickable label triggers.
*   **On-Device Neural Classifier**: A mathematically rigorous `SingleLayerPerceptron` (Multi-Class Softmax) in pure Dart performs real SGD backpropagation, showing actual loss reduction and training accuracy in a scrolling terminal.
*   **Auto-Recognition Inference**: Once trained, the perceptron classifies unidentified faces using true probability distributions (82–88% confidence thresholds) and auto-syncs labels to PostgreSQL.
*   **Chronological Age Timeline**: Visual galleries for enrolled people showing physical changes over time (childhood → adult progression).
*   **2D Vector Embeddings Map**: Custom-painted interactive scatter plot mapping face vector clusters with dotted age-progression path connectors.
*   **Age Variant Detection**: Low-similarity conflicts (>25 embedding distance) trigger confirmation dialogs: "Same Person (Age Variant)" vs "Different Person".

### 6. Python YOLO Training Pipeline
*   **Real YOLOv8 Training**: Fine-tune detection models on custom face datasets via `uv run scripts/yolo_train.py`.
*   **Modular CLI Tools**: Inference, evaluation, data preparation, and model export scripts.
*   **Flutter Integration**: Scripts stream JSON progress to stdout, rendered by the Dart terminal widget in real time.
*   **Experimentation Notebook**: 9-section Jupyter notebook with training curves, augmentation previews, embedding cluster analysis, and decision boundary visualisation.

### 7. Intelligent Offline Mode
*   **Fast-Load Bypass**: When Ollama is offline, imports complete in ~1.2s instead of ~90s by skipping network attempts.
*   **Smart Visual Fallbacks**: High-fidelity simulated analysis automatically engages when the VLM server is unavailable.
*   **Real-Time Status Indicators**: Glowing green/red dots in the dashboard and settings reflect VLM and YOLO service health.

---

## 🚀 Getting Started

### 📋 Prerequisites
* **Flutter SDK** installed and available in your environment path.
* **Visual Studio Build Tools** with C++ workloads installed (required for native Windows compilation).
* **Local PostgreSQL** database running (credentials configurable in Settings).
* **uv** (for Python YOLO pipeline — optional):
  ```powershell
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```

### 💻 Running the Application
```powershell
# Enable Developer Mode (Settings > System > Developer settings)
# Ensure your local PostgreSQL server is active.

flutter run -d windows
```

### 🐍 Running the Python YOLO Pipeline
```powershell
# Scaffold the dataset structure
uv run scripts/yolo_data_prep.py scaffold

# Train a YOLOv8 model
uv run scripts/yolo_train.py --epochs 50 --batch-size 16

# Run inference on images
uv run scripts/yolo_detect.py --source ./test_images/ --json

# Evaluate model performance
uv run scripts/yolo_evaluate.py

# Export to ONNX for deployment
uv run scripts/yolo_export.py --format onnx --simplify
```

### 🧪 Executing Unit & Widget Tests
```powershell
flutter test
```

### 🔍 Static Code Analysis
```powershell
flutter analyze
```

---

## 📅 Milestone History

| # | Milestone | Date | Design Document |
|---|-----------|------|-----------------|
| 1 | Scaffolding & Visual Foundation | May 26, 2026 | [01_scaffold_media_chronicle.md](docs/design_docs/01_scaffold_media_chronicle.md) |
| 2 | YOLO Face Recognition Engine | May 27, 2026 | [02_yolo_self_retraining_face_recognition.md](docs/design_docs/02_yolo_self_retraining_face_recognition.md) |
| 3 | Sequential Queues & Multi-Select | May 27, 2026 | [03_sequential_queue_multiselect_actions.md](docs/design_docs/03_sequential_queue_multiselect_actions.md) |
| 4 | Performance & Lifecycle Audit | May 27, 2026 | [04_architectural_best_practices_refactoring.md](docs/design_docs/04_architectural_best_practices_refactoring.md) |
| 5 | Comprehensive Refactoring | May 27, 2026 | [04_architectural_best_practices_refactoring.md](docs/design_docs/04_architectural_best_practices_refactoring.md) |
| 6 | On-Device ML Engine | June 1, 2026 | [02_yolo_self_retraining_face_recognition.md](docs/design_docs/02_yolo_self_retraining_face_recognition.md) |
| 7 | Web Elimination & Native Migration | June 1, 2026 | [05_native_desktop_migration.md](docs/design_docs/05_native_desktop_migration.md) |
| 8 | Fast-Load & Offline Bypass | June 1, 2026 | [06_fast_load_bypass.md](docs/design_docs/06_fast_load_bypass.md) |
| 9 | Project-Wide Modularisation | June 1, 2026 | [07_code_modularisation.md](docs/design_docs/07_code_modularisation.md) |
| 10 | Python YOLO Pipeline | June 1, 2026 | [08_python_yolo_pipeline.md](docs/design_docs/08_python_yolo_pipeline.md) |

> **Full milestone details:** See [docs/design_docs/00_milestone_summary.md](docs/design_docs/00_milestone_summary.md).

---

## 📚 Knowledge Base

The `docs/knowledge_base/` directory contains detailed technical lessons learned during development:

| Module | Topic |
|--------|-------|
| [01 — Testing & Mocking](docs/knowledge_base/01_testing_and_mocking.md) | Network interception, mock HTTP clients, sandbox testing |
| [02 — Layout & Rendering](docs/knowledge_base/02_layout_and_rendering.md) | RenderFlex overflows, sub-pixel drift, responsive layouts |
| [03 — Widget Lifecycle](docs/knowledge_base/03_widget_lifecycle_and_controllers.md) | Controller memory leaks, async context safety, cursor-jump fixes |
| [04 — State Management](docs/knowledge_base/04_state_management_and_performance.md) | Selector O(1) rebuilds, DRY dialogs, numerical state modelling |
| [05 — Edge ML](docs/knowledge_base/05_pure_dart_machine_learning.md) | Softmax, cross-entropy, SGD backpropagation, numerical stability |
