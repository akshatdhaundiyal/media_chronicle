# Technical Lesson: Widget Lifecycles, Controller Caching & Async Context Safety

This guide details the structural challenges of managing controller lifecycles in Flutter, preventing memory leaks, cursor-jumping bugs, and addressing critical asynchronous context gaps when working with dismissible dialog overlays.

---

## 🔍 Case Study 1: Cursor-Jumping Text Controllers

### ❌ The Hurdle
Declaring a `TextEditingController` inside a `StatelessWidget`'s `build` method or within an inline stateless helper method causes a new instance of the controller to be instantiated on **every single parent repaint pass**. 
* **The Glitch**: When a user types a single character inside a text field, the widget registers the text update, updates the backing State Provider, and triggers a parent rebuild.
* During the rebuild, the stateless widget instantiates a brand new `TextEditingController`. 
* This wipes out the active selection history and **resets the user's cursor back to index 0** (the very beginning of the field), making typing completely unusable.

```dart
// ❌ BAD: Instantiating controllers inside a stateless build scope
class LlmSettingsCard extends StatelessWidget {
  Widget build(BuildContext context) {
    // Recreated on every keystroke/repaint pass!
    final controller = TextEditingController(text: provider.ollamaUrl);
    
    return TextField(
      controller: controller,
      onChanged: (val) => provider.updateUrl(val),
    );
  }
}
```

---

## 🔍 Case Study 2: ScrollController Memory Leakage

### ❌ The Hurdle
A monospace retro terminal widget was designed to scroll training logs dynamically. 
* Declaring a `ScrollController` inside a `StatelessWidget` class created a new controller instance on every scrolling state change or print update.
* Because `StatelessWidget` has no `dispose()` hooks, the old `ScrollController` instances remained active and registered in the system memory.
* This caused severe **resource leaks**, sluggish scrolling performance, and reset the terminal scroll offset back to the top on every repaint pass.

---

## ⚡ The Solution: Stateful Caching & Proper Terminations

To resolve both cursor-jumping and scroll-leak issues, controllers **must** have their lifecycles bound to a persistent `StatefulWidget` class block:
1. Instantiate and cache controllers strictly inside `initState()`.
2. Terminate and release memory resources inside `dispose()`.

