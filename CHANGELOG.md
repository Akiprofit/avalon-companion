# Changelog

All notable changes to Avalon Companion are recorded here. One entry per completed
development phase, in the order the plan defines them.

## [0.9.0] — Phase 9: saved matches, recovery and history

### Added

- **The first Lord is drawn, not assumed.** After the night, a screen spins a wheel over the
  seats and lands on one. The draw is random on the device and the MC never chooses: the UI
  supplies the seat, the engine validates it, and later leaders still rotate from that seat in
  the usual order. Night narration ends on the wheel; the result is announced to the table and
  written to the match log as a seat, never a name.
- **Play Again** on the victory screen: a confirmation, then a brand-new match for the same
  roster and composition. Quests, votes, rejections, the drawn Lord and the accusation are all
  dropped because a new `GameState` is built from scratch; the finished match keeps its result
  and is never rewritten as abandoned.
- `lib/database/` — SQLite through Drift, implementing the master plan's PART 8 tables
  (`Games`, `Players`, `Quests`, `TeamProposals`, `GameEvents`, `Settings`) at schema version
  2. There is no character, role or allegiance column on a player: the schema has nowhere to
  put one.
- `MatchStore` (`lib/database/match_store.dart`) is the interface the session controller talks
  to; `GameRepository` implements it with transactions, so a finished match is written with its
  events in one go. Settings map through `SettingsRepository` (encode/decode are pure and
  tested without a database).
- Auto-save: every confirmed action writes the snapshot, and votes and quests also append their
  own row and a log line. Writes are chained, so a fast sequence of taps cannot land out of
  order, and a failed write is swallowed — a match at the table must never stop because a disk
  was busy. Starting a match while one is still running marks the old one abandoned instead of
  deleting it.
- Session recovery: `bootstrap()` opens the database, reads the saved preferences and looks for
  a running match before the first frame. **Continue Game** then restores the phase, quest,
  leader, proposal and roster where the table left off.
- **History** is a real list now: date, seat count, the five quest slots, how the match ended,
  the quest tally and the duration, newest first, with plain empty and error states. Abandoned
  matches stay in the list. No player name and no character ever appears.
- Settings persist across restarts, including language, narration rate and depth, volume,
  discussion length and default table size.

### Changed

- `AppSettings` moved to `lib/core/models/app_settings.dart` so the storage layer can map it
  without importing a screen-facing controller. `settings_controller.dart` re-exports it.
- Storage providers default to `null` and `bootstrap()` overrides them, so the app still plays
  a full match with no database at all (and the existing widget tests need no SQLite).
- The database schema is versioned at 2 with an explicit migration that adds the saved current
  proposal; settings are written update-then-insert because the table has no primary key.
- `sqlite3` is a dev dependency, so the schema tests run against real in-memory SQLite on the
  host instead of a mock.
- `pubspec.yaml` version `0.9.0+11`; `AppInfo.version` `0.9.0`, phase `Phase 9`.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 171 tests pass (30 new: 10 schema, 12 persistence, 4 settings, 4 history) |
| Schema tests | real in-memory SQLite: create, update-in-place, saved proposal, vote and quest rows, finished match not offered as Continue, abandonment, cascade delete, newest-first, settings upsert |
| Persistence tests | one row per match, snapshot order, vote and quest rows with counts, Play Again as a second row, restore with its row id, a match with no store, a match with every write failing |
| Privacy tests | `PRAGMA table_info('players')` has no character/role/allegiance column; the match log and the history list are searched for player names |
| `flutter build apk --debug` | built successfully (0.9.0+11) |
| Device: full match | 5 players from setup through the Lord wheel to GOOD VICTORY, writing every step to SQLite on the phone |
| Device: force-stop and relaunch | Continue Game restores the interrupted match at its phase — checked at PREPARATION, mid-vote (team kept, tally back at zero) and at QUEST 2 / 5 |
| Device: History | running match and finished match listed newest first, with quest dots, outcome and duration; no player name |
| Device: Play Again | confirmation, then a new match for the same five players; the finished row kept its Good victory instead of becoming abandoned |
| Device: settings | Filipino, force-stop, relaunch: the language survived |
| Device: abandon | Abort on a running match marked that row abandoned in SQLite (phase `preparation`) and left the finished row's `good` / `threeQuests` fields alone |
| Device: app update | reinstalling the new APK over the old one kept the saved match and the settings |

## [0.8.1] — App icon

### Changed

- The launcher icon is now the supplied Avalon artwork instead of the Flutter
  default. Generated for mdpi–xxxhdpi as adaptive, legacy and round variants,
  with the cream frame removed (Android masks the tile itself) and the art set
  on the palette navy `#04101D`.
