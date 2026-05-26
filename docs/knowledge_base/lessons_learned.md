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
