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
| 7 | Quest resolution | complete |
| 8 | Endgame and victory | complete |
| 9 | Database and auto-save | complete |
| 10 | Polish and accessibility | complete |
| 11 | Complete QA | complete |
| 12 | Android release | complete |

Advanced game settings (King selection mode, narrator extra delay) and the optional team
approval vote shipped after Phase 10 and before the QA pass; see the sections below the Phase 10
entry.

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

## Phase 7 — complete on automated gates and device

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
| Device: quest screen | 3-card quest counted at 3/3, "This quest succeeds", confirm dialog, "Good 2 — Evil 0" |
| Device: quest 3 of 5 | two-card team counted at 2/2, recorded after confirmation, three successes sent the match to the accusation |

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
- The supplied `assets/branding/new_app_icon.png` replaced that art in 0.12.0. It is a 1254 px
  mockup with the art on a white plate, so every density was rebuilt from the art alone: the
  legacy and round icons are re-masked by their own plate, and the adaptive foreground sits on
  the palette navy `#04101D` with transparent corners, so no white rim or mockup edge survives
  the launcher's mask. A release install showed the art in App info, the app drawer and the
  suggested-apps row without a white edge.

## Phase 9 — complete on automated gates and device

Delivered: a match is remembered. The app writes it as it is played, and an interrupted match
comes back where the table left it. The uncommitted work from the previous iteration — the
Lord wheel and Play Again — ships with this phase, and both are covered by the persistence
tests, because a played match now has to end with the right row.

- `lib/database/app_database.dart` — Drift schema at version 2 with the master plan's PART 8
  tables: `Games`, `Players`, `Quests`, `TeamProposals`, `GameEvents` and `Settings`. Foreign
  keys are enabled on open so a deleted match takes its seats, votes, quests and events with it.
  Version 2 added `Games.currentTeam`, so an interrupted proposal restores with its seats; the
  migration is an explicit `addColumn`, not a destructive rebuild.
- There is no character, role or allegiance column anywhere in the schema. The place where a
  role mapping would live does not exist, which is the strongest form of the privacy rule.
- `lib/database/match_store.dart` — `MatchStore`, the interface the session controller uses:
  `createMatch`, `saveState`, `recordProposal`, `recordQuest`, `addEvent`, `markAbandoned`,
  `findInProgress`, `matches`. `GameRepository` implements it with transactions; the
  controller never imports Drift.
- Auto-save is a side effect, never a dependency. State changes first and synchronously, then
  the same snapshot is chained onto a write queue, so two reports cannot interleave and the
  newest state always lands last. A failed write is swallowed and the match continues; the
  worst case is a match that cannot be restored, not a match that stops.
- A vote or a quest appends its own row (seats, counts, verdict, fail cards) plus the snapshot,
  so the history can be rebuilt from rows as well as from the snapshot.
- Play Again creates a new row. The finished match keeps its result: a victory is never
  rewritten as abandoned, which is what the "still running" check keys on.
- `bootstrap()` is async: it opens the database, loads the `Settings` row and looks for a
  running match before `runApp`, so the first frame already has the right language and no
  "Continue Game" flash. Every step is wrapped: if SQLite cannot be opened the app runs fully
  playable and simply remembers nothing.
- Storage providers default to `null` and are overridden in bootstrap, which keeps the widget
  tests hermetic (they pump `ProviderScope` with no database) without a single mock.
- History is a real `FutureProvider` over `MatchStore.matches()`, with empty, loading and error
  states, a quest-slot row per match, the outcome and a duration. Settings persist through the
  same database; `SettingsRepository.encode`/`decode` are pure and tested on their own.
- A restored vote starts its tally at zero on purpose: the app never stores a partial vote, and
  re-counting hands is safer than trusting half a count.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 171 tests pass (30 new) |
| New tests | `test/database/game_repository_test.dart` (10, real in-memory SQLite), `test/unit/persistence_test.dart` (12, controller against a fake store), `test/unit/settings_store_test.dart` (4), `test/widget/history_test.dart` (4) |
| Storage failure | a store where every write throws still plays a match to victory |
| No store at all | the whole match, including Play Again, works with `matchStoreProvider` null |
| Privacy | `PRAGMA table_info('players')` contains no character/role/allegiance/team column; the log and the history list are searched for the five player names |
| Device: full match | 5 players played from setup to GOOD VICTORY through the real SQLite database; History shows the finished row with its three quest dots |
| Device: restore | force-stop and relaunch restored the match at PREPARATION, mid-vote (team kept, tally at zero) and at QUEST 2 / 5 |
| Device: Play Again | confirmation, then a new match for the same five players, the round table at PREPARATION and its night ready to open; the finished row kept its Good victory |
| Device: History | the running match and the finished match listed newest first, "Three quests won · 28:49", no player names |
| Device: settings | Filipino chosen, force-stop, relaunch: still Filipino and still in progress |
| Device: abandon | Abort marked the running row `abandoned` in the pulled SQLite file; the finished row still reads `good` / `threeQuests` |
| Device: app update | `adb install -r` over the running install kept the saved match and settings |

Known limits:

- Votes in progress are not persisted. The team is, the tally is not (see cross-cutting issues).
- The database is one SQLite file in the app's data directory; there is no export or backup
  yet. Phase 10 adds the settings affordances around it, Phase 12 the release checklist.

## Phase 10 — complete on automated gates and device

Delivered: the app is usable in a real physical-game environment. The phone behaves like a
device at a table — it stays awake, ticks, vibrates, and can lay a low ambience under the
narration — and the screens hold up at large text sizes and with Android's reduced-motion
setting on. The MC can lock Settings and Abort behind a PIN. No new plugin was added for any of
it.

- `lib/core/services/host_services.dart` — `HostServices` with `setKeepAwake` and `setAmbient`,
  implemented by `AndroidHostServices` over a second method channel,
  `com.avalon.companion/host`. `NoHostServices` is the default, so widget tests never touch a
  platform channel and a missing host cannot break a match.
- `MainActivity` applies `FLAG_KEEP_SCREEN_ON` while a match is live and the preference is on,
  and releases it when the match ends, the app leaves, or the preference is switched off.
