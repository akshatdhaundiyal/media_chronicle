# /// script
# /// requires-python = ">=3.10"
# /// dependencies = [
# ///   "ultralytics>=8.2.0",
# ///   "pyyaml>=6.0",
# ///   "rich>=13.0",
# ///   "onnx>=1.14.0",
# /// ]
# /// [tool.uv]
# /// exclude-newer = "2026-06-01"
# ///
# ──────────────────────────────────────────────────────────────────────────────
# yolo_export.py — Model Export & Format Conversion Utility
# ──────────────────────────────────────────────────────────────────────────────
#
# Converts trained YOLOv8 `.pt` weights to deployment-ready formats such as
# ONNX, TorchScript, TensorFlow Lite, CoreML, or OpenVINO. This enables
# the Flutter desktop app to run inference using optimised runtimes without
# requiring the full PyTorch stack at deployment time.
#
# Supported export formats (via Ultralytics):
#   • onnx         — Open Neural Network Exchange (recommended for Windows).
#   • torchscript  — PyTorch JIT traced model.
#   • tflite       — TensorFlow Lite (mobile / edge).
#   • coreml       — Apple CoreML (macOS / iOS).
#   • openvino     — Intel OpenVINO IR.
#   • engine       — NVIDIA TensorRT (requires GPU + TensorRT).
#   • saved_model  — TensorFlow SavedModel.
#
# Usage:
#     uv run scripts/yolo_export.py --format onnx
#     uv run scripts/yolo_export.py --weights runs/train/weights/best.pt --format tflite
#     uv run scripts/yolo_export.py --format onnx --simplify --dynamic --image-size 320
# ──────────────────────────────────────────────────────────────────────────────

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

# ── Ensure scripts/ is on sys.path ──────────────────────────────────────────
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from utils.config import YoloConfig
from utils.logging_setup import setup_logger


# ── Supported export format descriptors ──────────────────────────────────────
EXPORT_FORMATS = {
    "onnx":        {"suffix": ".onnx",       "desc": "Open Neural Network Exchange"},
    "torchscript": {"suffix": ".torchscript", "desc": "PyTorch TorchScript"},
    "tflite":      {"suffix": ".tflite",      "desc": "TensorFlow Lite"},
    "coreml":      {"suffix": ".mlpackage",   "desc": "Apple CoreML"},
    "openvino":    {"suffix": "_openvino",     "desc": "Intel OpenVINO IR"},
    "engine":      {"suffix": ".engine",      "desc": "NVIDIA TensorRT"},
    "saved_model": {"suffix": "_saved_model", "desc": "TensorFlow SavedModel"},
}


# ═══════════════════════════════════════════════════════════════════════════════
# §1  CLI Argument Parser
# ═══════════════════════════════════════════════════════════════════════════════

