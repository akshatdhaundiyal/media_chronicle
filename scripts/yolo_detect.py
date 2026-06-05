# /// script
# /// requires-python = ">=3.10"
# /// dependencies = [
# ///   "ultralytics>=8.2.0",
# ///   "pyyaml>=6.0",
# ///   "rich>=13.0",
# ///   "opencv-python-headless>=4.8.0",
# ///   "Pillow>=10.0",
# /// ]
# /// [tool.uv]
# /// exclude-newer = "2026-06-01"
# ///
# ──────────────────────────────────────────────────────────────────────────────
# yolo_detect.py — YOLOv8 Face-Detection Inference Script
# ──────────────────────────────────────────────────────────────────────────────
#
# Runs a trained YOLOv8 model on input images (single file, directory, or
# glob pattern) and outputs detected face bounding boxes. Results can be
# emitted as:
#   • Annotated images saved to disk (with drawn bounding boxes).
#   • JSON output to stdout (for programmatic consumption by the Flutter app).
#   • Both simultaneously.
#
# This script is called from the Flutter desktop app via:
#     Process.start('uv', ['run', 'scripts/yolo_detect.py', '--source', ...])
#
# Usage:
#     uv run scripts/yolo_detect.py --source ./test_images/
#     uv run scripts/yolo_detect.py --source photo.jpg --weights runs/train/weights/best.pt
#     uv run scripts/yolo_detect.py --source ./photos/ --json --conf 0.4
# ──────────────────────────────────────────────────────────────────────────────

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

# ── Ensure scripts/ is on sys.path for relative imports ──────────────────────
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from utils.config import YoloConfig
from utils.logging_setup import setup_logger


# ═══════════════════════════════════════════════════════════════════════════════
# §1  CLI Argument Parser
# ═══════════════════════════════════════════════════════════════════════════════

