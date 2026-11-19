# Changelog

All notable changes to Avalon Companion are recorded here. One entry per completed
development phase, in the order the plan defines them.

## [1.7.2] — Okley (2026-11-20)

### Added

- **A second narrator ships with the app.** Okley's 28 recordings — all 14 night lines in
  English and in Filipino — are bundled under `assets/audio/voices/okley/`, so the table can
  switch narrator from **Settings → Narrator voice** without a rebuild, a download or a zip.
  Dahlia is still the default; the choice is remembered per device.
- Two tests guard the folder: one fails if a bundled voice folder is missing from
  `pubspec.yaml` (Flutter asset folders are not recursive, so an unlisted folder is silent),
  and one fails if Okley's set is incomplete or its name does not read as **Okley**.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 343 tests pass (341 + 2) |
| Voice tests | `voice_packs_test.dart` (19 tests): the folder is listed, every line is present in both languages, and the pack is named Okley |
| Device | `clip_playback_test.dart` passes on the Galaxy A36 (SM-A366B); the release app lists **Dahlia** and **Okley**, each English 14/14 · Filipino 14/14, and choosing Okley sticks after the dialog closes |
| Release APK | Signed **1.7.2+26** built (66.5 MB), zipaligned, verified with the release key and installed over 1.7.1 |

## [1.7.1] — Dahlia's folder (2026-11-20)

### Changed

- **The narrator has a name and a folder.** Her 28 recordings now ship under
  `assets/audio/narration/Dahlia voices/{en,fil}/`, so the narration folder can hold more than
  one voice, and the built-in voice is listed as **Dahlia** in Settings. Extra narrators still
  go under `assets/audio/voices/<pack>/` and are picked in **Settings → Narrator voice**.

### Fixed

- **A space in the narrator folder silenced the narration.** Flutter writes asset names into
  the APK percent-encoded — `Dahlia voices` becomes `Dahlia%20voices` — and the native player
  opened the readable path with `AssetManager.openFd`, which missed it and fell through to the
  phone's text-to-speech. The clip channel now encodes the key first, so every recorded night
  line plays from the bundle again. Found by the device gate, not by the host tests.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 341 tests pass |
| Device | `clip_playback_test.dart` passes on the Galaxy A36 (SM-A366B): a night line decodes from the `Dahlia%20voices` path in the APK |
| Release APK | Signed **1.7.1+25** built (64.0 MB), zipaligned, verified with the release key and installed over 1.7.0 on the Galaxy A36; SHA-256 `d22b36cc…74b6b57` |

## [1.7.0] — Table safety (2026-11-19)

### Added

- **A step can be taken back.** The proposal you just sent, the vote you just resolved and the
  quest you just recorded each offer **Undo** until anything else happens in the match. The
  previous snapshot is restored, the row the step wrote is deleted with its log line, and the
  previous screen stays exactly as it was — a misheard seat is corrected instead of recounted
  from the top.
- **A win can be rewound.** Undoing the quest that ended the match reopens it: the result, the
  finished timestamp and the winner all go back to the state before that quest. The offer is
  single-step: resolving a newer vote or quest replaces it, and any other action withdraws it.
- **The dashboard says what to do next.** One short line under the score names the next table
  action for the current phase — start the narration, draw the King, choose the team, count the
  vote, count the cards, or settle the accusation — so a first-time MC never has to guess.

### Changed

- The quest confirmation now says the result **can be undone from the result dialog**, instead
  of saying it cannot be edited.
- The old footer hint card is gone; the same guidance now sits at the top of the dashboard body,
  where it scrolls with the rest of the page at 200% text instead of fighting the fixed bar.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 341 tests pass (328 + 13) |
