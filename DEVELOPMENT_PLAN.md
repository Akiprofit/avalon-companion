# Development Plan

Tracks progress against `MASTER_PLAN.md.txt`. Update this file at the end of every phase.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Project foundation and UI/UX | complete |
| 2 | Game engine | complete |
| 3 | Game setup and session management | complete |
| 4 | Night narration engine (audio) | complete |
| 5 | Day phase and team selection | complete |
| 6 | Physical voting system | complete |
| 7 | Quest resolution | complete (device pass pending) |
| 8 | Endgame and victory | complete |
| 9 | Database and auto-save | not started |
| 10 | Polish and accessibility | not started |
| 11 | Complete QA | not started |
| 12 | Android release | not started |

## Phase 1 — complete

Delivered: project structure, token layer, theme, 16 components, router, nine screens,
setup validation, narration script data with EN/FIL preview, rule tables, unit and widget
tests.

Known limitations, all intentional and scheduled:

- Narration has no speech yet; the panel states this and the sequence is fully
  navigable. Android TTS lands in Phase 4.
- Settings live in memory only; persistence lands in Phase 9.
- Game History is a real empty state; nothing is saved until Phase 9.
- Dashboard shows the public state created at setup. Team selection, voting and quest
  resolution controls are not present yet (Phases 5–7), rather than being present and
  inert.
- MC PIN is displayed as unavailable (Phase 10).
- The state machine is a single phase value plus public counters; Phase 2 replaces it with
  the guarded transition function.
- Match duration, abandonment records and event log are not persisted yet.

## Phase 1 architecture decisions

- `lib/game_engine/` is pure Dart: no Flutter imports, so rule tests run without a widget
  binding.
- Composition is `Map<Character, int>` — characters by count, never by player.
- Setup defaults come from `AvalonTables.defaultComposition`, documented as a suggestion
  the MC can edit, not a rule.
- Validation splits hard errors (count mismatch, duplicate unique characters) from
  warnings (Percival without Morgana, Mordred without Merlin, no Assassin) that display
  and block nothing.
- Narration sequence is built by `NightScript.sequenceFor(composition)`, which also picks
  variant lines (Oberon-safe wording, Mordred-aware Merlin line, Percival pair vs single
  thumb) so a line never plays twice and never mentions an absent character.
- Fonts are bundled variable files with explicit `FontVariation` weights, so the app is
  fully offline and the type renders the same on every device.
- `AvalonScreen` is an internal shell helper, not a master-plan component.

## Phase 2 — complete

Delivered: the pure-Dart rules engine and the explicit state machine from Part 5.

- `GameEngine` (static, pure functions) — `create`, `startNight`, `endNight`,
  `beginTeamSelection`, `proposeTeam`, `recordVotes`, `resolveTeamVote`, `recordQuest`,
  `resolveAssassination`, `pause`, `resume`. Every illegal command throws
  `GameRuleException` with an MC-readable sentence; no silent state corruption.
- `GameState` — immutable value object: players, composition, phase, leader seat, quest
  number, rejection count, resolved quests, current team, vote totals, pause origin,
  `merlinIdentified`, timestamps. Lists are unmodifiable.
- Guards from §5.7: no phase skipping, no incomplete team, no vote total that does not
  account for every player, no more fail cards than team members, no double quest
  resolution, no play after victory.
- Leader rotation after every resolved proposal, approved or rejected, wrapping at the
  last seat. Approved teams clear the rejection counter; five consecutive rejections win
  for evil.
- Quest 4 needs two fail cards at 7+ players, one below that. Three successes go to the
  assassination; three failures end the match.
- `GameSessionController` is now a thin Riverpod notifier over `GameState?`: `start`,
  `startNight`, `endNight`, `togglePause`, `abort`. Screens call it; they cannot set a
  phase directly any more.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 90 tests pass (48 new: 43 engine, 5 privacy-source guards) |
