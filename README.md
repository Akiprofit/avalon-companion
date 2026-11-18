<p align="center">
  <img src="docs/icon.png" alt="Avalon Companion app icon" width="140" />
</p>

<h1 align="center">Avalon Companion</h1>

<p align="center">
  <em>The Game Master, in your pocket.</em>
</p>

<p align="center">
  <a href="https://github.com/Akiprofit/avalon-companion/releases/latest">
    <img alt="Download the Android APK" src="https://img.shields.io/badge/Download-Android%20APK-C5A15B?style=for-the-badge&logo=android&logoColor=0B0E14" />
  </a>
  <img alt="Version 1.5.0" src="https://img.shields.io/badge/version-1.5.0-0B0E14?style=for-the-badge" />
  <img alt="Offline first" src="https://img.shields.io/badge/offline-first-3D9B72?style=for-the-badge" />
</p>

**Avalon Companion** is an offline Android app that acts as the Game Master for
physical games of **The Resistance: Avalon**. One person — the MC — holds the
phone; everyone else plays with the physical cards. The app narrates the night
in **English and Filipino**, tracks the public state of the match, and does the
arithmetic.

It never asks who holds which character, so it cannot leak one. There is no
player-to-role mapping anywhere in the app or its storage — not on screen, not
in the database, not in a saved match.

No account. No ads. No network calls. Matches, history and settings stay in one
SQLite file on the device.

---

## Download

