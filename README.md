# algolens

See the Logic Behind Every Algorithm

## Code Organization

The Dart code uses a feature-based layout:

```text
lib/
  core/
    theme/app_theme.dart            # Shared light/dark themes
    config/supabase_config.dart      # Supabase configuration loaded from .env
    routing/app_router.dart         # GoRouter and session redirects
    utils/                          # Shared helpers
  data/
    services/                       # Shared API/database access
    repositories/                   # Shared caching and data mapping
  features/authentication/
    data/                           # Supabase service, repository, session storage
    presentation/
      views/                        # Sign in, registration, and recovery
      view_models/                  # Form and authentication state
      widgets/                      # Shared auth UI and Figma SVG icons
  features/home/presentation/
    views/home_view.dart            # Simple branded home screen
    view_models/                    # Feature UI state and logic
    widgets/                        # Reusable feature widgets
  main.dart                         # Bootstrap and app composition
test/
  features/home/presentation/views/home_view_test.dart
```

Place new features under `lib/features/<feature_name>/`. Put screens in
`presentation/views/`, UI state and logic in `presentation/view_models/`, and
reusable feature widgets in `presentation/widgets/`. The stateless home screen
does not need a view model yet. Add feature-specific `data/` services and
repositories and optional `domain/` entities or use cases when needed.

Keep application-wide themes, routing, and helpers in `core/`. Use top-level
`data/` for services and repositories shared across features. Services perform
API/database operations; repositories handle caching, mapping, and data errors.
Shared code should not depend on features. Reserved empty folders contain
`.gitkeep` files. Mirror source folders under `test/` and use `*_test.dart` names.

See [COMMIT_GUIDE.md](COMMIT_GUIDE.md) for commit and pull request conventions.

## Database

See [Supabase Auth Setup](docs/SUPABASE_AUTH_SETUP.md) to configure the dashboard,
connect the Flutter app, and sign in with email/password or OAuth.

The Supabase schema, optional taxonomy seed, permissions, and setup instructions
are documented in [supabase/README.md](supabase/README.md).

## Android App Branding

The Android display name is `AlgoLens`. The launcher icon is derived from
`assets/icons/algolens.svg`, with a navy background and an adaptive foreground.
The renderer adds 15% padding on every side; Android adaptive icons also use
the inset configured in `flutter_launcher_icons.yaml`.
The generated PNG sources and Android launcher resources live in the repository.

After editing the SVG, regenerate the icons from the project root (Node.js and
npm are required only for SVG rendering):

```sh
npm install --prefix .dart_tool/icon_renderer --no-save --package-lock=false @resvg/resvg-js@2.6.2
node tool/render_app_icon.cjs
dart run flutter_launcher_icons
```

`flutter_launcher_icons.yaml` configures Android icon generation. Rebuild and
reinstall the app to see launcher icon or display name changes.

## Flutter Resources

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