Here is the correct implementation used in our `PostgresSyncCard` inside [settings_screen.dart](file:///d:/lab/projects/media_chronicle/lib/features/settings/views/settings_screen.dart):

```dart
//  GOOD: Managing controller lifecycles safely inside a stateful widget
class PostgresSyncCard extends StatefulWidget {
  const PostgresSyncCard({super.key});

  @override
  State<PostgresSyncCard> createState() => _PostgresSyncCardState();
}

class _PostgresSyncCardState extends State<PostgresSyncCard> {
  late final ScrollController _terminalController;
  late final TextEditingController _hostController;

  @override
  void initState() {
    super.initState();
    _terminalController = ScrollController();
    
    final settings = context.read<SettingsProvider>();
    _hostController = TextEditingController(text: settings.postgresHost);
  }

  @override
  void dispose() {
    //  Clean up and release resources to prevent system memory leaks!
    _terminalController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Controller references remain stable on repaint passes
    return TextField(controller: _hostController);
  }
}
```

---

## 🔍 Case Study 3: The Silent Asynchronous Dialog Pop Hang

### ❌ The Hurdle
A critical bug occurred in our `MediaUploadDialog` (`media_upload_dialog.dart`) where imported camera snapshots and browsed files would **never actually show up** in the gallery catalog:

Here was the original button click implementation:

```dart
// ❌ BAD: Popping dialog context before asynchronous file picking
TextButton(
  onPressed: () async {
    Navigator.pop(context); // 1. Pops the dialog, immediately unmounting its BuildContext
    
    final result = await MediaHelper.pickImage(source: ImageSource.camera); // 2. Async pick
    
    if (result != null && result.bytes != null) {
      final newItem = MediaItem(...);
      
      if (context.mounted) { // 3. context.mounted is now FALSE!
        context.read<GalleryProvider>().addMediaItem(newItem); // ❌ Never executed!
      }
    }
  },
  child: const Text('Use Camera'),
)
```

* **Why it failed**: Popping the dialog immediately invalidates and unmounts the dialog's local `BuildContext`. After the asynchronous file picking finished, checking `if (context.mounted)` evaluated to `false`. Consequently, the code completely skipped calling `addMediaItem`, and the images were silently ignored!

---

## ⚡ The Solution: Synchronous Pre-Capturing & Safe Execution

To address asynchronous context gaps, we must **pre-capture all required provider and service instances synchronously** at the very beginning of the button handler—**before** any asynchronous gap (`await`) or dialog pops:

Here is our robust implementation in [media_upload_dialog.dart](file:///d:/lab/projects/media_chronicle/lib/features/gallery/views/widgets/media_upload_dialog.dart):

```dart
//  GOOD: Capture providers synchronously before async pickers or pops!
TextButton(
  onPressed: () async {
    // 1. Synchronously pre-capture references before any async gap or pop!
    final galleryProv = Provider.of<GalleryProvider>(context, listen: false);
    final yoloProv = Provider.of<YoloFaceProvider>(context, listen: false);
    final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 2. Perform the async file picking operation
    final result = await MediaHelper.pickImage(source: ImageSource.camera);
    
    if (result != null && result.bytes != null) {
      // 3. Safely pop the dialog using the captured navigator reference
      navigator.pop();
      
      final newItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bytes: result.bytes,
        title: result.name,
        type: result.type,
        date: DateTime.now(),
      );

      // 4. Safely invoke pipelines without touching any unmounted contexts
      yoloProv.runYoloDetection(newItem);
      galleryProv.addMediaItem(newItem);
      messenger.showSnackBar(
        const SnackBar(content: Text('Camera snapshot added to Gallery!')),
      );
    }
  },
  child: const Text('Use Camera'),
)
```

---

## 🔍 Case Study 4: Safe Listener Teardown in Widget Tests

### ❌ The Hurdle
Adding a listener to `GalleryProvider` inside `DashboardShell` created a memory leak and threw a test error:
```
A Timer is still pending even after the widget tree was disposed.
```
* **The Cause**: Inside `dispose()`, the state class was calling `context.read<GalleryProvider>().removeListener(_autoSelectModelListener)`. Calling `context.read` inside `dispose` throws a framework crash because the element tree is already torn down. The crash blocked the disposal sequence, preventing the poller timer inside `GalleryProvider` from being canceled!

### ⚡ The Resolution
Synchronously cache a raw reference to the provider inside the widget's initialization state so that you can safely dispose of listeners without relying on unmounted build contexts:

```dart
//  GOOD: Cache provider reference to safely unregister listeners in dispose
class _DashboardShellState extends State<DashboardShell> {
  GalleryProvider? _galleryProv;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _galleryProv = context.read<GalleryProvider>();
      _galleryProv?.addListener(_autoSelectModelListener);
    });
  }

  @override
  void dispose() {
    // Safe unregistration—no BuildContext lookups required!
    _galleryProv?.removeListener(_autoSelectModelListener);
    super.dispose();
  }
}
```

---

## 💡 Key Architectural Takeaways

1. **Stateful Container Rule**: Never instantiate any class with `dispose()` requirements (like `TextEditingController`, `ScrollController`, `AnimationController`, or `FocusNode`) inside a stateless scope. Bind them to `StatefulWidget` blocks.
2. **Never Trust Popped Contexts**: Popping a dialog invalidates its `BuildContext` immediately. Always pre-capture navigators, messengers, and provider references *before* popping or awaiting.
3. **Never Read Context in Dispose**: Never call `context.read<T>()` or `Provider.of<T>(context)` inside a State's `dispose()` lifecycle callback. Store parent provider references inside a state variable on startup.
