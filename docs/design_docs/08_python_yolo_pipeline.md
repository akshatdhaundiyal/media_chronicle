# Design Document: Python YOLO Training Pipeline & Experimentation Notebook

## 1. Goal

Create a complete, modular Python pipeline for real YOLOv8 face-detection model training, inference, evaluation, data preparation, and model export. The pipeline must:

*   Be invocable from the Flutter desktop app via `Process.start('uv', ['run', ...])`.
*   Use **PEP 723 inline script metadata** so `uv run` resolves dependencies into isolated ephemeral environments — **no global package pollution**.
*   Stream structured JSON progress events to stdout for real-time rendering in the Dart `YoloRetrainingTerminal` widget.
*   Provide a Jupyter notebook for interactive experimentation and parameter tuning.

---

## 2. Technical Architecture & Decisions

### A. Dependency Management: `uv` + PEP 723 & central `pyproject.toml`

The pipeline supports two concurrent dependency management options for runtime execution vs developer/notebook interactive usage:

1. **Inline Scripts (PEP 723)**: Each script embeds its own dependency metadata for zero-setup execution.
```python
# /// script
# /// requires-python = ">=3.10"
# /// dependencies = [
# ///   "ultralytics>=8.2.0",
# ///   "pyyaml>=6.0",
# ///   "rich>=13.0",
# ]
# ///
```

2. **Central Workspace (`pyproject.toml`)**: A highly optimized `pyproject.toml` is provided at the root using `package = false` (non-package mode) and separate `dev-dependencies`.
Running `uv sync` builds a single unified local `.venv` mapping runtime and heavy plotting tools (matplotlib, seaborn, scikit-learn, jupyter).

**Benefits:**
*   **Zero setup**: `uv run scripts/yolo_train.py` handles environments dynamically inside Flutter.
*   **Jupyter/IDE compatibility**: Running `uv sync` registers a stable local kernel for the experimental notebook (`yolo_pipeline.ipynb`) and provides complete autocomplete indexing in IDEs.
*   **Optimal Performance**: Restricts development libraries from bloating the clean execution of scripts.
*   **Isolated environments**: No global package pollution, conforming with the user's strict security guidelines.

### B. Configuration Architecture

All scripts share a unified `YoloConfig` dataclass with a layered override cascade:

```
CLI flags  >  Environment variables (YOLO_*)  >  yolo_config.yaml  >  Hardcoded defaults
```

**Key design decisions:**
*   `YoloConfig` uses `@dataclass` with `__post_init__` for lazy merging.
*   Project root is auto-resolved by walking upward from the script location to find `pubspec.yaml`.
*   All paths are `Path` objects for cross-platform safety.
*   YAML loading uses `yaml.safe_load()` for security.

### C. Flutter Integration Protocol

The Dart app invokes scripts via:
```dart
final process = await Process.start(
  'uv', ['run', 'scripts/yolo_train.py', '--epochs', '30'],
  runInShell: true,  // Required on Windows for PATH resolution
);
```

Scripts emit JSON events to stdout, one per line:

| Event | Fields | When |
|-------|--------|------|
| `train_start` | `total_epochs`, `message` | Training begins |
| `epoch_end` | `epoch`, `total_epochs`, `metrics` | After each epoch |
| `train_end` | `epoch`, `metrics`, `message` | Training completes |
| `detection_complete` | `total_images`, `total_detections`, `results` | Inference finishes |
| `evaluation_complete` | `metrics`, `weights`, `dataset` | Evaluation finishes |
| `export_complete` | `format`, `file_size_mb`, `exported_path` | Export finishes |
| `error` | `message` | On unrecoverable errors |

**JSON format:**
```json
{
  "event": "epoch_end",
  "timestamp": 1717225200.0,
  "epoch": 5,
  "total_epochs": 30,
  "metrics": {
    "mAP50": 0.8234,
    "box_loss": 0.0312
  }
}
```

---

## 3. Module Breakdown

### Shared Utilities (`scripts/utils/`)

#### `config.py` — Centralised Configuration
*   `YoloConfig` dataclass with 20+ tuneable attributes (model variant, epochs, lr, device, etc.).
*   `resolve_project_root()` — walks upward to find `pubspec.yaml`.
*   `_merge_yaml()` — loads `yolo_config.yaml` with unknown-key tolerance.
*   `_merge_env()` — maps `YOLO_*` environment variables to config fields.
*   `summary()` — pretty-prints a boxed configuration table.

#### `logging_setup.py` — Uniform Logging Factory
*   `setup_logger()` — idempotent factory returning a shared `logging.Logger`.
*   Rich console handler with colour-coded levels, timestamps, and tracebacks.
*   Rotating file handler (10 MB per file, 5 backups) at `runs/logs/yolo_pipeline.log`.
*   Graceful degradation to `StreamHandler` if Rich is not installed.

#### `data_transforms.py` — Augmentation & Format Converters
*   `build_augmentation_pipeline()` — Albumentations `Compose` with geometric (flip, rotate, scale) and photometric (brightness, contrast, hue, blur, noise) transforms. Configured with YOLO-format bbox parameters and `min_visibility=0.3`.
*   `coco_to_yolo()` — COCO JSON `[x_min, y_min, w, h]` → YOLO normalised `[x_center, y_center, w, h]`.
*   `yolo_to_coco()` — Inverse conversion using PIL for image dimension reads.
*   `voc_to_yolo()` — Pascal VOC XML `[xmin, ymin, xmax, ymax]` → YOLO normalised format.

