# CLAUDE.md

Guidance for working in this repository.

## Project

`lazy_games` ("Mind games") — a Flutter app bundling 9 mind/board games with a neon
glassmorphic UI. Targets Android, iOS, and web. Each game supports some combination
of single-player, LAN multiplayer (WebSocket), and online multiplayer (Supabase Realtime).

Games: Tic Tac Toe, Sudoku, 2048, Memory Match, Connect Four, Minesweeper, Word Search,
Sliding Puzzle, Checkers.

## Commands

```bash
flutter pub get          # install dependencies
flutter run              # run on attached device/emulator
flutter run -d chrome    # run on web
flutter analyze          # static analysis / lints (flutter_lints + analysis_options.yaml)
flutter test             # run tests (only test/widget_test.dart exists)
flutter build apk        # Android release build
flutter build web        # web build
```

Dart SDK `^3.11.1`. There is no separate lint/format CI config — `flutter analyze` is the gate.

## Architecture

State management is **Provider** (`ChangeNotifier`). All providers and the two network
managers are registered in a single `MultiProvider` in `lib/main.dart`. Routes are
declared there too as a flat string→widget map; games are pushed by route name.

Directory layout under `lib/`:
- `games/<game>.dart` — the game **screen** (UI, `StatefulWidget`). Wraps content in `GameShell`.
- `providers/<game>_provider.dart` — game **logic + state** (`ChangeNotifier`). Pure game rules; no UI.
- `screens/` — `splash_screen`, `home_screen` (game grid + mode selection), `online_lobby_screen`.
- `services/` — singletons for cross-cutting concerns (see below).
- `widgets/` — shared UI: `game_shell` (the per-game scaffold), glass components, overlays.
- `theme/app_theme.dart` — all colors, gradients, typography (Plus Jakarta Sans via google_fonts).
- `utils/` — generators (sudoku, word search) and `responsive_layout`.

Each game follows the **screen + provider** pair pattern. New games: add a provider, a
screen, register both in `main.dart` (provider list + route), and add a `GameInfo` entry
in `home_screen.dart`'s `_games` list.

### Three multiplayer modes

The same game logic drives all three modes; the screen wires up the transport:
1. **Local** — single device, `isMyTurn` always true.
2. **LAN** — `NetworkManager` (`services/network_manager.dart`): WebSocket, host runs a
   server (mobile only — web cannot host), client connects via `ws://ip:port/ws`.
   Platform server impl is selected by conditional import in `network_helper.dart`
   (`network_helper_io.dart` / `network_helper_web.dart` / `network_helper_stub.dart`).
3. **Online** — `SupabaseRoomManager` (`services/supabase_room_manager.dart`): Supabase
   Realtime over a `game_rooms` table. Host `createRoom` generates a 6-char code; guest
   `joinRoom` flips status to `playing`; moves broadcast via `sendGameState` (row update).

Both `NetworkManager` and `SupabaseRoomManager` expose an `addMessageListener` /
`removeMessageListener` API and dispatch packets shaped `{type, sender, data}`. Game
screens subscribe and translate packets into provider calls (e.g. `handleNetworkMove`,
`applyOnlineState`). `GameShell` itself listens for the shared `reload_request` /
`reload_approve` / `reload_decline` restart-handshake and `room_abandoned` events.

### Online gating (Supabase)

- `SupabaseService` — central Supabase client wrapper; `initialize()` runs once in
  `main()` and does anonymous sign-in. URL + anon key are hardcoded constants.
- `AppConfigService` — remote kill-switch read from the `app_config` table
  (`key = online_multiplayer`). Toggle online play off without a release by setting
  `value = {"enabled": false}` in the Supabase dashboard. Cached 30 min.
- `EntitlementService` — 1-hour online-play entitlement in `multiplayer_entitlements`
  table, granted after watching a rewarded ad.
- `AdMobService` — Google Mobile Ads rewarded ads (mobile only, no-op on web). Currently
  uses Google **test** ad unit IDs; the AdMob App ID lives in `AndroidManifest.xml`.
  Real ad unit IDs must replace the test IDs before release.

Online lobby flow (`online_lobby_screen.dart`): kill-switch → entitlement → ad gate →
create/join room. Web is hard-blocked from online play.

### Other services

- `AudioService` — singleton, `init()` in `main()`. Win/fail are mp3 assets; all other
  sounds are synthesized procedurally as WAV byte buffers. Also wraps haptics. Audio
  errors are swallowed silently so they never crash a game.

## Conventions

- UI is glassmorphic: build with `GlassContainer` / `GlassButton` and `LiquidGlassBackground`,
  not raw `Container`/`ElevatedButton`. Pull all colors and text styles from `AppTheme`
  (`neonCyan`, `neonViolet`, `neonPink`, etc.; `headlineMd`, `bodyMd`, …). Don't hardcode
  hex colors or font sizes in widgets.
- Border radii follow a scale: 16 (cards), 24 (controls/dialogs).
- Providers hold game state and rules and call `notifyListeners()`; screens stay presentational.
- Keep web compatibility: guard mobile-only code with `kIsWeb` (see AdMob, LAN hosting).
- `flutter_lints` is active — match existing style (single quotes, `const` where possible).

## Notes

- The `supabase/` directory is empty (no committed migrations); schema lives in the
  remote Supabase project. Tables referenced in code: `game_rooms`, `app_config`,
  `multiplayer_entitlements`.
- Supabase URL/anon key and AdMob IDs are committed in source (anon key is a public
  client key by design; the ad IDs are test placeholders).