| Engine test coverage | create validation, illegal transitions, team size/seat/duplicate, vote totals, approval and rejection, rotation incl. wrap, rejection reset, five rejections, quest 4 both sizes, double resolve, three successes, three failures, assassination both outcomes, pause/resume, no play after victory |
| Privacy | source-level test fails if a player→character map, role assignment API or assassination target ever appears |

Known limitations, all scheduled:

- State lives in memory; persistence, auto-save and recovery are Phase 9.
- Dashboard still shows the public state only. Team selection, voting and quest
  resolution controls land in Phases 5–7, wired to the engine that now exists.
- The narration screen drives night start/end; speech is Phase 4.

## Phase 2 architecture decisions

- Rules are `static` functions over `GameState`, not methods on a mutable object: a
  command either returns a new state or throws, which makes tests read like the rulebook.
- `GameRuleException` messages are shown verbatim to the MC, so they are sentences, never
  codes.
- Vote recording stores only the two totals. The app never learns who voted how, matching
  the physical voting model.
- `questResults` grows by one per resolved quest; `questSlots` is derived from it for the
  UI, so the tracker and the engine cannot disagree.
- Season-4 style variants are out of scope: base game only.

## Phase 3 — complete

Delivered: the MC can build a match through the screens, and the session survives leaving the
dashboard.

- Setup screen: 5–10 seats, name per seat, editable good/evil composition with live
  counters against the rule table, duplicate-name and count validation, and warnings that
  inform without blocking.
- Preparation screen: final summary (seats, good/evil, starting leader, composition, quest
  sizes) plus the explicit "deal the physical cards now" reminder.
- `GameEngine.create` is the only way a match begins; a composition that does not match the
  seat count is refused before the dashboard is reachable.
- Session state lives in `gameSessionProvider`. `Continue Game` resumes the live match from
  Home; the router redirect still keeps `/dashboard` and `/narration` unreachable when no
  match exists. Abort clears the session after a confirmation.
- Four new widget tests cover every table size, the full create-and-continue path, aborting,
  and abandoning preparation without creating a match. Verified on the physical Galaxy A36.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 94 tests pass |
| 5–10 player setups startable | covered by widget test per count |
| Device: setup → preparation → dashboard → narration | screenshots taken on the A36, no overflow, no crash |

Fixed while verifying on device and at 360 dp width:

- Dashboard body had zero height: its bottom bar was a `Column` that expanded to the full
  screen, squeezing the roster out. Now `MainAxisSize.min`.
- `GameProgressHeader`'s top row overflowed by up to 20 px on a 360 dp screen; the phase
  badge is now flexible and ellipsises, and `StatusIndicator` truncates instead of
  overflowing.

## Phase 4 — complete

Delivered: the night sequence is spoken by the phone, in English or Filipino, and the panel
follows the voice.

- `MainActivity.kt` hosts the platform `TextToSpeech` engine behind a MethodChannel
  (`com.avalon.companion/tts`): `init`, `speak`, `stop`, `isLanguageAvailable`, with
  `UtteranceProgressListener` callbacks for done, stopped and error. Nothing is logged,
  stored or sent; synthesis happens on the device.
- `AndroidTtsService` (Dart) wraps the channel, reports availability through
  `isAvailable`/`unavailableReason` instead of throwing, and turns an utterance into a
  single completer.
- `NarrationController` is now async and line-at-a-time: play speaks the current line and
  advances when the voice finishes; pause stops mid-line; replay always speaks; next and
  previous stay silent unless playing; rate and volume from Settings reach the engine;
  language and rate changes restart only the current line, and only while playing.
- A generation counter invalidates late utterance callbacks, so a line that was cut off can
  never advance the panel.
- Missing voice handling: the controller asks whether the chosen language has a voice. If
  not, it says so under the panel, stops autoplay and keeps the text on screen; it never
  silently switches language.
- Audio interruption: leaving the app (call, notification shade, screen lock) pauses
  narration through `WidgetsBindingObserver`.
