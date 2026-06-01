# 📚 Knowledge Base: Technical Lessons Learned (Technical Audits)

This knowledge base logs technical hurdles, architectural decisions, and critical bug resolutions encountered during the development and optimization of the *Media Chronicle* offline-first Windows desktop application.

To keep documentation clean, modular, and highly detailed, the technical logs have been categorized into specialized modules:

---

## 🛠️ Specialized Technical Modules

### 🧪 [Module 1: Network Interception & Sandbox Testing](file:///d:/lab/projects/media_chronicle/docs/knowledge_base/01_testing_and_mocking.md)
*   **Focus**: Intercepting network requests inside secure, offline Flutter test environments.
*   **Key Concepts**: `HttpOverrides.global`, mock `HttpClient` streams, and injecting 1x1 transparent GIF memory bytes safely without production code pollution.
*   **Related Milestones**: M1 (Scaffolding), M5 (Comprehensive Refactoring).

### 📐 [Module 2: Bounded Constraints & Layout Overflow Prevention](file:///d:/lab/projects/media_chronicle/docs/knowledge_base/02_layout_and_rendering.md)
*   **Focus**: Debugging horizontal `RenderFlex` overflows, sub-pixel text rendering drift, and flexible multi-viewport layouts.
*   **Key Concepts**: `Flexible` and `Expanded` boundaries inside unbounded flex rows, top alignment cross-axes, and responsive design systems.
*   **Related Milestones**: M4 (Performance Audit), M9 (Modularisation).

### ⚡ [Module 3: Controllers Lifecycle & Async Context Safety](file:///d:/lab/projects/media_chronicle/docs/knowledge_base/03_widget_lifecycle_and_controllers.md)
*   **Focus**: Preventing memory leaks from scroll controllers, text cursor jumps in stateless repaints, and unmounted async context pop bugs.
*   **Key Concepts**: Stateful controller caching, `dispose()` memory frees, synchronous pre-capturing prior to popping contexts, and safe listener teardowns in widget tests.
*   **Related Milestones**: M4 (Performance Audit), M7 (Native Migration — async lifecycle fix).

### 📊 [Module 4: Performance Isolation & Selective Rebuilding](file:///d:/lab/projects/media_chronicle/docs/knowledge_base/04_state_management_and_performance.md)
*   **Focus**: Optimizing scrolling speeds in long list grids, DRY dialog extraction, and clean numerical state modeling.
*   **Key Concepts**: Precise granular `Selector` filters for $O(1)$ repaints, self-contained overlay classes, and raw data variables paired with dynamic getters.
*   **Related Milestones**: M5 (Comprehensive Refactoring), M9 (Modularisation).

### 🧠 [Module 5: Pure Dart Edge Machine Learning & Perceptrons](file:///d:/lab/projects/media_chronicle/docs/knowledge_base/05_pure_dart_machine_learning.md)
*   **Focus**: Writing mathematically complete neural networks inside pure Dart client applications for live, local active learning.
*   **Key Concepts**: Softmax activation with numerical stability constants, cross-entropy loss, online Stochastic Gradient Descent (SGD) backpropagation, and vector cluster coordinate mapping.
*   **Related Milestones**: M2 (YOLO Face Recognition), M6 (On-Device ML Engine).

---

## 📐 Cross-Reference: Milestones → Knowledge Modules

| Milestone | Relevant Knowledge Modules |
|-----------|---------------------------|
| M1 — Scaffolding & Visual Foundation | Module 1 (Testing) |
| M2 — YOLO Face Recognition Engine | Module 5 (Edge ML) |
| M3 — Sequential Queues & Multi-Select | Module 4 (State Management) |
| M4 — Performance & Lifecycle Audit | Modules 2, 3, 4 (Layout, Lifecycle, Performance) |
| M5 — Comprehensive Refactoring | Modules 1, 4 (Testing, Performance) |
| M6 — On-Device ML Engine | Module 5 (Edge ML) |
| M7 — Web Elimination & Native Migration | Module 3 (Async Context Safety) |
| M8 — Fast-Load & Offline Bypass | Module 4 (State Management) |
| M9 — Project-Wide Modularisation | Modules 2, 4 (Layout, Performance) |
| M10 — Python YOLO Pipeline | PEP 723 dependency isolation & unified config cascade design patterns |

---

## 📁 Design Documents Index

All milestone design documents are located in `docs/design_docs/`:

| Document | Milestone |
|----------|-----------|
| [00_milestone_summary.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/00_milestone_summary.md) | Complete milestone index with Gantt timeline |
| [01_scaffold_media_chronicle.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/01_scaffold_media_chronicle.md) | M1 — Initial scaffolding |
| [02_yolo_self_retraining_face_recognition.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/02_yolo_self_retraining_face_recognition.md) | M2 + M6 — YOLO engine & on-device ML |
| [03_sequential_queue_multiselect_actions.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/03_sequential_queue_multiselect_actions.md) | M3 — VLM queues & batch actions |
| [04_architectural_best_practices_refactoring.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/04_architectural_best_practices_refactoring.md) | M4 + M5 — Architecture & refactoring |
| [05_native_desktop_migration.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/05_native_desktop_migration.md) | M7 — Web elimination & native migration |
| [06_fast_load_bypass.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/06_fast_load_bypass.md) | M8 — Fast-load & offline bypass |
| [07_code_modularisation.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/07_code_modularisation.md) | M9 — Widget decomposition |
| [08_python_yolo_pipeline.md](file:///d:/lab/projects/media_chronicle/docs/design_docs/08_python_yolo_pipeline.md) | M10 — Python pipeline & notebook |

---

## 💻 Compilation & Verification Status

All static guidelines and test validation checks are 100% green and certified:
* **Analysis**: `No issues found!` (0 errors, 0 warnings).
* **Unit Tests**: `All tests passed!` (100% green).