The latest signed Android APK is on the
[**Releases page**](https://github.com/Akiprofit/avalon-companion/releases/latest).

- Android **7.0 and newer**
- Works completely offline
- Release build signed for installation outside the Play Store
- One APK for arm64, arm and x86_64

### Install on Android

1. Download `Avalon-Companion-1.5.0.apk` from the latest release.
2. Open the downloaded APK.
3. Allow **Install unknown apps** for the browser or file manager you used.
4. Tap **Install**.
5. If Play Protect shows a warning, choose **Install anyway** — only do this if
   you trust the source.

> **Updating:** install a newer APK over the old one. Keep the same package and
> signing key. Updating keeps every saved match, the history and the settings.
> Uninstalling the app deletes them.

### Install over USB (optional)

1. Enable **Developer options → USB debugging** and connect the phone.
2. `adb devices` must list it.
3. Install or update without losing anything:

   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

---

## Features

### The night, read aloud

- **28 recorded lines** — every night line exists in **English** and in
  **Filipino**, bundled inside the APK (2.6 MB, stored uncompressed so
  `MediaPlayer` can open them)
- The phone's text-to-speech is the **fallback narrator**, used only for a line
  with no recording or a clip that cannot play
- **Play / pause, next, previous, replay**, in a transport row that keeps the
  line-by-line controls together, plus speed, depth and volume for the fallback
  voice; **End night** is a separate labelled action in the app bar behind a
  confirmation, so it cannot be hit while reaching for next
- **Narrator extra delay:** 0–20 seconds of silence after every line, counted
  from the moment the voice stops, so the table has time to move its cards
- **Narrator voices are packs, not files.** Import a voice as a `.zip` holding
  an `en/` folder, a `fil/` folder, or both; name it — *Voice of Dahlia* — and
  it reads the night. The shipped narrator can be renamed or hidden, and an
  imported voice can be deleted again along with its recordings. Any line a
  voice did not record falls back to the phone, so a half-finished set still
  works
- A low night ambience can loop under the narration
- The screen stays on during a live match; confirmed actions tick and vibrate

### The match

- Create a match for **5–10 players** with physical cards at the table
- The **wheel** draws the first Lord; with the automatic King mode it draws the
  King of every round — never the same player twice in a row while others can
  lead, or only when the MC asks
- Discussion timer as a **ring** that starts, pauses and restarts on tap, turns
  red and clicks at 10 seconds, and double-taps at zero — no counting down with
  the phone face down
- Team proposal, then the table's vote **by seat**: tap each seat approve or
  reject once, tap again to clear it; *Resolve* waits until every seat is
  counted. Skip the vote for a house rule, where the leader's team goes straight
  to the quest
- Record the success and fail cards that come back; the engine applies the
  **quest 4 two-fail rule**, keeps the score and decides when the match is over
- The accusation records **whether Merlin was named**, never a person
- The result screen summarises the match without naming a role, and **Play
  Again** deals the same table a fresh match
- Every confirmed action is written to SQLite, so an interrupted match reopens
  with **Continue Game** at the phase, quest and roster it stopped on; home
  leads with a live-match card and keeps **New Game** as the secondary action
- The dashboard roster is a **two-column grid of seats** — number, name, leader
  crown and the current quest team — and the whole table reads at once
- **The quests** is one board: the five markers, then the team that went on each
  resolved quest, exactly as the table saw it. The same board closes the result
  screen
- **History** lists finished and abandoned matches, and a tap opens the record:
  result, quest tally, rejected proposals and the team on each quest. Seats
  only — no names, no roles. **Long-press a match to select it**, long-press or
  tap more to build a selection, then delete just those; **Select all** skips
  the match in progress, which is always kept. The list-wide clear dialog can
  still remove the oldest N or everything
- **Selection feels physical:** a long press buzzes, the card dips and lifts
  with a gold border and a springing check, the header counts the selection, and
  deleted cards collapse out of the list
- **Use the last table** on setup restores the player count and every name from
  the most recent match, still editable — names only, no roles

### Settings and table tools

- **MC PIN** locks Settings and Abort behind a salted digest — a lock on the
  table, not encryption — while the match stays playable without it
- **Language:** English or Filipino, switchable at any time; changing it never
  restarts a match
- **Fallback voice:** speed, depth and volume for the text-to-speech narrator
- **Extra delay after each line:** 0–20 seconds, also settable during a match
- **Automatic narration** and **ambient audio** beneath it
- **King selection mode:** automatic every round, or only when the MC asks
- **Team approval vote** on or off
- **Default player count** and **discussion timer** length
- **Keep screen awake**, **confirmation dialogs**, **haptic feedback** and
  **sound effects**
- A match in progress and every setting survive a restart

### Designed for Android

- **Tablet support:** the same layout everywhere, centred in a 600 dp reading
  column on a wide screen — no stretched cards, no second layout to learn
- Survives a **200% text scale**; honours Android's **reduced-motion** setting
- Every control is at least **48 dp** tall
- Safe areas, keyboard-aware setup form, and the system Back button are handled
- Adaptive launcher icon that fits circular, rounded and squircle masks

### Private by default

- No player-to-character mapping, ever
- Assassination records an outcome, not a person
- No account, no analytics, no ads, no cloud sync, no server calls
- All data stays on the device, in a single SQLite file
- Saved matches store the roster, the public state and the outcome — including
  the seats that went on each resolved quest, which the whole table already saw.
  There is no character, role or allegiance column on a player, so the history
  screen has nothing to leak

---

## Tech stack

- **Flutter** stable (developed against Flutter 3.50 / Dart 3.14)
- **Riverpod** for state
- **Drift + SQLite** for matches, history and settings (schema v7)
- **go_router** for navigation
- **Kotlin MethodChannel + `MediaPlayer`** for the recorded narrator
  (`com.avalon.companion/clips`); **flutter_tts** as the fallback voice
- **Kotlin MethodChannel + `archive`** for importing a voice
  (`com.avalon.companion/voices`): the system file picker hands over a zip,
  which is unpacked on the device — nothing is uploaded
- No network access needed at runtime

Rules live in `lib/game_engine/` as pure Dart. No Flutter import is allowed
there, which is what makes the rule tests fast and the rules independently
verifiable.

Storage lives in `lib/database/`. The session controller talks to the
`MatchStore` interface, never to Drift, so the live match is testable with a
fake and still runs on a device where the database file cannot be opened —
persistence is a side effect, never a dependency.

---

## Run locally

Requirements:

- Flutter stable
- Android SDK with JDK 17 or newer
- A connected Android device or emulator

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
flutter test integration_test -d <device-id>   # real app on a phone, real database
flutter test integration_test/clip_playback_test.dart -d <device-id>  # narrator audio decodes
```

The device run installs a debug build and Flutter uninstalls it afterwards, so
the phone's saved matches do not survive it. Debug builds are signed with the
release key when `android/key.properties` exists, which lets them install over
the release app in the first place.

---

## Build the Android app

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The signed APK is written to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

About 63 MB — the Flutter engine for arm64, arm and x86_64, stripped, plus the
28 narrator recordings. The build strips the engine libraries with the NDK
pinned in `android/app/build.gradle.kts` (`ndkVersion`); without that NDK the
strip step fails the build. On a machine that has no NDK, set
`AVALON_KEEP_SYMBOLS=1` to skip stripping instead — the APK grows to about
500 MB and is only for local testing. Stop the Gradle daemon after changing the
variable (`android\gradlew.bat --stop`), or it keeps the old environment.

### Release build

Release signing is configured through `android/key.properties`, which is
intentionally excluded from Git along with the keystore. The file points at a
keystore outside the repository:

```properties
storePassword=…
keyPassword=…
keyAlias=avalon
storeFile=C:/Users/<you>/.avalon/avalon-release.jks
```

Without it Gradle falls back to the debug key, which still installs for testing
but cannot be published or updated over an install signed with the real key.

> Keep the keystore and its passwords backed up. Android refuses an update
> signed with a different key, so losing them means a new package identity.

### Check the signature and alignment

```powershell
$bt = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0"
& "$bt\zipalign.exe" -c -p 4 build\app\outputs\flutter-apk\app-release.apk
& "$bt\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

`zipalign -c` is silent and exits 0 when the APK is aligned; `apksigner verify`
prints the signer.

---

## Project structure

```text
lib/
  app/                 bootstrap, MaterialApp, router, splash
  core/                theme tokens, constants, shared components, app settings model
  database/            Drift schema, repositories, storage providers
  features/            home, setup, preparation, narration, dashboard, history, settings
  game_engine/         models, rule tables, session controller
  narration_engine/    script data, narration controller, recorded clips, TTS fallback
assets/
  audio/narration/     the narrator's recordings: en/ and fil/, one MP3 per night line
  audio/voices/        extra bundled voices, one folder per voice (see its README)
  images/              the seven public-domain environment plates
test/
  database/            the real schema, against in-memory SQLite
  unit/                rule tables, engine, privacy guards, narration, persistence, settings
  support/             in-memory match store and other fakes
  widget/              navigation, layout, tablet sizes and flow gates
integration_test/      on-device run of the real app against the real database
tool/                  make_icons.ps1, which regenerates every launcher and splash PNG
docs/icon.png          the app icon used by this README
```

---

## Status

**v1.5.0** — Narrator voices. The night can be read by a voice the MC adds,
not only the one that ships: import a zip of recordings, name it, hide the
shipped voice, delete an added one. A pack covers the lines it has and falls
back to the phone for the rest, line by line.

**v1.4.0** — History selection. Long-press a finished or abandoned match to
buzz, select it and delete it with others; select-all never includes the match
in progress. Selection, deletion and the list's arrival are animated, and the
About panel now reports the real version.

**v1.3.1** — Device-pass fixes. The night title fits beside **End night**, and
an unfinished match's record no longer says the match ended.

**v1.3.0** — UI/UX pass. Nine table-side changes: vote by seat,
the discussion ring, separated night controls, one quest board, a two-column
roster grid, a live-match home hero, a history detail sheet, **Use the last
table**, and real empty states. No rule, engine or stored value changed.

**v1.2.0** — Tablet layout. The `AvalonScreen` shell bounds the body to a
600 dp column and centres it, and bottom action bars keep the same width, so a
tablet shows the phone UI in the middle of the glass instead of stretching every
card and line of text. Covered at 800×1280 and 1280×800 in widget tests. No
physical tablet was available.

**v1.1.0** — Recorded narrator and past quest teams. The night is read by the
recordings made for the app — 14 lines in English, 14 in Filipino — instead of
the phone's voice, and every resolved quest keeps the team that went on it.
Drift schema v6 adds `games.questTeams`; a match finished before this build
shows its quest results but not its teams.

**v1.0.0** — The first signed release: 5–10 players, the narrated night, the
wheel and King selection, the discussion timer, team proposal and vote, quest
resolution and the 4th-quest two-fail rule, assassination outcome, results,
history, resume, settings and the MC PIN.

Every phase is verified by `flutter analyze`, **325 unit and widget tests**, and
three on-device integration tests on a Galaxy A36 (Android 17) through signed
1.0.0, 1.1.0 and 1.2.0 builds; 1.3.0, 1.3.1 and 1.4.0 were installed and driven
by hand on the same phone. Tablet sizes are covered by widget tests only.
See [`DEVELOPMENT_PLAN.md`](DEVELOPMENT_PLAN.md) for the phase table,
[`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) for the visual system and
[`CHANGELOG.md`](CHANGELOG.md) for what has shipped.

---

## License

MIT — see [`LICENSE`](LICENSE). Use it, change it, ship it; keep the copyright
notice.

The bundled paintings are public domain (their artists died more than 70 years
ago) and were sourced from Wikimedia Commons; `DESIGN_SYSTEM.md` §7 credits
them. The fonts are under the SIL Open Font License.

## Credits

Typography: **Cinzel** by Natanael Gama and **Inter** by Rasmus Andersson, both
under the SIL Open Font License. See `assets/fonts/OFL-Cinzel.txt` and
`assets/fonts/OFL-Inter.txt`.

The app is an unofficial fan-made companion: not affiliated with or endorsed by
the publisher of *The Resistance: Avalon*, and the Avalon name is used only to
describe what the app accompanies.

Built for tables that would rather argue about the quest than do the bookkeeping.
