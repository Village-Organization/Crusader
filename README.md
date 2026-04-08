# Crusader

A sleek, modern email client that finally feels good to use. Built with Flutter, inspired by the design philosophy of Superhuman and Linear -- glassmorphism, neon accents, zero bloat, and keyboard-first navigation.

## Features

**Email**
- Gmail and Outlook via OAuth2 (PKCE on desktop)
- IMAP fetch and SMTP send with XOAUTH2 authentication
- Threaded conversation view with collapsible messages
- HTML email rendering
- Attachments -- view, download, and open
- Unified inbox across multiple accounts
- Snooze emails until a chosen date/time

**Compose**
- Rich text editor (flutter_quill)
- To / Cc / Bcc chip fields
- File attachments
- Undo Send with configurable delay (0-30 seconds)
- Reply, Reply All, and Forward with prefill
- Per-account email signatures

**Search**
- Full-text search across cached emails (local SQLite)
- Debounced live results
- Filter chips: All, Unread, Attachments, Flagged, From Me
- Recent search history

**Keyboard Shortcuts (Vim/Superhuman-style)**

| Key | Action |
|-----|--------|
| `C` / `Ctrl+N` | Compose |
| `/` / `Ctrl+K` | Search |
| `J` / `K` | Navigate threads |
| `Enter` | Open thread |
| `R` | Reply |
| `F` | Forward |
| `E` | Archive |
| `#` | Delete |
| `S` | Star/Flag |
| `Ctrl+Enter` | Send |
| `Ctrl+B` | Toggle sidebar |
| `G then I` | Go to Inbox |
| `G then S` | Go to Settings |
| `?` | Show shortcuts |

**Design**
- Dark mode first with light mode toggle
- Glassmorphism 2.0 -- backdrop blur, translucent panels, neon glow borders
- 12 accent color options
- 18 Google Fonts choices
- Responsive layout -- sidebar + master-detail on desktop, bottom nav on mobile

**Offline-First**
- Local SQLite cache via Drift
- Instant reads from cache, background IMAP sync
- Gravatar avatars with memory + disk caching

## Architecture

Clean architecture with four layers:

```
lib/
  core/           Constants, DI (Riverpod providers, go_router), Theme system
  domain/         Pure entities -- no Flutter/data dependencies
  data/           Repositories, datasources (IMAP, SMTP, OAuth, Drift DB, avatars)
  features/       Feature-scoped Riverpod state (auth, inbox, compose, search)
  presentation/   Screens, layouts, widgets
  utils/          Platform utilities
```

- **State management:** Riverpod with StateNotifier
- **Navigation:** go_router with ShellRoute
- **Database:** Drift (SQLite)
- **Secure storage:** flutter_secure_storage for tokens

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.9.2)
- For Windows: Visual Studio with C++ desktop development workload
- For iOS: Xcode

### Setup

```bash
# Clone the repo
git clone https://github.com/Village-Organization/Crusader.git
cd Crusader

# Install dependencies
flutter pub get

# Generate Drift database code (if needed)
dart run build_runner build

# Run the app
flutter run
```

### OAuth Configuration

To connect email accounts, you need OAuth2 client credentials:

**Gmail:**
1. Create a project in the [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the Gmail API
3. Create OAuth 2.0 credentials (Desktop or iOS application type)
4. Add your client ID to `lib/data/datasources/oauth_service.dart`

**Outlook:**
1. Register an app in the [Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps)
2. Add `Mail.ReadWrite`, `Mail.Send`, `offline_access` permissions
3. Add your client ID to `lib/data/datasources/oauth_service.dart`

## Platforms

| Platform | Status |
|----------|--------|
| Windows  | Primary target |
| iOS      | Supported |
| macOS    | Code paths exist, no runner yet |
| Linux    | Code paths exist, no runner yet |

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

Tests are organized by layer:
- `test/domain/entities/` -- Entity unit tests
- `test/features/` -- Provider tests (auth, compose, search)
- `test/presentation/widgets/` -- Widget tests

## Tech Stack

| Category | Library |
|----------|---------|
| State | flutter_riverpod |
| Navigation | go_router |
| Email | enough_mail |
| Database | drift + sqlite3_flutter_libs |
| Auth | google_sign_in, flutter_appauth |
| Editor | flutter_quill |
| HTML | flutter_widget_from_html |
| Animations | flutter_animate |
| Fonts | google_fonts |

## License

All rights reserved.
