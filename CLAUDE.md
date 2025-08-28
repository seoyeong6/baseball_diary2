# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Flutter-based baseball diary application that allows users to track their baseball activities. The app uses Material Design 3 with a black color scheme seed and supports both light and dark themes with system theme detection.

## Common Development Commands

### Running the Application
```bash
flutter run
```

### Development Tools
```bash
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
```bash
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

## Architecture

### Main Application Structure
- **Entry Point**: `lib/main.dart` contains the `BaseballDiaryApp` root widget with Material3 theming
- **Navigation**: `lib/main_navigation_screen.dart` implements a 5-tab bottom navigation using stateful navigation with `Offstage` widgets to preserve screen state
- **Theme System**: `lib/widgets/themes.dart` provides centralized theme management with black color seed

### Navigation Architecture
The app uses a bottom navigation bar with 5 main sections:
1. **Home** - Main dashboard (`lib/home_screen/home_screen.dart`)
2. **Diary** - Baseball diary entries (placeholder)
3. **Record** - Recording baseball activities (placeholder)
4. **Graphs** - Data visualization (placeholder) 
5. **Settings** - App settings (placeholder)

The navigation uses `Offstage` widgets to maintain state across tab switches, ensuring screens don't rebuild when switching tabs.

### Widget Components
- **NavTab**: Custom bottom navigation tab widget (`lib/widgets/nav_tab.dart`) using FontAwesome icons with animated opacity
- **Themes**: Centralized theme management with Material3 design system

### Dependencies
- `cupertino_icons: ^1.0.8` - iOS-style icons
- `font_awesome_flutter: ^10.3.0` - FontAwesome icons for navigation
- `flutter_lints: ^5.0.0` - Dart/Flutter linting rules

### File Organization
```
lib/
├── main.dart                     # App entry point
├── main_navigation_screen.dart   # Main navigation container
├── home_screen/                  # Home screen module
│   └── home_screen.dart
└── widgets/                      # Shared UI components
    ├── nav_tab.dart             # Bottom navigation tab widget
    └── themes.dart              # Theme configuration
```

## Testing
The project includes widget tests in `test/widget_test.dart`. Note that the current test is a template and needs to be updated to match the actual app functionality.

## Linting and Analysis
Uses `package:flutter_lints/flutter.yaml` for code quality. Run `flutter analyze` to check for issues.

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
