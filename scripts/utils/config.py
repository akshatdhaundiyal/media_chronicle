# ──────────────────────────────────────────────────────────────────────────────
# config.py — Centralised Configuration for the YOLO Face-Detection Pipeline
# ──────────────────────────────────────────────────────────────────────────────
#
# This module owns every tuneable knob in the pipeline. All scripts import
# `YoloConfig` rather than scattering magic numbers across the codebase.
#
# Configuration sources (highest priority wins):
#   1. CLI flags (each script uses `argparse` and overrides `YoloConfig`).
#   2. Environment variables   (e.g. YOLO_DATA_DIR, YOLO_EPOCHS).
#   3. An optional YAML file   (`scripts/yolo_config.yaml`).
#   4. Hardcoded defaults      (defined right here).
#
# Usage:
#   from utils.config import YoloConfig
#   cfg = YoloConfig()                  # uses defaults + env + yaml
#   cfg = YoloConfig(epochs=50, lr=0.005)  # override at construction
# ──────────────────────────────────────────────────────────────────────────────

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import yaml  # PyYAML — loaded lazily to keep cold-start fast


# ──────────────────────────────────────────────────────────────────────────────
# Path resolution helpers
# ──────────────────────────────────────────────────────────────────────────────

def resolve_project_root() -> Path:
    """Walk upward from this file until we find the Flutter `pubspec.yaml`.

    This ensures scripts work identically whether called from the repo root,
    from `scripts/`, or from an arbitrary working directory.

    Returns:
        Path: Absolute path to the Media Chronicle project root.

    Raises:
        FileNotFoundError: If no `pubspec.yaml` ancestor is found (e.g. the
            script was copied outside the project tree).
    """
    current = Path(__file__).resolve().parent
    for ancestor in [current] + list(current.parents):
        if (ancestor / "pubspec.yaml").exists():
            return ancestor
    raise FileNotFoundError(
        "Could not locate project root (no pubspec.yaml found in ancestors). "
        "Make sure the scripts/ directory lives inside the Media Chronicle repo."
    )


# ──────────────────────────────────────────────────────────────────────────────
# Configuration dataclass
# ──────────────────────────────────────────────────────────────────────────────

