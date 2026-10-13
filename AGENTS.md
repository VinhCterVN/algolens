# Repository Guidelines

## Project Structure & Module Organization

AlgoLens is a Flutter application for exploring algorithms. The current implementation is the starter counter app.

- `lib/main.dart` contains the entry point, app theme, and home screen. Place new Dart code under `lib/`, separating widgets and algorithm logic as features grow.
- `test/widget_test.dart` contains the counter interaction smoke test. Keep additional tests under `test/`.
- `assets/icons/` contains the AlgoLens SVG. Register new asset directories in `pubspec.yaml`.
- `android/` contains the Android host and Gradle configuration; it is the only platform directory currently present.
- `analysis_options.yaml` enables `flutter_lints`. Dependency and SDK constraints live in `pubspec.yaml`.

## Build, Test, and Development Commands

Use a Flutter SDK compatible with the Dart constraint `^3.12.2`. Run commands from the repository root:

- `flutter pub get` — install dependencies.
- `flutter devices` — list available devices and emulators.
- `flutter run -d <device-id>` — launch locally with hot reload.
- `dart format lib test` — format Dart source and tests.
- `flutter analyze` — check static errors and configured lints.
- `flutter test` — run the full test suite.
- `flutter build apk --debug` — build an Android APK for local verification.

## Coding Style & Naming Conventions

Use two-space indentation and let `dart format` control layout. Follow the configured Flutter lints; prefer `const` constructors where possible. Name files `snake_case.dart`, classes `UpperCamelCase`, and members `lowerCamelCase`. Use a leading underscore for private declarations. Keep algorithm logic independent of widgets so it can be unit tested.

## Testing Guidelines

Use `flutter_test` for unit and widget tests. Name files `<subject>_test.dart` and describe the behavior in test names. Add tests for algorithm edge cases and changed user interactions. Run `flutter test` and `flutter analyze` before submitting. No numerical coverage threshold is configured; `flutter test --coverage` generates coverage data when needed.

## Commit & Pull Request Guidelines

Git history is unavailable in this checkout, so existing commit conventions cannot be verified. Use concise, imperative messages, such as `Add binary search visualization`. Keep each change focused. Pull requests should explain the behavior changed, link relevant issues, list validation commands and results, and include screenshots for visible UI changes.
