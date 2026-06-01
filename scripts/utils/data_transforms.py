# ──────────────────────────────────────────────────────────────────────────────
# data_transforms.py — Image Augmentation & Dataset Format Converters
# ──────────────────────────────────────────────────────────────────────────────
#
# Centralises all data manipulation logic so that training, evaluation, and
# data-prep scripts share identical augmentation pipelines and annotation
# format converters.
#
# Sections:
#   1. Augmentation pipeline builder (Albumentations-based).
#   2. Annotation format converters: COCO ↔ YOLO ↔ Pascal VOC.
#   3. Utility helpers: image resizing, padding, normalisation.
#
# All functions are pure (no side-effects, no file I/O) unless explicitly
# documented otherwise, making them trivially testable.
# ──────────────────────────────────────────────────────────────────────────────

from __future__ import annotations

import json
import logging
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Optional

logger = logging.getLogger("yolo_pipeline")


# ═══════════════════════════════════════════════════════════════════════════════
# §1  Augmentation Pipeline
# ═══════════════════════════════════════════════════════════════════════════════

def build_augmentation_pipeline(
    image_size: int = 640,
    *,
    flip_horizontal: bool = True,
    flip_vertical: bool = False,
    brightness_limit: float = 0.2,
    contrast_limit: float = 0.2,
    hue_shift_limit: int = 20,
    saturation_limit: int = 30,
    blur_limit: int = 5,
    rotate_limit: int = 15,
    scale_range: tuple[float, float] = (0.8, 1.2),
    mosaic: bool = False,
) -> Any:
    """Build an Albumentations augmentation pipeline for face-detection training.

    The returned ``Compose`` object accepts an image + bounding boxes and
    returns augmented versions with geometrically consistent bbox transforms.

    Args:
        image_size:        Target square resolution after resize + padding.
        flip_horizontal:   Random left-right flip (p=0.5).
        flip_vertical:     Random top-bottom flip (p=0.5).  Disabled by
                           default — faces are rarely upside-down.
        brightness_limit:  Max brightness delta (±).
        contrast_limit:    Max contrast delta (±).
        hue_shift_limit:   Max hue shift in degrees.
        saturation_limit:  Max saturation shift.
        blur_limit:        Max Gaussian blur kernel size.
        rotate_limit:      Max rotation angle (degrees).
        scale_range:       Min/max scale factors for random resize.
        mosaic:            Whether to include CutOut / GridDropout
                           (approximation of YOLO mosaic, since true
                           mosaic requires multi-image compositing at
                           the DataLoader level).

    Returns:
        An ``albumentations.Compose`` pipeline configured with bbox support
        in YOLO normalised format ``[x_center, y_center, width, height]``.

    Raises:
        ImportError: If Albumentations is not installed. The error message
            includes the exact ``uv`` command to install it.

    Example::

        pipeline = build_augmentation_pipeline(image_size=640)
        result = pipeline(image=img_np, bboxes=boxes, class_labels=labels)
        augmented_img = result["image"]
        augmented_boxes = result["bboxes"]
    """
    try:
        import albumentations as A
    except ImportError as exc:
        raise ImportError(
            "Albumentations is required for augmentation. "
            "Install via: uv pip install albumentations"
        ) from exc

    # ── Assemble the transform list ──────────────────────────────────────
    transforms: list[Any] = []

    # Geometric transforms (applied to both image and bboxes).
    if flip_horizontal:
        transforms.append(A.HorizontalFlip(p=0.5))
    if flip_vertical:
        transforms.append(A.VerticalFlip(p=0.5))

    transforms.append(
        A.ShiftScaleRotate(
            shift_limit=0.05,
            scale_limit=(scale_range[0] - 1.0, scale_range[1] - 1.0),
            rotate_limit=rotate_limit,
            border_mode=0,  # cv2.BORDER_CONSTANT
            p=0.5,
        )
    )

    # Photometric transforms (image-only, bboxes unchanged).
    transforms.append(
        A.RandomBrightnessContrast(
            brightness_limit=brightness_limit,
            contrast_limit=contrast_limit,
            p=0.5,
        )
    )
    transforms.append(
        A.HueSaturationValue(
            hue_shift_limit=hue_shift_limit,
            sat_shift_limit=saturation_limit,
            val_shift_limit=20,
            p=0.4,
        )
    )
    transforms.append(A.GaussianBlur(blur_limit=(3, blur_limit), p=0.2))
    transforms.append(A.GaussNoise(p=0.15))

    # Optional cutout (coarse dropout) as a mosaic approximation.
    if mosaic:
        transforms.append(
            A.CoarseDropout(
                max_holes=8,
                max_height=int(image_size * 0.1),
                max_width=int(image_size * 0.1),
                fill_value=114,  # YOLO standard grey padding value
                p=0.3,
            )
        )

    # Final resize + padding to the target square resolution.
    transforms.append(
        A.LongestMaxSize(max_size=image_size)
    )
    transforms.append(
        A.PadIfNeeded(
            min_height=image_size,
            min_width=image_size,
            border_mode=0,
            value=(114, 114, 114),  # YOLO grey padding
            p=1.0,
        )
    )

    # ── Compose with YOLO-format bbox parameters ────────────────────────
    pipeline = A.Compose(
        transforms,
        bbox_params=A.BboxParams(
            format="yolo",                         # [x_center, y_center, w, h] normalised
            label_fields=["class_labels"],
            min_visibility=0.3,                    # drop bboxes that are >70% clipped
        ),
    )

    logger.debug(
        "Augmentation pipeline built — %d transforms, target %d×%d",
        len(transforms), image_size, image_size,
    )
    return pipeline