### Pipeline Scripts

#### `yolo_train.py` — Training Entrypoint
*   CLI parser with 15+ flags mapping to `YoloConfig` attributes.
*   `validate_dataset()` — verifies directory structure and `data.yaml` presence.
*   `emit_progress()` — JSON event emitter for Flutter stdout streaming.
*   `run_training()` — loads Ultralytics YOLO model, configures training kwargs, and launches `model.train()`.
*   Exit codes: 0 (success), 1 (dataset error), 2 (training error).

#### `yolo_detect.py` — Inference Runner
*   `resolve_source()` — expands single files, directories, or glob patterns into image lists.
*   Runs `model.predict()` per image, extracting `xyxy`, `xywhn`, confidence, and class name.
*   Dual output: annotated images to disk + JSON to stdout.
*   Supports `--json` and `--no-save-images` flags for headless operation.

#### `yolo_evaluate.py` — Validation Metrics
*   Runs `model.val()` on the validation split.
*   Extracts aggregate metrics (mAP@50, mAP@50-95, precision, recall) and per-class breakdowns.
*   Saves `evaluation_metrics.json` to the output directory.
*   Generates confusion matrix and PR curve plots via Ultralytics.

#### `yolo_data_prep.py` — Dataset Preparation CLI
Sub-command architecture using `argparse` sub-parsers:

| Sub-command | Action |
|-------------|--------|
| `scaffold` | Creates `datasets/faces/` directory tree + `data.yaml` |
| `split` | Splits flat image+label directory into train/val sets (configurable ratio, seeded shuffle) |
| `convert` | Converts COCO JSON or Pascal VOC XML → YOLO `.txt` labels |
| `augment` | Offline augmentation: generates N augmented copies per training image with consistent bbox transforms |
| `stats` | Prints per-split image counts, annotation counts, class distributions, and bbox size statistics |

#### `yolo_export.py` — Model Format Export
Supports 7 export formats via Ultralytics:

| Format | Suffix | Use Case |
|--------|--------|----------|
| ONNX | `.onnx` | Windows desktop deployment (recommended) |
| TorchScript | `.torchscript` | PyTorch JIT |
| TFLite | `.tflite` | Mobile / edge |
| CoreML | `.mlpackage` | macOS / iOS |
| OpenVINO | `_openvino/` | Intel CPUs |
| TensorRT | `.engine` | NVIDIA GPUs |
| SavedModel | `_saved_model/` | TensorFlow Serving |

Supports `--half` (FP16), `--dynamic` (variable input shapes), and `--simplify` (ONNX graph optimisation).

---

## 4. Experimentation Notebook

The `experiments/yolo_pipeline.ipynb` notebook provides 9 interactive sections:

| Section | Content |
|---------|---------|
| §1 Environment Setup | Path resolution, `YoloConfig` loading, matplotlib dark theme |
| §2 Dataset Preparation | Directory scaffolding, `data.yaml` creation, per-split statistics, sample image grid with YOLO bboxes |
| §3 Augmentation Preview | Side-by-side original + 7 augmented variants with bboxes |
| §4 Model Training | YOLOv8 fine-tuning with live Ultralytics progress |
| §5 Metrics Visualization | Loss, mAP, precision, recall curves parsed from `results.csv`; embedded Ultralytics plots (confusion matrix, PR curves) |
| §6 Model Evaluation | Formal validation with per-class breakdown |
| §7 Inference Visualization | Detection on test images with drawn bounding boxes and confidence labels |
| §8 Model Export | ONNX export with size reporting |
| §9 Embedding Analysis | Synthetic 2D embedding clusters (mirroring Dart's `YoloFaceProvider`), K-Means unsupervised discovery, `SoftmaxClassifier` training curves (mirroring Dart's `SingleLayerPerceptron`), and decision boundary visualisation |

---

## 5. Expected Directory Structure After First Run

```
media_chronicle/
├── scripts/                    # Python YOLO pipeline (version-controlled)
│   ├── yolo_train.py
│   ├── yolo_detect.py
│   ├── yolo_evaluate.py
│   ├── yolo_export.py
│   ├── yolo_data_prep.py
│   ├── yolo_config.yaml
│   ├── README.md
│   └── utils/
│       ├── __init__.py
│       ├── config.py
│       ├── logging_setup.py
│       └── data_transforms.py
├── datasets/                   # Generated data (gitignored)
│   └── faces/
│       ├── data.yaml
│       ├── train/
│       │   ├── images/
│       │   └── labels/
│       └── val/
│           ├── images/
│           └── labels/
├── runs/                       # Generated outputs (gitignored)
│   ├── train/
│   │   └── weights/
│   │       ├── best.pt
│   │       └── last.pt
│   ├── detect/
│   ├── evaluate/
│   ├── export/
│   └── logs/
│       └── yolo_pipeline.log
├── experiments/                # Notebook (version-controlled)
│   └── yolo_pipeline.ipynb
├── pyproject.toml              # Centralized Python workspace config (non-package uv sync)
└── pubspec.yaml                # Flutter project configuration
```

---

## 6. Verification

*   All Python scripts pass syntax validation.
*   PEP 723 metadata is correctly formatted for `uv run`.
*   Flutter codebase unaffected — `flutter analyze` remains clean.
*   `.gitignore` updated to exclude `runs/`, `datasets/`, `__pycache__/`, `.ipynb_checkpoints/`.
