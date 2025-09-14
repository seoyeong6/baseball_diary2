# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Project Overview

This is a Flutter-based **Baseball Diary** application that allows users
to track their baseball experiences.\
Users can select their favorite KBO team, write diary entries with text,
emotion, and one photo, and visualize their records in a calendar and
charts.

The app follows **Material Design 3** with a black color scheme seed and
supports both light and dark themes with system theme detection.

------------------------------------------------------------------------

## Common Development Commands

### Running the Application

``` bash
flutter run
```

### Development Tools

``` bash
# Install dependencies
flutter pub get

# Analyze code (lint and static analysis)
flutter analyze

# Run tests
flutter test

# Clean build artifacts
flutter clean

# Get outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### Build Commands

``` bash
# Build for Android
flutter build apk
flutter build appbundle

# Build for iOS
flutter build ios

# Build for Web
flutter build web

# Build for Desktop
flutter build macos
flutter build linux
flutter build windows
```

------------------------------------------------------------------------

## Architecture

### Main Application Structure

-   **Entry Point**: `lib/main.dart` contains the `BaseballDiaryApp`
    root widget with Material3 theming
-   **Navigation**: `lib/main_navigation_screen.dart` implements a 5-tab
    bottom navigation using `Offstage` widgets to preserve screen state
-   **Theme System**: `lib/widgets/themes.dart` provides centralized
    theme management with black color seed

### Navigation Architecture

The app uses a bottom navigation bar with 5 main sections (aligned with
PRD): 1. **Calendar** -- Monthly calendar view with stickers
(`lib/calendar_screen/`) 2. **Diary List** -- List of written diary
entries (`lib/diary_list_screen/`) 3. **Diary Editor** -- Write/edit
diary entry with title, content, emotion, and one photo
(`lib/diary_editor_screen/`) 4. **Statistics** -- Data visualization of
emotions and team records (`lib/stats_screen/`) 5. **Settings** -- App
configuration such as team selection and dark mode
(`lib/settings_screen/`)

Navigation state is preserved using `Offstage` so switching tabs does
not rebuild screens.

------------------------------------------------------------------------

## Data Models

Located in `lib/models/`

-   **DiaryEntry**
    -   `id`, `title`, `content`, `emotion`, `imagePath`, `date`,
        `teamId`
-   **Team**
    -   `id`, `name`, `primaryColor`, `secondaryColor`, `logoPath`
-   **Sticker**
    -   `id`, `date`, `iconType` (fixed set of icons: win, star,
        direct-attendance, etc.)

All models implement `toJson/fromJson` for persistence.

------------------------------------------------------------------------

## Dependencies

-   **UI & Icons**
    -   `cupertino_icons: ^1.0.8`
    -   `font_awesome_flutter: ^10.3.0`
-   **State Management**
    -   `flutter_riverpod: ^2.x` (recommended)
-   **Persistence**
    -   `shared_preferences: ^2.x`
    -   `cloud_firestore: ^4.x` (for logged-in users, optional)
-   **Images**
    -   `image_picker: ^1.x`
-   **Charts**
    -   `fl_chart: ^0.68.0`
-   **Linting**
    -   `flutter_lints: ^5.0.0`

------------------------------------------------------------------------

## File Organization

    lib/
    ├── main.dart                     # App entry point
    ├── main_navigation_screen.dart   # Main navigation container
    ├── models/                       # Data models (DiaryEntry, Team, Sticker)
    ├── calendar_screen/              # Calendar + sticker UI
    ├── diary_list_screen/            # Diary list with preview
    ├── diary_editor_screen/          # Diary writing/editing screen
    ├── stats_screen/                 # Statistics visualization
    ├── settings_screen/              # App settings (team, theme, backup)
    └── widgets/                      # Shared UI components
        ├── nav_tab.dart              # Bottom navigation tab widget
        └── themes.dart               # Theme configuration

------------------------------------------------------------------------

## Testing

-   Widget tests in `test/widget_test.dart`
-   Additional tests should be added for:
    -   Diary entry creation, update, and deletion
    -   Sticker attachment on calendar
    -   Statistics rendering (pie chart, line chart)
    -   Team switching logic
    -   Dark mode toggling

------------------------------------------------------------------------

## Linting and Analysis

Uses `package:flutter_lints/flutter.yaml` for code quality. Run:

``` bash
flutter analyze
```

to check for issues.

------------------------------------------------------------------------

## Task Master AI Instructions

**Import Task Master's development workflow commands and guidelines,
treat as if import is in the main CLAUDE.md file.**\
@./.taskmaster/CLAUDE.md