- A silent fallback keeps the panel usable and paces it by estimate when a phone has no TTS
  engine at all.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 107 tests pass (13 new controller tests with a fake engine) |
| Device: English narration | spoke line 1 and advanced to 2/11 on the Galaxy A36 |
| Device: Filipino narration | spoke in the Filipino voice (`fil-PH`) and advanced 5 → 6 |
| Device: pause / replay / stop | pause holds the line; replay speaks while paused without advancing; stop jumps to the last line |
| Device: end of night | last line returns to the dashboard, phase reads DAY |
| Interruption | leaving the app pauses speech (lifecycle observer) |

## Narration voice — The Royal Chronicler

The narration now has a defined vocal identity rather than whatever the phone happens to
pick: deep, British, restrained, slow-to-moderate, with deliberate beats.

- English narration asks for `en-GB` (`NarrationLanguage.english.localeCode`), so the engine
  chooses a British voice. Filipino is unchanged (`fil-PH`).
- `MainActivity.kt` picks the voice explicitly: same language, same country first, then high
  quality, and only voices installed on the device (`notInstalled` and network-only voices are
  skipped). It falls back to any voice in the same language, so a phone without an en-GB voice
  still narrates rather than going silent.
- `NarrationState.pitch` is a new narrator control, default `0.92` (a touch below natural for a
  mature register), passed through `TtsService.speak` to `TextToSpeech.setPitch`. Settings
  exposes it as **Voice depth** (0.70–1.20).
- `pauseAfter` on each scripted instruction is now honoured between lines during autoplay, so
  the table has time to move the physical cards.
- 3 new controller tests: the profile (locale, depth, rate) reaches the engine, the setting
  reaches the engine, and the panel holds on a line until its pause has elapsed.

Gate evidence:

| Check | Result |
| --- | --- |
| Device: locale | Google TTS log reads `currentLocale = en-GB` |
| Device: voice | `en-gb-x-gba-local`, an on-device British voice (no network) |
| Device: pacing | line 1 at 05:53:10, line 2 at 05:53:16 — pause plus speech, not a jump |
| Device: pause respected | panel holds the current line while the pause runs |

Known limit: Android's TTS API does not expose a voice's gender or timbre, so the chosen voice
is the best installed British voice rather than a guaranteed male one. The **Voice depth**
slider tunes it; a voice picker listing installed en-GB voices is the Phase 10 answer if the
phone's default does not suit the table.

## Phase 5 — complete

Delivered:

- `DiscussionTimerController` with start, pause, reset and expiry driven by the discussion
  length in Settings; `discussionTimerProvider` exposes the remaining time and the label.
- Dashboard is now phase-aware: the primary action becomes **Choose the Quest Team** at Day,
  the discussion card appears with the timer, and the proposed team is highlighted on the
  roster.
- `TeamSelectionScreen` (`/game/team-selection`) lists the table, takes seats only, and can
  only confirm at the exact quest size; the engine refuses anything else.
- The dashboard keeps the proposed team recoverable if the MC backs out.
- 4 widget tests: dashboard after the night, timer run/reset, exact-size team selection,
  leaving team selection keeps the proposal.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 118 tests pass overall |
| Device: dashboard after the night | DAY, discussion timer at 5:00, roster intact on the A36 |
| Device: team selection | seats 1 and 2 of 5 chosen, confirm enabled at the quest size |
| Device: back out | dashboard restores the proposal and the leader keeps the token |

## Phase 6 — complete

Delivered:

- `VotingScreen` (`/game/voting`): proposed team, independent approve/reject tallies, the
  remaining-vote count, a live "this vote approves/rejects" indicator and a resolve action
  that only enables once every player is counted.
- `CounterStepper`, the large −/+ tally used for the vote and, later, for quest cards.
- Tallies live in the screen until resolution because the engine deliberately records a
  vote once, for the whole table; it validates that the totals account for every player.
