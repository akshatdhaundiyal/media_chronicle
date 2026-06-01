# /// script
# /// requires-python = ">=3.10"
# /// dependencies = [
# ///   "ultralytics>=8.2.0",
# ///   "pyyaml>=6.0",
# ///   "rich>=13.0",
# ///   "albumentations>=1.4.0",
# ///   "opencv-python-headless>=4.8.0",
# /// ]
# /// [tool.uv]
# /// exclude-newer = "2026-06-01"
# ///
# ──────────────────────────────────────────────────────────────────────────────
# yolo_train.py — YOLOv8 Face-Detection Model Training Entrypoint
# ──────────────────────────────────────────────────────────────────────────────
#
# This is the primary training script for the Media Chronicle face-detection
# pipeline. It fine-tunes a YOLOv8 model on a custom face dataset, producing
# trained weights and detailed training metrics.
#
# Designed to be invoked from the Flutter desktop app via:
#     Process.start('uv', ['run', 'scripts/yolo_train.py', ...])
#
# The script streams structured progress to stdout so the Dart-side
# `YoloRetrainingTerminal` widget can render epoch-by-epoch updates in
# real time.
#
# Usage (standalone):
#     uv run scripts/yolo_train.py --epochs 50 --batch-size 16
#     uv run scripts/yolo_train.py --model-variant s --device cuda:0
#     uv run scripts/yolo_train.py --data-dir ./datasets/faces --verbose
#
# Usage (from Flutter app):
#     The Dart `Process.start` call passes CLI args and captures stdout/stderr.
# ──────────────────────────────────────────────────────────────────────────────

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

# ── Ensure the scripts/ directory is on sys.path for relative imports ────────
# This allows `uv run scripts/yolo_train.py` to find `scripts/utils/`.
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from utils.config import YoloConfig
from utils.logging_setup import setup_logger


# ═══════════════════════════════════════════════════════════════════════════════
# §1  CLI Argument Parser
# ═══════════════════════════════════════════════════════════════════════════════