- Icon resources are named `avalon_launcher*` rather than `ic_launcher*`, and
  `AndroidManifest.xml` sets both `android:icon` and `android:roundIcon`.
- `pubspec.yaml` version `0.8.1+10`.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 132 tests pass |
| `flutter build apk --debug` | built successfully (0.8.1+10) |
| APK contents | `aapt2` resolves the icon to `res/mipmap-anydpi-v26/avalon_launcher.xml`; packaged PNGs match the generated art |
| Device: App info | Avalon artwork, after a fresh install of 0.8.1+10 |
| Device: launcher | Avalon artwork in Suggested apps |
| Device: Recents | Avalon artwork in the task card and its header |

Note: One UI kept the old Flutter icon for `com.avalon.companion` through a
reboot, an in-place reinstall, a version bump and a resource rename, even though
the installed APK was byte-identical to the new build. Installing the same build
under a second package id showed the new icon, which proved the APK was correct
and the stale bitmap was cached per package name. A final uninstall and clean
install of `0.8.1+10` cleared it.

## [0.8.0] — Phase 8: The endgame

### Added

- Assassination screen (`/game/assassination`): after three successful quests it announces
  that Good has won the quests, sets out the three physical steps of the accusation, and
  offers exactly two outcomes — **Merlin was named** and **Merlin survived**. The app never
  asks for, stores or displays the name; `GameState.merlinIdentified` records only which
  answer the MC gave.