- Resolution shows the outcome and who receives the leader token next; the fifth rejection
  ends the match for Evil. Leader rotation and rejection counting stay in `GameEngine`.
- 4 widget tests: validation, miscount correction, approved vote → quest resolution,
  rejected vote → back to Day.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 118 tests pass (4 new voting tests, 3 narrator-profile tests) |
| `flutter build apk --debug` | built successfully |
| Device: voting tallies | 0/5 → 3 approve / 2 reject, resolve enabled at 5 counted |
| Device: approved vote | dialog reads "The team is approved"; the screen behind stays frozen and dimmed |
| Device: back to the table | dashboard reads QUEST RESOLUTION, leader token moved to the next seat |

## Phase 7 — complete on automated gates, device pass pending

Delivered:

- `QuestResolutionScreen` (`/game/quest`): the approved team, success and fail card tallies,
  the remaining-card count, a live quest verdict, the rule in force ("One fail card fails the
  quest." or the quest 4 two-fail rule) and the running Good/Evil score.
- The MC confirmation the brief asks for: resolving shows the counted cards and the result
  that will be saved; cancelling keeps the tallies. Only then is the quest recorded.
- `GameSessionController.recordQuest({failCards})` funnels every save through
  `GameEngine.recordQuest`, which derives successes from the team size, applies the special
  rule, advances the quest number and routes to assassination or Evil victory.
- Outcome dialog states the new score and the next step; the screen is frozen behind it, the
  same pattern as the vote, so a re-render cannot change the numbers under the dialog.
- Dashboard action **Resolve the Quest** replaces the narration action at this phase.
- `CounterStepper` reused unchanged for both tallies.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 126 tests pass (5 new quest-resolution tests) |
| `flutter build apk --debug` | built successfully |
| Device: quest screen | not run — the test phone was disconnected during installation |

## Phase 8 — complete on automated gates and device

Delivered:

- `AssassinationScreen` (`/game/assassination`): announces the three successful quests, sets
  out the physical accusation in three steps, and offers two outcomes — **Merlin was named**
  and **Merlin survived**. The app never asks for the name: `GameState.merlinIdentified` holds
  only the answer, so no player can be tied to Merlin.
- One confirmation per outcome, so a stray tap cannot end the match; the screen behind the
  dialog stays frozen, as with the vote and the quest.
- `VictoryScreen` (`/game/results`): separate Good (gold, shield, `Artwork.results`) and Evil
  (crimson accent, gavel, `Artwork.excalibur`) treatments, the reason the match ended, the
  five quest slots and a public summary. **New Match** resets to setup; **Return Home** keeps
  the finished record so home shows **Review the Last Match**.
- `GameSessionController.resolveAssassination` → `GameEngine.resolveAssassination`, phase
  guarded, so the result can be recorded once.
- Dashboard actions follow the phase: **Begin the Accusation**, then **See the Result**;
  pause and abort are hidden on a finished match.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 132 tests pass (6 new endgame tests) |
| `flutter build apk --debug` | built successfully (0.8.0+9) |
| Device: Evil victory | three failed quests → "Evil wins the match… Good 0 — Evil 3" → EVIL VICTORY, 3 quests lost, both buttons |
| Device: assassination | correct announcement, three steps, both outcomes; no text field anywhere |
| Device: Good victory | "Merlin survived" → confirm → GOOD VICTORY, summary scrolls to all five rows |
| Device: review | Return Home keeps the match; home shows Review the Last Match and "Last match ended in a Good victory." |

## Design system refresh — foundation complete, screens in progress

The cinematic dark-Arthurian refresh was audited first and continues alongside the game
phases. Nothing in the game engine changed.

- One palette in `app_colors.dart` (master plan §3.2 amended), including the new light gold,
  secondary text, neutral, veil and overlay tokens; the last raw hex in the theme is gone.
- `DESIGN_SYSTEM.md` records the token table, typography, spacing, motion rules, the brief's
  component-name mapping and the artwork plan.
- `CinematicBackground` (artwork plate + legibility veil + slow drift) now backs every
  `AvalonScreen`; screens opt into a plate with `backgroundImage`, and the gradient remains
  the fallback.
- Reduced motion: `app_motion.dart` reads `MediaQuery.disableAnimations`; drift stops, splash
  scale snaps, spinners are replaced by a static line, and the new route transition collapses
  to no animation.
- `SettingsTile` replaces the private switch/slider rows; `CounterStepper` added; Home and
  Splash carry the new hero treatment.
- Artwork: the seven plates are bundled in `assets/images/` (1080×1920 JPEG, 1.95 MB total),
  all public domain and credited in `DESIGN_SYSTEM.md` §7. Home, Setup, Preparation,
  Dashboard, Narration, Team Selection, Voting, Quest Resolution, History, Settings, How to
  Play and Splash now pass a plate to `backgroundImage`; the token gradient stays as the
  fallback. No third-party or copyrighted art has been introduced.
- Drift is a single 24 s `forward()` rather than a loop, so a screen settles and the phone
  stops repainting while a match runs; `test/unit/artwork_test.dart` keeps the files, the
  asset manifest and the `Artwork` map in agreement.
- App icon: `assets/branding/app_icon.png` is the supplied master and is not bundled. The art
  inside its cream frame is rendered to `avalon_launcher*` resources at mdpi–xxxhdpi, as
  adaptive, legacy and round variants on the palette navy; the set and its generation rules
  are recorded in `DESIGN_SYSTEM.md` §7. One UI showed the old Flutter icon for the debug
  package through a reboot, an in-place reinstall, a version bump and a resource rename; the
  APK was proven correct (byte-identical on device, correct under a second package id) and a
  clean install of `0.8.1+10` displayed the new icon in App info, the launcher and Recents.

## Cross-cutting known issues

- Nothing is persisted yet: a match lives only in memory, so the Android low-memory killer
  can end it mid-play. One run was cut short this way (`exit-info`:
  `reason=3 (LOW_MEMORY)`, `anrInfo=timeoutMillis=14600`), and the table had to start over.
  Phase 9 (Drift and auto-save) is the fix; until then, keep the app in the foreground.
- The debug APK is ~1.4 GB because AGP cannot strip the Flutter engine libraries (no NDK
  toolchain on this machine) and `keepDebugSymbols` keeps everything. Functionally fine; it
  must be resolved before the release build in Phase 12 — either by installing the NDK
  properly or by shipping a split-ABI release without the strip step.
- The dashboard and narration app bars truncate their titles on 360 dp because the trailing
  chips take priority. Scheduled for Phase 10 polish. The new voting app bar is short enough
  to avoid it.
- The bundled plates are public-domain paintings, not commissioned art: they were chosen for
  mood and composition, so a few are only loosely on-subject (the Excalibur plate is
  Waterhouse's *Magic Circle*). Replacing them with commissioned plates only requires new
  files under the same names.
- The narrator voice is the best installed British English voice, not a fixed recording: the
  TTS API exposes no gender or timbre, so the phone decides. **Voice depth** compensates; a
  voice picker is the Phase 10 follow-up.
- Gradle is pinned in two places (`org.gradle.java.home` in `android/gradle.properties` and
  the JDK paths there). The generated `android/gradle/gradle-daemon-jvm.properties` was
  renamed to `.bak`: its toolchain criteria won over `org.gradle.java.home` and made Gradle
  pick a JRE from a VS Code extension that has no `jlink`, which fails the
  `androidJdkImage` transform. Restoring that file will reintroduce the failure.

## Next phase

Phase 9 — database and auto-save: SQLite through Drift with the plan's tables, the current
match written after every confirmed action, match and event history, session recovery on
launch and settings persistence. The acceptance test is that an interrupted match resumes
without losing confirmed progress — the gap behind the low-memory kill noted above.