| Undo state | `persistence_test.dart` (+6): a proposal, a vote and a quest each restore the previous snapshot; a stale token is refused; any other action clears the offer; a quest that ended the match reopens it; the accusation is never undoable |
| Undo storage | `game_repository_test.dart` (+3): the newest vote or quest and its event are deleted in one transaction, a proposal-only undo leaves the log intact, and a finished match becomes the match in progress again |
| Undo UI | `voting_test.dart` (+1) and `quest_resolution_test.dart` (+1): the dialog's Undo returns to the live count with the same tally or cards, and the step can be recorded again; `team_selection_test.dart` (+1): the proposal snackbar undoes the team and the dashboard offers Continue Team Selection |
| Phase hint | `team_selection_test.dart` (+1): the hint names the narration in Preparation and the quest team in Day |
| Device pass | **Passed on a Galaxy A36 (SM-A366B) over wireless debugging.** The three integration tests ran in two clean invocations — `app_test.dart` (2) and `clip_playback_test.dart` (1): the settings switch writes to the installed database, a match starts on the real store, no table has a role column, and a recorded night line decodes in English and Filipino |
| Release APK | Signed **1.7.0+24** built (64.0 MB), zipaligned, verified with the release key, installed on the phone and opened; SHA-256 `66f84332…d1657f06` |

## [1.6.0] — The manual (2026-11-19)

### Added

- **How to Play now teaches Avalon, not the app.** The page is a user manual in play order:
  before you begin, set up the table, know the characters, the night, every round, team size,
  rules that catch people out, the final accusation, how to win, using the app, at the table.
  It covers the physical deal, the approve and reject cards, the leader token, and what each
  character knows — in the same order the night is actually run.
- **The numbers are the engine's.** The team-size table is drawn from `AvalonTables` for every
  count from 5 to 10 and every quest, so the manual cannot disagree with the app. The two-fail
  rule on quest 4 at seven or more players, the strict majority, the five-rejection loss, the
  clockwise token and both victory paths are stated the way `GameEngine` implements them.
- **The night section follows the recording.** Close eyes, minions without Oberon, Merlin seeing
  every evil player except Mordred, Percival seeing two possible Merlins, then the first Lord.
  A character who is not in play gets no step, exactly as in narration.
- **The MC's part is marked at each step** — New Game, Preparation, Begin the match, Open Night
  Narration, Choose the Quest Team, Open the Vote, Resolve the Quest, Begin the Accusation, See
  the Result — so one person can hold the phone and still follow the table.
- **"At the table" advice:** eyes closed means eyes closed, never show a card, Merlin must be
  useful without being obvious, Evil can pass a quest to buy trust, and house rules are agreed
  before the deal.

### Changed

- The old page's three short sections became **eleven**, and "What this app does" became the
  opening "Before you begin", which now explains the game first and the phone second.
- The page remains one scrollable list of section cards, centred in the same 600 dp column as
  every other screen; no new route or stored state.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 328 tests pass (325 + 3) |
