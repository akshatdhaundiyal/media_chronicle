# ──────────────────────────────────────────────────────────────────────────────
# Media Chronicle — Python YOLO Pipeline Utilities
# ──────────────────────────────────────────────────────────────────────────────
#
# This package consolidates shared helpers used across all YOLO training,
# inference, evaluation, and data-preparation scripts. Each module is
# independently importable and has zero coupling to any particular script's
# CLI interface.
#
# Modules:
#   config.py     — Centralised path resolution, hyperparameter defaults,
#                   and YAML/env configuration loading.
#   logging_setup.py — Uniform rich-console + rotating-file logging factory.
#   data_transforms.py — Image augmentation pipelines and dataset format
#                        converters (COCO ↔ YOLO ↔ Pascal VOC).
# ──────────────────────────────────────────────────────────────────────────────

from .config import YoloConfig, resolve_project_root
from .logging_setup import setup_logger
from .data_transforms import (
    build_augmentation_pipeline,
    coco_to_yolo,
    yolo_to_coco,
    voc_to_yolo,
)

__all__ = [
    "YoloConfig",
    "resolve_project_root",
    "setup_logger",
    "build_augmentation_pipeline",
    "coco_to_yolo",
    "yolo_to_coco",
    "voc_to_yolo",
]