@dataclass
class YoloConfig:
    """Immutable-ish configuration container for the entire YOLO pipeline.

    Attributes:
        project_root:  Absolute path to the Flutter project root.
        data_dir:      Directory containing raw images and label files.
        output_dir:    Where trained weights, metrics, and exports land.
        model_variant: YOLOv8 model size suffix (n/s/m/l/x).
        pretrained_weights: Path or URL to an existing `.pt` checkpoint.
        image_size:    Training input resolution (square).
        epochs:        Total training epochs.
        batch_size:    Mini-batch size (−1 = auto).
        lr:            Initial learning rate (for SGD or AdamW).
        momentum:      SGD momentum coefficient.
        weight_decay:  L2 regularisation penalty.
        confidence_threshold: Minimum confidence for NMS post-processing.
        iou_threshold: IoU overlap threshold for NMS suppression.
        device:        Compute device string ("cpu", "0", "cuda:0", …).
        workers:       DataLoader worker processes.
        seed:          Random seed for reproducibility.
        augment:       Whether to apply Albumentations augmentation.
        freeze_backbone: Number of backbone layers to freeze (0 = none).
        export_format: Target format for model export (onnx, torchscript, …).
        postgres_dsn:  Optional DSN for syncing results to the app's Postgres.
        verbose:       Enables debug-level logging across all modules.
    """

    # ── Path configuration ────────────────────────────────────────────────
    project_root: Path = field(default_factory=resolve_project_root)
    data_dir: Optional[Path] = None
    output_dir: Optional[Path] = None

    # ── Model architecture ────────────────────────────────────────────────
    model_prefix: str = "yolov8"                   # default model architecture prefix (e.g. "yolov8", "yolov12")
    model_variant: str = "n"                       # nano by default (fast iteration)
    pretrained_weights: Optional[str] = None       # None → download COCO pretrained

    # ── Training hyperparameters ──────────────────────────────────────────
    image_size: int = 640
    epochs: int = 30
    batch_size: int = 16
    lr: float = 0.01
    momentum: float = 0.937
    weight_decay: float = 0.0005
    confidence_threshold: float = 0.25
    iou_threshold: float = 0.45

    # ── Hardware / reproducibility ────────────────────────────────────────
    device: str = "cpu"                            # safe Windows default
    workers: int = 2
    seed: int = 42

    # ── Augmentation & fine-tuning ────────────────────────────────────────
    augment: bool = True
    freeze_backbone: int = 0

    # ── Export ────────────────────────────────────────────────────────────
    export_format: str = "onnx"

    # ── Optional database sync ────────────────────────────────────────────
    postgres_dsn: Optional[str] = None

    # ── Logging ───────────────────────────────────────────────────────────
    verbose: bool = False

    def __post_init__(self) -> None:
        """Resolve derived paths and merge environment / YAML overrides."""
        # --- Merge YAML config file if it exists ---
        yaml_path = self.project_root / "scripts" / "yolo_config.yaml"
        if yaml_path.exists():
            self._merge_yaml(yaml_path)

        # --- Merge environment variables (highest priority) ---
        self._merge_env()

        # --- Resolve data & output directories ---
        if self.data_dir is None:
            self.data_dir = self.project_root / "datasets" / "faces"
        else:
            self.data_dir = Path(self.data_dir)

        if self.output_dir is None:
            self.output_dir = self.project_root / "runs" / "train"
        else:
            self.output_dir = Path(self.output_dir)

    # ──────────────────────────────────────────────────────────────────────
    # Internal merge helpers
    # ──────────────────────────────────────────────────────────────────────

    def _merge_yaml(self, path: Path) -> None:
        """Override default values with entries from a YAML config file.

        Only keys that exactly match a dataclass field name are applied.
        Unknown keys are silently ignored so the YAML can contain comments
        or future extensions without breaking older script versions.
        """
        with open(path, "r", encoding="utf-8") as fh:
            data = yaml.safe_load(fh) or {}

        for key, value in data.items():
            if hasattr(self, key) and value is not None:
                # Convert string paths to Path objects where appropriate.
                if key in ("data_dir", "output_dir", "project_root"):
                    value = Path(value)
                setattr(self, key, value)

    def _merge_env(self) -> None:
        """Override fields from environment variables prefixed with ``YOLO_``.

        Mapping:
            YOLO_DATA_DIR      → data_dir     (Path)
            YOLO_OUTPUT_DIR    → output_dir   (Path)
            YOLO_EPOCHS        → epochs       (int)
            YOLO_BATCH_SIZE    → batch_size   (int)
            YOLO_LR            → lr           (float)
            YOLO_DEVICE        → device       (str)
            YOLO_IMAGE_SIZE    → image_size   (int)
            YOLO_MODEL_PREFIX  → model_prefix (str)
            YOLO_MODEL_VARIANT → model_variant(str)
            YOLO_VERBOSE       → verbose      (bool)
            YOLO_POSTGRES_DSN  → postgres_dsn (str)
        """
        env_map: dict[str, tuple[str, type]] = {
            "YOLO_DATA_DIR":      ("data_dir",      Path),
            "YOLO_OUTPUT_DIR":    ("output_dir",    Path),
            "YOLO_EPOCHS":        ("epochs",        int),
            "YOLO_BATCH_SIZE":    ("batch_size",    int),
            "YOLO_LR":            ("lr",            float),
            "YOLO_DEVICE":        ("device",        str),
            "YOLO_IMAGE_SIZE":    ("image_size",    int),
            "YOLO_MODEL_PREFIX":  ("model_prefix",  str),
            "YOLO_MODEL_VARIANT": ("model_variant", str),
            "YOLO_VERBOSE":       ("verbose",       lambda v: v.lower() in ("1", "true", "yes")),
            "YOLO_POSTGRES_DSN":  ("postgres_dsn",  str),
        }

        for env_key, (field_name, cast) in env_map.items():
            raw = os.environ.get(env_key)
            if raw is not None:
                setattr(self, field_name, cast(raw))

    # ──────────────────────────────────────────────────────────────────────
    # Convenience properties
    # ──────────────────────────────────────────────────────────────────────

    @property
    def model_name(self) -> str:
        """Canonical YOLO model identifier (e.g. ``yolov8n``, ``yolov12n``)."""
        return f"{self.model_prefix}{self.model_variant}"

    @property
    def weights_path(self) -> str:
        """Resolve the starting checkpoint: custom file or COCO pretrained."""
        if self.pretrained_weights:
            return self.pretrained_weights
        return f"{self.model_prefix}{self.model_variant}.pt"

    def summary(self) -> str:
        """Return a human-readable multi-line summary of the configuration."""
        lines = [
            "┌─── YOLO Pipeline Configuration ───────────────────────────┐",
            f"│  Project root      : {self.project_root}",
            f"│  Data directory    : {self.data_dir}",
            f"│  Output directory  : {self.output_dir}",
            f"│  Model             : {self.model_name} ({self.weights_path})",
            f"│  Image size        : {self.image_size}×{self.image_size}",
            f"│  Epochs            : {self.epochs}",
            f"│  Batch size        : {self.batch_size}",
            f"│  Learning rate     : {self.lr}",
            f"│  Device            : {self.device}",
            f"│  Workers           : {self.workers}",
            f"│  Seed              : {self.seed}",
            f"│  Augmentation      : {'ON' if self.augment else 'OFF'}",
            f"│  Freeze backbone   : {self.freeze_backbone} layers",
            f"│  Export format     : {self.export_format}",
            f"│  Verbose           : {self.verbose}",
            "└──────────────────────────────────────────────────────────┘",
        ]
        return "\n".join(lines)
