# Design Document: VLM Sequential Queue & Multi-Select Archive Actions

## 1. Goal
Implement a highly resilient, sequential image ingestion queue for local vision-language models (VLM), coordinate face annotations directly into LLM prompts, and form a premium multi-selection batch action system in the Media Chronicle gallery.

## 2. Technical Architectures
*   **Sequential VLM Task Queue (`GalleryProvider`)**:
    *   Defines a `_VlmTask` containing target parameters, identified faces, and callbacks.
    *   Maintains a sequential queue loop (`_processVlmQueue`) executing VLM queries one-at-a-time, protecting the local Ollama server from parallel ingestion overloads.
    *   Increases timeouts to **90 seconds** and engages the high-fidelity smart visual fallback simulator on offline/failure states.
*   **YOLO -> VLM Prompt Sequencing**:
    *   By default, YOLO face recognition runs *first* synchronously.
    *   Identified face names are aggregated and passed to the VLM via the `preIdentifiedFaces` prompt modifier.
    *   VLM uses these pre-identified face names inside its generated short and long descriptions, creating a cohesive, unified metadata profile.
*   **Multi-Select & Batch Actions (`GalleryScreen`)**:
    *   Maintains a local selection state `_selectedItemIds` and toggles selection mode.
    *   Displays a glowing twilight selection toolbar in the gallery header with Select All, Cancel, and Action dropdown triggers.
    *   Image cards show glowing checkmark overlays and custom neon borders when selected.
    *   Batch Actions:
        *   `Move`: Adds items to the chosen album and removes them from the current active folder.
        *   `Copy`: Adds items to the chosen album, keeping original positions.
        *   `Delete`: Removes selected items from the gallery and Postgres sync tables in a batch.
        *   `Re-run VLM`: Re-queues selected items inside the VLM queue, passing pre-identified face names.

## 3. UI Component Details
*   **Selection Toolbar HUD**: Placed in `lib/features/gallery/views/gallery_screen.dart`, it replaces the standard header row with a neon checkmark bar when selection is active.
*   **Overlay Selection Checkmark**: Image cards render a semi-transparent primary overlay with a glowing central checkmark and a thick neon cyan border.
*   **Action Popup Menu**: Triggered from the Actions dropdown, providing one-click moves, copies, deletions, and sequential VLM re-tagging.

## 4. Verification Setup
*   **Static Code Analysis**: Audited and compiled with zero errors or warnings using the Flutter compiler.
