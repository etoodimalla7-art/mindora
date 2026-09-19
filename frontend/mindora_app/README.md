# MINDORA — Flutter App

## Run

```bash
flutter pub get
flutter run              # Android device/emulator
flutter run -d windows    # Windows desktop (after `flutter config --enable-windows-desktop`)
```

## What's here (Phase 1)
- `core/theme/` — design tokens (color, typography, spacing, radius,
  elevation, motion) + light/dark ThemeData. Rebrand by editing
  `brand_config.dart` only.
- `core/routing/app_router.dart` — go_router StatefulShellRoute for the
  5-tab navigation (Home / AI / Planner / Learn / Profile), responsive:
  bottom nav on mobile, nav rail on wide/desktop layouts.
- `presentation/features/*` — placeholder screens with real design
  language and empty states (not blank screens), one per tab.

See `../../docs/` for architecture, API map, DB schema and roadmap.
