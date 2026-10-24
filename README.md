# Botanical Ink — Personal Todo & Life Organizer

> A calm, tactile, editorial personal productivity companion combining daily tasks, calendar agendas, local reminders, notebook reflections, and activity rhythms. Built with **Flutter**, **Dart**, **Riverpod**, and **SQLite**.

---

## 1. Visual Identity & Design System

Botanical Ink embraces a calm, tactile aesthetic inspired by pressed-botanical stationery, letterpress planners, and unbleached art papers.

### Color Palette

| Token | Hex Value | Role & Usage |
|---|---|---|
| **Warm Paper Background** | `#F3F1E9` | Primary viewport background (light mode) |
| **Botanical Green Primary** | `#35594F` | Primary actions, navigation selection, hero dates |
| **Pressed Green** | `#28483F` | Active pressed state, deep accents, badges |
| **Muted Terracotta Accent** | `#C77D5B` | Due-date flags, urgent priorities, subtle highlights |
| **Charcoal Ink** | `#242B28` | Primary text and sharp outline borders |
| **Secondary Ink** | `#747A72` | Timestamps, subtitles, secondary labels |
| **Ivory Surface** | `#FCFBF7` | Elevated content cards and list items |
| **Pale Sage Surface** | `#E8E8DC` | Chip backgrounds, subtle containers, dividers |
| **Subtle Border** | `#D7D9CE` | Clean 1px structural outlines (replacing heavy drop shadows) |
| **Completed Task Surface** | `#DCE7DA` | Soft, rewarding highlight for accomplished tasks |

*A complementary dark palette (**Forest Charcoal**) is included, utilizing deep slate-forest surfaces (`#171B19`), gentle sage text, and soft terracotta emphasis.*

### Typography & Dimensions

- **Headings & Hero Numerals:** `DM Serif Display` with tabular figure alignments for bold calendar dates (`10 JUN`).
- **Body & Controls:** `DM Sans` (400 regular, 500 medium, 600 semi-bold, 700 bold).
- **Cards & Sheets:** Rounded 24–32px corner radii.
- **Buttons, Inputs & Chips:** Rounded 12–16px corner radii.
- **Spacing Grid:** Multiples of 8px (8, 16, 24, 32).

---

## 2. Core Architectural Highlights

- **100% Offline-First:** No cloud subscriptions, forced logins, or external dependencies needed. All data lives in a local SQLite database with automatic migrations and ACID transactions.
- **Cross-Platform Storage Strategy:** Automatically adapts between native mobile (`sqflite`) and desktop FFI (`sqflite_common_ffi`).
- **Reactive State Management:** Driven by **Riverpod** StateNotifiers, ensuring instant UI updates, optimistic UI toggles, and undo capabilities.
- **Speech-to-Text Reflection Input:** Native microphone speech recognition for daily reflections with seamless text fallback when offline or unavailable.
- **Accurate OS Notifications:** Native system notification scheduling for time-sensitive tasks and reminders with snooze capabilities (15m, 1h).

---

## 3. Screen-by-Screen Overview

### 1. Today Dashboard (`/today`)
- **Hero Header:** Bold date (`10 JUN`), weekday name, personalized greeting (*"Good morning, Aadix"*), and count indicators for pending items.
- **Daily Progress Rhythm:** Minimalist progress bar showing completed vs. total items, percentage, and upcoming alerts without noisy analytics widgets.
- **Structured Task Groups:** Grouped into **Overdue** (terracotta warning badge), **Today**, **Upcoming**, and **Completed** (with undo snackbar).
- **Daily Reflection Box:** Direct input with microphone voice-recording toggle and a button to review past reflections in an editorial card stream.

### 2. Calendar & Agenda (`/calendar`)
- **Views:** Switch effortlessly between **Month**, **Week**, and **Day** views.
- **Calendar Grid:** 7-column layout with accurate leap-year handling, start-of-month weekday offsets, and today indicator.
- **Marker Dots:** Subtle dots indicate scheduled tasks, reminders, and calendar events.
- **Timeline Agenda:** Scrollable hourly timeline showing scheduled appointments, meetings, and all-day blocks with color-coded tags.

### 3. Task Management (`/tasks`)
- Filter by **All**, **Today**, **Upcoming**, **Overdue**, and **Completed**.
- Priority sorting: **Urgent**, **High**, **Medium**, **Low**.
- Search by task title or description.
- Subtask checklist with interactive completion toggles.
- Categorization (Work, Personal, Wellness, Garden, Study).

### 4. Reminders & Alerts (`/reminders`)
- Grouped into **Today**, **Upcoming**, and **Completed/Dismissed**.
- Quick **Snooze** actions (+15 minutes, +1 hour).
- Integration with native Android / Windows local notifications.

### 5. Notes & Daily Journal (`/notes`)
- **Pinned Notes:** Keep key references at the top of your notebook.
- **Search & Tag Filters:** Filter by `#botanical`, `#ideas`, `#journal`, etc.
- **Distraction-Free Editor:** Minimalist sheet with real-time word counter and autosave.
- **Daily Journal Stream:** Date-stamped reflections capturing mood, prompts, and insights.

### 6. Activity & Rhythms (`/activity`)
- Restrained 7-day completion rhythm bar chart.
- Task completion rate and active reminder tracking.
- Recent edits and notebook audit log.