def build_parser() -> argparse.ArgumentParser:
    """Construct the CLI parser for export-specific flags.

    Returns:
        A configured :class:`argparse.ArgumentParser`.
    """
    format_help = "\n".join(f"  {k:15s} — {v['desc']}" for k, v in EXPORT_FORMATS.items())

    parser = argparse.ArgumentParser(
        prog="yolo_export",
        description=(
            "Export a trained YOLOv8 model to a deployment-ready format.\n\n"
            f"Supported formats:\n{format_help}"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # ── Model ────────────────────────────────────────────────────────────
    parser.add_argument(
        "--weights", type=str, default=None,
        help="Path to the trained .pt weights to export. Defaults to "
             "<project_root>/runs/train/weights/best.pt.",
    )

    # ── Export options ───────────────────────────────────────────────────
    parser.add_argument(
        "--format", type=str, default="onnx",
        choices=list(EXPORT_FORMATS.keys()),
        help="Target export format (default: onnx).",
    )
    parser.add_argument("--image-size", type=int, default=640, help="Export input resolution (default: 640).")
    parser.add_argument("--device", type=str, default="cpu", help="Device for tracing (default: cpu).")
    parser.add_argument(
        "--half", action="store_true",
        help="Export with FP16 half-precision (reduces model size, needs GPU).",
    )
    parser.add_argument(
        "--dynamic", action="store_true",
        help="Enable dynamic input shapes (ONNX/TorchScript only).",
    )
    parser.add_argument(
        "--simplify", action="store_true",
        help="Simplify ONNX graph using onnx-simplifier.",
    )
    parser.add_argument(
        "--opset", type=int, default=17,
        help="ONNX opset version (default: 17).",
    )

    # ── Output ───────────────────────────────────────────────────────────
    parser.add_argument(
        "--output-dir", type=Path, default=None,
        help="Directory for exported models. Defaults to <project_root>/runs/export.",
    )
    parser.add_argument(
        "--json", action="store_true", dest="json_output",
        help="Emit export metadata as JSON to stdout.",
    )

    # ── Logging ──────────────────────────────────────────────────────────
    parser.add_argument("--verbose", action="store_true", help="Enable debug logging.")

    return parser


# ═══════════════════════════════════════════════════════════════════════════════
# §2  Export Runner
# ═══════════════════════════════════════════════════════════════════════════════

def run_export(args: argparse.Namespace, cfg: YoloConfig, logger) -> dict:
    """Execute the model export pipeline.

    Pipeline stages:
        1. Locate the trained ``.pt`` weights file.
        2. Load the YOLOv8 model.
        3. Call ``model.export()`` with the requested format and options.
        4. Report the exported file path and size.

    Args:
        args:   Parsed CLI arguments.
        cfg:    Resolved configuration.
        logger: Logger instance.

    Returns:
        Dict containing export metadata (path, size, format, elapsed time).
    """
    from ultralytics import YOLO

    # ── §2.1  Locate weights ─────────────────────────────────────────────
    weights = args.weights
    if weights is None:
        default_best = cfg.project_root / "runs" / "train" / "weights" / "best.pt"
        if default_best.exists():
            weights = str(default_best)
        else:
            logger.error(
                "No trained weights found at: %s\n"
                "Either train a model first or specify --weights.",
                default_best,
            )
            sys.exit(1)

    logger.info("Loading model from: %s", weights)
    model = YOLO(weights)

    # ── §2.2  Execute export ─────────────────────────────────────────────
    export_format = args.format
    logger.info("Exporting to %s format...", export_format.upper())
    t_start = time.perf_counter()

    export_kwargs = {
        "format": export_format,
        "imgsz": args.image_size,
        "device": args.device,
        "half": args.half,
    }

    # Format-specific options.
    if export_format == "onnx":
        export_kwargs["dynamic"] = args.dynamic
        export_kwargs["simplify"] = args.simplify
        export_kwargs["opset"] = args.opset
    elif export_format == "torchscript":
        pass  # no extra options needed
    elif export_format == "engine":
        export_kwargs["dynamic"] = args.dynamic

    exported_path = model.export(**export_kwargs)
    elapsed = time.perf_counter() - t_start

    # ── §2.3  Measure output ─────────────────────────────────────────────
    exported_path = Path(exported_path) if exported_path else None
    file_size_mb = 0.0
    if exported_path and exported_path.exists():
        if exported_path.is_file():
            file_size_mb = exported_path.stat().st_size / (1024 * 1024)
        elif exported_path.is_dir():
            # Some formats export as directories (e.g. OpenVINO, SavedModel).
            total = sum(f.stat().st_size for f in exported_path.rglob("*") if f.is_file())
            file_size_mb = total / (1024 * 1024)

    # ── §2.4  Optionally copy to output directory ────────────────────────
    output_dir = args.output_dir or (cfg.project_root / "runs" / "export")
    output_dir.mkdir(parents=True, exist_ok=True)

    # ── §2.5  Report results ─────────────────────────────────────────────
    result = {
        "format": export_format,
        "source_weights": weights,
        "exported_path": str(exported_path) if exported_path else None,
        "file_size_mb": round(file_size_mb, 2),
        "image_size": args.image_size,
        "half_precision": args.half,
        "dynamic_shapes": args.dynamic,
        "elapsed_seconds": round(elapsed, 3),
    }

    logger.info("═══ Export Complete ═══")
    logger.info("  Format:     %s", export_format)
    logger.info("  Output:     %s", exported_path)
    logger.info("  Size:       %.2f MB", file_size_mb)
    logger.info("  Elapsed:    %.2fs", elapsed)

    # ── §2.6  JSON output ────────────────────────────────────────────────
    if args.json_output:
        output = {
            "event": "export_complete",
            "timestamp": time.time(),
            **result,
        }
        print(json.dumps(output, indent=2), flush=True)

    return result


# ═══════════════════════════════════════════════════════════════════════════════
# §3  Main Entry Point
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    """Parse CLI arguments and run model export.

    Exit codes:
        0 — Export completed successfully.
        1 — Weights not found.
        2 — Export error.
    """
    parser = build_parser()
    args = parser.parse_args()

    cfg = YoloConfig(
        image_size=args.image_size,
        device=args.device,
        export_format=args.format,
        verbose=args.verbose,
    )

    logger = setup_logger(verbose=cfg.verbose)

    try:
        run_export(args, cfg, logger)
    except SystemExit:
        raise
    except Exception as exc:
        logger.exception("Export failed: %s", exc)
        sys.exit(2)


if __name__ == "__main__":
    main()
