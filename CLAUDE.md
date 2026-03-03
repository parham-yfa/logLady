# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Get dependencies
flutter pub get

# Run the app (choose a connected device/emulator)
flutter run

# Analyze for lint/type errors
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build for release
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
```

## Architecture

This is a single-file Flutter app. **All application code lives in `lib/main.dart`** (~786 lines). There are no separate files, screens, models, or services — everything is co-located.

### Data Layer
- **Backend**: Supabase (URL and anon key are hardcoded at the top of `main()`).
- **Table**: `activity_logs` with columns: `id`, `activity_date` (ISO 8601 string), `type` (string), `duration` (int, minutes).
- Data is fetched via a real-time `stream` directly in the `build()` method of `_DashboardScreenState`, so the UI auto-updates on any DB change.

### Key Classes
- `LogLadyApp` — root `MaterialApp`, sets up the theme (Inter font, light mode, `Color(0xFF2D3436)` seed).
- `DashboardScreen` / `_DashboardScreenState` — the only screen. Contains all state, metric calculations, and UI builders.
- `BarChartPainter` — a `CustomPainter` that draws the animated weekly activity bar chart.

### Localization
The app supports English and Turkish via a simple inline dictionary. The `t(String key)` method on `_DashboardScreenState` looks up the current language (`_isTurkish` bool). All UI strings must go through `t()`. There is no external localization package.

### Streak / Metric Logic
`_calculateSmartMetrics()` computes all dashboard metrics. Critically, it adds **legacy offsets** to the raw DB counts:
- `legacyStreakDays = 5000` — added to the current consecutive-day streak.
- `legacyStackCount = 50` — added to the count of multi-activity days.

Weekly and monthly streaks are derived by dividing the daily streak value (including the legacy offset).

### Activity Tags
Default tags are stored in `_activityTags` (a `List<String>` in state). Users can add/delete tags at runtime, but these changes are **not persisted** — they reset on app restart. Historical tags from Supabase are merged in the bottom sheet UI.

### Shield / Rest logic
When a "Rest" type activity is logged, a tip message is shown. The `_getActivityColor` / `_getActivityIcon` helpers use `String.contains()` matching (case-insensitive) to map activity names to colors and icons.