| Manual coverage | `how_to_play_test.dart` (3): opening copy, setup and the night order, the quest table, the majority/rejection/two-fail rules, the accusation and both victory paths — scrolled end to end at phone size |
| Content accuracy | Team sizes and the two-fail threshold come from `AvalonTables`; vote, token and victory wording matches `GameEngine`; the night matches `NightScript` |
| Device pass | **Passed on a Galaxy A36 (SM-A366B).** The three integration tests ran on the phone: a settings switch round-trips through the installed database, a match starts on the real store with no role column in any table, and a recorded night line decodes in English and Filipino. The manual was also opened on the device and scrolled from **Before you begin** to **At the table**; the quest table rendered with its header |
| Release APK | Signed **1.6.0+23** built (63.9 MB), installed over 1.4.0 on the phone, and published as [**v1.6.0**](https://github.com/Akiprofit/avalon-companion/releases/tag/v1.6.0) with `Avalon-Companion-1.6.0.apk` (SHA-256 `5f87bbee…c5e0f`) |
| Voice import | **Still unverified on hardware:** no voice recordings ship with this build, so the picker and zip unpacking were not exercised on the device |

## [1.5.0] — Narrator voices (2026-11-18)

### Added

- **A voice is a pack, not a file.** The night is fourteen separate lines, so a
  voice answers for each one on its own. A pack that records some of them still
  works: the lines it did not record are spoken by the phone, one line at a time,
  instead of going silent.
- **Import a voice from Settings → Narrator voice.** The system file picker hands
  the app a `.zip`; the recordings inside `en/` and/or `fil/` are unpacked into
  app storage, the MC names it (**Voice of Dahlia**), and it becomes the narrator.
  A zip with the MP3s at its top level is read as English. Nothing is uploaded.
- **Rename, hide, delete.** The shipped narrator and any bundled voice can be
  renamed or hidden from the list; an imported voice can be deleted for real,
  recordings included. Deleting or hiding the voice in use returns the match to
  the shipped recordings rather than to silence.
- **Bundled voices.** A rebuild can ship extra voices by dropping
  `assets/audio/voices/<pack>/en/` (and `fil/`) into the project, listing each
  language folder in `pubspec.yaml`, and optionally naming it in `voice.json`.
  `assets/audio/voices/README.md` documents the layout.

### Changed

- **Settings → Narration** now leads with the voice in use and what it covers
  ("English 14/14 · Filipino not recorded"), then the language and the fallback
  voice controls. A hidden voice stays usable for a match already running and
  comes back from **Hidden voices**.
- **Drift schema v7** adds the `voicePacks` table and `settings.voicePackId`.
  Upgrade keeps every saved match, the history and every setting; bundled voices
  are seeded on first read.
- **`archive` 3.6.1** (pure Dart, already in the pub cache) reads the zip. The
  file picker and the voices directory come from a Kotlin MethodChannel
  (`com.avalon.companion/voices`); `MediaPlayer` now accepts an absolute path as
  well as an APK asset, so an imported recording plays exactly like a bundled one.
- The web build still compiles: `dart:io` is isolated behind a conditional
  export, and the import action is hidden where the filesystem is not available.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 325 tests pass (300 + 25) |
| Voice coverage | `voice_packs_test.dart` (17): asset manifest parsing, readable names and `voice.json`, a pack missing a language, zip folders/flat/junk/not-a-zip, path-climbing ids, unique folder ids, DB round trip, the v6 → v7 upgrade, rename and hide, and install/delete of real files in a temp directory |
| Narration coverage | `narration_controller_test.dart` (+3): the chosen pack's own path is played, a line it did not record falls back to speech, and an unknown pack falls back to the shipped recordings |
| Settings coverage | `voice_picker_test.dart` (+5): the coverage label, switching voices, renaming, deleting the active imported voice, and hiding the bundled one (which offers Hide, never Delete); `settings_store_test.dart` also round-trips the chosen voice |
| Device pass | **Not run.** No phone was attached to this machine, and no voice recordings ship with this build, so the file picker, the unpacking and the absolute-path playback are covered by unit and widget tests only |
| Release APK | **Not built for 1.5.0 yet** |

## [1.4.0] – History selection (2026-11-17)

### Added

- **Long-press a match to select it.** A finished or abandoned match buzzes, dips and lifts with
  a gold border and a springing check. The app bar becomes **“N selected”** with **Select all**
  and **Delete** actions.
- **Multi-select.** Tap cards to add or remove them while selecting, long-press to add another,
  or use **Select all**. The running match is never selectable and is marked with a lock; trying
  to select it explains that it must be finished or abandoned first.
- **Delete only what is selected.** The confirmation names the count, the delete is by exact id,
  and the store refuses an in-progress id even if a stale selection sent one. Cancelling keeps the
  selection so a second look costs nothing.
- **Motion and haptics.** The app bar title and count cross-fade, checks spring in, the card
  pulses under the finger, cards fade and rise in with a small stagger, and deleted cards collapse
  out of the list. A medium haptic fires on selection; the existing Haptics setting still turns it
  off. Every animation honours the system's reduced-motion flag.

### Fixed

- **Settings → About showed version 1.1.0.** `AppInfo.version` was hard-coded and had not followed
  the releases. It now reads 1.4.0.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 300 tests pass (291 + 9) |
| New store coverage | `game_repository_test.dart`: exact ids go, the running match is refused even when passed, and an empty or unknown selection deletes nothing |
| New screen coverage | `history_test.dart`: long-press and tap counts, in-progress refusal, select-all, cancel keeps selection, confirm deletes and reaches the empty state, and system back leaves selection mode |
| Clear history | the existing oldest-N/all dialog and its six tests are unchanged and still pass |
| Device pass | Galaxy A36 (Android 17), installed over 1.3.1: selected the abandoned match, saw the in-progress lock, confirmed the dialog, got **Deleted 1 match.**, the in-progress record stayed, and Settings → About read 1.4.0 |
| Release APK | 63.0 MB (66,048,666 bytes), `versionName` 1.4.0, `versionCode` 21, arm64-v8a + armeabi-v7a + x86_64 |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` — the same key as 1.0.0–1.3.1; APK SHA-256 `B84CF79D…4D5178F0` |
| GitHub release | `v1.4.0` published with `Avalon-Companion-1.4.0.apk`; its digest matches the local build |

## [1.3.1] – Device-pass fixes (2026-11-17)

### Fixed

- **The night title fits.** The night screen's app bar now reads **THE NIGHT**. *NIGHT NARRATION*
  was truncated to "NIGHT NARRAT…" on a 360 dp phone once **End night** moved into the bar beside
  it.
- **An unfinished record does not claim the match ended.** Opening an in-progress match from
  history now says "No quest has resolved yet." instead of "No quest was resolved before the
  match ended."

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 291 tests pass (290 + 1) |
| Device pass | Installed over 1.1.0 on a Galaxy A36 (Android 17): the in-place upgrade kept the stored match, and the full loop — night, draw, team, vote by seat, quest — ran on the release build |
| New coverage | `narration_controls_test.dart` asserts the shorter title; `history_test.dart` opens an unfinished record and checks its wording |
| Release APK | 62.9 MB (65,999,270 bytes), `versionName` 1.3.1, `versionCode` 20, arm64-v8a + armeabi-v7a + x86_64 |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` — the same key as 1.0.0–1.3.0; APK SHA-256 `4B64481B…CDE41105` |
| GitHub release | `v1.3.1` published with `Avalon-Companion-1.3.1.apk`; its digest matches the local build |

## [1.3.0] – UI/UX pass (2026-11-17)

### Changed

- **The vote is counted by seat.** The voting screen marks each player approve or reject once
  instead of asking the MC to tap two steppers until they add up. Tapping the same side again
  clears the seat, and tapping the row cycles approve → reject → uncounted, so a misheard vote
  is corrected on the seat it belongs to. *Resolve* stays disabled and reads "Count N more
  votes" until every seat is marked; the rule engine still receives the two totals.
- **The discussion timer is a ring.** A 76 dp ring shows the remaining share of the round, gold
  until the last 10 seconds and danger red after that. The ring starts, pauses and restarts the
  clock, with pause and reset beside it. The clock clicks once at 10 seconds and
  `Feedback.alarm()` double-taps at zero, so the end is audible from across the table.
- **Night controls are separated.** *End night* moved to the app bar as a labelled action behind
  a confirmation, and the narration transport is now previous, replay, play/pause and next.
  The English/Filipino switch moved to the top of the panel instead of sitting under the
  transport, where it crowded the thumb row.
- **One quest board.** The dashboard's five quest markers and the separate "Past quest teams"
  card are now a single **The quests** board: the markers, then the team that went on each
  resolved quest, with the empty card explaining itself in one line. The victory screen uses the
  same board instead of a second section. `QuestLog` became `QuestBoard`
  (`lib/core/widgets/quest_board.dart`).
- **The table is a grid.** The dashboard roster is a two-column grid of seat tiles — number,
  name, leader crown, gold mark for the quest team — instead of a ten-row list. Same two columns
  on a tablet, inside the existing 600 dp column.
- **Home leads with the live match.** While a match is in progress, home opens with a hero card
  showing the table size, quest number, phase and resolved quests, with **Continue Game** as the
  gold action and **New Game** demoted beneath it. The duplicate History and Settings cards are
  gone — the bottom navigation already reaches both — leaving How to Play as the only card.
- **History opens a record.** A stored match is now tappable and opens a sheet with the result,
  the quests and the team that went on each one. It reads only what was stored — the summary
  gained `questTeams` and `rejectionCount` — so the sheet has no player names and no roles.
- **The last table is reusable.** Setup offers **Use the last table** when it has a stored table:
  one tap restores the player count and every name from the most recent match (`lastRoster()`),
  still editable. Names only — there is no role to restore.
- **Empty states explain themselves.** A dashboard with no match and a vote under way for no team
  now show the standard `EmptyState` with a way back, instead of a blank body or two lines of
  text.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 290 tests pass (286 + 4) |
| New coverage | `voting_test.dart` rewritten for seat marking, clearing and correction; a ring test in `team_selection_test.dart`; `narration_controls_test.dart` for the night layout and the End night confirmation; `home_dashboard_test.dart` for the live-match hero, the removed duplicate cards and the two-column seat grid; `history_test.dart` for the detail sheet; `last_table_test.dart` for the restored table |
| Updated coverage | `quest_log_test.dart` now reads the merged board; `history_test.dart` reaches history through the bottom navigation; `match_setup_test.dart` checks the hero copy; `voting_test.dart` covers the no-vote empty state |
| Release APK | `flutter build apk --release` succeeds: 62.9 MB (65,999,270 bytes), `versionName` 1.3.0, `versionCode` 19, arm64-v8a + armeabi-v7a + x86_64 |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` — the same key as 1.0.0–1.2.0; APK SHA-256 `25E1660B…C05761D3` |
| GitHub release | `v1.3.0` published with `Avalon-Companion-1.3.0.apk`; its digest matches the local build |

## [1.2.0] – Tablet layout (2026-11-17)

### Changed

- **One layout for every screen size.** The `AvalonScreen` shell now bounds the body to a
  600 dp column and centres it, so the same layout that fills a phone fills the middle of a
  tablet instead of stretching every card and line of text across the glass. The bottom
  action bars keep the same width as the content — a gold button stays a button, not a band —
  while the navigation bar still runs edge to edge and centres only its three items.
- Nothing else changed: no breakpoints, no second layout, no new screens. A tablet gets the
  phone UI, readable and centred.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 280 tests pass |
| New tablet gate | `test/widget/tablet_layout_test.dart`: 360×780 phone keeps the full-width layout; home, settings, history, setup and how-to-play centre a 600 dp column at 800×1280; a ten-player dashboard at 1280×800 keeps its action column; the night panel fits 1280×800 at 1.3× and 2.0× text; the navigation band stays a bar and its taps still land |
| Release APK | `flutter build apk --release` succeeds: 62.6 MB (65,655,374 bytes), `versionName` 1.2.0, `versionCode` 18, arm64-v8a + armeabi-v7a + x86_64 |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` — the same key as 1.0.0 and 1.1.0; `zipalign -c -p 4` passes; APK SHA-256 `9F0E06CD…D02AA78` |
| GitHub release | `v1.2.0` published with `Avalon-Companion-1.2.0.apk`; its digest matches the local build |

### Known limits

- No physical tablet was available. Tablet support is proven in widget tests at 800×1280 and
  1280×800 logical pixels, not on a bought device.

## [1.1.0] - Recorded narrator and past quest teams

### Added

- **Recorded narrator.** The night is now read by the recordings made for the app — 14 night
  lines in English and 14 in Filipino under `assets/audio/narration/` — instead of relying on
  the phone's voice. `AndroidClipService` plays them over a new
  `com.avalon.companion/clips` channel backed by `MediaPlayer` reading `flutter_assets`, so the
  audio ships inside the APK and is never downloaded. Volume follows Settings; the recordings
  play at the pace they were made, and the speed slider shapes only the fallback voice.
- **Past quest teams.** The dashboard lists every resolved quest with its outcome and the
  players who went on it, and the result screen closes with the same list. Teams are public
  state — what the table saw when it approved them — and are stored with the match so the board
  can be read back after a reload. `GameState.questTeams`, `teamForQuest()` and `questLog`
  expose them; `GameEngine.recordQuest` records them alongside the result.

### Changed

- The speech engine is now the fallback narrator, used only for a line with no recording or a
  clip that cannot play. Settings gains a caption saying so and the voice picker is renamed
  **Fallback voice**; the "no voice installed" notice is hidden while the current line has a
  recording.
- Drift schema v6 adds `games.questTeams` (`1,3;2,4,5`), migrating older rows to an empty value.
  A match finished before this build shows its quest results but cannot show its teams.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 274 tests pass |
| Release APK | `flutter build apk --release` succeeds: 62.6 MB, `versionName` 1.1.0, `versionCode` 17, arm64-v8a + armeabi-v7a + x86_64 |
| Audio inside the APK | 28 MP3s (2.57 MB) present as **stored** entries under `assets/flutter_assets/assets/audio/narration/en/` and the matching `fil/` folder, so `MediaPlayer` can open them with `AssetManager.openFd` |
| Bundle guard | `test/unit/narration_clips_test.dart` now also fails if `pubspec.yaml` stops listing a language folder — the first build shipped only the folder's README, because Flutter asset folders are not recursive |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` — the same certificate as the installed 1.0.0; `zipalign -c -p 4` passes; SHA-256 of the APK `D7A4D72F…ECBBD9EC` |
| Device: upgrade | `adb install -r` over the release-signed 1.0.0 succeeded on a Galaxy A36 (Android 17), keeping the match and settings saved by 1.0.0. The app opened on Home with **Continue Game** and "In progress: 5 players, quest 1 of 5", so the schema v6 migration ran against a real database |
| Device: recorded narrator | `integration_test/clip_playback_test.dart` passed on `RFCY30E0LRT`: the English and Filipino `night.end` clips both decoded and finished from inside the installed APK (played at volume 0, so only decoding is asserted) |
| Device: saved audio | the test also proves `MediaPlayer` can open the MP3s with `AssetManager.openFd`, which is what the stored (uncompressed) entries are for |

### Known limits

- The seven round lines are defined but never played, so they have no recordings; enabling them
  later will need audio to avoid a change of narrator mid-match.
- The device test run installs a debug build and Flutter uninstalls the app when the run ends, so
  the matches the phone held before it are gone: the phone now has a fresh 1.1.0 install, not the
  upgraded one. The upgrade itself kept its data (see the Device: upgrade row); the loss came
  from the test harness, not the app. `android/app/build.gradle.kts` now signs debug builds with
  the release key when `key.properties` exists, so the test can install over the release app
  without an uninstall — it is Flutter's teardown after the run that removes the package.
- The upgrade test could only be run once, because the test uninstalled the app afterwards.

## [1.0.0] – Phase 12 Android release

The first release build: the same app Phase 11 verified, packaged, signed and installed on a
phone. No game rule changed.

### Added

- A signed release APK, built with `flutter build apk --release` against the NDK that
  `android/app/build.gradle.kts` pins, so AGP strips Flutter's engine with `llvm-strip` and the
  APK ships at **60.0 MB** instead of the ~500 MB the unstripped build produced. The build is
  signed by the keystore named in the gitignored `android/key.properties`, verified with
  `apksigner verify` (signer `CN=Avalon Companion`) and `zipalign -c -p 4`, and carries version
  `1.0.0` (`versionCode` 16), `minSdk` 24, `targetSdk` 36 and the arm64, arm and x86_64 ABIs.
- `tool/make_icons.ps1` and the README's build and install guide, so the next build — launcher
  icon, splash, signature and install — can be reproduced from a clean checkout.

### Changed

- `pubspec.yaml` version `1.0.0+16`; the app's About footer reads **Phase 12**.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 257 tests pass |
| `flutter test integration_test` | 2 tests pass on the Galaxy A36 `RFCY30E0LRT` |
| Release build | 60.0 MB APK, `versionName` 1.0.0, `versionCode` 16, arm64-v8a + armeabi-v7a + x86_64 |
| Signature | `apksigner verify` reports one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` |
| Alignment | `zipalign -c -p 4` passes |
| Install | `adb install` succeeds on a clean phone; the app launches to Home with **v1.0.0** in the splash |
| Launcher icon | shown by One UI at its own mask: navy plate, gold shield, no white edge and no crop |
| Device: 10 players | the setup screen reads "10 players — 6 good, 4 evil" with ten seats |

## [0.12.1] — Phase 11 QA

No game rule changed in this release: it is the QA pass over the finished product, adding the
coverage that was still missing, the device evidence to go with it, and a way to clear the match
history.

### Added

- **Clear history** on the History screen. The `delete_sweep` action in the section header opens
  a dialog that takes a number of matches, or **All N**. Deletion starts at the bottom of the list
  — the oldest match — and never touches a match still in progress, because that is the match
  **Continue Game** offers. The count, the button label ("Delete the oldest 2", "Delete all 3
  matches") and the confirmation say exactly what goes, and the action is disabled rather than
  hidden when there is nothing to delete. `MatchStore.deleteHistory(count:)` deletes the
  finished and abandoned rows in one transaction ordered by `updatedAt`, so the votes, quests,
  events and seats of each deleted match go with it.
- `DangerButton`, the single red-fill control in the design system, used by
  `ConfirmationDialog` and the clear dialog.
- `integration_test/app_test.dart`, the first on-device test. It boots the real app against the
  installed SQLite file, flips **Team approval vote** and reads the stored row back, then creates
  a match and inspects the live schema. Run it with `flutter test integration_test -d DEVICE_ID`
  while a phone is connected; it leaves the database as it found it.
- `integration_test` development dependency.

### Changed

- The schema privacy gate covers the whole database, not just the players table. It walks
  `games`, `players`, `quests`, `team_proposals`, `game_events` and `settings` and fails on any
  column that could tie a character or an allegiance to a seat. Words are matched per underscore
  token, so `games.assassination_outcome` — the public record of whether Merlin was named — stays
  valid. The on-device test repeats the same scan against the database the app is writing to.
- `pubspec.yaml` version `0.12.1+15`.

## [0.12.0] — Optional team approval vote

### Added

- **Team approval vote** (Settings → Game). The base game's approve/reject vote can be switched
  off for a house rule. With it off, confirming a team sends the table straight to quest
  resolution: no tally is recorded, the rejection counter stays at zero, and five rejections can
  never end a match. Team size, seat checks and the quest 4 two-fail rule are unchanged, and the
  leadership token still passes to the next player — or to the wheel — once the quest is
  resolved, so one player does not lead every round.
- The progress strip reads **VOTE Off** instead of a rejection counter while the vote is off,
  the team selection screen says the team goes straight to the quest, and How to Play mentions
  the house rule.

### Changed

- `GameEngine.proposeTeam` takes `skipVote:` and opens `Phase.questResolution` directly;
  `GameEngine.recordQuest` hands the leadership token on when the quest was resolved without a
  vote, while the wheel keeps the serving King so its draw can still leave them out.
- Drift schema version 5 adds `Settings.team_vote_enabled`, default on, with an explicit
  `addColumn` migration from v4. The switch is read when a team is confirmed, so an interrupted
  match carries on normally.
- `GameProgressHeader` takes `showRejections:` so no in-game screen advertises a rule the table
  has turned off.
- `pubspec.yaml` version `0.12.0+14`.

### Icon

- New launcher icon from `assets/branding/new_app_icon.png`. The source is a mockup with the
  artwork on a white plate, so every density was rebuilt from the art alone: the legacy and round
  icons are clipped by their own mask, and the adaptive foreground sits on the app's navy
  `#04101D` plate with transparent corners, so no white edge shows under any launcher shape.

### Fixed

- **Play Again** now lands on the round table with the fresh match already waiting. It used to
  bounce through the setup preparation screen, whose "Begin the match" button starts a match from
  the setup draft — and that draft had just been cleared, so the button stayed disabled and the
  new match could not be started at all. The roster, the composition and every setting, including
  the approval-vote switch, still carry over, and the finished match keeps its result.

### Verified

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 247 tests pass (8 engine/controller and 4 widget tests new; the simulation suite now plays every player count with the vote both on and off) |
| Engine rules | `test/unit/team_vote_setting_test.dart`: off goes straight to the quest with no tally, on still votes, size and seat checks unchanged, the token passes on, the wheel still excludes the serving King, a whole match without a vote counts no rejection, quest 4 still needs two fail cards |
| Settings storage | `test/unit/settings_store_test.dart`: the switch round-trips through `Settings`, defaults to on, and drift schema v5 migrates from v4 |
| Screen flow | `test/widget/team_vote_setting_test.dart`: the switch and its live caption, off → quest resolution with no voting screen, on → the vote, a questless-of-vote round returning to the day with the token moved |
| Simulation | `test/unit/game_simulation_test.dart`: 40 seeded matches per player count across both King modes and both vote modes, exactly one victory path fires, no rejection is ever counted without a vote |

## [0.11.0] — Advanced game settings: King every round, narrator extra delay

### Added

- **King selection mode** (Settings → Game). *Automatic* spins the wheel at the start of every
  round and sends the table straight to it after a resolved vote or quest, so a new King leads
  each quest; *Manual* (the default) leaves the wheel closed until the MC opens it, and the
  leadership token keeps its own order. Either way the wheel leaves out the King who has just
  served, so nobody leads twice in a row while somebody else can lead. The opening draw of a
  match still takes the whole table. A "Draw a new King" action appears on the dashboard in
  manual mode.
- **Narrator extra delay** (Settings → Narration). 0, 1, 2, 3, 5, 7 or 10 seconds, or a custom
  0–20 seconds. The extra silence starts only after the line has finished speaking (the TTS
  completion callback, or the length estimate when the phone has no voice), is added to the
  script's own beat, and is cancelled by pause, skip, replay or leaving the screen. Settings
  shows the effect in plain words: "Each narration slide will wait an additional 3 seconds
  before continuing."
- The "Automatic narration" switch now starts the night reading on its own, which is what makes
  the extra delay apply without the MC pressing play.

### Fixed

- The wheel no longer claims "every seat takes part in the draw" once the serving King is
  standing down; the caption follows the same rule as the draw itself.

### Changed

- `GameEngine.resolveTeamVote` and `recordQuest` take `drawLord:`; with it the match returns to
  `Phase.lordSelection` instead of `dayDiscussion`, and the token stays with the serving King
  until the wheel lands so the draw knows whom to leave out. `GameEngine.beginLordDraw` and
  `GameEngine.drawableLordSeats` are the two new pure rules.
- Drift schema version 4 adds `Settings.king_selection` and `Settings.narrator_extra_delay_ms`,
  with an explicit `addColumn` migration from v3.
- The narration controller holds its inter-line wait in a cancellable timer instead of an
  awaited `Future.delayed`, so a stopped or restarted night can never advance twice.

## [0.10.0] — Phase 10: polish and accessibility

### Added

- **The optional MC PIN.** Settings → Security sets a four-to-eight digit PIN. It is stored as
  a salted, 20 000-round SHA-256 digest (`rounds$salt$digest`) in the one `Settings` row — never
  the digits, never in `AppSettings`. When a PIN is set, Settings opens locked and Abort asks
  for it before discarding a round; unlocking lasts the app session, so the MC types it once.
  The match itself stays playable without it, and a damaged hash locks instead of opening.
- **Platform feedback** (`lib/core/services/feedback.dart`): a short vibration on confirmed
  dialog actions and on the phase change, plus an optional system tone. Haptics and sound are
  separate switches, and `SilentFeedback` covers both being off.
- **The wheel lands with a confirmation.** The Lord draw clicks when it stops, so a tap the MC
  did not watch still registers.
- **A real night ambience bed.** `res/raw/ambient_night.wav` is a generated 20-second seamless
  low drone, looped by the activity at 0.35 volume only while narration is on screen and the
  app is in the foreground. The existing "Ambient audio" switch now controls something.
- **Keep screen awake** is a window flag applied by the activity whenever a match is live and
  the preference is on, and released when the match ends or the app leaves.
- **Voice picker.** The speech engine now lists its installed, offline voices for the chosen
  language, and Settings → Narration lets the MC pick one (or Automatic). The choice is stored
  in `Settings.voiceId` and used for every line. A phone that exposes no voice list keeps the
  previous "best installed voice" behaviour.
- Loading states on the history list and the narration screen, with a plain label instead of a
  bare spinner.

### Changed

- `MainActivity` gained a second channel, `com.avalon.companion/host`, for the screen-awake
  flag and the ambience loop. It is a no-op everywhere else, so tests stay hermetic.
- Drift schema version 3 adds `Settings.sound_effects` and `Settings.mc_pin_hash`, with an
  explicit `addColumn` migration from v2. Existing matches and preferences survive the update.
- `crypto` is now a direct dependency for the PIN digest.

### Fixed

- The dashboard and narration app bars no longer carry a duplicate status chip, so both titles
  fit at 360 dp.
- The bottom navigation and the splash screen grow or scroll instead of overflowing at a 200%
  text scale.
- Counter steppers and the dashboard's Pause/Abort row are 48 dp high, the documented minimum.

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
