# ──────────────────────────────────────────────────────────────────────────────
# logging_setup.py — Uniform Logging Factory for the YOLO Pipeline
# ──────────────────────────────────────────────────────────────────────────────
#
# Provides a single `setup_logger()` function that every script calls once at
# startup. This avoids ad-hoc `print()` calls scattered throughout the
# codebase and gives us consistent, time-stamped, level-tagged output in both
# the console (via Rich) and a rotating log file.
#
# Features:
#   • Rich-formatted console output with colour-coded log levels.
#   • Automatic rotating file handler (10 MB max, 5 backups).
#   • Separate formatting for console (concise) vs file (verbose + traceback).
#   • Importable `logger` singleton so every module gets the same instance.
#
# Usage:
#   from utils.logging_setup import setup_logger
#   logger = setup_logger(verbose=True)
#   logger.info("Training started")
# ──────────────────────────────────────────────────────────────────────────────

from __future__ import annotations

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Optional


def setup_logger(
    name: str = "yolo_pipeline",
    log_dir: Optional[Path] = None,
    verbose: bool = False,
) -> logging.Logger:
    """Create and configure the pipeline-wide logger.

    This function is idempotent — calling it multiple times returns the same
    logger instance (standard ``logging`` module behaviour). Handlers are only
    attached on the first invocation to prevent duplicate output.

    Args:
        name:     Logger name. All pipeline modules should share the same name
                  so that log levels propagate uniformly.
        log_dir:  Directory for the rotating log file. Defaults to
                  ``<project_root>/runs/logs/``. The directory is created
                  automatically if it doesn't exist.
        verbose:  If True, sets log level to DEBUG; otherwise INFO.

    Returns:
        A fully configured :class:`logging.Logger` instance.
    """
    logger = logging.getLogger(name)

    # ── Guard: only attach handlers once ──────────────────────────────────
    if logger.handlers:
        return logger

    level = logging.DEBUG if verbose else logging.INFO
    logger.setLevel(level)

    # ── Console handler ──────────────────────────────────────────────────
    # We attempt to use Rich for beautiful terminal output. If Rich is not
    # installed (it's optional), we fall back to a plain StreamHandler.
    try:
        from rich.logging import RichHandler

        console_handler = RichHandler(
            level=level,
            show_time=True,
            show_path=verbose,       # only show file paths in debug mode
            markup=True,
            rich_tracebacks=True,
            tracebacks_show_locals=verbose,
        )
        console_handler.setFormatter(logging.Formatter("%(message)s"))
    except ImportError:
        # Graceful degradation: plain console output if Rich is unavailable.
        console_handler = logging.StreamHandler(sys.stdout)
        console_fmt = logging.Formatter(
            fmt="%(asctime)s │ %(levelname)-8s │ %(message)s",
            datefmt="%H:%M:%S",
        )
        console_handler.setFormatter(console_fmt)
        console_handler.setLevel(level)

    logger.addHandler(console_handler)

    # ── Rotating file handler ────────────────────────────────────────────
    # Each run appends to the same log file; rotation kicks in at 10 MB.
    if log_dir is None:
        # Lazy import to avoid circular dependency at module load time.
        from .config import resolve_project_root

        log_dir = resolve_project_root() / "runs" / "logs"

    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / f"{name}.log"

    file_handler = RotatingFileHandler(
        filename=str(log_file),
        maxBytes=10 * 1024 * 1024,   # 10 MB per file
        backupCount=5,               # keep 5 rotated archives
        encoding="utf-8",
    )
    file_handler.setLevel(logging.DEBUG)  # always capture everything to file
    file_fmt = logging.Formatter(
        fmt="%(asctime)s │ %(levelname)-8s │ %(name)s:%(funcName)s:%(lineno)d │ %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    file_handler.setFormatter(file_fmt)
    logger.addHandler(file_handler)

    # ── Initial banner ───────────────────────────────────────────────────
    logger.debug("Logger initialised — level=%s, file=%s", level, log_file)

    return logger