def build_parser() -> argparse.ArgumentParser:
    """Construct the CLI parser for inference-specific flags.

    Returns:
        A configured :class:`argparse.ArgumentParser`.
    """
    parser = argparse.ArgumentParser(
        prog="yolo_detect",
        description=(
            "Run YOLOv8 face detection on images. Outputs annotated images "
            "and/or JSON bounding-box results."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # ── Required ─────────────────────────────────────────────────────────
    parser.add_argument(
        "--source", type=str, required=True,
        help="Input source: path to a single image, a directory of images, "
             "or a glob pattern (e.g. 'photos/*.jpg').",
    )

    # ── Model ────────────────────────────────────────────────────────────
    parser.add_argument(
        "--weights", type=str, default=None,
        help="Path to trained .pt weights. Defaults to "
             "<project_root>/runs/train/weights/best.pt.",
    )
    parser.add_argument(
        "--model-variant", type=str, default="n",
        choices=["n", "s", "m", "l", "x"],
        help="YOLOv8 variant (used only if --weights is not specified).",
    )

    # ── Inference parameters ─────────────────────────────────────────────
    parser.add_argument("--conf", type=float, default=0.25, help="Confidence threshold (default: 0.25).")
    parser.add_argument("--iou", type=float, default=0.45, help="NMS IoU threshold (default: 0.45).")
    parser.add_argument("--image-size", type=int, default=640, help="Input resolution (default: 640).")
    parser.add_argument("--device", type=str, default="cpu", help="Compute device (default: cpu).")

    # ── Output options ───────────────────────────────────────────────────
    parser.add_argument(
        "--output-dir", type=Path, default=None,
        help="Directory for annotated output images. "
             "Defaults to <project_root>/runs/detect.",
    )
    parser.add_argument(
        "--json", action="store_true", dest="json_output",
        help="Emit detection results as JSON to stdout.",
    )
    parser.add_argument(
        "--save-images", action="store_true", default=True,
        help="Save annotated images with drawn bounding boxes (default: True).",
    )
    parser.add_argument(
        "--no-save-images", action="store_false", dest="save_images",
        help="Skip saving annotated images (useful with --json).",
    )

    # ── Logging ──────────────────────────────────────────────────────────
    parser.add_argument("--verbose", action="store_true", help="Enable debug logging.")

    return parser


# ═══════════════════════════════════════════════════════════════════════════════
# §2  Source Resolution
# ═══════════════════════════════════════════════════════════════════════════════

SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".tiff", ".tif"}


def resolve_source(source: str) -> list[Path]:
    """Expand the source argument into a list of image file paths.

    Handles three input patterns:
        1. Single file path   → ``["photo.jpg"]``
        2. Directory path     → all images in the directory (non-recursive).
        3. Glob pattern       → expanded via ``Path.glob()``.

    Args:
        source: The raw ``--source`` CLI argument.

    Returns:
        Sorted list of resolved image :class:`Path` objects.

    Raises:
        FileNotFoundError: If no images are found.
    """
    source_path = Path(source)
    images: list[Path] = []

    if source_path.is_file():
        # Single file.
        if source_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            images.append(source_path.resolve())
    elif source_path.is_dir():
        # Directory: collect all supported image files.
        for ext in SUPPORTED_EXTENSIONS:
            images.extend(source_path.glob(f"*{ext}"))
    else:
        # Try as a glob pattern (e.g. "photos/*.jpg").
        parent = source_path.parent if source_path.parent.exists() else Path(".")
        images.extend(parent.glob(source_path.name))

    images = sorted(set(p.resolve() for p in images))

    if not images:
        raise FileNotFoundError(
            f"No supported images found for source: '{source}'. "
            f"Supported formats: {', '.join(sorted(SUPPORTED_EXTENSIONS))}"
        )

    return images


# ═══════════════════════════════════════════════════════════════════════════════
# §3  Detection Runner
# ═══════════════════════════════════════════════════════════════════════════════

def run_detection(
    args: argparse.Namespace,
    cfg: YoloConfig,
    logger,
) -> list[dict[str, Any]]:
    """Execute YOLOv8 inference on the resolved image sources.

    Pipeline stages:
        1. Resolve the input source to a list of image paths.
        2. Load the YOLOv8 model (trained weights or pretrained).
        3. Run inference on each image.
        4. Collect and format results as a list of dicts.
        5. Optionally save annotated images and/or emit JSON to stdout.

    Args:
        args:   Parsed CLI arguments.
        cfg:    Resolved configuration.
        logger: Logger instance.

    Returns:
        List of per-image detection result dicts with structure::

            {
                "image": "photo.jpg",
                "image_width": 1920,
                "image_height": 1080,
                "detections": [
                    {
                        "class_id": 0,
                        "class_name": "face",
                        "confidence": 0.92,
                        "bbox_xyxy": [100, 200, 300, 400],
                        "bbox_xywhn": [0.104, 0.278, 0.104, 0.185]
                    }
                ]
            }
    """
    from ultralytics import YOLO

    # ── §3.1  Resolve source images ──────────────────────────────────────
    images = resolve_source(args.source)
    logger.info("Found %d image(s) to process.", len(images))

    # ── §3.2  Load model ─────────────────────────────────────────────────
    weights = args.weights
    if weights is None:
        # Check if the user specified a custom pretrained weights path or registry key
        if cfg.pretrained_weights:
            weights = cfg.pretrained_weights
            logger.info("Using configured custom weights: %s", weights)
        else:
            # Fallback to local default best.pt if no custom weights are configured
            default_best = cfg.project_root / "runs" / "train" / "weights" / "best.pt"
            if default_best.exists():
                weights = str(default_best)
                logger.info("Using trained weights fallback: %s", weights)
            else:
                weights = cfg.weights_path
                logger.info("No custom weights configured or fallback found. Using default pretrained: %s", weights)
    else:
        logger.info("Using specified weights from CLI: %s", weights)

    model = YOLO(weights)
    output_dir = args.output_dir or (cfg.project_root / "runs" / "detect")
    output_dir.mkdir(parents=True, exist_ok=True)

    # ── §3.4  Run inference ──────────────────────────────────────────────
    all_results: list[dict[str, Any]] = []
    t_start = time.perf_counter()

    for img_path in images:
        logger.debug("Processing: %s", img_path.name)

        # Run YOLOv8 prediction on a single image.
        predictions = model.predict(
            source=str(img_path),
            conf=args.conf,
            iou=args.iou,
            imgsz=args.image_size,
            device=args.device,
            save=args.save_images,
            project=str(output_dir.parent),
            name=output_dir.name,
            exist_ok=True,
            verbose=False,        # we handle our own logging
        )

        # ── §3.5  Parse Ultralytics Result objects ───────────────────────
        for result in predictions:
            img_result: dict[str, Any] = {
                "image": img_path.name,
                "image_path": str(img_path),
                "image_width": int(result.orig_shape[1]),
                "image_height": int(result.orig_shape[0]),
                "detections": [],
            }

            if result.boxes is not None:
                boxes = result.boxes
                for i in range(len(boxes)):
                    # Extract bounding box coordinates.
                    xyxy = boxes.xyxy[i].tolist()          # [x1, y1, x2, y2] absolute
                    xywhn = boxes.xywhn[i].tolist()        # [x, y, w, h] normalised
                    conf = float(boxes.conf[i])
                    cls_id = int(boxes.cls[i])

                    # Resolve class name from the model's names dict.
                    cls_name = result.names.get(cls_id, f"class_{cls_id}")

                    detection = {
                        "class_id": cls_id,
                        "class_name": cls_name,
                        "confidence": round(conf, 4),
                        "bbox_xyxy": [round(v, 2) for v in xyxy],
                        "bbox_xywhn": [round(v, 6) for v in xywhn],
                    }
                    img_result["detections"].append(detection)

            all_results.append(img_result)
            logger.info(
                "  %s — %d detection(s)",
                img_path.name, len(img_result["detections"]),
            )

    elapsed = time.perf_counter() - t_start
    total_detections = sum(len(r["detections"]) for r in all_results)
    logger.info(
        "Inference complete: %d images, %d detections in %.2fs",
        len(all_results), total_detections, elapsed,
    )

    # ── §3.6  JSON output to stdout ──────────────────────────────────────
    if args.json_output:
        output = {
            "event": "detection_complete",
            "timestamp": time.time(),
            "total_images": len(all_results),
            "total_detections": total_detections,
            "elapsed_seconds": round(elapsed, 3),
            "results": all_results,
        }
        print(json.dumps(output, indent=2), flush=True)

    return all_results


# ═══════════════════════════════════════════════════════════════════════════════
# §4  Main Entry Point
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    """Parse CLI arguments and run face detection.

    Exit codes:
        0 — Inference completed successfully.
        1 — Source file/directory not found.
        2 — Model loading or inference error.
    """
    parser = build_parser()
    args = parser.parse_args()

    cfg = YoloConfig(
        model_variant=args.model_variant,
        confidence_threshold=args.conf,
        iou_threshold=args.iou,
        image_size=args.image_size,
        device=args.device,
        verbose=args.verbose,
    )

    logger = setup_logger(verbose=cfg.verbose)

    try:
        run_detection(args, cfg, logger)
    except FileNotFoundError as exc:
        logger.error("Source error: %s", exc)
        sys.exit(1)
    except Exception as exc:
        logger.exception("Detection failed: %s", exc)
        sys.exit(2)


if __name__ == "__main__":
    main()