### 7. Settings & Personalization (`/settings`)
- Profile name customization (defaults to `Aadix`).
- Theme selector: **Botanical Ink** (Light), **Forest Charcoal** (Dark), or System.
- Accent hue customizer (Terracotta, Botanical Green, Sage, Olive, Amber).
- Calendar week start toggle (Monday vs. Sunday).
- Time format toggle (12-hour AM/PM vs. 24-hour military).
- Notification preferences and microphone permission status.
- **Local JSON Data Backup & Export:** Export your complete organizer data in one tap.
- **Reset Demo Data:** Easily reseed sample planner data for testing.

---

## 4. Project Structure

```
botanical_planner/
├── lib/
│   ├── main.dart                          # Application entry point with ProviderScope
│   ├── core/
│   │   ├── database/
│   │   │   └── database_service.dart      # SQLite service (CRUD, migrations, sample data)
│   │   ├── services/
│   │   │   ├── notification_service.dart  # Native OS notification management
│   │   │   └── speech_service.dart        # Voice-to-text recognition with fallback
│   │   └── theme/
│   │       ├── app_theme.dart             # Light & Dark ThemeData configurations
│   │       ├── colors.dart                # Botanical Ink color palette tokens
│   │       └── typography.dart            # DM Serif Display & DM Sans typography
│   ├── models/
│   │   ├── event.dart                     # CalendarEvent domain model
│   │   ├── journal_entry.dart             # JournalEntry reflection model
│   │   ├── note.dart                      # Note notebook model
│   │   ├── reminder.dart                  # Reminder alert model
│   │   ├── task.dart                      # Task & Subtask models
│   │   └── user_settings.dart             # UserPreferences model
│   ├── providers/
│   │   └── providers.dart                 # Riverpod state notifiers & computed selectors
│   ├── views/
│   │   ├── activity/activity_view.dart    # 7-day completion rhythm & statistics
│   │   ├── calendar/calendar_view.dart    # Month/Week/Day calendar & agenda
│   │   ├── notes/notes_view.dart          # Notes & Daily Journal notebook
│   │   ├── reminders/reminders_view.dart  # Reminders with snooze controls
│   │   ├── search/search_view.dart        # Unified global cross-entity search
│   │   ├── settings/settings_view.dart    # Profile, theme, export, & preferences
│   │   ├── tasks/tasks_view.dart          # Full task manager with filters & priorities
│   │   └── today/today_view.dart          # Hero Today dashboard & daily thought
│   └── widgets/
│       ├── app_scaffold.dart              # Adaptive navigation (Bottom bar vs Sidebar)
│       ├── botanical_icons.dart           # Consistent outline icon suite
│       ├── circular_checkbox.dart         # Custom tactile animated checkbox
│       ├── event_editor_sheet.dart        # Modal editor for calendar events
│       ├── note_editor_sheet.dart         # Distraction-free note editor
│       ├── quick_add_sheet.dart           # Floating quick-create bottom sheet
│       ├── reminder_editor_sheet.dart     # Reminder scheduler sheet
│       └── task_editor_sheet.dart         # Full task & subtask editor sheet
├── test/
│   └── botanical_planner_test.dart        # Comprehensive unit & model test suite
├── android/                               # Native Android application configuration
│   ├── app/
│   │   ├── build.gradle.kts               # Android app build specification
│   │   └── src/main/
│   │       ├── AndroidManifest.xml        # Permissions (Audio, Notifications, Alarm)
│   │       ├── kotlin/com/botanical/planner/MainActivity.kt
│   │       └── res/                       # App icons & Botanical Paper splash screen
│   ├── build.gradle.kts                   # Root gradle build configuration
│   └── settings.gradle.kts                # Plugin and dependency repositories
├── windows/                               # Native Windows desktop application
│   ├── CMakeLists.txt                     # Desktop CMake build specification
│   └── runner/                            # Desktop C++ runner & window configuration
└── pubspec.yaml                           # Flutter dependencies & assets
```

---

## 5. Building & Running the Application

### Prerequisites

- Flutter SDK (v3.29.0 or higher) with Dart (v3.7.0 or higher)
- Android SDK (API 34/35) and Java JDK 17/21 (for Android builds)
- Visual Studio 2022 with Desktop C++ workload (for Windows desktop builds)

### 1. Android Mobile Application

To build and run on an Android device or emulator:

```bash
# Fetch dependencies
flutter pub get

# Run on connected Android device/emulator
flutter run -d android

# Build a release APK
flutter build apk --release

# The compiled APK is located at:
# build/app/outputs/flutter-apk/app-release.apk
```

### 2. Windows Desktop Application

The application dynamically detects Windows desktop and adapts its UI into a spacious sidebar layout with master-detail navigation:

```bash
# Run on Windows desktop
flutter run -d windows

# Build packaged Windows release executable
flutter build windows --release
```

---

## 6. Offline Data & Sample Profile

The application includes realistic pre-seeded data for user **Aadix**:
- Tasks: Herbarium documentation, greenhouse misting, weekly planning.
- Calendar Events: Botanical Society reading, garden plot inspection, studio planning.
- Notes: Pressed flora techniques, seasonal planting schedules.
- Reflections: Calming daily thought entries.

You can modify or reset this data at any time under **Settings > Reset to Demo Data**.
