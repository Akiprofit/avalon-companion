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
| Signature | `CN=Android Debug`, because `android/key.properties` is not in this checkout. The APK cannot update the release-signed 1.0.0 on the phone until the keystore passwords are restored, so nothing was installed |
| Engine | `test/unit/engine_test.dart`: the team is kept with its result, each quest keeps its own team in play order, and a later quest does not overwrite an earlier one |
| Persistence | `test/database/game_repository_test.dart`: two different teams survive a save and a reload in the right order; schema v6 migrates v5 rows |
| Widget | `test/widget/quest_log_test.dart` (3): a played quest lists its names and seats, the section is absent before the first quest resolves, and a second quest adds its row |
| Narration | `test/unit/narration_controller_test.dart` (6 new): clip before engine, the Filipino folder, volume and speed reach the player, a finished clip advances like speech, an unplayable clip falls back, and a recorded line needs no installed voice |

Known limits:

- The round lines are still unrecorded and unplayed; if they are turned on later they will need
  the same treatment to avoid a change of narrator mid-match.
- The teams are only kept from v6 onwards. Matches finished before this build show their quest
  results but not their teams, because the seats were never stored.

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

## Cross-cutting known issues

- A match that is interrupted mid-vote restores its proposed team but starts the tally again
  from zero. That is deliberate: the app never stores a partial vote, and re-counting hands is
  safer than trusting a half-written tally. Re-counting is a few seconds at the table.
- The 1.1.0 checkout has no `android/key.properties`, so any local release build is signed with
  the debug key and cannot update the release-signed 1.0.0 on the phone. Restoring the keystore
  password and alias (keystore at `C:/Users/Marc/.avalon/avalon-release.jks`, alias `avalon`)
  makes the release build upgradeable again.
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
- `build/` is a junction to `%LOCALAPPDATA%\Temp\avalon_build` because this project lives in a
  OneDrive folder and the sync client kept a handle on `build\app\intermediates`, failing the
  Android build with "Unable to delete directory". Anything that deletes `build/` should keep the
  junction (or recreate it with `mklink /J build %LOCALAPPDATA%\Temp\avalon_build`).
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

## Next phase

No phase is scheduled: **1.0.0** is the released build, signed, installed and verified on the
phone. Work after 1.0.0 would be maintenance rather than plan phases — lifting the
`path_provider_android` pin now that the NDK is installed, split-per-abi APKs if download size
matters, commissioned artwork to replace the public-domain plates, or a Play Store listing with
its own upload key.
