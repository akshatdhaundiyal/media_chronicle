# Feature Folder Structure Guide

Every feature in the Media Chronicle app should follow this Feature-First, Layered Clean Architecture pattern:

```
lib/features/[feature_name]/
├── data/
│   ├── datasources/   # Local/Remote database & network clients
│   └── repositories/  # Repository implementations
├── domain/
│   ├── entities/      # Pure Dart domain models & objects
│   └── repositories/  # Repository interfaces (contracts)
└── presentation/
    ├── providers/     # Riverpod StateNotifier/Notifier providers
    ├── screens/       # Main screen widgets
    └── widgets/       # Feature-specific sub-widgets
```

## Rules:
1. **No Business Logic in UI**: UI Widgets should only handle rendering and user interactions. Use Riverpod providers to manage state and logic.
2. **Absolute Imports**: Do not use relative imports (`../`). Always use absolute package imports (`package:media_chronicle/...`).
3. **Handle Async States Cleanly**: Use `AsyncValue` to handle asynchronous operations. Keep the UI clean by using `.when(data: ..., loading: ..., error: ...)` or similar constructs.
