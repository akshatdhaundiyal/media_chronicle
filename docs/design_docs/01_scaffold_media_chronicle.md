# Design Document: Scaffolding Media Chronicle Workspace

## 1. Goal
Scaffold a premium, responsive Flutter application named `media_chronicle` targeting visual gallery archiving, story narrative curation, and general control center preference setting.

## 2. Tech Stack & State Management
*   **Target Platform**: Flutter Web (Originally scaffolded for Web; permanently migrated to Windows-native Desktop only in Milestone 7)
*   **State Coordination**: `MultiProvider` tree linking:
    *   `AppState`: Coordinates top tabs (`stories`, `gallery`, `settings`) and global filtering values.
    *   `StoriesProvider`: Tracks and mutates chronological story narratives.
    *   `GalleryProvider`: Manages individual media collections.
    *   `SettingsProvider`: Manages visual configuration flags, display names, and storage charts.
*   **Design Accents**: Custom geometric typography (`Outfit`), frosted cards using `BackdropFilter`, thin light strokes (`Color(0x1BFFFFFF)`), and floating ambient background glows.

## 3. UI Component Breakdown
*   **Sidebar Navigation Panel**: Renders session profile metadata, quick storage meters, and floating menu items on desktop sizes. Swaps to a compact bottom navigation bar on mobile sizes.
*   **Global Filter Header**: A responsive search input field filtering memory posts and images dynamically across screens.
*   **Masonry Gallery Board**: Displays image cards with responsive layout grids (2 to 4 columns), full photo details, and file uploads.
*   **Chronological Narrative Stream**: Renders stories with cover images and handles rich journal draft creation.
*   **Control Center Screen**: Handles storage synchronizers, display name overrides, dark toggles, and notification settings.

## 4. Verification Setup
*   **Static Code Analysis**: Enforced strict linter rule audits, removing all deprecated elements.
*   **Widget Viewport Interceptors**: Overrides default viewport resolutions (1200x800) and intercepts mock HTTP network calls in test wrappers.