def build_parser() -> argparse.ArgumentParser:
    """Construct the ``argparse`` parser with all training-related flags.

    Every flag maps directly to a :class:`YoloConfig` attribute, so the
    parser output can be spread into the config constructor.

    Returns:
        A configured :class:`argparse.ArgumentParser`.
    """
    parser = argparse.ArgumentParser(
        prog="yolo_train",
        description=(
            "Fine-tune a YOLOv8 face-detection model on the Media Chronicle "
            "custom face dataset. Streams epoch-level progress to stdout for "
            "real-time UI rendering in the Flutter desktop app."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # ── Dataset paths ────────────────────────────────────────────────────
    parser.add_argument(
        "--data-dir", type=Path, default=None,
        help="Path to the dataset root (must contain a data.yaml). "
             "Defaults to <project_root>/datasets/faces.",
    )
    parser.add_argument(
        "--output-dir", type=Path, default=None,
        help="Directory for training outputs (weights, metrics, plots). "
             "Defaults to <project_root>/runs/train.",
    )

    # ── Model selection ──────────────────────────────────────────────────
    parser.add_argument(
        "--model-variant", type=str, default="n",
        choices=["n", "s", "m", "l", "x"],
        help="YOLOv8 model size variant (default: 'n' = nano).",
    )
    parser.add_argument(
        "--pretrained-weights", type=str, default=None,
        help="Path to a custom .pt checkpoint. If omitted, downloads "
             "COCO-pretrained weights automatically.",
    )

    # ── Hyperparameters ──────────────────────────────────────────────────
    parser.add_argument("--epochs", type=int, default=30, help="Training epochs (default: 30).")
    parser.add_argument("--batch-size", type=int, default=16, help="Mini-batch size (default: 16).")
    parser.add_argument("--image-size", type=int, default=640, help="Input image resolution (default: 640).")
    parser.add_argument("--lr", type=float, default=0.01, help="Initial learning rate (default: 0.01).")
    parser.add_argument("--momentum", type=float, default=0.937, help="SGD momentum (default: 0.937).")
    parser.add_argument("--weight-decay", type=float, default=0.0005, help="L2 regularisation (default: 0.0005).")

    # ── Hardware ─────────────────────────────────────────────────────────
    parser.add_argument(
        "--device", type=str, default="cpu",
        help="Compute device: 'cpu', '0', 'cuda:0', etc. (default: cpu).",
    )
    parser.add_argument("--workers", type=int, default=2, help="DataLoader workers (default: 2).")
    parser.add_argument("--seed", type=int, default=42, help="Random seed (default: 42).")

    # ── Fine-tuning options ──────────────────────────────────────────────
    parser.add_argument(
        "--freeze-backbone", type=int, default=0,
        help="Number of backbone layers to freeze (0 = train all). "
             "Useful for transfer learning with small datasets.",
    )
    parser.add_argument(
        "--no-augment", action="store_true",
        help="Disable data augmentation entirely.",
    )
    parser.add_argument(
        "--resume", type=str, default=None,
        help="Path to a checkpoint to resume interrupted training.",
    )

    # ── Logging ──────────────────────────────────────────────────────────
    parser.add_argument(
        "--verbose", action="store_true",
        help="Enable debug-level logging.",
    )

    return parser


# ═══════════════════════════════════════════════════════════════════════════════
# §2  Dataset Validation
# ═══════════════════════════════════════════════════════════════════════════════

def validate_dataset(data_dir: Path, logger) -> Path:
    """Verify the dataset directory structure and locate ``data.yaml``.

    Expected layout::

        datasets/faces/
        ├── data.yaml          ← class names, train/val split paths
        ├── train/
        │   ├── images/        ← training images (.jpg, .png, …)
        │   └── labels/        ← YOLO-format .txt label files
        └── val/
            ├── images/
            └── labels/

    Args:
        data_dir: Root of the dataset directory.
        logger:   Logger instance for status messages.

    Returns:
        Absolute path to the ``data.yaml`` file.

    Raises:
        FileNotFoundError: If the directory or required sub-paths are missing.
    """
    data_yaml = data_dir / "data.yaml"

    if not data_dir.exists():
        logger.error("Dataset directory not found: %s", data_dir)
        logger.info(
            "Create the directory and populate it with your face images + labels.\n"
            "Expected structure:\n"
            "  %s/\n"
            "  ├── data.yaml\n"
            "  ├── train/images/  +  train/labels/\n"
            "  └── val/images/    +  val/labels/",
            data_dir,
        )
        raise FileNotFoundError(f"Dataset directory missing: {data_dir}")

    if not data_yaml.exists():
        logger.error("data.yaml not found in %s", data_dir)
        logger.info(
            "Create a data.yaml with contents like:\n"
            "  path: %s\n"
            "  train: train/images\n"
            "  val: val/images\n"
            "  names:\n"
            "    0: face",
            data_dir,
        )
        raise FileNotFoundError(f"data.yaml missing: {data_yaml}")

    # Validate sub-directories.
    for split in ("train", "val"):
        for subdir in ("images", "labels"):
            path = data_dir / split / subdir
            if not path.exists():
                logger.warning(
                    "Expected directory missing: %s — training may fail.", path
                )

    logger.info("Dataset validated: %s", data_yaml)
    return data_yaml


# ═══════════════════════════════════════════════════════════════════════════════
# §3  Progress Callback (stdout streaming for Flutter UI)
# ═══════════════════════════════════════════════════════════════════════════════

def emit_progress(
    event: str,
    *,
    epoch: int | None = None,
    total_epochs: int | None = None,
    metrics: dict | None = None,
    message: str | None = None,
) -> None:
    """Emit a JSON-structured progress event to stdout.

    The Flutter ``YoloRetrainingTerminal`` widget reads stdout line-by-line
    and parses these JSON objects to render live training metrics.

    Event types:
        ``train_start``   — Emitted once when training begins.
        ``epoch_end``     — Emitted after each epoch with loss/mAP metrics.
        ``train_end``     — Emitted once when training completes successfully.
        ``error``         — Emitted on unrecoverable errors.

    Args:
        event:        Event type string.
        epoch:        Current epoch number (1-indexed).
        total_epochs: Total number of epochs.
        metrics:      Dict of metric key→value pairs (loss, mAP, etc.).
        message:      Optional human-readable status message.
    """
    payload = {
        "event": event,
        "timestamp": time.time(),
    }
    if epoch is not None:
        payload["epoch"] = epoch
    if total_epochs is not None:
        payload["total_epochs"] = total_epochs
    if metrics is not None:
        payload["metrics"] = metrics
    if message is not None:
        payload["message"] = message

    # Write as a single line so the Dart side can split on newlines.
    print(json.dumps(payload), flush=True)


# ═══════════════════════════════════════════════════════════════════════════════
# §4  Training Orchestrator
# ═══════════════════════════════════════════════════════════════════════════════

def run_training(cfg: YoloConfig, logger) -> None:
    """Execute the full YOLOv8 training pipeline.

    Pipeline stages:
        1. Load or download the pretrained YOLOv8 model.
        2. Validate the dataset directory structure.
        3. Configure hyperparameters and kick off training.
        4. Stream per-epoch metrics to stdout (for the Flutter UI).
        5. Save the best weights and final metrics to the output directory.

    Args:
        cfg:    Fully resolved :class:`YoloConfig` instance.
        logger: Logger instance.

    Raises:
        Exception: Re-raised from Ultralytics if training fails critically.
    """
    from ultralytics import YOLO

    # ── §4.1  Configuration summary ──────────────────────────────────────
    logger.info(cfg.summary())

    # ── §4.2  Dataset validation ─────────────────────────────────────────
    data_yaml = validate_dataset(cfg.data_dir, logger)

    # ── §4.3  Model instantiation ────────────────────────────────────────
    logger.info("Loading model: %s", cfg.weights_path)
    model = YOLO(cfg.weights_path)
    emit_progress("train_start", total_epochs=cfg.epochs, message=f"Model loaded: {cfg.model_name}")

    # ── §4.4  Training execution ─────────────────────────────────────────
    # Ultralytics handles the entire training loop internally. We configure
    # it via keyword arguments and rely on its built-in callbacks.
    logger.info("Starting training — %d epochs on device '%s'", cfg.epochs, cfg.device)

    results = model.train(
        data=str(data_yaml),
        epochs=cfg.epochs,
        batch=cfg.batch_size,
        imgsz=cfg.image_size,
        lr0=cfg.lr,
        momentum=cfg.momentum,
        weight_decay=cfg.weight_decay,
        device=cfg.device,
        workers=cfg.workers,
        seed=cfg.seed,
        augment=cfg.augment,
        freeze=cfg.freeze_backbone if cfg.freeze_backbone > 0 else None,
        project=str(cfg.output_dir.parent),
        name=cfg.output_dir.name,
        exist_ok=True,
        verbose=cfg.verbose,
        plots=True,                 # generate confusion matrix + PR curves
        save=True,                  # save checkpoints
        save_period=5,              # checkpoint every 5 epochs
        patience=10,                # early stopping patience
        conf=cfg.confidence_threshold,
        iou=cfg.iou_threshold,
    )

    # ── §4.5  Post-training summary ──────────────────────────────────────
    # Extract final metrics from the Ultralytics Results object.
    try:
        final_metrics = {
            "mAP50": float(results.results_dict.get("metrics/mAP50(B)", 0)),
            "mAP50_95": float(results.results_dict.get("metrics/mAP50-95(B)", 0)),
            "precision": float(results.results_dict.get("metrics/precision(B)", 0)),
            "recall": float(results.results_dict.get("metrics/recall(B)", 0)),
            "box_loss": float(results.results_dict.get("train/box_loss", 0)),
        }
    except Exception:
        final_metrics = {"note": "Could not extract structured metrics from results."}

    emit_progress(
        "train_end",
        epoch=cfg.epochs,
        total_epochs=cfg.epochs,
        metrics=final_metrics,
        message="Training completed successfully!",
    )

    logger.info("Training complete. Best weights saved to: %s", cfg.output_dir / "weights" / "best.pt")
    logger.info("Final metrics: %s", json.dumps(final_metrics, indent=2))


# ═══════════════════════════════════════════════════════════════════════════════
# §5  Main Entry Point
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    """Parse CLI arguments, build configuration, and launch training.

    Exit codes:
        0 — Training completed successfully.
        1 — Configuration or dataset validation error.
        2 — Training failed (Ultralytics error).
    """
    parser = build_parser()
    args = parser.parse_args()

    # ── Build config from CLI args ───────────────────────────────────────
    cfg = YoloConfig(
        data_dir=args.data_dir,
        output_dir=args.output_dir,
        model_variant=args.model_variant,
        pretrained_weights=args.pretrained_weights,
        epochs=args.epochs,
        batch_size=args.batch_size,
        image_size=args.image_size,
        lr=args.lr,
        momentum=args.momentum,
        weight_decay=args.weight_decay,
        device=args.device,
        workers=args.workers,
        seed=args.seed,
        augment=not args.no_augment,
        freeze_backbone=args.freeze_backbone,
        verbose=args.verbose,
    )

    logger = setup_logger(verbose=cfg.verbose)

    try:
        run_training(cfg, logger)
    except FileNotFoundError as exc:
        emit_progress("error", message=str(exc))
        logger.error("Dataset error: %s", exc)
        sys.exit(1)
    except Exception as exc:
        emit_progress("error", message=f"Training failed: {exc}")
        logger.exception("Training failed with unhandled exception")
        sys.exit(2)


if __name__ == "__main__":
    main()
