# Technical Lesson: State Management, Granular Selectors & Performance Isolation

This guide details the challenges of building high-performance, responsive state layers in Flutter, detailing granular card rebuild boundaries, decoupled overlay components, and clean data modeling.

---

## 🔍 Case Study 1: High-Performance List Rebuild Isolation

### ❌ The Hurdle
When displaying many items inside a scrolling gallery, we often render status indicators or face tags fetched from a related state class (such as `YoloFaceProvider`).
* **The Performance Bottleneck**: A common pattern is listening to the provider inside each card using standard `context.watch<T>()` or `Consumer<T>`:

```dart
// ❌ BAD: Rebuilds every card on any face update
Widget build(BuildContext context) {
  final yoloFaceProv = context.watch<YoloFaceProvider>();
  final faces = yoloFaceProv.getFacesForMediaItem(item.id);
  
  return Card(child: Text('Faces detected: ${faces.length}'));
}
```

* **Why it fails**: When a user labels a face on *one single image*, the `YoloFaceProvider` registers the change and calls `notifyListeners()`.
* Because every card is watching the provider globally, **every single card on the screen is forced to rebuild and repaint**.
* In large archives of 200+ images, this triggers massive UI rendering churn, dropped frames (jank), and heavy scrolling lag ($O(N)$ rebuild complexity).

---

## ⚡ The Solution: Precise `Selector` Filtering

To isolate state updates and achieve highly-performant $O(1)$ rebuild complexity, we utilize granular `Selector` widgets instead of watching the entire provider:

Here is the highly optimized implementation used in our `GalleryCard` inside [gallery_card.dart](file:///d:/lab/projects/media_chronicle/lib/features/gallery/views/widgets/gallery_card.dart):

```dart
//  GOOD: Isolating card repaints using precise Selector filters
@override
Widget build(BuildContext context) {
  return Container(
    child: Column(
      children: [
        // Standard card elements...
        
        // Granular Selector isolating face updates to just this card!
        Selector<YoloFaceProvider, List<DetectedFace>>(
          // 1. Selector only listens to the list of faces matching THIS card's ID
          selector: (context, provider) => provider.getFacesForMediaItem(item.id),
          // 2. Only triggers rebuild if the old list does not equal the new list
          shouldRebuild: (oldList, newList) => !listEquals(oldList, newList),
          builder: (context, itemFaces, child) {
            if (itemFaces.isNotEmpty) {
              final hasUnidentified = itemFaces.any((f) => !f.isIdentified);
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: _buildLlmCapsuleBadge(
                  hasUnidentified ? Icons.warning_amber_rounded : Icons.psychology_outlined,
                  hasUnidentified
                      ? 'YOLO: ${itemFaces.length} Faces (Label Required)'
                      : 'YOLO: ${itemFaces.length} Faces Recognized',
                  hasUnidentified ? AppConstants.secondary : Colors.greenAccent,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  );
}
```

* **Why it works**: By filtering the provider update using the card's `item.id`, the Flutter layout engine only triggers a repaint pass for the specific card whose face list actually changed. All other 199+ cards bypass the build phase completely, enabling liquid-smooth scrolling at a solid 120 FPS.

---

## 🔍 Case Study 2: Decoupled Dialog Orchestration (DRY Views)

### ❌ The Hurdle
Features like *Face Labeling* or *Credential Editing* are interactive overlays that can be triggered from multiple screens (e.g. from the active Gallery screen, the YOLO Face Hub screen, or sidebar navigation menus).
* **The Pitfall**: Re-implementing dialog overlay methods, text field decorators, and auto-focus controllers inside each separate screen widget creates double-maintenance overhead and violates the **DRY (Don't Repeat Yourself)** principle.

### ⚡ The Solution: Standalone Overlay Classes
We extract all highly interactive dialog forms into dedicated, self-contained dialog classes (like `FaceLabelingDialog` or `MediaUploadDialog`) exposed via static `show()` helpers. 

This keeps the main screens clean and ensures that overlay logic is maintained in a single location:

```dart
//  GOOD: Self-contained, multi-screen decoupled dialog class
class FaceLabelingDialog extends StatefulWidget {
  final DetectedFace face;
  final String parentSha256;

  const FaceLabelingDialog({
    super.key,
    required this.face,
    required this.parentSha256,
  });

  static void show(BuildContext context, DetectedFace face, String parentSha256) {
    showDialog(
      context: context,
      builder: (context) => FaceLabelingDialog(face: face, parentSha256: parentSha256),
    );
  }

  @override
  State<FaceLabelingDialog> createState() => _FaceLabelingDialogState();
}
```

---

## 🔍 Case Study 3: Baseline Numerical State Modeling

### ❌ The Hurdle
Storing progress metrics (like a storage quota display) as static formatted strings inside the provider prevents other widgets from using the raw value for calculations.

```dart
// ❌ BAD: Storing pre-formatted strings makes values rigid
class SettingsProvider extends ChangeNotifier {
  String storageUsedStr = "2.4 GB"; // Rigid! Cannot use for LinearProgressIndicators
}
```

### ⚡ The Solution: Dynamic Getters
Always store baseline, raw numerical values in the provider and compute visual layouts or string formatting inside **getters**:

```dart
//  GOOD: Raw numerical states with dynamic formatting getters
class SettingsProvider extends ChangeNotifier {
  double _storageUsedGB = 2.4;
  final double _storageTotalGB = 15.0;

  double get storageUsedGB => _storageUsedGB;
  double get storageTotalGB => _storageTotalGB;

  // Dynamic progress value calculated on the fly
  double get storageProgress => _storageUsedGB / _storageTotalGB;

  // Formatted display getter
  String get storageLimit => '${_storageUsedGB.toStringAsFixed(1)} GB / ${_storageTotalGB.toInt()} GB';
}
```

---

## 💡 Key Architectural Takeaways

1. **Avoid Universal Consumer**: Never use global `context.watch<T>()` or `Consumer<T>` on complex, multiple-instanced widgets in lists. Use `Selector` to filter updates.
2. **Abstract Overlays**: Encapsulate complex forms, alert triggers, and sheet overlays into dedicated static helper classes to maintain lightweight views.
3. **Compute Visuals Dynamically**: Keep the provider's backing variables raw and clean. Delegate text formatting, divisions, and rounding to getters.
