# Knowledge Base: Riverpod & Provider Package Coexistence

## The Hurdle: Namespace Collisions
During the migration from the `provider` state management package to the modern `flutter_riverpod` package, both libraries are imported simultaneously. This creates ambiguity and compiler errors because both libraries export identically named core classes:
*   `Provider`
*   `Consumer`
*   `ChangeNotifierProvider`

For instance, trying to read a legacy provider (`Provider.of<T>(context)`) or wrapping a widget tree in a `ChangeNotifierProvider` results in:
`error - The name 'Provider' is defined in the libraries 'package:provider/src/provider.dart' and 'package:riverpod/src/provider.dart' - ambiguous_import`

---

## The Resolution: Prefix Namespacing
To allow smooth, gradual migration without breaking the compilation of the existing codebase:
1.  **Prefix the Legacy Provider Import**: Always import the `provider` package using the `legacy` prefix:
    ```dart
    import 'package:provider/provider.dart' as legacy;
    ```
2.  **Access Legacy Types Explicitly**: Use the prefixed namespace for all legacy provider operations:
    ```dart
    // Read legacy state
    final settings = legacy.Provider.of<SettingsProvider>(context);

    // Legacy bootstrap in main.dart
    legacy.MultiProvider(
      providers: [
        legacy.ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const App(),
    )
    ```
3.  **Use Native Riverpod Types Unprefixed**: Import `flutter_riverpod` cleanly without a prefix to use its components natively for new feature states:
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';

    class App extends ConsumerWidget {
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        ...
      }
    }
    ```

---

## Lessons Learned
*   **Incremental Migration Support**: Wrapping the app root inside a Riverpod `ProviderScope` does not interfere with nested `MultiProvider` trees, meaning both ecosystems can coexist peacefully.
*   **Widget Testing Contexts**: When testing widgets that contain `ConsumerWidget` or Riverpod consumers, the widget test tree must be wrapped in `ProviderScope`. If the widget also accesses legacy provider state, it must also be wrapped in a nested legacy `MultiProvider`.
*   **Record-Based Selectors for O(1) Performance**: To optimize build performance inside large scrolling collections (e.g., `GalleryCard` in the image grid), we can select record tuples using Dart 3 value equality (e.g., `(faceCount, hasUnidentified)`). This prevents unnecessary card rebuilds when unrelated fields in `YoloFaceState` change, keeping scrolling smooth.
*   **Import Resolution Cleanup**: Once a class is fully migrated, removing legacy `provider.dart` imports is crucial to resolve ambiguous type conflicts (e.g. `Consumer` class conflict) and eliminate unused import warnings.
*   **Auto-Dispose Provider Testing**: Generated Riverpod providers default to `autoDispose`. In unit test environments (`ProviderContainer`), if there are no active UI listeners, these providers are automatically disposed of at the end of the microtask queue (e.g., when an `await` yields to the event loop). To prevent states (like local queue collections or database connections) from being garbage collected mid-test, always initialize an active listener subscription using `final sub = container.listen(provider, (prev, next) {});` and clean it up via `addTearDown(sub.close)`.
