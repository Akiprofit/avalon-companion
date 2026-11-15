# Avalon Companion

An offline Android companion app that acts as the Game Master for physical games of
**The Resistance: Avalon**.

One person — the MC — holds the phone. Everyone else plays with the physical Avalon cards.
The app narrates the night, tracks the public state of the match, and does the arithmetic.
It never learns who holds which character, because it never asks: there is no
player-to-role mapping anywhere in the app or its storage.

## Status

Phase 10 of 12 is implemented, plus three settings that came after it: the finished product,
until the QA and release passes. A match can be created for 5–10 players, the night is spoken
aloud by the phone in English or Filipino — English in a British narrator voice with deliberate
pauses, now chosen from the voices actually installed on the phone — the wheel draws the first
Lord (and, with the automatic King mode, the King of every round), and the MC runs the
discussion timer, proposes a quest team, records the table's vote — or skips it — and the
success and fail cards that come back from the quest. The engine applies the quest 4 two-fail
rule, keeps the score and decides when the match is over; the accusation records only whether
Merlin was named, and the result screen summarises the match without ever naming a player.
**Play Again** deals the same table a fresh match and puts the round table straight back in front
of the MC.

Every confirmed action is written to an on-device SQLite database, so an interrupted match
reopens where it stopped: the app offers **Continue Game** at launch with the phase, quest and
roster already restored. **History** lists finished and abandoned matches with their quest
record and outcome, and can clear them — a chosen number of the oldest, or all of them, with a
match still in progress always kept. Settings persist across restarts. Nothing is uploaded and
no account is needed; the database never holds a character for a player, because the app is never
told one.

At the table the phone keeps its screen on during a live match, ticks and vibrates on confirmed
actions, and can loop a low night ambience under the narration. An optional **MC PIN** locks
Settings and Abort behind a salted digest — a lock on the table, not encryption — while the
match itself stays playable without it. The UI survives a 200% text scale, honours Android's
reduced-motion setting, and keeps every control at least 48 dp.

Two further settings shape the flow. **King selection mode** chooses whether the wheel spins by
itself at the start of every round (a new King each quest, never the same player twice in a row
while others can lead) or only when the MC asks for it. **Narrator extra delay** adds 0–20
seconds of silence after every spoken line, counted from the moment the voice stops, so the
table has time to move its physical cards. A third, **Team approval vote**, can be switched
off for a house rule: the leader's team then goes straight to the quest, rejections are never
counted, and the token still passes on when the quest is resolved.

Every phase has been verified by automated gates — `flutter analyze`, 257 unit and widget tests,
two on-device integration tests — and on a Galaxy A36 (Android 16) through a signed 1.0.0 release
build. See `DEVELOPMENT_PLAN.md` for the phase table, `DESIGN_SYSTEM.md` for the visual system and
`CHANGELOG.md` for what has shipped.

## Requirements

- Flutter stable (developed against Flutter 3.50 / Dart 3.14)
- Android SDK with JDK 17 or newer
- No network access needed at runtime

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
flutter test integration_test -d <device-id>   # real app on a phone, real database
```

## Build the APK

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`, about 60 MB — the
Flutter engine for arm64, arm and x86_64, stripped.

The release build is signed with the keystore named in `android/key.properties`
(gitignored). That file points at a keystore outside the repository:

```properties
storePassword=…
keyPassword=…
keyAlias=avalon
storeFile=C:/Users/<you>/.avalon/avalon-release.jks
```

Without it Gradle falls back to the debug key, which still installs for testing
but cannot be published or updated over an install signed with the real key.
Keep the keystore and its passwords somewhere safe: Android refuses an update
signed with a different key, so losing them means a new package identity.

### Check the signature and alignment

```powershell
$bt = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0"
& "$bt\zipalign.exe" -c -p 4 build\app\outputs\flutter-apk\app-release.apk
& "$bt\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

`zipalign -c` is silent and exits 0 when the APK is aligned; `apksigner verify`
prints the signer. The build strips Flutter's engine libraries with the NDK
pinned in `android/app/build.gradle.kts` (`ndkVersion`); without that NDK the
strip step fails the build. On a machine that has no NDK, set
`AVALON_KEEP_SYMBOLS=1` to skip stripping instead — the APK grows to about
500 MB and is only for local testing. Stop the Gradle daemon after changing the
variable (`android\gradlew.bat --stop`), or it keeps the old environment.

## Install on a phone

1. Enable **Developer options → USB debugging** and connect the phone.
2. `adb devices` must list it.
3. Install or update without losing the saved match and settings:

   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

4. First install from a file also works: copy the APK to the phone and open it,
   allowing "install unknown apps" for the file manager.
5. `adb install -r` keeps the database; uninstalling removes every saved match,
   the history and the settings.

## Project layout

```text
lib/
  app/                 bootstrap, MaterialApp, router, splash
  core/                theme tokens, constants, shared components, app settings model
  database/            Drift schema, repositories, storage providers
  features/            home, setup, preparation, narration, dashboard, history, settings
  game_engine/         models, rule tables, session controller
  narration_engine/    script data, narration controller, TTS abstraction
test/
  database/            the real schema, against in-memory SQLite
  unit/                rule tables, engine, privacy guards, narration, persistence, settings
  support/             in-memory match store and other fakes
  widget/              navigation and layout
integration_test/      on-device run of the real app against the real database
tool/                  make_icons.ps1, which regenerates every launcher and splash PNG
```

Rules live in `lib/game_engine/` as pure Dart. No Flutter import is allowed there, which
is what makes the rule tests fast and the rules independently verifiable.

Storage lives in `lib/database/`. The session controller talks to the `MatchStore` interface,
never to Drift, so the live match is testable with a fake and still runs on a device where the
database file cannot be opened — persistence is a side effect, never a dependency.

## Privacy

- No player-to-character mapping, ever.
- Assassination records an outcome, not a person.
- No analytics, no network calls, no cloud sync.
- All data stays on the device, in a single SQLite file.
- Saved matches store the roster, the public state and the outcome. There is no character,
  role or allegiance column on a player, so the history screen has nothing to leak.

## Credits

Typography: Cinzel by Natanael Gama and Inter by Rasmus Andersson, both under the SIL Open
Font License. See `assets/fonts/OFL-Cinzel.txt` and `assets/fonts/OFL-Inter.txt`.

Unofficial fan-made companion. Not affiliated with or endorsed by the publisher of
The Resistance: Avalon.
