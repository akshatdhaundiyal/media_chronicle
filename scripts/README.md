# ──────────────────────────────────────────────────────────────────────────────
# Media Chronicle — YOLO Python Scripts README
# ──────────────────────────────────────────────────────────────────────────────
#
# This directory contains modular Python scripts for the YOLOv8 face-detection
# training, inference, evaluation, and data-preparation pipeline.
#
# All scripts use PEP 723 inline script metadata, so they are fully
# self-contained — `uv run` automatically resolves and installs dependencies
# into an isolated ephemeral environment. No global package pollution!
#
# ──────────────────────────────────────────────────────────────────────────────

## Prerequisites

- **uv** (Astral's ultra-fast Python package manager):
  ```powershell
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```

## Development Environment Setup (Jupyter & IDE)

To run the interactive notebook (`experiments/yolo_pipeline.ipynb`) or configure auto-completion for your IDE, initialize a unified local virtual environment (`.venv`) containing all runtime and development packages (like Jupyter, matplotlib, and scikit-learn):

```powershell
# In the project root, run:
uv sync
```

This will automatically create a highly optimized `.venv` folder in the project root. You can select this virtual environment as your Python Kernel inside your IDE or Jupyter interface.

## Quick Start

```powershell
# 1. Create the dataset directory structure
uv run scripts/yolo_data_prep.py scaffold

# 2. Place your face images + YOLO labels into datasets/faces/train/ and val/

# 3. Check dataset statistics
uv run scripts/yolo_data_prep.py stats

# 4. Train the model
uv run scripts/yolo_train.py --epochs 50 --batch-size 16

# 5. Evaluate on validation set
uv run scripts/yolo_evaluate.py

# 6. Run detection on new images
uv run scripts/yolo_detect.py --source ./test_images/ --json

# 7. Export to ONNX for deployment
uv run scripts/yolo_export.py --format onnx --simplify
```

## Script Overview

| Script              | Purpose                                        |
|---------------------|-------------------------------------------------|
| `yolo_train.py`     | Fine-tune YOLOv8 on custom face dataset         |
| `yolo_detect.py`    | Run inference on images (annotated + JSON)       |
| `yolo_evaluate.py`  | Evaluate model metrics (mAP, precision, recall)  |
| `yolo_export.py`    | Export .pt to ONNX, TFLite, CoreML, etc.         |
| `yolo_data_prep.py` | Dataset scaffolding, splitting, conversion, augmentation |
| `yolo_config.yaml`  | Default hyperparameters and paths                |
| `utils/`            | Shared config, logging, and data transform modules |

## Configuration Priority

All scripts share a unified configuration system:

```
CLI flags  >  Environment variables (YOLO_*)  >  yolo_config.yaml  >  Hardcoded defaults
```

## Dynamic Model & Weights Resolution

To support out-of-the-box community checkpoints (like `yolov12n-face.pt`) for immediate inference without hardcoding `best.pt`, all pipeline scripts feature a unified weights resolution cascade:

1. **CLI Flag (`--weights <path/identifier>`)** — The highest priority, explicitly overriding any other setting. E.g.:
   ```powershell
   uv run scripts/yolo_detect.py --weights yolov12n-face.pt --source image.jpg
   ```
2. **Configuration Override (`pretrained_weights` in `yolo_config.yaml` or env)** — Loads custom pre-trained or community weight files from local disk or online registries directly. E.g., setting `pretrained_weights: "yolov12n-face.pt"` will auto-download and run the YOLOv12 face detector.
3. **Training Fallback (`runs/train/weights/best.pt`)** — Falls back to local custom-trained model weights if present inside the default training runs folder.
4. **Default Variant Pretrained Weight (`yolov8{variant}.pt`, `yolov12{variant}.pt`)** — The base fallback, auto-downloaded if no other custom weight is configured or exists on disk.

To switch default model architecture versions, update the `model_prefix` configuration (e.g. from `yolov8` to `yolov12`) inside `yolo_config.yaml`.

## Flutter Integration

From the Dart desktop app, these scripts are invoked via:
```dart
Process.start('uv', ['run', 'scripts/yolo_train.py', '--epochs', '30'], runInShell: true)
```

The scripts emit JSON-structured progress events to stdout, which the
`YoloRetrainingTerminal` widget parses and renders in real time.

## Directory Structure (after training)

```
media_chronicle/
├── scripts/
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
├── datasets/
│   └── faces/
│       ├── data.yaml
│       ├── train/images/ + train/labels/
│       └── val/images/   + val/labels/
├── runs/
│   ├── train/weights/best.pt
│   ├── detect/
│   ├── evaluate/
│   ├── export/
│   └── logs/
└── experiments/
    └── yolo_pipeline.ipynb
```