- The night ambience is `res/raw/ambient_night.wav`: a generated 20-second seamless mono drone
  (A2, E3, A3, C#4, E4, A4 partials, 1-second fades at both ends), looped by a `MediaPlayer` at
  0.35 volume. The narration screen starts it when it opens and when the app resumes, and stops
  it on dispose and whenever the app leaves the foreground.
- `lib/core/services/feedback.dart` — `Feedback` with `tap`, `phaseChange` and `warning`.
  `PlatformFeedback` uses `HapticFeedback` plus `SystemSound.play`, gated by two settings;
  `SilentFeedback` is used when haptics are off. `confirmAction(context, ref, ...)` is
  `showConfirmation` plus one confirmed tap, and replaces it on the assassination, leaving the
  dashboard, leaving narration and Play Again. The wheel clicks when it lands.
- `AppSettings` gained `soundEffects` and `narratorVoiceId`; `Settings` gained
  `sound_effects` and `mc_pin_hash` at schema version 3, with an explicit `addColumn`
  migration from v2. The existing `voice_id` and `mc_pin_enabled` columns are now used.
- The MC PIN: `PinRepository` writes `rounds$salt$digest` — 20 000 rounds of salted SHA-256 —
  and only ever answers "is this the same PIN?". `PinController` holds the hash and the
  session's unlocked flag; `requestPin` and `requestNewPin` are the only ways in. With a PIN
  set, Settings renders a lock view instead of its content, and Abort asks for the PIN before
  it asks for the abort confirmation. Unlocking lasts until the app is closed, and a match is
  playable whether or not the PIN is entered.
- The voice picker asks the engine for its voices over the TTS channel (`voices`), lists only
  installed offline voices for the chosen language, and passes an exact `voiceId` back on every
  line. "Automatic" keeps the previous ranking, which stays the fallback when a stored voice
  has been uninstalled.
- Accessibility: the dashboard phase chip exists once (it was duplicated in the app bar, which
  is what truncated the title at 360 dp), the narration app bar carries only its title, the
  bottom navigation grows instead of clipping and the splash screen scrolls at a 200% text
  scale, counter steppers and Pause/Abort are 48 dp, and the wheel, cinematic background and
  page transitions already honoured reduced motion.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 184 tests pass (13 new) |
| New tests | `test/unit/pin_test.dart` (4, digest format and failure cases), `test/database/pin_repository_test.dart` (5, real in-memory SQLite), `test/widget/accessibility_test.dart` (4) |
| Large text | Settings and the dashboard render at a 200% text scale with no overflow |
| PIN lock | with a digest seeded, Settings shows the lock view; a wrong PIN keeps it locked with an inline error; the right PIN shows the preferences |
| No PIN | Settings opens straight away and offers "Set a PIN" |
| PIN storage | the saved value is a `rounds$salt$digest` triple, never the digits; clearing it leaves language, discussion length and both feedback switches intact |

Known limits:

- The PIN is a table lock, not encryption (see cross-cutting issues).
- The ambience is one looped file with a fixed volume; there is no music or per-phase sting.

## Advanced game settings - complete

Two table preferences the MC can change between matches, both stored in the existing one-row
`Settings` table and both applied without a restart.

### King selection mode (Settings → Game)

- **Automatic** — the wheel spins at the start of every round. `resolveTeamVote(drawLord: true)`
  and `recordQuest(drawLord: true)` return the match to `Phase.lordSelection` instead of
  `dayDiscussion`; the voting and quest screens then open the wheel directly, and the wheel
  starts its own spin on arrival, so the MC only hands the phone over.
- **Manual** (default) — the token keeps its order and the wheel stays closed until the MC uses
  "Choose the Lord" or the new "Draw a new King" action on the dashboard. That action calls
  `GameSessionController.beginLordDraw`, which is refused outside `dayDiscussion` and
  `teamSelection`, so a draw can never interrupt a tally.
- The draw itself is unchanged (`LordSelectionScreen`): a real random seat, a reel animated to
  land on it, then the engine records the seat. What changed is **who may be drawn**.
  `GameEngine.drawableLordSeats` excludes the serving King from every draw after the opening one
  — that is, once a quest has been resolved or a proposal rejected. The opening draw of a match
  still takes the whole table, and a one-seat table still draws that seat.
- Because the token is left with the serving King while the wheel is open, the exclusion is
  derived from public state only: no draw history is stored, and `playAgain` builds a fresh
  `GameState`, which is exactly the reset the roster needs.
- The wheel's own caption says who takes part in the draw, so the table is never told that
  "every seat" takes part when the serving King is standing down.

### Narrator extra delay (Settings → Narration)

- Presets 0, 1, 2, 3, 5, 7 and 10 seconds plus a custom 0–20 seconds slider, with a live sentence
  under the chips.
- The delay is enforced in `NarrationController`: speech must finish first, then the script's own
  `pauseAfter` and the configured delay run together, then the panel advances. The wait is a
  cancellable timer (`_waitFor` / `_cancelWait`) rather than an awaited `Future.delayed`, so
  pause, skip, replay, a language change and leaving the screen all end it; a generation counter
  makes a late wait or utterance callback unable to advance twice. When the phone has no speech
  engine, the same delay is added to `estimateSpeechDuration`.
- A change applies from the next line — a line already speaking is never interrupted. The
  "Automatic narration" switch now actually starts the night reading, which is what lets the
  delay apply unattended.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 205 tests pass (21 new) |
| King rules | `test/unit/king_selection_test.dart` (10): opening draw takes the table, a new King after every quest and after a rejected proposal, the serving King is excluded, manual mode keeps the token order, the wheel opens on demand and never mid-vote, a single eligible player is drawn, Play Again resets the history, the roster is never duplicated |
| Narration timing | `test/unit/narration_controller_test.dart` (+4): the delay starts only after speech ends, skipping mid-delay leaves no timer, replaying mid-delay advances exactly once, the value is capped and survives a reload |
| Settings persistence | `test/unit/settings_store_test.dart`: both new fields round-trip through `Settings`, an unknown King mode falls back to manual, drift schema v4 migrates from v3 |
| Settings UI | `test/widget/king_and_timing_settings_test.dart` (6): both controls, the live preview, the custom dialog, and the wheel spinning by itself in automatic mode while waiting for a tap in manual mode |

Device evidence (Pixel-class phone, `RFCY30E0LRT`, debug APK 0.11.0):

| Check | Result |
| --- | --- |
| Settings shows the controls | "King selection mode" with Automatic/Manual (selected chip filled and ticked) plus the sentence preview, and "Extra delay after each line" with 0/1/2/3/5/7/10/Custom |
| Live preview | Tapping 3 s changed the caption to "Each narration slide will wait an additional 3 seconds before continuing." |
| Persistence | Automatic + 3 s survived a force-stop and relaunch; the About card reads 0.11.0 |
| Automatic wheel | After the night the wheel opened and spun by itself, landed on a seat and announced "Leads the table for quest 1"; no dashboard draw action was offered |
| Automatic after a quest | Recording a quest returned to the wheel with "The vote is settled. Draw the King for quest 3", which spun itself and picked a different player from the King who had just served |
| Manual wheel | "Draw a new King" appears on the Day dashboard, opens the wheel and waits: "Wheel of seats, not yet spun" with a "Choose the Lord" button |
| Extra delay on real TTS | With automatic narration and 10 s: the panel stayed on each line well past the end of speech (1/11 held ~19 s, then roughly 14–18 s per line) instead of the ~4–6 s a zero delay gives; nothing spoke twice |

Known limits:

- The opening draw of a match takes the whole table, so a redraw before the first proposal may
  land on the same King again. From the second round on the serving King is always left out.
- The extra delay is a silent wait: it adds time after the line, not before it, and it does not
  change the length of the script's own beat.

## Optional team approval vote - complete

A house-rule switch requested after Phase 10: some tables do not want to vote on every proposed
team. Settings → Game → **Team approval vote** turns the approve/reject step off. The base game
keeps it on, which is the default.

### Behaviour with the vote on (default)

Unchanged from Phase 6: confirming a team opens `Phase.teamVoting`, the MC records the hands, a
majority approves, and a rejection counts towards the five-rejection loss.

### Behaviour with the vote off

- Confirming a team calls `GameEngine.proposeTeam(..., skipVote: true)`, which validates the team
  exactly as before (size from `AvalonTables`, distinct seats, existing players) and then opens
  `Phase.questResolution` directly. No tally is written: `approveVotes` and `rejectVotes` stay at
  zero and `hasVotes` stays false.
- Because no proposal is ever rejected, `rejectionCount` stays at zero for the whole match and the
  five-rejection victory for Evil becomes unreachable. The other victory paths are untouched, and
  the quest 4 two-fail rule still applies.
- The leadership token still moves. `recordQuest` takes `voteSkipped:`, and when it is set the
  round hands the token to the next player — the move a rejected or approved vote would have made
  — so the same player does not lead every round. With the automatic King mode the wheel keeps
  the serving King and excludes them from its own draw, exactly as it does after a vote.
- The quest screen passes `voteSkipped: !settings.teamVoteEnabled` rather than deriving the flag
  from the state, so a restored quest (which never stores a vote) cannot be mistaken for a
  voteless one and rotate the token twice.
- UI: the team selection screen says "The approval vote is off: this team goes straight to the
  quest", and `GameProgressHeader` shows **VOTE Off** in place of the rejection tile on the
  dashboard, team selection, quest resolution and assassination screens. The voting screen itself
  is unchanged and is simply never reached.
- The switch is app-wide, not per match: an MC who wants the base game back turns it on again.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 247 tests pass (8 unit + 4 widget new; the simulation suite also runs every player count both ways) |
| Engine rules | `test/unit/team_vote_setting_test.dart` (8): straight to the quest, the same team still votes when the switch is on, size/seat checks unchanged, the token passes on, the wheel still excludes the serving King, a whole voteless match counts no rejection, the controller carries the flag, quest 4 still needs two fail cards |
| Simulation | `test/unit/game_simulation_test.dart` (29): 40 seeded matches per player count across vote on/off and both King modes, no rejection is ever counted without a vote, exactly one victory path fires |
| Persistence | `test/unit/settings_store_test.dart`: `team_vote_enabled` encodes, decodes and survives a reset; drift schema v5 migrates from v4 with the column defaulting to on |
| Settings + flow | `test/widget/team_vote_setting_test.dart` (4): the switch and its dynamic caption, off → quest resolution (never the voting screen) with `VOTE Off` in the strip, on → the vote as before, and a voteless quest returning to the day with the token on the next seat |

Known limits:

- The switch applies to the whole app and takes effect when a team is confirmed. Flipping it in
  the middle of a match is allowed and simply changes the next proposal; the screen says which
  mode is in force, and a half-played match that had rejections keeps them.
- With the vote off, Evil's five-rejection victory cannot happen. That is the point of the house
  rule, and How to Play says so.

Device evidence (release APK `0.12.0+14`, installed over 0.11.0 on the Galaxy A36
`RFCY30E0LRT`): the switch appeared under Settings → Game, its caption changed as it was flipped,
and it was still off after a force-stop and relaunch, which exercises the real v4 → v5 migration
on the installed database. The dashboard, team selection, quest resolution and assassination
headers read **VOTE Off**; confirming a 2-player team for quest 1 and a 3-player team for quest 2
went straight to quest resolution with no voting screen, both quests resolved, the leader token
moved from seat 2 to 3 and then on, and the rejection tile never appeared. Play Again and a fresh
night on the same table kept the switch off.

**Play Again, fixed in the same build.** Play Again used to reset the setup draft and then open
the setup preparation screen, whose "Begin the match" button starts a match *from that draft* —
so the button was disabled and the new match could not be started at all. It now goes to the
round table with the fresh match already waiting at PREPARATION. The roster, the composition and
every setting carry over, the finished match keeps its result, and
`test/widget/endgame_test.dart` proves the night can be opened from there.

## Recorded narrator and past quest teams - complete

Two additions after 1.0.0: the night is now read by a narrator recorded for the app, and the
dashboard remembers who went on every finished quest.

### Recorded narrator

- The 14 night lines exist as MP3s in English and Filipino under `assets/audio/narration/`.
  They are the default narrator: `NarrationController` plays the clip for a line before it
  considers the phone's voice, so nothing has to be configured.
- `ClipService` (`lib/narration_engine/services/clip_service.dart`) is the playback interface;
  `AndroidClipService` talks to `com.avalon.companion/clips`, implemented in `MainActivity.kt`
  with a `MediaPlayer` reading the file straight out of `flutter_assets`. No download, no cache
  copy, nothing leaves the device. The volume comes from Settings; the recording plays at the
  pace it was made, so the MC's speech-speed setting keeps shaping the fallback voice and never
  drags the narrator away from how it was delivered.
- The speech engine stays as the fallback: a line with no recording, or a clip the player cannot
  open, is spoken by the installed voice. Missing audio therefore degrades to a voice rather than
  silence, and the existing unit tests still describe that path unchanged (the fake clip service
  reports unavailable unless a test asks otherwise).
- Settings says the recordings are the narrator; the voice picker is relabelled **Fallback
  voice** and explains it is used only when a recorded line cannot play. The "no voice installed"
  notice is suppressed while the current line has a recording, because no voice is needed.
- `test/unit/narration_clips_test.dart` is the gate on the set: every night line must have a file
  in both languages, every recorded id must match a scripted line, and no round line may be
  listed while it has no audio.

### Past quest teams

- `GameState.questTeams` holds the seats that went on each resolved quest, index-aligned with
  `questResults`; `GameEngine.recordQuest` appends the approved team, sorted, in the same step it
  appends the result. `teamForQuest(n)` and `questLog` read it back.
- This is public state, not a role: it is exactly what the table saw when it approved the team.
  The engine never learns who holds which card, and nothing here is derived from a card.
- Dashboard shows **Past quest teams** under Quest progress once a quest has resolved: quest
  number, won or lost, the players' names and their seats, newest quest last. The result screen
  closes with the same list.
- Persistence: drift schema v6 adds `games.questTeams`, one `;`-separated group of comma-joined
  seats per resolved quest (`1,3;2,4,5`). Rows written before v6 migrate to an empty string; a
  quest they never stored is shown as "The team was not recorded for this quest." rather than
  guessed.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 274 tests pass (2 engine, 1 persistence, 3 board-review widgets, 6 recorded-narrator controller, 4 clip-set and bundle gates new) |
| `flutter build apk --release` | succeeds: 62.6 MB, `versionName` 1.1.0, `versionCode` 17, arm64-v8a + armeabi-v7a + x86_64 |
| Audio in the APK | 28 MP3s (2.57 MB) stored uncompressed under `assets/flutter_assets/assets/audio/narration/en/` and `.../fil/`, which is what `AssetManager.openFd` needs. The first build bundled only the folder README: Flutter asset folders are not recursive, so `en/` and `fil/` are now listed in `pubspec.yaml` and a test guards it |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808`, the same certificate as the installed 1.0.0; `zipalign -c -p 4` passes; APK SHA-256 `D7A4D72F…ECBBD9EC`. `android/key.properties` was recovered from the previous checkout, so the build is release-signed again |
| Device: upgrade | `adb install -r` over the release-signed 1.0.0 on the Galaxy A36 (Android 17, `RFCY30E0LRT`) succeeded and kept its data: Home offered **Continue Game** with "In progress: 5 players, quest 1 of 5", so the v6 migration ran against the database 1.0.0 wrote |
| Device: recorded narrator | `flutter test integration_test/clip_playback_test.dart -d RFCY30E0LRT` passed: the `night.end` clip decoded and finished in both English and Filipino, read from inside the installed APK at volume 0 |
| Device: debug signing | `android/app/build.gradle.kts` signs a debug build with the release key when `key.properties` exists, so the integration test installed over the release app instead of forcing an uninstall first |
| Engine | `test/unit/engine_test.dart`: the team is kept with its result, each quest keeps its own team in play order, and a later quest does not overwrite an earlier one |
| Persistence | `test/database/game_repository_test.dart`: two different teams survive a save and a reload in the right order; schema v6 migrates v5 rows |
| Widget | `test/widget/quest_log_test.dart` (3): a played quest lists its names and seats, the section is absent before the first quest resolves, and a second quest adds its row |
| Narration | `test/unit/narration_controller_test.dart` (6 new): clip before engine, the Filipino folder, volume reaches the player, a finished clip advances like speech, an unplayable clip falls back, and a recorded line needs no installed voice |

Known limits:

- The round lines are still unrecorded and unplayed; if they are turned on later they will need
  the same treatment to avoid a change of narrator mid-match.
- The teams are only kept from v6 onwards. Matches finished before this build show their quest
  results but not their teams, because the seats were never stored.
- The on-device test run uninstalls the app when it ends, so it can only confirm the upgrade once
  and it takes the phone's saved matches with it. The phone currently holds a fresh install of
  1.1.0 rather than the upgraded one.

## Phase 11 — complete on automated gates and device

Delivered: the QA pass over the finished product. No rule, screen or stored value changed; the
phase added the coverage that was still missing and the evidence for the numbers below.

- **On-device integration test** (`integration_test/app_test.dart`). The master plan lists
  `test/integration/`; Flutter's on-device harness requires the top-level `integration_test/`
  folder, so that is where it lives, with `integration_test` added to `dev_dependencies`. Run it
  with `flutter test integration_test -d DEVICE_ID` while a phone is connected. Two tests run
  the real app against the real SQLite file and the real platform channels:
  - *the team approval vote round-trips through the real store* — opens Settings, flips
    **Team approval vote**, reads `settings.team_vote_enabled` back from the installed database,
    then flips it back so the device is left as it was found.
  - *a match starts on the real database and stores no characters* — creates a five-player
    match, confirms the round table opened, then walks `pragma_table_info` for every table in the
    live schema and fails on any column that could hold a character, an allegiance or a role.
    It also asserts the roster table is the game, the seat and the name only, and that the five
    entered names are the five in the session.
- **Schema privacy test** widened from the players table to the whole database. It walks
  `games`, `players`, `quests`, `team_proposals`, `game_events` and `settings`, matching per
  underscore token, so `games.assassination_outcome` — the public record of whether Merlin was
  named — stays valid while any column that could tie a character to a seat fails the suite.
  This replaces the narrower "no role on a player" check rather than duplicating it.
- **Clear history** on the History screen, requested after the QA build. The section header carries
  a `delete_sweep` action that opens `lib/features/history/clear_history_dialog.dart`: a stepper for
  any number from 1 to what is stored, plus **All N**. Deleting starts at the bottom of the list —
  the oldest match — and a match still in progress is never touched, because that is the match
  **Continue Game** offers. `MatchStore.deleteHistory(count:)` does it in one transaction ordered by
  `updatedAt`, so the votes, quests, events and seats of each deleted match cascade away with it,
  and the action is disabled rather than hidden when there is nothing to delete.
- **Performance** measured on the 0.12.0 release APK on the Galaxy A36 (Android 16): cold start
  (`am start -W` after `force-stop`) 493 / 318 / 299 ms across three runs; `dumpsys meminfo`
  with a match on the dashboard reports TOTAL PSS 106 MB and TOTAL RSS 200 MB. `dumpsys gfxinfo`
  records a single frame for a Flutter surface, so it cannot produce jank percentiles: no
  frame-timing claim is made.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 257 tests pass (1 new: the whole-schema privacy scan; 9 new for clearing history) |
| `flutter test integration_test` | 2 tests pass on the Galaxy A36 `RFCY30E0LRT` |
| Rule coverage | 12 table tests, 29 seeded simulations (40 matches per player count, both King modes, vote on and off) and the engine/controller suites; every victory path is reached and only one fires |
| Privacy, in source | `test/unit/privacy_test.dart` keeps the engine free of character-to-player links |
| Privacy, on screen | no screen asks for or shows a name next to a character; the assassination records only whether Merlin was named |
| Privacy, on disk | the whole schema and the installed database are scanned for role columns; the roster holds seat and name |
| History clearing | `test/database/game_repository_test.dart` covers oldest-first, delete-all, more than stored, zero, the cascade and the running match kept; `test/widget/history_test.dart` covers the dialog, the stepper, All N, the snack bar, the disabled action and cancelling |
| Device: 10 players | the setup screen accepts a ten-player table and reads "10 players — 6 good, 4 evil", with the six name fields and the counter scrollable |
| Device: settings | settings survive a refresh, a new match and Play Again (verified in 0.12.0) |
| Device: recovery | a force-stop mid-match restores the same match at the same phase and seat |

Known limits:

- The integration test drives the real database, so it edits the device's settings and leaves the
  last match it created behind. It restores the one setting it flips but does not delete the
  match it starts. It also needs a device without an MC PIN, because Settings opens locked and the
  test would have no PIN to type.
- Performance is measured on one device. There is no baseline from another phone, and Flutter's
  own frame timings are not readable through `dumpsys gfxinfo`, so smoothness is judged by feel
  rather than by a number.

## Phase 12 — complete: signed 1.0.0 release

Delivered: the release build, signed and installed on the phone. Version 1.0.0+16; no rule,
screen or stored value changed.

- **Release build.** `flutter build apk --release` with Android NDK 28.2.13676358 (r28c)
  installed at the version `android/app/build.gradle.kts` pins. AGP's strip step now runs, so
  Flutter's three engine libraries are stripped with `llvm-strip` and the APK is **60.0 MB**
  (62,936,522 bytes) — arm64-v8a, armeabi-v7a and x86_64 in one file, `minSdk` 24,
  `targetSdk` 36.
- **Signing.** The release keystore lives outside the repository, at
  `C:/Users/<mc>/.avalon/avalon-release.jks` (alias `avalon`); `android/key.properties` names it
  and is gitignored. `apksigner verify --print-certs` reports one signer,
  `CN=Avalon Companion, OU=Game Master, …`, SHA-256 `1aa864f1…a570b808`. Without
  `key.properties` the build falls back to the debug key, which installs but cannot update a
  release-signed install.
- **Checks.** `zipalign -c -p 4` passes; `aapt2 dump badging` reads `com.avalon.companion`,
  `versionCode` 16, `versionName` 1.0.0.
- **Install and smoke test.** `adb install` on the Galaxy A36 (Android 16) after removing the old
  debug install, because a release signature cannot update a debug-signed app. The app opened on
  Home, the splash read **v1.0.0**, One UI drew the launcher icon in its own mask — navy plate,
  gold shield, no white edge, no crop — and the setup screen accepted a ten-player table
  ("10 players — 6 good, 4 evil").

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 257 tests pass |
| `flutter test integration_test` | 2 tests pass on the Galaxy A36 `RFCY30E0LRT` |
| Release APK | 60.0 MB, `versionName` 1.0.0, `versionCode` 16, three ABIs |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` |
| Alignment | `zipalign -c -p 4` passes |
| Device: launch | installed release build opens on Home; splash shows v1.0.0 |
| Device: icon | launcher mask applied by One UI; no white plate or clipped artwork |
| Device: 10 players | setup reads "10 players — 6 good, 4 evil" with ten seats |

Known limits:

- The APK carries all three ABIs so one file serves every phone; `flutter build apk
  --split-per-abi` would cut each download to roughly a third, at the cost of three files to
  hand out.
- The keystore is the app's only identity. There is no upload key and no Play Store listing, so
  losing the keystore means a new package on Android rather than an update.

## Tablet layout — complete on automated gates

Delivered: the same layout, readable on any Android tablet. No rule, screen or stored value
changed, and this entry documents it. Version 1.2.0+18; no rule, screen or stored value changed.

- **One bounded column.** `AvalonScreen` measures the window and, above 600 dp, centres the body
  in a `ConstrainedBox` at `kMaxContentWidth` (600 dp, `lib/core/theme/app_metrics.dart`).
  Below that width the body is returned untouched, so a phone renders exactly as before.
- **Action bars follow the content.** A bottom action bar is capped to the same 600 dp, so a
  confirmation button is no longer a full-width band on a landscape tablet. The navigation bar
  opts out with `capBottom: false`: its band is still edge to edge, but its three items sit in the
  600 dp column. Both use `Align(heightFactor: 1)` so the bar keeps its own height instead of
  filling the Scaffold's loose constraint.
- **No second layout.** There are no breakpoints and no two-pane screens; the requirement was
  that a tablet shows the same UI/UX as the phone, only centred.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 280 tests pass (274 + 6 tablet tests) |
| Phone unchanged | 360×780: content column is the full 360 dp with no gutter |
| Portrait tablet | 800×1280: home, settings, history, setup and how-to-play each centre a column ≤ 600 dp with equal gutters and a body taller than 300 dp |
| Landscape tablet | 1280×800: ten-player dashboard column ≤ 600 dp; the primary button is ≤ 600 dp wide |
| Large text | night narration panel at 1280×800 with 1.3× and 2.0× text scale: no exception |
| Navigation | the band is under 140 dp tall on a tablet and tapping History still opens GAME HISTORY |
| Release APK | 62.6 MB (65,655,374 bytes), `versionName` 1.2.0, `versionCode` 18, three ABIs |
| Signature | one signer, `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808`; `zipalign -c -p 4` passes |
| GitHub release | `v1.2.0` published with `Avalon-Companion-1.2.0.apk`; digest matches the local build |

Known limits:

- No physical tablet was available for this pass; the sizes above are widget-test viewports.
  `DESIGN_SYSTEM.md` §9 now lists them alongside the phone widths.



- A match that is interrupted mid-vote restores its proposed team but starts the tally again
  from zero. That is deliberate: the app never stores a partial vote, and re-counting hands is
  safer than trusting a half-written tally. Re-counting is a few seconds at the table.
- A device integration test run uninstalls the app it installed, so it cannot be used to check an
  in-place upgrade twice, and it deletes the matches the phone held. `android/app/build.gradle.kts`
  now signs debug builds with the release key whenever `android/key.properties` exists, which is
  what lets the test install over the release app at all; the package is still removed by
  Flutter's teardown, not by the install.
- The 1.1.0 build is signed with the same keystore as 1.0.0 (`CN=Avalon Companion`), so updates
  install in place. `android/key.properties` is gitignored, so a clean checkout has to recreate it
  from the keystore at `C:/Users/Marc/.avalon/avalon-release.jks` (alias `avalon`) before building.
- A restored match keeps its original start time, so a match that spanned a crash reports the
  wall-clock length, including the time the app was closed. Duration is a convenience, not a
  rule.
- The Android build pins `path_provider_android` below 2.3 through
  `dependency_overrides`. From 2.3 it depends on `package:jni`, which compiles a native
  helper with CMake and needs a complete Android NDK. The NDK is now installed
  (`ndk/28.2.13676358`, r28c), so the pin could be lifted and tested; until then the last
  platform-channel implementation serves the documents directory the app asks for.
- `AVALON_KEEP_SYMBOLS=1` exists for a machine without the pinned NDK: it skips the strip step
  and produces an APK around 500 MB, for local testing only. Gradle's daemon keeps the variable
  it was started with, so stop it (`android\gradlew.bat --stop`) after changing it. With the NDK
  installed, both debug and release builds strip normally.
- The MC PIN is a lock on the table, not a security boundary: a four-digit PIN with a salted
  SHA-256 digest stops a curious player from changing settings or aborting a round, and the
  digest sits in the one `Settings` row. It is not encryption of the database, and anyone with
  the unlocked phone and developer tools can read the matches — there is nothing secret in them
  to read. Unlocking lasts the app session; closing the app locks it again.
- `build/` used to be a junction to `%LOCALAPPDATA%\Temp\avalon_build`, because the project lived
  in a OneDrive folder and the sync client kept a handle on `build\app\intermediates`, failing the
  Android build with "Unable to delete directory". The project now lives at `C:\avalon-companion`,
  outside OneDrive, and `build/` is an ordinary directory again; the junction and its note are
  retired. If the project is ever moved back under a synced folder, expect the same failure.
- The bundled plates are public-domain paintings, not commissioned art: they were chosen for
  mood and composition, so a few are only loosely on-subject (the Excalibur plate is
  Waterhouse's *Magic Circle*). Replacing them with commissioned plates only requires new
  files under the same names.
- The night is read from the recordings bundled in the APK. The phone's voice is only the
  fallback for a line with no recording. Android's TTS API exposes no gender or timbre, so that
  voice is the best installed one for the language, and **Voice depth** still shifts its
  register; the picker lists only voices the engine reports as installed and offline, and a
  phone that hides its voice list falls back to Automatic. The seven round lines (`round.proposal`,
  the vote results, the quest result and the accusation) are defined but never played, so they
  have no recordings and no voice of their own yet.
- The night ambience is one generated 20-second WAV in `res/raw`, looped by the activity. It is
  a bed, not a soundtrack: there is no music, no per-phase sting and no volume separate from
  the master. A later release can replace the file without touching code.
- Gradle is pinned in two places (`org.gradle.java.home` in `android/gradle.properties` and
  the JDK paths there). The generated `android/gradle/gradle-daemon-jvm.properties` was
  renamed to `.bak`: its toolchain criteria won over `org.gradle.java.home` and made Gradle
  pick a JRE from a VS Code extension that has no `jlink`, which fails the
  `androidJdkImage` transform. Restoring that file will reintroduce the failure.

## UI/UX pass — tiers 1–3 complete on automated gates

Delivered: nine changes at the table. Version 1.3.0+19; no rule, engine or stored value changed;
each is covered by widget tests that drive the real screens.

- **Vote by seat.** `VotingScreen` marks each seat approve or reject once, instead of two
  steppers the MC taps until they add up. Tapping the same side clears the seat; tapping the
  row cycles approve → reject → uncounted, so a misheard vote is corrected on the seat it
  belongs to. *Resolve* stays disabled and reads "Count N more votes" until every seat is
  marked, and the engine still receives the two totals and decides the outcome.
- **Discussion ring.** The Day discussion timer is a 76 dp ring showing the remaining share of
  the round, gold until the last 10 seconds and danger red after that. The ring itself starts,
  pauses and restarts the clock; pause and reset stay beside it as icon buttons.
  `Feedback.alarm()` adds a double heavy tap at zero, and the clock clicks once at 10 seconds,
  so the end of the discussion is audible with the phone face down.
- **Night controls.** *End night* moved out of the narration transport into the app bar as a
  labelled action behind a confirmation. The transport is now previous, replay, play/pause and
  next only, so the control that skips the script cannot be hit while reaching for next. The
  English/Filipino switch moved to the top of the panel, out of the thumb row.
- **One quest board.** `QuestBoard` (`lib/core/widgets/quest_board.dart`, replacing
  `QuestLog`) stacks the five markers and the team that went on each resolved quest in one card,
  with one line of explanation while nothing has resolved. The dashboard's second "Past quest
  teams" section and its caption are gone, and the victory screen uses the same board.
- **Roster grid.** The dashboard table is a two-column grid of seat tiles (`PlayerGrid`,
  `PlayerSeatTile`): seat number, name, leader crown, gold border and team mark for the current
  quest team. Two columns at every width, so a tablet keeps the phone layout.
- **Home hero.** While a match is live, home opens with a card for it — players, quest number,
  phase, quests resolved — and **Continue Game** is the gold action, with **New Game** demoted
  to the secondary button. The History and Settings cards are removed because the bottom
  navigation already reaches both; How to Play stays.
- **History detail.** A history tile opens `MatchDetailSheet`
  (`lib/features/history/match_detail_sheet.dart`): result, win reason, quest tally, rejected
  proposals and the team that went on each quest, drawn from `MatchSummary.questTeams` and
  `rejectionCount`. Seats only — no names, no roles — because that is all the store keeps.
- **Last table.** `MatchStore.lastRoster()` returns the names of the most recent match in seat
  order, and `lastRosterProvider` feeds a **Use the last table** chip on setup. It restores the
  count and the names, and every field stays editable.
- **Empty states.** A dashboard with no match and a vote screen with no proposal under way use
  `EmptyState` with a way back, so a blank body is never the answer.

Gate evidence:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 290 tests pass (280 + 10) |
| Vote by seat | `test/widget/voting_test.dart`: every seat counted before resolving, a seat cleared and recast, a miscount corrected, the approve/reject outcomes, and the no-vote empty state |
| Discussion ring | `test/widget/team_selection_test.dart`: the ring starts at 1.0, follows the clock and pauses on tap |
| Night controls | `test/widget/narration_controls_test.dart`: no stop in the transport, the language row sits above it, End night cancels and then confirms into the draw |
| Merged board | `quest_log_test.dart`: the board appears once, names the team that went, and shows its hint line before the first quest resolves |
| Home and grid | `home_dashboard_test.dart`: the live match is the hero with a PrimaryButton, New Game is not, the duplicate cards are gone, and seats lay out two per row at 56 dp |
| History detail | `history_test.dart`: a stored match opens its quest-by-quest record, shows its seats and rejected count, and closes back to the list |
| Last table | `last_table_test.dart`: the chip restores seven seats and their names, stays editable, and is absent with nothing stored |
| Navigation | `history_test.dart` reaches history through the bottom navigation, the only path now |
| Release APK | 62.9 MB (65,999,270 bytes), `versionName` 1.3.0, `versionCode` 19, three ABIs |
| Signature | `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` — the same key as 1.0.0–1.2.0; APK SHA-256 `25E1660B…C05761D3` |
| GitHub release | `v1.3.0` published with `Avalon-Companion-1.3.0.apk`; digest matches the local build |
| Phone and tablet | no layout rule changed: the same screens, still in the 600 dp column on a tablet |


## Device pass — 1.3.1 on a Galaxy A36

1.3.0 was installed with `adb install -r` over the 1.1.0 build already on the phone. The upgrade
kept the stored match and its SQLite file. The release build was then driven by hand through
home → night → draw → team → vote → quest → day.

What the device showed, and what 1.3.1 changes:

- **The night title was truncated.** With **End night** in the app bar, *NIGHT NARRATION* rendered
  as "NIGHT NARRAT…". The title is now **THE NIGHT**, which fits beside the action at 360 dp.
- **An unfinished record claimed the match ended.** The history detail sheet said "No quest was
  resolved before the match ended." for a match still in progress. It now says "No quest has
  resolved yet."; finished and abandoned matches keep the original line.

Everything else behaved as designed on the phone: the home hero restored the live match, the
two-column roster and merged quest board laid out cleanly, the discussion ring counted down from
5:00 and paused on tap, seat voting enabled *Resolve* only after all five seats, and the board
showed **Quest 1 · won, Seats 1, 2** after the quest resolved.

| Check | Result |
| --- | --- |
| `flutter test` | 291 tests pass (290 + 1) |
| Release APK | `versionName` 1.3.1, `versionCode` 20, same signer as 1.0.0–1.3.0 |
| Signature | `CN=Avalon Companion`, APK SHA-256 `4B64481B…CDE41105` |
| GitHub release | `v1.3.1` published with `Avalon-Companion-1.3.1.apk`; digest matches the local build |
| Install | `adb install -r` over 1.1.0 succeeded and kept stored data |
| Re-check | title and record wording confirmed on the phone after the fix |

## History selection — 1.4.0

Requested after 1.3.1: long-press a stored match to delete it, and build a multi-select so several
matches can go at once.

### What changed

- **`HistoryScreen`** is now a `ConsumerStatefulWidget` with a `Set<int>` of selected ids. Empty
  means normal mode; non-empty means selection mode, so there is no second boolean to drift.
  `PopScope` turns system back into "leave selection" while the set is non-empty.
- **`MedievalCard`** gained `onLongPress`, `isSelected` and a press dip. Selection is drawn with the
  same gold border and raised surface as a chosen seat on `PlayerTile`, so the app has one selected
  style rather than two.
- **`Feedback.select()`** is the long-press acknowledgement: a medium haptic plus the click tone
  when sound is on. `SilentFeedback` implements it as a no-op, so widget tests stay hermetic.
- **`MatchStore.deleteMatches(Iterable<int> ids)`** deletes exact ids in one transaction and keeps
  the in-progress guard in SQL (`status != 'inProgress'`), not only in the UI. `deleteHistory` is
  unchanged, so the old clear dialog and its tests keep working.
- **`AppInfo.version`** was still `1.1.0`; it now follows the release at `1.4.0`.

### Interaction

| Gesture | Result |
| --- | --- |
| Long-press a finished or abandoned match | Medium haptic, card dips and lifts, gold border and springing check, app bar becomes **N selected** |
| Long-press another, or tap cards while selecting | Adds or removes that card; the count and the app bar animate |
| Select all | Takes every finished and abandoned match; never the running one |
| Lock on the in-progress card | That card is not selectable; warning haptic and a snackbar explain it is kept |
| Delete | Count-aware confirmation; cancel keeps the selection, confirm collapses the cards and deletes exactly those ids |
| Back or the close button | Leaves selection mode without deleting |
| Reduced motion | All of the above still works with animations set to zero and no stagger |

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 300 tests pass (291 + 9) |
| Store coverage | `game_repository_test.dart`: chosen ids only, in-progress id refused even when passed, empty/unknown selection deletes nothing |
| Screen coverage | `history_test.dart`: long-press and tap counts, in-progress refusal, select-all, cancel keeps selection, confirm reaches the empty state, system back leaves selection |
| Existing clear path | the six clear-history tests still pass unchanged |
| Device pass | Galaxy A36 (Android 17), installed over 1.3.1: long-pressed the abandoned match, saw **1 SELECTED**, the in-progress card locked, the count-aware dialog, **Deleted 1 match.**, the in-progress record kept, and Settings → About at **1.4.0** |
| Release APK | 63.0 MB (66,048,666 bytes), `versionName` 1.4.0, `versionCode` 21, arm64-v8a + armeabi-v7a + x86_64 |
| Signature | `CN=Avalon Companion`, SHA-256 `1aa864f1…a570b808` — the same key as 1.0.0–1.3.1; APK SHA-256 `B84CF79D…4D5178F0` |
| GitHub release | `v1.4.0` published with `Avalon-Companion-1.4.0.apk`; its digest matches the local build |

## Narrator voices — 1.5.0

Requested after 1.4.0: more narrator voices, the shipped one out of the way, and "just import a
file" to add one.

### What changed

- **`VoicePack`** (`lib/narration_engine/models/voice_pack.dart`) is the unit of a voice: id, name,
  root, the line ids each language can play, `builtIn`, `hidden`. `pathFor` returns null for a line
  the pack did not record, so the narration controller falls back to text-to-speech line by line
  rather than per pack.
- **`VoicePackCatalogue`** reads Flutter's own asset manifest instead of a hard-coded list:
  `assets/audio/narration/Dahlia voices` is the `classic` voice; every
  `assets/audio/voices/<pack>/<en|fil>/*.mp3`
  is another bundled voice, named from its folder (`voice-of-dahlia` → "Voice of Dahlia") or
  `voice.json`. A manifest that cannot be read leaves the shipped voice in place.
- **`VoiceImport`** is pure: zip bytes to `{en: {id: bytes}}`, ignoring READMEs, `__MACOSX`, other
  language folders and anything that is not `.mp3`. A zip with no narration raises a readable
  `VoiceImportException`; `slugForName` and `uniqueId` keep folder names safe and distinct, and
  `isValidId` is checked before any file is read or written.
- **`VoiceFiles`** is behind a conditional export so the web build still compiles: `dart:io` writes
  clips under `<app files>/voices/<pack>/` and deletes a voice again. **`VoiceImportChannel`** is
  the Kotlin half — `directory` and `pickZip`, using `ACTION_OPEN_DOCUMENT` and a cache copy so
  content URIs from any storage provider work.
- **`VoicePacksController`** merges the bundle with the stored rows, seeds a row for each bundled
  voice so it can be renamed and hidden, drops rows for voices this build no longer ships, and
  keeps working with no database (in-memory list, shipped voice intact).
- **Schema v7** adds `voicePacks` and `settings.voicePackId`. `NarrationController` takes the chosen
  id from settings, resolves it through the loaded packs, and treats an unknown id as the shipped
  recordings. Settings keeps the chosen voice through `SettingsRepository`.
- **Settings → Narration** leads with the voice and its coverage ("English 14/14 · Filipino not
  recorded"), then language and the fallback controls. The picker content is a fixed-width
  `SizedBox` around the shrink-wrapped list: `AlertDialog` wraps content in `IntrinsicWidth`, and a
  viewport cannot answer intrinsic measurements — the first build threw in layout instead of
  opening the dialog.
- **Kotlin**: the voices channel, `voicesDirectory()`, `pickZip()`/`onActivityResult()` and
  `copyToCache()`. `playClip` accepts an absolute path, so an imported recording plays through the
  same `MediaPlayer` as a bundled asset.

### Interaction

| Action | Result |
| --- | --- |
| Settings → Narrator voice | Lists the shipped voice and every added one, with English and Filipino counts |
| Import a voice… | System picker → name dialog → the voice becomes the narrator, with a snackbar |
| Rename… | Only the label changes; the folder and MP3s are untouched |
| Hide (bundled) | Leaves the list, stays playable for a match in progress; restorable from Hidden voices |
| Delete (imported) | Confirmation names the voice; the row and its recordings go; the active voice falls back to the shipped one |
| A line the voice did not record | The phone speaks that line; the rest of the night stays in the chosen voice |

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 325 tests pass (300 + 25) |
| Model and import | `voice_packs_test.dart`: manifest parsing (only `<pack>/<lang>/<id>.mp3`, README and other folders ignored), readable names and `voice.json`, a pack missing a language, zip folders/flat/junk/not-a-zip, path-climbing ids, unique folder ids, and install/delete of real files in a temp directory |
| Narration | `narration_controller_test.dart` (+3): the chosen pack's own path is played, a line it did not record falls back to speech, an unknown pack falls back to the shipped recordings |
| Settings | `voice_picker_test.dart` (+5): the coverage label, switching voices, renaming, deleting the active imported voice, and hiding the bundled one (which offers Hide, never Delete); the picker's layout is exercised by every one of these |
| Data | `voice_packs_test.dart` also covers the stored clip map (empty/corrupt read as "no recordings"), rename/hide keeping the folder, and the v6 → v7 upgrade; `settings_store_test.dart` round-trips the chosen voice |
| Device pass | **Not run.** No phone was attached, and no voice recordings ship with this build, so the file picker, the unpacking and absolute-path playback are unverified on hardware |
| Release APK | **Not built or published for 1.5.0** |

## The manual — 1.6.0

Requested after 1.5.0: **How to Play** should teach the game, not the app — "the actual
instruction to play Avalon, like a user manual".

### What changed

- **`HowToPlayScreen`** is now a manual in play order: before you begin, set up the table,
  know the characters, the night, every round, team size, rules that catch people out, the
  final accusation, how to win, using the app, at the table.
- **The rules come from the engine, not from memory.** The team-size table is rendered from
  `AvalonTables.teamSize` for every count from 5 to 10, so it cannot drift from the numbers
  the engine enforces; the two-fail rule, strict majority, five rejections, token order and
  win conditions are stated the way `GameEngine` and `AvalonTables` implement them.
- **The night section follows `NightScript`**: close eyes, minions without Oberon, Merlin
  seeing every evil player except Mordred, Percival seeing Merlin and Morgana, then the
  first Lord draw. The app skips absent characters, exactly as the narration does.
- **The MC's part is marked at each step**: New Game, Preparation, Begin the match, Open
  Night Narration, Choose the Quest Team, Open the Vote, Resolve the Quest, Begin the
  Accusation, See the Result. The manual also states what the app deliberately does not do,
  and why: it is never told who holds which card.
- **The list is one scrollable page**, section by section, with the same section headers and
  cards as the rest of the app; no new route, no game state.

### Interaction

| Section | What it settles |
| --- | --- |
| Before you begin | 5–10 players, one character card each, one phone with the MC |
| Set up the table | Seating, roster, deal, approve/reject cards, leader token, first night |
| Know the characters | Merlin, Percival, loyal servant, Assassin, Morgana, Mordred, Oberon, minion |
| The night | The exact order and who may open their eyes |
| Every round | Proposal, discussion, vote by seat, strict majority, rejection, next leader |
| Team size | A 5–10 × quest 1–5 table read from `AvalonTables` |
| Rules that catch people out | Ties, five rejections, quest 4's two fails, quest cards, accusation |
| The final accusation | The Assassin names Merlin; the app stores only the outcome |
| How to win | Three quests plus Merlin alive; three fails, five rejections or Merlin named |
| Using the app | The dashboard's phase button, night transport, language, voice, pause |
| At the table | Eyes closed, no card shows, bluffing, house rules agreed up front |

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 328 tests pass (325 + 3) |
| Manual coverage | `how_to_play_test.dart`: opening copy, setup and night order, the quest table, the strict-majority/five-rejection/two-fail rules, the accusation and both victory paths; the page is scrolled end to end at phone size, so layout is exercised |
| Content accuracy | Team sizes and the two-fail threshold are read from `AvalonTables`; vote, token and victory language matches `GameEngine`; the night matches `NightScript` |
| Device pass | **Passed on a Galaxy A36 (SM-A366B).** `flutter test integration_test` ran all 3 tests on the phone: the settings switch writes to the installed database, a match starts on the real store, and no table has a role column; a recorded night line decodes in both languages. The manual was opened and scrolled on the device from the opening to **At the table**, and the quest table rendered |
| Release APK | Signed **1.6.0+23** built (63.9 MB), installed over 1.4.0 on the phone, and published as [**v1.6.0**](https://github.com/Akiprofit/avalon-companion/releases/tag/v1.6.0) with `Avalon-Companion-1.6.0.apk`; the uploaded asset's SHA-256 matches the local build |
| Voice import | **Still unverified on hardware:** no recordings ship, so the picker and zip unpacking were not exercised |

## Table safety — 1.7.0

Requested after 1.6.0: the phone should survive a misheard seat. The three places where a
mistake is most expensive — a wrong proposal, a wrong vote count, a wrong quest count — are
each reversible until the next action.

### What changed

- **Single-step undo in `GameSessionController`.** `proposeTeam`, `resolveTeamVote` and
  `recordQuest` remember the `GameState` they replaced, with a token. `undoOffer` exposes
  that step; `undoLastStep(token)` restores it only while the token still matches. Any other
  transition clears the offer, so an old snackbar cannot rewind a newer step.
- **Storage rolls back in one transaction.** `MatchStore.undoStep(gameId, state,
  removeProposal:, removeQuest:)` restores the snapshot, deletes the newest proposal or quest
  row for the match and the newest event, and rewrites the game row. A finished match is
  written back as in progress, with no winner and no duration.
- **Where the offer appears:** a snackbar with Undo after a team is sent, and an **Undo the
  vote** / **Undo the result** action in the outcome dialogs. Undo returns to the live voting
  or quest screen with the recorded counts and cards still there, so the MC corrects one seat
  or one card instead of recounting the table.
- **Not undoable:** the Lord draw, the night, pause/resume, abort and the accusation. They are
  narration steps or deliberate decisions, not counts that can be misheard.
- **Phase hint.** The dashboard body opens with one line naming the next action for the
  current phase; the old footer card that duplicated it was removed, so the hint scrolls and
  survives a 200% text scale.

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 341 tests pass (328 + 13) |
| Controller | `persistence_test.dart` (+6): proposal, vote and quest undo restore the snapshot; stale tokens and later actions are refused; a finished match reopens; the accusation offers nothing |
| Storage | `game_repository_test.dart` (+3): the newest row and event are deleted in one transaction, older log lines are kept, and a finished match becomes the match in progress |
| UI | `voting_test.dart` (+1) and `quest_resolution_test.dart` (+1): the dialog's Undo keeps the tally or the cards and the step can be recorded again; `team_selection_test.dart` (+1): the snackbar undoes the proposal |
| Hint | `team_selection_test.dart` (+1): the line names the narration in Preparation and the team action in Day |
| Device pass | **Passed on a Galaxy A36 (SM-A366B) over wireless debugging.** `app_test.dart` (2 tests) and `clip_playback_test.dart` (1) ran on the phone: the settings switch survives the installed database, a match starts on the real store with no role column in any table, and a night line decodes in both languages |
| Release APK | Signed **1.7.0+24** built (64.0 MB), zipaligned and verified with the release key, installed on the phone and opened; SHA-256 `66f84332…d1657f06` |

## The big table — 1.10.0

Avalon stops at ten players, and the app stopped there with it: the setup stepper was built from
`AvalonTables.maxPlayers`, and the three rule tables had no row for eleven. A table of eleven was
the one request the app could not answer.

The question was not whether the app can count to fourteen — it can — but whether it should pretend
the rulebook does. It should not. Eleven to fourteen is a house rule: there is no published
composition, no agreed quest sizes, and the balance drifts as the seats grow. So the sizes sit
behind a switch, off on a fresh install and off for every upgraded one, and both setup and the
manual say plainly whose numbers they are. `AvalonTables` now keeps `officialMaxPlayers` (ten) apart
from `maxPlayers` (fourteen), and the How to Play team-size table still lists only the official
rows.

The house rows keep the Evil share near the official 33–40%: 7/4 at eleven, 8/4 at twelve, 8/5 at
thirteen and 9/5 at fourteen, with quest teams one card larger than ten's from the first quest.
Quest four still needs two fails, and five rejections still hand the match to Evil. A fifth Evil
seat is a Minion of Mordred, because the four named Evil are already in play.

The card pool is the honest limit. The box holds fourteen character cards and a ten-player game
already uses ten of them, so eleven fits only if the box has five plain Servants; twelve and up may
need proxies. The app can track fourteen seats, but it cannot deal cards it does not have, and the
house-table line in setup says so.

Turning the switch off also clamps a stored default player count back to ten and hides **Use the
last table** for a roster the app no longer offers, so a table cannot fall back into a size setup
will not show.

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 393 tests pass (120 widget, 273 unit and database) |
| House tables | `rules_test.dart` (+12): good/evil and team sizes for 11–14, the house-table marking, a 14-seat roster whose fifth Evil is a Minion, and the Evil share held between 30% and 40% |
| Engine | `engine_test.dart` (+1): a 14-seat match starts with five-card first quests, and 15 seats are rejected |
| Setting | `big_table_setting_test.dart` (+5): off by default in Settings and setup, turning it on unlocks 11–14 with the house note, a 14-seat match is set up and started on a phone, a 12-seat last table is only offered when the switch is on, and a stored 13 falls back to 10 when it goes off |
| Storage | `settings_store_test.dart`: the switch round-trips and a v4 row gains it switched off; `voice_packs_test.dart` still migrates a v6 file |
| Version | `app_info_test.dart` (+1): the About panel's version matches `pubspec.yaml` |
| Device | **Galaxy A36 (SM-A366B) over USB**: 1.10.0+33 walked end to end. Off on the fresh install, Settings offered only 5-10 and setup showed no house line. Turning the switch on changed the tile's description and added 11-14 to both the default-count chips and setup's player rows, with the house note above them. A 14-seat table was then set up and started: 9 good and 5 evil, the fifth Evil a Minion of Mordred, quest teams 5-6-6-7-7, and the Round Table screen drew 14 seated with no overflow and no Flutter error in logcat. Turning the switch off reverted the description, dropped 11-14 from Settings and setup, and removed the house note |
| Release APK | Signed **1.10.0+33** release build (71.8 MB, `arm64-v8a`, `armeabi-v7a`, `x86_64`); SHA-256 C9F73993968A409133AB61AF019DE42AC2A33DC3AAD30949D03E65289FA994FA. A forced Dart recompile from the current tree produced the same digest, so the tested build and the shipped file are the same bytes |

## The round, spoken — 1.9.0

The night was the only part of a match the narrator played. Seven recorded round lines sat in every
voice folder, unused: between quests the phone went quiet while the table worked out what had just
happened. This release plays them.

The design question was where a line belongs — the narration panel or the event itself. The panel
was the obvious place and the wrong one: the MC would have to open it mid-round, leaving the table
and the screen that shows the state. Each line is attached to the action that causes it instead:
confirming a team announces the proposal, resolving the vote announces the outcome, recording a
quest announces the result, opening the accusation announces that the assassin is awake.

That also settled the fourth rejection. The table needs to hear that one more rejected team hands
the match to Evil, and that is only known once the count settles, so it is a separate line chosen
by `NarrationCues.voteOutcome` rather than a fixed sentence.

One line at a time. A new cue stops the previous clip — or the phone's voice — and starts itself; a
voice with no recording falls through to the platform voice, and a phone with neither simply stays
quiet. No screen awaits a cue, so a silent phone cannot slow the table, and a failure to play never
becomes an error dialog over the board.

The language switch in the narration panel used to change the panel only. With round lines reading
`AppSettings.defaultLanguage`, that would have let the night speak Filipino while the round spoke
English. The panel now writes the setting as well, so there is one answer to "which language is the
table hearing".

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 370 tests pass (115 widget, 255 unit and database) |
| Round cues | `round_cues_test.dart` (+2): a proposed team, an approved vote and a recorded quest each play their line, and opening the accusation plays its own |
| Voice rule | `narration_cues_test.dart` (+11): the recording wins over speech, Filipino reads the `fil` folder, a failed play falls back to speech, a half-recorded voice falls back per line, a phone with neither stays quiet, and only the fourth rejection warns |
| Tablet gutters | `tablet_layout_test.dart` (+1): a drag that lands beside the reading column moves the page |
| Device | **Galaxy A36 (SM-A366B) over USB**: the round cues were walked on the 1.9.0 build — the proposal, the approved vote and the quest success each started a clip, and quests 1 and 2 played through. Locked to landscape on the rebuilt APK: on team selection a drag beside the reading column moved nothing before the fix, and now scrolls the list on either side with the progress header and the action bar pinned |
| Release APK | Signed **1.9.0+32** built (71.8 MB), zipaligned and verified with the release key; SHA-256 F6B3960576E1639AF3C282BF419B4452AD05142F3F96A3E1CBAC2DC73E6E867F |

The release walk also caught a landscape-tablet dead zone. The reading column is centred at 600
points, so on a wide screen most of the glass is beside it, and that glass belonged to no scroll
view: a finger there moved nothing while the list under the middle of the screen scrolled, which
reads as a frozen app. Both gutters now start a real drag on the page's own scroll position, so a
finger anywhere on the screen scrolls and flings. The phone layout is untouched — there the column
is the screen, and no gutter exists.

## Two minutes — 1.8.4

The accusation was the one screen with no clock. Three quests are won, the assassin wakes, and the
table has as long as it likes to argue. Everything else in the app already had a ring that starts,
pauses and restarts on tap; this release gives the accusation the same one, at two minutes.

The design question was whether the clock should be a rule. It is not: the table still records what
happened, even after zero. Blocking the outcome would make the app the referee of a social
conversation, and a table that needs a third minute would be stuck holding a phone that refuses to
listen. So zero says "Time's up", double-taps, and gets out of the way.

It starts itself when the screen opens. The screen already tells the MC not to touch the phone
during an accusation, so asking for a tap to start the clock would contradict its own copy — and a
clock nobody starts is a clock that silently does nothing.

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 358 tests pass (112 widget, 246 unit and database) |
| Clock | `endgame_test.dart` (+3): 2:00 down to 0:00 with the last ten seconds red, the ring pauses and resumes, restart returns to 2:00, and the outcome can still be recorded at zero |
| Voices | `voice_packs_test.dart` (+1): a capitalised folder is a voice, and every bundled folder is listed in `pubspec.yaml` |
| Device | **Galaxy A36 (SM-A366B) over USB**: installed over 1.8.3 and kept the saved match; the clock started itself at 2:00, paused and resumed from the ring, and reached 0:00 in red with **Time's up** while **Merlin survived** still opened its confirmation; the picker now lists **Dahlia**, **Grok** and **Okley**, each English 21/21 · Filipino 21/21 |
| Release APK | Signed **1.8.4+31** built (71.8 MB), zipaligned and verified with the release key; SHA-256 F85B043968DE6C25704063187B9D805536D5A2C2F4CF81EC69AFAF9CB0D43FBD |

A voice folder named `Grok` was invisible: bundled folder names were validated as lowercase, so the
manifest listed it, the catalogue dropped it, and nothing said why. Capitals are now accepted, and
the test that every bundled folder is in `pubspec.yaml` catches the other half of that mistake.

## No halo — 1.8.3

A fair question came back after 1.8.2: does this button look like AI slop? A gradient with a glow
is exactly the shape that look takes, so the face was audited against the usual signatures instead
of being defended.

| Signature | Result |
| --- | --- |
| Violet/blue gradient | No: one hue family, all existing tokens |
| Gradient text or shadowed type | No: flat `onGold`, about 8:1 on the mid face |
| Pill shapes or 24-point radii | No: `Radii.card`, the radius the cards use |
| Glassmorphism or blur panels | No |
| Shadow on everything | Only the two action faces — and see below |
| Motion for its own sake | No: 130 ms tied to the press |
| Raw colours in widgets | No: the sheen's transparent end is `AppColors.hairlineFade` |

One element failed. The 25% glow under the gold and destructive faces could not be seen against
the photographic plates at all; a decoration that neither reads nor does work is decoration that
should not be in the widget. It was removed, along with the two tokens that existed only for it,
and the face is now the gradient, the hairline and the top sheen. The button sits **in** the
artwork rather than floating over it.

`buttons_test.dart` gained one test so the halo cannot come back by habit: the button's own
`BoxDecoration` must have no `boxShadow` and must keep a gradient.

**Dialogs end in the same buttons as the screens.** `lib/core/widgets/dialog_actions.dart` is one
action block: the dominant action on top, a quiet way out under it, both full width. The vote
outcome, the quest result, the quest confirm, the voice-name prompt and the custom-delay dialog used
to end in bare `TextButton`s — or in a row — which read as links next to the gold actions behind
them. `ConfirmationDialog`, the two PIN prompts and Clear history were folded onto the same block,
so there is one action layout in the app rather than six near-copies.

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 354 tests pass (348 + 6; widget 109, unit and database 245) |
| Buttons | `buttons_test.dart` (6 tests): geometry and tap target, compact width, disabled and loading states, the outline and destructive faces, and the no-shadow rule |
| Device | **Galaxy A36 (SM-A366B) over wireless debugging**: installed over 1.8.2 on the phone; the quest record and result dialogs were walked, and Undo the result returned to the count with the cards kept |
| Release APK | Signed **1.8.3+30** built (66.5 MB), zipaligned and verified with the release key; SHA-256 77CC902BB3C88E1F5AF8CFBC94A4D5FE82D53BFF7026F80CB41BF188016B3958 |

## Struck gold — 1.8.2

The app worked; the buttons looked like coloured rectangles. This release is appearance only: no
new control, no new screen, no change to what any button does.

### What changed

- **One shared surface, `lib/core/widgets/button_frame.dart`.** `PrimaryButton`, `SecondaryButton`
  and `DangerButton` each choose a gradient, a rim colour, an optional glow and their content; the
  frame draws the face, the hairline border, the top sheen, the pressed state and the ripple. One
  place to change the look of every action in the app.
- **The face is lit, not flat.** A vertical gradient from `lightGold` through `gold` to `mutedGold`
  (diagonal would run out of light across a wide button), a 1.2-point sheen along the top edge with
  `AppColors.hairlineFade` at both ends, and a 20-point `goldGlow` shadow under it.
- **The press is physical.** The face scales to 0.98 and the content steps down 2 points for
  `Motion.micro`, then settles back.
- **Metrics.** Height 52 → 56, corner radius `Radii.input` (12) → `Radii.card` (16). `kMinTapTarget`
  is 48, so the taller face keeps a comfortable margin.
- **The outline action is filled** — `surfaceRaised` to `surface` with a `mutedGold` rim and a gold
  icon — so it reads as a button first and a secondary action second.
- **The destructive action matches** in `danger` to `dangerDeep` with a `dangerGlow`.
- New tokens in `AppColors`: `dangerDeep`, `hairline`, `hairlineFade`, `goldGlow`, `dangerGlow`.
  Nothing outside the palette; no inline colours in the widgets.
- Disabled actions dim to 45% instead of the previous 38–40%, so the label still reads.

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 353 tests pass (348 + 5; `test\widget` 108, `test\unit` + `test\database` 245) |
| Buttons | `buttons_test.dart` (5 tests): the gold action fills the row at 56 and its tap target is the whole face; a compact action sizes itself when the row offers unbounded width; a tap fires and a disabled face refuses it at 45% opacity; a loading action shows a spinner and refuses the tap; the outline and destructive faces share the same height and both fire |
| Preview | Rendered through a temporary golden with the real Cinzel and Inter fonts at 1080×1500, three iterations (flat gradient → diagonal → vertical + sheen + glow) before the design was settled |
| Device | **Passed on a Galaxy A36 (SM-A366B) over wireless debugging**: the signed release installed over 1.8.0 and every button was checked on the phone |
| Release APK | Signed **1.8.2+29** built (66.5 MB), zipaligned and verified with the release key, installed over 1.8.0 on the Galaxy A36 (SM-A366B) and opened; SHA-256 A7B22F8F6539FD3E3E6CE46CF2B700F50E31C5F5B29497659C7E811C8CF5F41E |

## The bar that would not leave — 1.8.1

The undo offer from 1.7.0 worked, then refused to go away. Confirming a team showed
"Quest team sent to the vote." with **Undo** over the vote count, and it was still there on every
screen afterwards.

### What caused it

`showSnackBar` is supposed to take a bar down after its duration. Under `MaterialApp.router` it
does not: the message clock lives in `ScaffoldMessengerState.build`, which is only reached while
the messenger's own route is current. Changing route means no build, and the clock is never armed —
so the bar has no timeout at all. A minimal `go_router` repro confirmed it, and that the bar stays
even when the messenger is poked:

| Variant | Bar after 9 s |
| --- | --- |
| SnackBar shown, no navigation | gone |
| Shown, then `context.go()` | still there |
| Shown in a post-frame callback after `context.go()` | still there |
| Own `Timer` calling `hideCurrentSnackBar` | gone |

### What changed

- **`lib/core/widgets/timed_snack_bar.dart`** — `showTimedSnackBar(messenger, bar)` shows the bar
  and closes it on its own clock. The clock is cancelled when the bar closes early, so an Undo tap
  or a newer message leaves nothing ticking.
- It is used by every `showSnackBar` in the app: the team proposal and its undo confirmation, the
  PIN saved/removed messages, the history delete result and the voice import result. All of them
  shared the same failure mode; only the proposal bar was loud enough to notice.
- The team screen passes the messenger it captured before `context.goNamed`, because the undo
  callback fires after that context is gone.

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 348 tests pass (347 + 1) |
| Undo bar | `team_selection_test.dart` (8 tests): the offer shows on the vote screen, Undo still returns to team selection with its confirmation, the confirmation clears itself, and the offer is gone nine seconds after it appears |
| Device | Not claimed for the 1.8.1 build itself: the phone dropped off wireless debugging during it. The same code was walked on the phone in **1.8.2**: the offer appears on the vote screen and is gone twelve seconds later |
| Release APK | Signed **1.8.1+28** built (66.5 MB), zipaligned, verified with the release key; SHA-256 00313985D57E7E7FE42E70F2C4A7953DD0E3553C863133159A516FBFD01D4058 |

## Hear it before you pick it — 1.8.0

Choosing a narrator by name alone was guesswork once there were two. Each row in the picker now
plays a line.

### What changed

- **A play button per voice** (`voice_pack_picker.dart`). It plays the first id the pack has —
  `night.close_eyes`, the line that opens every match — at the volume from settings, and flips
  to a stop icon while it runs. A second tap stops it; so does closing the dialog, via the
  clip service captured in `initState` (Riverpod forbids touching `ref` in `dispose`).
- **`samplePathFor(pack, language)`** prefers the table's language and falls back to the other,
  so a voice that only recorded Filipino still samples instead of showing a dead button. A pack
  with no recordings shows a muted icon.
- The button reuses `clipServiceProvider`, so tests record what was asked to play and no
  platform channel is touched.

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 347 tests pass (343 + 4) |
| Picker | `voice_picker_test.dart` (+4, 9 tests total): the shipped voice plays Dahlia's asset path, an imported voice plays its own, Filipino picks the `fil` file, a one-language voice falls back, a silent pack cannot be sampled, and closing stops the clip |
| Device | Walked on the Galaxy A36 (SM-A366B) with 1.8.0+27: the button flips to a stop square, `dumpsys audio` shows the app's `MediaPlayer` at `state:started` (44.1 kHz), tapping the other voice stops the first, and closing the list leaves no player running |
| Release APK | Signed **1.8.0+27** built, zipaligned, verified with the release key and installed over 1.7.2 |

## Okley — 1.7.2

The second narrator arrived as 28 MP3s — all 14 night lines in both languages — dropped into
`assets/audio/narration/Okley/`. That folder is storage: the app only bundles the voice named
by `NarrationClips.voice` and the packs under `assets/audio/voices/`. The set was moved to
`assets/audio/voices/okley/` (lowercase, the id rule for pack folders), named by `voice.json`,
and its two language folders were added to `pubspec.yaml`.

### What changed

- **Okley is a bundled voice**, listed in **Settings → Narrator voice** beside **Dahlia**.
  Choosing it plays Okley for every line; the choice is stored, and Dahlia remains the default.
- **Two guards for bundled voices.** `voice_packs_test.dart` now fails when a folder on disk is
  missing from `pubspec.yaml`, and when Okley's set is not exactly the 14 ids in both languages
  or its name does not read as Okley. The first is the failure mode that makes a voice silent
  rather than wrong: Flutter asset folders are not recursive.

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 343 tests pass (341 + 2) |
| Voice catalogue | `voice_packs_test.dart` (19 tests): the folder is listed, both languages carry the full set, the pack is named Okley |
| Device | `clip_playback_test.dart` passes on the Galaxy A36 (SM-A366B); the release app lists **Dahlia** and **Okley**, each English 14/14 · Filipino 14/14, and choosing Okley survives the dialog |
| Release APK | Signed **1.7.2+26** built (66.5 MB), zipaligned, verified with the release key and installed over 1.7.1; SHA-256 `f8db5469…1804ed28` |

## Dahlia's folder — 1.7.1

The narrator is Dahlia, and her recordings are now filed under her name so the narration folder
can hold more than one voice without a second folder convention.

### What changed

- `assets/audio/narration/Dahlia voices/{en,fil}/` holds the 28 recordings; `NarrationClips`
  names the folder once (`voice`) and builds `directory` from it, and `pubspec.yaml` lists the
  two language folders. `VoicePackCatalogue` reads the `<voice>/<lang>/<id>.mp3` layout.
- The built-in voice is listed as **Dahlia** in **Settings → Narrator voice**
  (`VoicePackCatalogue.classicName`).
- Extra narrators still live under `assets/audio/voices/<pack>/`; a second folder inside
  `narration/` is not played, and the narration README says so.

### Fixed on the way

- **The space in the folder name broke playback.** Flutter stores asset keys percent-encoded in
  the APK, so the folder is `Dahlia%20voices` inside `flutter_assets`. The host tests passed
  because they read the files from disk; the device gate failed because `AssetManager.openFd`
  was given the readable path and every line fell back to text-to-speech. `MainActivity.assetKey`
  now encodes the key before opening it.

### Gate evidence

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 341 tests pass |
| Narration tests | `narration_clips_test.dart`, `narration_controller_test.dart` and `voice_packs_test.dart` (51 tests) pass against the new paths |
| Device | `clip_playback_test.dart` passes on the Galaxy A36 (SM-A366B): the English and Filipino lines decode from `Dahlia%20voices` in the APK |
| Release APK | Signed **1.7.1+25** built (64.0 MB), zipaligned, verified with the release key and installed over 1.7.0 on the Galaxy A36; SHA-256 `d22b36cc…74b6b57` |

## At the table - 1.11.0

Phase 1 of the Table Mode proposal in **`docs/table-mode.md`**, and only Phase 1:
a room, a code, a QR, names, live seats and reconnect. No characters are dealt,
nothing is voted on, and the solo game is untouched.

The device on the table opens a room and shows a six-character code with a QR.
Every other phone types the code — or scans it — gives a name, and takes the
lowest free seat. The board lists who is at the table and whether they are still
connected. A phone that loses Wi-Fi comes back to its own seat, with its name,
when the network returns; a phone that leaves gives the seat up at once.

Two apps, one protocol. Phase 1 forced that decision: a host has to work on a
phone as well as a tablet, and the solo app carries a database, voice packs and
settings that a board has no use for. The board is now its own small app,
**Virtual Avalon** (`com.virtualavalon.app`), and this app keeps the player side.
Its own host screens still work and are still tested, but they are superseded
and are scheduled for removal once the split has been used on real hardware.

| Decision | Choice |
| --- | --- |
| Platform | **Android only**: two APKs, no iOS build, no web client, no store |
| Player client | This app, in player mode. The board is `Virtual Avalon` |
| Publishing | GitHub releases only |
| Host device | A phone or a tablet. Desktop boards are out of scope |
| Seats | Join order, no accounts |
| Characters | Not in Phase 1 at all. A seat is a number, a name and a presence flag |
| Engine | `GameState` gained no field. Table Mode never imports the match engine |

Phases, each with a stop condition:

| Phase | Content | Stop if |
| --- | --- | --- |
| 1 | **Shipped.** Room: host, Join, QR, name, live seats, reconnect. No characters | Joining takes longer than ~15 s per player, or a phone cannot reach the host |
| 2 | Cast picker, sealed deal, hold-to-reveal hand | A character reaches the board, the history file or a log |
| 3 | Approve / reject from phones | A vote needs the board touched |
| 4 | Secret quest cards, Assassin from their phone | A match needs the board touched |
| 5 | Board skin, narration on the host | It still reads as a settings page |

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 511 tests pass (130 widget, 381 unit and database); 393 before Table Mode |
| Privacy | `table_privacy_test.dart` reads the source: no Table Mode file names a character, a role or an allegiance, no seat carries more than seat/name/connected, and the board screen never sees a token |
| Probe, loopback | 8 synthetic phones: slowest join 722 ms, a dropped phone back at its seat in 11–28 ms, 8 of 8 still seated after a minute |
| Device | **Galaxy A36 (SM-A366B) over USB, real Wi-Fi**: this app on the phone joined a board on the PC by typing its address — seat 1, name MARC, CONNECTED. Wi-Fi off → "Lost the board — reconnecting (3)…"; Wi-Fi on → the same seat 1 on a new TCP socket. Leave → seat released, socket closed |
| Discovery | **Works phone to phone.** On 2026-11-27 the A32 typed the A36 board's code and found it on the first attempt, with no PC and no firewall in the path. The earlier "Nothing on this Wi-Fi answered for ABC234" was the PC's firewall dropping the UDP announcement, not the protocol |
| Camera | **Works.** With the board restarted under a new code (`WAZ V6S`), the A32 scanned the QR and filled in the new code with nothing typed. Negative control first: with the board stopped and the QR out of view, the scanner stayed open on a live preview and decoded nothing |
| Second phone | **Two real phones at one table**: A36 hosting, A32 joining by code and by scan, seat 1 both times, and a leave that put the board back to "0 of 14" |
| Wi-Fi drop | **A32 client, A36 host**: Wi-Fi off → "Lost the board — reconnecting (5)…"; Wi-Fi on → seat 1, MARC, CONNECTED again with nothing retyped. The host's own Wi-Fi address changed during the run (`.3` → `.10`) and the board kept publishing the old one — a known limit, recorded in the board repo |
| Release APK | Signed **1.11.0+35** (89.2 MB, up from 71.8 MB because the camera scanner bundles ML Kit); SHA-256 `1C6F19C825287B1B23821F2D8DE068A0DC7D5454D2D212A1CFCBC56447D880DC`; permissions `INTERNET`, `CAMERA`, `ACCESS_NETWORK_STATE`, with `android.hardware.camera` marked not required |

Not tested, and said plainly: a real tablet. Seats 2–14 are covered by the
synthetic clients, not by people.

Traps worth keeping:

- A developer machine with `http_proxy` set sends Dart's socket through it and a
  LAN room answers 502. Both probes build their own `HttpClient` with
  `findProxy = 'DIRECT'`.
- A machine with a VirtualBox adapter advertises that adapter's address instead
  of Wi-Fi unless the interface matcher knows the Windows name `Wi-Fi`.
- `TableClient.dispose()` closes the socket **before** cancelling the incoming
  subscription; cancelling first tears down TCP and loses the leave frame, and
  the board keeps a seat nobody is sitting in.

## Signed, dated - 1.10.1

Two lines in the About panel were saying the wrong thing.

The first named nobody: "Design and build: Avalon Companion project". A project is not an author, and
the one person who wrote every screen had no line in their own app. It now reads "Design and build:
Akiprofit", with the Cinzel and Inter acknowledgment left as it was.

The second said too much. The version row read "1.10.0 · Phase 12", and the phase had been frozen
since 1.0.0 ten releases earlier. A phase number is a build-plan coordinate; it means nothing to a
player who opened Settings to check which APK they installed, and a stale one is worse than none. The
row is now the version alone, and `AppInfo.buildPhase` is deleted rather than left as a constant
nothing reads.

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 393 tests pass (120 widget, 273 unit and database) |
| Version | `app_info_test.dart` still matches `AppInfo.version` to `pubspec.yaml` (1.10.1) |
| Device | **Galaxy A36 (SM-A366B) over USB**: 1.10.1+34 installed over 1.10.0; Settings → About reads **1.10.1** with no phase suffix, and Credits read "Design and build: Akiprofit" |
| Release APK | Signed **1.10.1+34** release build (71.8 MB); SHA-256 673644FBDA6DA6DF3317C08ECACCD4C01E6DC49F3CD503E269D640BF3B10293D. A stray 216 KB PDF that had appeared in `assets/audio/voices/Grok/fil/` was moved out before this build, so the asset tree holds only the voice recordings again |

## Next phase

No phase is scheduled: **1.11.0** is the current build (2026-11-26). It adds Phase 1
of Table Mode — a room, a code, a QR and live seats, with no characters — and with
it the two-app split: the board is now its own app, `Virtual Avalon`. Phases 2–5
(cast picker, sealed deal, votes, quest cards, board skin) are not built and are
not scheduled. The 1.10.1 About-panel fix, 1.10.0's big table, 1.9.0's round cues
and 1.5.0's voice packs ship inside it, and 1.0.0–1.3.1 remain
verified on the phone. The
voice import still needs a real zip — Okley proves the bundled path, not the import path. Work
after that is maintenance rather than plan phases — lifting the `path_provider_android` pin now
that the NDK is installed, split-per-abi APKs if download size matters (the camera scanner took the
universal APK from 71.8 MB to 89.2 MB), commissioned artwork to
replace the public-domain plates, or a Play Store listing with its own upload key.