# ═══════════════════════════════════════════════════════════════════════════════
# §2  Annotation Format Converters
# ═══════════════════════════════════════════════════════════════════════════════

def coco_to_yolo(
    coco_json_path: Path,
    output_dir: Path,
    *,
    class_names: Optional[list[str]] = None,
) -> dict[str, int]:
    """Convert a COCO-format annotation JSON file to YOLO per-image ``.txt`` labels.

    COCO bbox format:  ``[x_min, y_min, width, height]`` (absolute pixels).
    YOLO bbox format:  ``[class_id, x_center, y_center, width, height]`` (normalised 0–1).

    Args:
        coco_json_path: Path to the COCO ``instances_*.json`` file.
        output_dir:     Directory where per-image ``.txt`` files are written.
                        Created automatically if missing.
        class_names:    Optional ordered list of class names. If provided,
                        COCO category IDs are remapped to indices in this list.
                        If None, the original ``category_id`` is used as-is.

    Returns:
        A dict with conversion statistics::

            {"images_processed": 150, "annotations_written": 423}

    Raises:
        FileNotFoundError: If ``coco_json_path`` doesn't exist.
        json.JSONDecodeError: If the file isn't valid JSON.
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    with open(coco_json_path, "r", encoding="utf-8") as fh:
        coco_data = json.load(fh)

    # ── Build lookup tables ──────────────────────────────────────────────
    # Map COCO category IDs → sequential class indices.
    categories = {cat["id"]: cat["name"] for cat in coco_data.get("categories", [])}
    if class_names:
        cat_id_to_idx = {}
        for cat_id, cat_name in categories.items():
            if cat_name in class_names:
                cat_id_to_idx[cat_id] = class_names.index(cat_name)
    else:
        cat_id_to_idx = {cat_id: cat_id for cat_id in categories}

    # Map image IDs → (filename, width, height).
    images = {
        img["id"]: (img["file_name"], img["width"], img["height"])
        for img in coco_data.get("images", [])
    }

    # ── Group annotations by image ───────────────────────────────────────
    from collections import defaultdict
    annotations_by_image: dict[int, list] = defaultdict(list)
    for ann in coco_data.get("annotations", []):
        annotations_by_image[ann["image_id"]].append(ann)

    # ── Write one .txt per image ─────────────────────────────────────────
    stats = {"images_processed": 0, "annotations_written": 0}

    for img_id, (filename, img_w, img_h) in images.items():
        txt_name = Path(filename).stem + ".txt"
        txt_path = output_dir / txt_name
        lines: list[str] = []

        for ann in annotations_by_image.get(img_id, []):
            cat_id = ann["category_id"]
            if cat_id not in cat_id_to_idx:
                continue  # skip categories not in our class list

            class_idx = cat_id_to_idx[cat_id]
            x_min, y_min, box_w, box_h = ann["bbox"]

            # Convert absolute pixels → normalised YOLO format.
            x_center = (x_min + box_w / 2.0) / img_w
            y_center = (y_min + box_h / 2.0) / img_h
            norm_w = box_w / img_w
            norm_h = box_h / img_h

            lines.append(f"{class_idx} {x_center:.6f} {y_center:.6f} {norm_w:.6f} {norm_h:.6f}")
            stats["annotations_written"] += 1

        txt_path.write_text("\n".join(lines), encoding="utf-8")
        stats["images_processed"] += 1

    logger.info(
        "COCO → YOLO conversion complete: %d images, %d annotations",
        stats["images_processed"], stats["annotations_written"],
    )
    return stats


def yolo_to_coco(
    labels_dir: Path,
    images_dir: Path,
    class_names: list[str],
    output_json: Path,
) -> dict[str, int]:
    """Convert YOLO per-image ``.txt`` labels back to a single COCO JSON file.

    This is the inverse of :func:`coco_to_yolo`, useful for evaluating
    YOLO-trained models with COCO mAP tools (pycocotools).

    Args:
        labels_dir:   Directory containing YOLO ``.txt`` label files.
        images_dir:   Directory containing the corresponding images (used
                      to read image dimensions via PIL).
        class_names:  Ordered list of class names (index = class_id).
        output_json:  Path where the output COCO JSON is written.

    Returns:
        A dict with conversion statistics::

            {"images_processed": 150, "annotations_written": 423}
    """
    try:
        from PIL import Image
    except ImportError as exc:
        raise ImportError(
            "Pillow is required for yolo_to_coco. Install via: uv pip install Pillow"
        ) from exc

    coco_output: dict[str, Any] = {
        "images": [],
        "annotations": [],
        "categories": [
            {"id": idx, "name": name} for idx, name in enumerate(class_names)
        ],
    }

    ann_id = 0
    stats = {"images_processed": 0, "annotations_written": 0}

    for txt_file in sorted(labels_dir.glob("*.txt")):
        # Find the matching image file (try common extensions).
        img_file = None
        for ext in (".jpg", ".jpeg", ".png", ".bmp", ".webp"):
            candidate = images_dir / (txt_file.stem + ext)
            if candidate.exists():
                img_file = candidate
                break

        if img_file is None:
            logger.warning("No image found for label file: %s", txt_file.name)
            continue

        img = Image.open(img_file)
        img_w, img_h = img.size
        img_id = stats["images_processed"]

        coco_output["images"].append({
            "id": img_id,
            "file_name": img_file.name,
            "width": img_w,
            "height": img_h,
        })

        # Parse YOLO label lines.
        for line in txt_file.read_text(encoding="utf-8").strip().splitlines():
            parts = line.strip().split()
            if len(parts) < 5:
                continue

            class_idx = int(parts[0])
            x_center, y_center, norm_w, norm_h = map(float, parts[1:5])

            # Convert normalised YOLO → absolute COCO bbox [x_min, y_min, w, h].
            box_w = norm_w * img_w
            box_h = norm_h * img_h
            x_min = (x_center * img_w) - (box_w / 2.0)
            y_min = (y_center * img_h) - (box_h / 2.0)

            coco_output["annotations"].append({
                "id": ann_id,
                "image_id": img_id,
                "category_id": class_idx,
                "bbox": [round(x_min, 2), round(y_min, 2), round(box_w, 2), round(box_h, 2)],
                "area": round(box_w * box_h, 2),
                "iscrowd": 0,
            })
            ann_id += 1
            stats["annotations_written"] += 1

        stats["images_processed"] += 1

    output_json.parent.mkdir(parents=True, exist_ok=True)
    with open(output_json, "w", encoding="utf-8") as fh:
        json.dump(coco_output, fh, indent=2)

    logger.info(
        "YOLO → COCO conversion complete: %d images, %d annotations → %s",
        stats["images_processed"], stats["annotations_written"], output_json,
    )
    return stats


def voc_to_yolo(
    voc_xml_dir: Path,
    output_dir: Path,
    class_names: list[str],
) -> dict[str, int]:
    """Convert Pascal VOC XML annotations to YOLO per-image ``.txt`` labels.

    VOC stores bounding boxes as ``[xmin, ymin, xmax, ymax]`` in absolute
    pixels. This function normalises them to YOLO's
    ``[x_center, y_center, width, height]`` format.

    Args:
        voc_xml_dir:  Directory containing Pascal VOC ``.xml`` annotation files.
        output_dir:   Directory for the output YOLO ``.txt`` label files.
        class_names:  Ordered list of class names. Objects whose class is not
                      in this list are skipped with a warning.

    Returns:
        A dict with conversion statistics::

            {"images_processed": 150, "annotations_written": 423}
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    stats = {"images_processed": 0, "annotations_written": 0}

    for xml_file in sorted(voc_xml_dir.glob("*.xml")):
        tree = ET.parse(xml_file)
        root = tree.getroot()

        # Extract image dimensions from the XML.
        size_el = root.find("size")
        if size_el is None:
            logger.warning("Skipping %s — no <size> element found.", xml_file.name)
            continue

        img_w = int(size_el.findtext("width", "0"))
        img_h = int(size_el.findtext("height", "0"))
        if img_w == 0 or img_h == 0:
            logger.warning("Skipping %s — zero image dimensions.", xml_file.name)
            continue

        lines: list[str] = []

        for obj in root.iter("object"):
            name = obj.findtext("name", "").strip()
            if name not in class_names:
                logger.debug("Skipping unknown class '%s' in %s", name, xml_file.name)
                continue

            class_idx = class_names.index(name)
            bbox = obj.find("bndbox")
            if bbox is None:
                continue

            xmin = float(bbox.findtext("xmin", "0"))
            ymin = float(bbox.findtext("ymin", "0"))
            xmax = float(bbox.findtext("xmax", "0"))
            ymax = float(bbox.findtext("ymax", "0"))

            # Convert absolute corners → normalised YOLO center format.
            x_center = ((xmin + xmax) / 2.0) / img_w
            y_center = ((ymin + ymax) / 2.0) / img_h
            norm_w = (xmax - xmin) / img_w
            norm_h = (ymax - ymin) / img_h

            lines.append(f"{class_idx} {x_center:.6f} {y_center:.6f} {norm_w:.6f} {norm_h:.6f}")
            stats["annotations_written"] += 1

        txt_path = output_dir / (xml_file.stem + ".txt")
        txt_path.write_text("\n".join(lines), encoding="utf-8")
        stats["images_processed"] += 1

    logger.info(
        "VOC → YOLO conversion complete: %d images, %d annotations",
        stats["images_processed"], stats["annotations_written"],
    )
    return stats
