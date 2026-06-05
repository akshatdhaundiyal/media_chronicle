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
# yolo_evaluate.py — Model Evaluation & Metrics Reporting
# ──────────────────────────────────────────────────────────────────────────────
#
# Evaluates a trained YOLOv8 model on a validation (or test) dataset and
# reports detailed metrics including mAP, precision, recall, per-class
# performance, and confusion matrix generation.
#
# Output modes:
#   • Rich console table (default) — formatted for human readability.
#   • JSON stdout (--json) — structured for programmatic consumption
#     by the Flutter desktop app.
#   • Saved plots (confusion matrix, PR curves) to the output directory.
#
# Usage:
#     uv run scripts/yolo_evaluate.py
#     uv run scripts/yolo_evaluate.py --weights runs/train/weights/best.pt
#     uv run scripts/yolo_evaluate.py --json --conf 0.4 --device cuda:0
# ──────────────────────────────────────────────────────────────────────────────

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

# ── Ensure scripts/ is on sys.path ──────────────────────────────────────────
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from utils.config import YoloConfig
from utils.logging_setup import setup_logger


# ═══════════════════════════════════════════════════════════════════════════════
# §1  CLI Argument Parser
# ═══════════════════════════════════════════════════════════════════════════════

def build_parser() -> argparse.ArgumentParser:
    """Construct the CLI parser for evaluation flags.

    Returns:
        A configured :class:`argparse.ArgumentParser`.
    """
    parser = argparse.ArgumentParser(
        prog="yolo_evaluate",
        description=(
            "Evaluate a trained YOLOv8 model on the validation dataset. "
            "Reports mAP, precision, recall, and per-class metrics."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
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

    # ── Dataset ──────────────────────────────────────────────────────────
    parser.add_argument(
        "--data-dir", type=Path, default=None,
        help="Dataset root containing data.yaml.",
    )

    # ── Evaluation parameters ────────────────────────────────────────────
    parser.add_argument("--conf", type=float, default=0.001, help="Confidence threshold for val (default: 0.001).")
    parser.add_argument("--iou", type=float, default=0.6, help="IoU threshold for val NMS (default: 0.6).")
    parser.add_argument("--image-size", type=int, default=640, help="Input resolution (default: 640).")
    parser.add_argument("--device", type=str, default="cpu", help="Compute device (default: cpu).")
    parser.add_argument("--batch-size", type=int, default=16, help="Batch size for validation (default: 16).")

    # ── Output ───────────────────────────────────────────────────────────
    parser.add_argument(
        "--output-dir", type=Path, default=None,
        help="Directory for evaluation outputs. Defaults to <project_root>/runs/evaluate.",
    )
    parser.add_argument(
        "--json", action="store_true", dest="json_output",
        help="Emit evaluation results as JSON to stdout.",
    )
    parser.add_argument(
        "--plots", action="store_true", default=True,
        help="Generate confusion matrix and PR curve plots (default: True).",
    )

    # ── Logging ──────────────────────────────────────────────────────────
    parser.add_argument("--verbose", action="store_true", help="Enable debug logging.")

    return parser


# ═══════════════════════════════════════════════════════════════════════════════
# §2  Evaluation Runner
# ═══════════════════════════════════════════════════════════════════════════════

def run_evaluation(
    args: argparse.Namespace,
    cfg: YoloConfig,
    logger,
) -> dict[str, Any]:
    """Execute YOLOv8 validation and collect metrics.

    Pipeline stages:
        1. Locate and validate the dataset ``data.yaml``.
        2. Load the YOLOv8 model from trained or pretrained weights.
        3. Run the Ultralytics ``val()`` method on the validation split.
        4. Extract per-class and aggregate metrics.
        5. Generate plots (confusion matrix, PR curves) if requested.
        6. Optionally emit JSON results to stdout.

    Args:
        args:   Parsed CLI arguments.
        cfg:    Resolved configuration.
        logger: Logger instance.

    Returns:
        Dict containing all evaluation metrics.
    """
    from ultralytics import YOLO

    # ── §2.1  Locate dataset ─────────────────────────────────────────────
    data_yaml = cfg.data_dir / "data.yaml"
    if not data_yaml.exists():
        logger.error("data.yaml not found: %s", data_yaml)
        logger.info("Run 'yolo_data_prep.py scaffold' first to create the dataset structure.")
        sys.exit(1)

    # ── §2.2  Load model ─────────────────────────────────────────────────
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

    # ── §2.3  Configure output ───────────────────────────────────────────
    output_dir = args.output_dir or (cfg.project_root / "runs" / "evaluate")
    output_dir.mkdir(parents=True, exist_ok=True)

    # ── §2.4  Run validation ─────────────────────────────────────────────
    logger.info("Starting evaluation on: %s", data_yaml)
    t_start = time.perf_counter()

    results = model.val(
        data=str(data_yaml),
        imgsz=args.image_size,
        batch=args.batch_size,
        conf=args.conf,
        iou=args.iou,
        device=args.device,
        project=str(output_dir.parent),
        name=output_dir.name,
        exist_ok=True,
        plots=args.plots,
        verbose=cfg.verbose,
    )

    elapsed = time.perf_counter() - t_start

    # ── §2.5  Extract metrics ────────────────────────────────────────────
    metrics: dict[str, Any] = {
        "elapsed_seconds": round(elapsed, 3),
    }

    try:
        metrics["mAP50"] = round(float(results.results_dict.get("metrics/mAP50(B)", 0)), 4)
        metrics["mAP50_95"] = round(float(results.results_dict.get("metrics/mAP50-95(B)", 0)), 4)
        metrics["precision"] = round(float(results.results_dict.get("metrics/precision(B)", 0)), 4)
        metrics["recall"] = round(float(results.results_dict.get("metrics/recall(B)", 0)), 4)

        if hasattr(results, "maps") and results.maps is not None:
            per_class = []
            class_names = model.names if hasattr(model, "names") else {}
            for i, map_val in enumerate(results.maps):
                per_class.append({
                    "class_id": i,
                    "class_name": class_names.get(i, f"class_{i}"),
                    "mAP50_95": round(float(map_val), 4),
                })
            metrics["per_class"] = per_class

    except Exception as exc:
        logger.warning("Could not extract full metrics: %s", exc)
        metrics["extraction_error"] = str(exc)

    # ── §2.6  Console output ─────────────────────────────────────────────
    logger.info("═══ Evaluation Results ═══")
    logger.info("  mAP@50:       %.4f", metrics.get("mAP50", 0))
    logger.info("  mAP@50-95:    %.4f", metrics.get("mAP50_95", 0))
    logger.info("  Precision:    %.4f", metrics.get("precision", 0))
    logger.info("  Recall:       %.4f", metrics.get("recall", 0))
    logger.info("  Elapsed:      %.2fs", elapsed)

    if "per_class" in metrics:
        logger.info("  Per-class mAP@50-95:")
        for cls_info in metrics["per_class"]:
            logger.info("    %s: %.4f", cls_info["class_name"], cls_info["mAP50_95"])

    # ── §2.7  JSON output ────────────────────────────────────────────────
    if args.json_output:
        output = {
            "event": "evaluation_complete",
            "timestamp": time.time(),
            "weights": weights,
            "dataset": str(data_yaml),
            "metrics": metrics,
        }
        print(json.dumps(output, indent=2), flush=True)

    # ── §2.8  Save metrics to file ───────────────────────────────────────
    metrics_file = output_dir / "evaluation_metrics.json"
    with open(metrics_file, "w", encoding="utf-8") as fh:
        json.dump(metrics, fh, indent=2)
    logger.info("Metrics saved to: %s", metrics_file)

    return metrics


# ═══════════════════════════════════════════════════════════════════════════════
# §3  Main Entry Point
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    """Parse CLI arguments and run model evaluation.

    Exit codes:
        0 — Evaluation completed successfully.
        1 — Dataset or weights not found.
        2 — Evaluation error.
    """
    parser = build_parser()
    args = parser.parse_args()

    cfg = YoloConfig(
        data_dir=args.data_dir,
        model_variant=args.model_variant,
        confidence_threshold=args.conf,
        iou_threshold=args.iou,
        image_size=args.image_size,
        device=args.device,
        batch_size=args.batch_size,
        verbose=args.verbose,
    )

    logger = setup_logger(verbose=cfg.verbose)

    try:
        run_evaluation(args, cfg, logger)
    except SystemExit:
        raise
    except Exception as exc:
        logger.exception("Evaluation failed: %s", exc)
        sys.exit(2)


if __name__ == "__main__":
    main()
