# Knowledge Base: Lessons Learned (Technical Audits)

This knowledge base records technical hurdles, architectural decisions, and bug resolutions encountered in the Media Chronicle repository that required significant effort.

---

## 🛠️ Lessons Logged

### Lesson 1: Network Image Interception in Flutter Test Environments
*   **Hurdle**: Flutter widget tests run in a sandbox that blocks internet access by default. Any `NetworkImage` resource loader throws an HTTP 400 error, causing widget test suites to crash.
*   **Resolution**: Implemented custom system-wide `HttpOverrides` inside [widget_test.dart](file:///d:/lab/projects/media_chronicle/test/widget_test.dart):
    *   Intercepts `getUrl` and `openUrl` requests.
    *   Returns a mock response containing raw memory bytes representing a 1x1 transparent GIF (`mockImageBytes`).
*   **Takeaway**: Overriding global IO clients directly inside tests resolves all external asset dependencies cleanly without adding mock dependencies inside the production manifest (`pubspec.yaml`).

### Lesson 2: Resolving Sub-Pixel RenderFlex Layout Overflows
*   **Hurdle**: Layout testing under restricted viewport bounds can fail due to extremely tiny overflows (e.g., `0.750 pixels` on the right) when text length slightly exceeds bounds due to differing system font scale factors.
*   **Resolution**: 
    *   Replaced rigid layouts in [main.dart](file:///d:/lab/projects/media_chronicle/lib/main.dart) by wrapping text containers with `Expanded` widgets.
    *   Adjusted layout padding parameters from rigid values (`EdgeInsets.all(24.0)`) to modular symmetric parameters.
*   **Takeaway**: Never let text widgets expand unconstrained horizontally inside horizontal Flex containers (`Row`) unless wrapped in `Expanded` or `Flexible` widgets, particularly inside narrow parent containers like drawers or sidebars.

### Lesson 3: Resolving Keystroke Cursor Jumps in Inline StatelessWidget Controllers
*   **Hurdle**: Declaring inline `TextEditingController`s inside stateless helper methods or `StatelessWidget` `build` scopes causes the controller instances to be recreated on every parent state rebuild. When the text changes, a state refresh updates the provider, triggers a parent repaint, re-instantiates the controller, and resets the user's cursor selection back to the boundary.
*   **Resolution**: Converted the inline configurator card into a dedicated `StatefulWidget`. By caching controller objects in `initState()` and securely calling `dispose()` at widget termination, we guarantee stable text selection and smooth, cursor-jump-free configurations.
*   **Takeaway**: Never instantiate inline text editing controllers inside a stateless repaint scope. Bind controller lifecycles to state blocks.

### Lesson 4: ScrollController Resource Leakage in Stateless Builder Methods
*   **Hurdle**: A monospace sync terminal required a `ScrollController` to autoscroll logs. Declaring `ScrollController` inside a `StatelessWidget` builder helper causes it to be instantiated repeatedly, triggering severe memory leaks and resetting scroll offsets on repaint passes.
*   **Resolution**: Replaced the stateless card helper with a standalone `StatefulWidget` class, instantiating the log console `ScrollController` inside `initState()` and terminating it via `dispose()`.
*   **Takeaway**: Always manage dynamic list, terminal, and grid scroll controllers inside stateful lifecycles.

### Lesson 5: Compilation Recovery for Nested Class Scoping Bounds
*   **Hurdle**: Accidentally omitting the closing brace `}` of a screen state class block causes any subsequently declared widget classes to be parsed as nested statements. Because Dart does not support class nesting, the compiler recovered by treating card class fields and methods as local variables, throwing a cascade of 68 warnings and syntax errors.
*   **Resolution**: Terminated the parent state class block cleanly, cleaned up orphaned badge helper duplicates, and migrated the card class to the bottom of the file as an independent, standalone `StatelessWidget` class.
*   **Takeaway**: Keep screen state and card layouts clearly separated into contiguous class declarations. Prefer standalone files or bottom-of-the-file class placements.

### Lesson 6: High-Performance List Rebuild isolation via `Selector`
*   **Hurdle**: Listening to a provider globally via `context.watch<T>()` or standard `Consumer<T>` on grid cards triggers O(N) rebuild complexity upon any single list update. In large galleries, this leads to heavy layout churn and scrolling lag.
*   **Resolution**: Integrated a granular `Selector<YoloFaceProvider, List<DetectedFace>>` filtered by `item.id`. By comparing the filtered face list with unmodifiable lists, only the specific card hosting that face is rebuilt.
*   **Takeaway**: Always use precise `Selector` boundaries to isolate card repaint passes inside long scrolling lists.

### Lesson 7: Decoupled Multi-Screen Shared Dialog Orchestration
*   **Hurdle**: Inline form structures (like face labeling bounding boxes) are easily duplicated across different feature views (e.g. Gallery screen and YOLO Face Hub screen), which violates DRY principles and creates double-maintenance overhead.
*   **Resolution**: Extracted the dialog forms into a dedicated, self-contained `FaceLabelingDialog` class. It manages text controllers, autofocusing, and dual-step confirmation parameters cleanly in a single location.
*   **Takeaway**: Move highly-interactive overlay states (dialogs, lightboxes) into dedicated custom widgets to maintain lean orchestrating views.

### Lesson 8: Dynamic Quota Progress Linking
*   **Hurdle**: Storing calculated status metadata (such as formatted progress strings) as static string constants prevents dynamic progress bar widgets from sharing the underlying state metrics.
*   **Resolution**: Migrated storage variables from raw hardcoded strings to standard double attributes inside `SettingsProvider` (GB used and GB total), and calculated final limits dynamically via a getter.
*   **Takeaway**: Always store baseline raw numerical attributes inside provider models and compute formatting details dynamically inside clean getters.