- One confirmation per accusation ("Record a successful assassination?" / "Record Merlin's
  escape?"), so a mis-tap cannot end a match.
- Victory screen (`/game/results`) with two treatments: gold and a shield for Good, crimson
  and a gavel for Evil. Each states the reason the match ended, the five quest slots, and a
  final summary of players, quests won and lost, rejections in the last round and match
  length. The summary counts quests and names no player.
- **New Match** resets the table and opens setup; **Return Home** leaves the finished match in
  place so the home screen offers **Review the Last Match** with the result in one line.
- Dashboard: **Begin the Accusation** at the assassination phase, **See the Result** once the
  match is over, and pause/abort hidden on a finished match.
- `GameSessionController.resolveAssassination` and `GameEngine.resolveAssassination` are the
  only way to record the accusation and are ignored outside that phase.
- 6 widget tests (`test/widget/endgame_test.dart`): all three victory paths, the two
  confirmation dialogs, replacing a finished match, and reviewing it from home.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 132 tests pass (6 endgame tests) |
| `flutter build apk --debug` | built successfully |
| Device: Evil victory | three failed quests → "Evil wins the match… Good 0 — Evil 3" → EVIL VICTORY screen, 3 lost quests, New Match / Return Home |
| Device: assassination | screen reached with the correct announcement and both outcome buttons |
| Device: Good victory | "Merlin survived" → confirm → GOOD VICTORY with summary and New Match / Return Home |
| Device: review | Return Home keeps the match; home offers Review the Last Match with the result in one line |

## [0.7.0] — Phase 7: Quest resolution

### Added

- Quest resolution screen (`/game/quest`): the approved team, independent success and fail
  card tallies, the number of cards still to count, and a live statement of whether the
  counted cards pass the quest.
- The engine decides the outcome: one fail card fails a quest, except quest 4 at seven or
  more players, where two are needed. The screen states which rule applies before the MC
  commits, and only the fail count is sent on, so success can never disagree with the total.
- **Require MC confirmation before saving**: resolving opens a summary of the counted cards
  and the result it will record; **Keep counting** returns to the tallies untouched.
- After saving, the outcome states the new score ("Good 1 — Evil 0") and where the match
  goes next: back to discussion, to the assassination after three successes, or to an
  immediate Evil victory after three failures.
- `GameSessionController.recordQuest` is the only way the UI can save a quest; it ignores
  calls outside `QuestResolution`, so a double tap cannot record twice.
- Dashboard action **Resolve the Quest** while the table is at quest resolution.
- 5 widget tests: card-total validation, miscount correction, cancelling the confirmation, a
  successful quest and a failed quest.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 126 tests pass (5 new) |
| `flutter build apk --debug` | built successfully |

The device pass for this phase is still outstanding: the test phone was disconnected while
the build was being installed.

## [0.6.1] — The Royal Chronicler narration voice

### Added

- Narration has a defined voice profile: British English (`en-GB`), a deeper-than-natural
  pitch and deliberate pauses between scripted lines.
- `NarrationState.pitch`, `NarrationController.setPitch` and **Voice depth** in Settings
  (0.70–1.20, default 0.92), carried through the TTS channel to `TextToSpeech.setPitch`.
- `pauseAfter` is now honoured during autoplay, so the panel waits out the beat before the
  next instruction instead of speaking back-to-back.
- Android voice selection: the same country is preferred, then quality, and only voices
  installed on the device are used; a missing regional voice falls back to any voice in the
  same language, so narration never goes silent over an accent.
- 3 controller tests for the profile, the setting and the pause.

### Fixed

- The vote-resolution dialog no longer shows a live screen behind it: the screen is frozen
  while the outcome is on screen, so a re-render cannot alter the table underneath.

### Artwork

- Seven public-domain plates are bundled in `assets/images/` (1080×1920 JPEG, quality 68,
  1.95 MB total) and the asset folder is declared in `pubspec.yaml`.
- Home, Setup, Preparation, Dashboard, Narration, Team Selection, Voting, History, Settings,
  How to Play and Splash each carry a plate behind the legibility veil; the gradient remains
  the fallback when a plate is missing.
- `CinematicBackground` drift is now one slow 24 s settle instead of an endless loop, so the
  screen holds still for the rest of a match and `pumpAndSettle` works in tests.
- `test/unit/artwork_test.dart`: every plate is bundled, a portrait JPEG, the set stays under
  2 MB, and every screen maps to a plate in the set.
- `DESIGN_SYSTEM.md` §7 lists each work, artist and Commons file page.

### Verified on device (Galaxy A36)

- Google TTS reports `currentLocale = en-GB` and speaks with `en-gb-x-gba-local`, an on-device
  British voice.
- Phase 5 and 6 walkthrough: day timer, team selection, 3/2 vote, "The team is approved",
  QUEST RESOLUTION on the dashboard with the leader token rotated.

## [0.6.0] — Phase 6: Physical voting system

### Added

- Voting screen (`/game/voting`): the proposed team, independent approve and reject tallies,
  the number of votes still to count, and a live indication of whether the current tally
  approves or rejects the team.
- Resolve is only available once every player has been counted; the engine records the vote
  once, for the whole table, and rejects partial totals.
- The outcome is stated explicitly after resolution, including the next leader's name, and
  the fifth rejection ends the match for Evil.
- `CounterStepper`: a large labelled tally with 48 dp −/+ controls, reusable for quest cards.
- 4 widget tests covering validation, miscount correction, an approved vote and a rejected
  vote.

### Changed

- `GameSessionController.recordVotes` now takes both totals, matching the engine contract.
- Dashboard phase-aware action: **Open the Vote** while the table is voting.

### Design system (foundation)

- Palette replaced with the cinematic dark-Arthurian tokens; master plan §3.2 amended. Added
  light gold, secondary text, neutral, gold overlay and artwork-veil tokens. No raw colour
  remains outside `app_colors.dart`.
- `DESIGN_SYSTEM.md` documents tokens, type, spacing, motion, the brief-to-project component
  mapping, the artwork plan and the verification checklist.
- `CinematicBackground`: optional artwork plate, legibility veil, slow drift; every
  `AvalonScreen` uses it, with the gradient as fallback.
- Reduced motion: new `app_motion.dart` and `CinematicPageTransitionsBuilder`; drift, splash
  scale and page transitions stop when the system asks for reduced motion.
- `SettingsTile` replaces the settings screen's private rows; Home and Splash get the new
  hero treatment.

## [0.5.0] — Phase 5: Day phase and team selection

### Added

- `DiscussionTimerController` and `discussionTimerProvider`: start, pause, reset and expiry
  using the discussion length from Settings.
- Phase-aware dashboard: the primary action becomes **Choose the Quest Team** at Day, the
  discussion card appears with the timer, and the proposed team is highlighted on the roster.
- Team selection screen (`/game/team-selection`): seats only, exact quest size enforced by the
  engine, and the proposal survives leaving the screen.
- 4 widget tests for the day phase, the timer, exact-size selection and recovery.

## [0.4.0] — Phase 4: Night narration engine (audio)

### Added

- On-device speech: `MainActivity.kt` exposes Android `TextToSpeech` over a MethodChannel,
  with completion, stop and error callbacks. The app speaks, and nothing else: no text is
  logged, stored or transmitted.
- `AndroidTtsService` and a `ttsServiceProvider`, so the narration controller can be tested
  with a fake engine and screens never touch a platform channel.
- Line-at-a-time narration: playing speaks the current line and advances when the voice
  finishes; pause stops mid-line; replay always speaks; next and previous stay silent unless
  playing; rate and volume come from Settings.
- Graceful voice handling: a language with no installed voice is reported under the panel,
  autoplay stops, and the text stays on screen. Switching language never silently falls
  back.
- Interruption handling: leaving the app pauses narration.
- 13 controller tests covering playback, advancing, cancelling a cut-off line, pause, replay,
  rate/volume, missing voices, silent devices and skip-to-end.

### Changed

- `TtsService` is now async and reports availability instead of throwing; `SilentTtsService`
  remains for tests and for phones with no engine.
- The narration panel's notice now comes from controller state, so a missing voice is
  explained exactly where it matters.

### Fixed

- Android build: `android/gradle/gradle-daemon-jvm.properties` was overriding the pinned
  Gradle JVM and selecting a JRE without `jlink`; the generated file is kept aside as
  `.bak` so `org.gradle.java.home` wins.

## [0.3.0] — Phase 3: Game setup and session management

### Added

- Widget tests that prove the MC can create a valid match at every supported table size
  (5–10), reach the dashboard, leave it, and continue the same session from Home.
- Widget tests for aborting a match and for backing out of preparation without creating one.
- Device verification on a Galaxy A36 (Android 17, 1080×2340) covering setup, preparation,
  dashboard and narration.

### Fixed

- The dashboard body was 0 px tall on a real device: the bottom action bar was a `Column`
  that expanded to the full screen height. It now wraps its content.
- The progress header overflowed by up to 20 px on a 360 dp wide screen; the phase badge
  flexes and ellipsises, and `StatusIndicator` truncates its label.

## [0.2.0] — Phase 2: Game engine

### Added

- `GameEngine`, a pure-Dart rule engine with an explicit state machine: `create`,
  night start/end, team selection, team proposal, vote recording, vote resolution, quest
  resolution, assassination, pause and resume.
- `GameState`, an immutable snapshot of a match: seats, composition, phase, leader seat,
  quest number, rejection count, resolved quests, current team, vote totals, pause origin,
  `merlinIdentified` and timestamps.
- `GameRuleException` with MC-readable sentences. Illegal commands throw instead of
  corrupting state: skipping phases, incomplete teams, vote totals that miss a player, more
  fail cards than team members, resolving a quest twice, and playing on after victory.
- Leader rotation after every resolved proposal, wrapping at the last seat; approved teams
  clear the rejection counter; five consecutive rejections win for evil.
- Quest 4 uses two fail cards at 7+ players and one below that; three successes lead to
  the assassination, three failures end the match.
- `GameSessionController` reduced to a thin notifier over `GameState?`, so screens can no
  longer set a phase by hand.
- 48 new tests: 43 engine cases (including every player count) and 5 privacy guards that
  scan the source for a player→character map, role assignment APIs or an assassination
  target.

### Changed

- `Player` no longer carries any match state beyond a seat and a name.
- Dashboard pauses through `togglePause`; narration starts and ends the night through the
  engine, so reopening the screen cannot rewind or double-advance the phase.

### Fixed

- Android build: keep debug symbols so AGP does not need `llvm-strip` from a full NDK,
  and pin the Gradle JVM to Android Studio's JDK so `jlink` is available.

## [0.1.0] — Phase 1: Project foundation and UI/UX

### Added

- Flutter project scaffold (`avalon_companion`) with Riverpod and GoRouter.
- Design token layer: `AppColors`, `AppText`, `Space`, `Radii`, `Motion` — the palette and
  type scale from the master plan, with Cinzel and Inter bundled as variable fonts.
- Dark-only theme with tokenised input, switch, slider, dialog, card and snackbar styling.
- Component library: `PrimaryButton`, `SecondaryButton`, `AvalonIconButton`,
  `MedievalCard`, `SectionHeader`, `QuestTracker`, `PlayerTile`, `StatusIndicator`,
  `GoldDivider`, `ConfirmationDialog`, `AvalonBottomNavigation`, `NarrationPanel`,
  `GameProgressHeader`, `EmptyState`, `ErrorState`, `LoadingState`.
- Screens: Splash, Home, Game Setup, Preparation, Dashboard, Night Narrator,
  Game History (empty state), How to Play, Settings.
- Client-side setup validation: good/evil counts against the player-count table, unique
  characters, duplicate names, and composition warnings.
- Night narration script data in English and Filipino, filtered by composition, with a
  panel that previews ordering and pacing.
- Rule tables for composition, quest sizes, quest 4 fail threshold and vote majority,
  in `game_engine/rules/avalon_tables.dart`.
- Unit tests for the tables, composition validation and narration sequence; widget tests
  for navigation, small-screen layout and the dashboard guard.

### Notes

- No player-to-character data exists anywhere in this build, by design.
- Narration audio, the state machine, persistence, team selection, voting, quest
  resolution, assassination and victory screens arrive in later phases.
- The MC PIN is shown as unavailable rather than stubbed.
