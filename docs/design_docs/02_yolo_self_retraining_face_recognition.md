# Design Document: YOLO Self-Retraining Face Recognition Engine

## 1. Goal
Implement a self-retraining YOLO face recognition and detection engine in the Media Chronicle Flutter application. The system detects faces, groups them chronologically by identity, handles face variations resulting from growth and age progression, asks for user labeling when unknown faces are detected, and performs stochastic gradient descent (SGD) retraining in the background with interactive visual feedback.

## 2. Architecture & State Management
*   **Target Domain**: Integrated inside the Media Gallery and global navigation flow.
*   **State Coordination**:
    *   `YoloFaceProvider`: Central coordinator for face databases, mock online neural fine-tuning loops, vector cluster maps, and similarity distance calculators.
    *   `DetectedFace`: Core data structure containing coordinates (`x`, `y`, `width`, `height`), 2D vector embeddings, recognized identities, and variant categories.
*   **Decoupled Ingestion Pipeline**:
    *   Modified `GalleryProvider.addMediaItem` to accept an `onAnalyzeComplete` callback. This triggers YOLO face detection automatically right after VLM (Ollama/Fallback) image analysis completes or when a new photo is added.

## 3. UI Component Breakdown
*   **YOLO Face Hub (Primary Screen)**:
    *   *Weights Metrics HUD*: Shows live loss/accuracy meters, enrolled stats, and triggers manual model weight resets.
    *   *Live Training Log Console*: Renders real-time stochastic gradient descent logs inside a scrolling terminal window when retraining is running.
    *   *Embeddings Vector Map*: A custom-drawn 2D scatter plot mapping face vector points. Chronological developments under the same name are linked with subtle dotted path connections representing face aging.
    *   *Chronological Age Timeline*: Displays horizontal grids of enrolled individuals showing their chronological face variations (e.g. John from Childhood to Adulthood) using original photo clippings.
    *   *Active Learning Queue*: Lists unidentified faces with prompt triggers to label and retrain.
*   **Interactive Glowing Bounding Boxes**:
    *   Displays responsive neon cyan (recognized) and rose pink (unknown) glowing bounding boxes stacked on top of photo detail views using a responsive `LayoutBuilder`.
    *   Tapping overlays triggers the direct face-labeling dialog.
*   **Age/Growth Variance Validation**:
    *   Calculates similarity distances between new labels and enrolled profiles.
    *   If a face differs significantly (> 25 units in embedding space) from existing enrolled profiles under the same name, it triggers an **Age Variant Detected** dialog prompting the host to register it as a "Same Person (Age Variant)" or a "Different Person".

## 4. Verification Setup
*   **Static Code Analysis**: Audited and compiled with zero errors, warnings, or formatting issues across the entire workspace using the Flutter compiler.
