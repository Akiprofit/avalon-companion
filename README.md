# Avalon Companion

An offline Android companion app that acts as the Game Master for physical games of
**The Resistance: Avalon**.

One person — the MC — holds the phone. Everyone else plays with the physical Avalon cards.
The app narrates the night, tracks the public state of the match, and does the arithmetic.
It never learns who holds which character, because it never asks: there is no
player-to-role mapping anywhere in the app or its storage.

## Status

Phase 8 of 12 is implemented: day discussion, team selection, the physical vote, quest
resolution, the assassination and both victory screens. A match can be created for 5–10
players, the night is spoken aloud by the phone in English or Filipino — English in a British
narrator voice with deliberate pauses — the MC runs the discussion timer, proposes a quest
team, records the table's vote and the success and fail cards that come back from the quest.
The engine applies the quest 4 two-fail rule, keeps the score and decides when the match is
over; the accusation records only whether Merlin was named, and the result screen summarises
the match without ever naming a player. Phases 5, 6 and 8 have been verified on a Galaxy A36;
Phase 7 passes its automated gates and is waiting for the next device pass. Saved matches,
history and settings persistence arrive next. See `DEVELOPMENT_PLAN.md` for the phase table,
`DESIGN_SYSTEM.md` for the visual system and `CHANGELOG.md` for what has shipped.

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
```

## Build the APK

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Project layout

```text
lib/
  app/                 bootstrap, MaterialApp, router, splash
  core/                theme tokens, constants, shared components
  features/            home, setup, preparation, narration, dashboard, history, settings
  game_engine/         models, rule tables, session controller
  narration_engine/    script data, narration controller, TTS abstraction
test/
  unit/                rule tables, engine, privacy guards, narration sequence and playback
  widget/              navigation and layout
```

Rules live in `lib/game_engine/` as pure Dart. No Flutter import is allowed there, which
is what makes the rule tests fast and the rules independently verifiable.

## Privacy

- No player-to-character mapping, ever.
- Assassination records an outcome, not a person.
- No analytics, no network calls, no cloud sync.
- All data stays on the device.

## Credits

Typography: Cinzel by Natanael Gama and Inter by Rasmus Andersson, both under the SIL Open
Font License. See `assets/fonts/OFL-Cinzel.txt` and `assets/fonts/OFL-Inter.txt`.

Unofficial fan-made companion. Not affiliated with or endorsed by the publisher of
The Resistance: Avalon.
