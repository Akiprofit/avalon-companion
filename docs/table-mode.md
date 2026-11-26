# Table Mode — design proposal

**Status:** proposed, not approved, not scheduled. Nothing in this document is
built. It exists so the decisions can be argued with before any code is written.

**One line:** the Android device on the table becomes the board, everyone else
joins it from the same app on their own Android phone, and characters are dealt
privately to each phone.

**Platform:** Android only. No iOS build, no `.ipa`, no web client, no store.

> **Decision update (2026-11-26): the board is its own app.** Everything below
> about the room, the protocol, the seat projection and the phases still holds.
> What changed is §3: the board no longer ships inside Avalon Companion. It is
> **Virtual Avalon**, a separate project and repository
> (`C:\Virtual Avalon`, application id `com.virtualavalon.app`), documented in
> that repo's `docs/board-app.md`.
>
> Why: a board binary that contains no character data, no database and no
> settings row cannot leak a role, and that is a structural guarantee rather
> than a code-review habit. It also removes the per-device role switch from the
> companion, which keeps the solo app a solo app.
>
> Consequences for this document:
>
> - The board has no Home screen and no router; launching it opens a room.
> - The board is host-capable on any device, phone or tablet. On a phone the
>   lobby is one column with a smaller QR; nothing is tablet-only.
> - Avalon Companion keeps the player side only: join by code or QR, take a
>   seat, reconnect to the same seat.
> - The `table_role` setting in the companion (`solo` / `board` / `player`) is
>   now only a way to reach the player screens; a phone that hosts runs the
>   other app.
> - §3's "install at the table" APK-serving idea is still unimplemented and
>   still optional.

---

## 1. Why this is a separate mode

The app today is a moderator's phone: one device, one driver, physical cards,
no player accounts, and — by design — no idea who is Merlin. Table Mode is not
that app with buttons added. It is a second product sharing a game engine.

The solo mode is **not modified**. `New Game` / `Continue Game` keep working
exactly as they do in 1.8.3, offline, with no network of any kind. Table Mode is
reached from its own two buttons and can be ignored forever.

---

## 2. Shape

| Button on Home | Who taps it | Result |
| --- | --- | --- |
| **Tablet Mode** | the device that sits on the table | becomes the board and hosts one room |
| **Join a Game** | every other player | scans the QR (or types a code), names themselves, gets a seat |
| `New Game` / `Continue Game` | the MC, alone | unchanged |

Players are seated **in join order**. There is no sign-up, no account, no room
history, and no way to join a room that is gone.

---

## 3. Devices

### Host (the board)

**An Android tablet.** An Android phone works too, just smaller. The host:

- hosts the room and the WebSocket endpoint on the local network,
- shows the QR code and the six-character room code,
- shows the public board and nothing else,
- **never acts on a player's behalf** — no "vote for Seat 3" control exists.

Network setup is the tablet's own hotspot, or the venue's router when one is
available. The host reports the address it is serving on and refuses to start if
it cannot find one.

### Player (an Android phone)

**The same app**, opened through `Join a Game`. It reads the QR with the camera,
asks for a name, and shows the hand. There is no second client to maintain: one
codebase, one build, one APK.

This is why Android-only is simpler than the web-client idea that came before
it. In-app QR scanning needs no HTTPS, no certificate and no browser quirks —
just the camera permission.

### Distribution

GitHub releases remain the only publishing step:

| Device | How it gets the build |
| --- | --- |
| Board tablet | Signed APK from the release, installed by the MC before game night |
| Player phones | Signed APK from the release — **or the tablet serves it** (see below) |

**Installing at the table.** The board can serve its own APK on
`http://<tablet>:8080/avalon.apk`. A player who has not installed the app scans
that code with their camera app, downloads it over the hotspot, installs it once
(Android asks to allow installs from that source), and joins. No internet, no
GitHub visit, no file transfer. The host shows both codes: one to install, one
to join.

---

## 4. Flow

```
HOME (board)                    HOME (player)
[ New Game ]                    [ New Game ]
[ Tablet Mode ] ── hosts ──┐    [ Join a Game ] ── scan QR ──┐
[ Continue Game ]          │                                 │
                           ▼                                 ▼
                    ┌──────────────────────────────────────────────┐
                    │  LOBBY                                       │
                    │  QR + code 7K3QF                             │
                    │  Seat 1  Ana     connected                   │
                    │  Seat 2  Ben     connected                   │
                    │  Seat 3  ...                                 │
                    │  [ Choose the cast ]   [ Start the match ]   │
                    └───────────────────┬──────────────────────────┘
                                        │ deal, privately
              ┌─────────────────────────┼─────────────────────────┐
              ▼                         ▼                         ▼
        BOARD (tablet)            HAND (phone)              HAND (phone)
        public state only         hold to reveal            hold to reveal
```

---

## 5. Screens

| Route | On | Job |
| --- | --- | --- |
| `/table` | board | lobby, then the board |
| `/join` | player | QR scan or code, then name |

Reused as-is: `dashboard`, `voting`, `questResolution`, `assassination`,
`results`, `history`. They gain a `TableMode` presentation flag that hides every
input and enlarges the type; the widgets themselves are unchanged.

New player screens: join, hand (character, the current ask, hold to reveal).

The mode is chosen per device at launch and remembered; a player's phone does not
show a "Tablet Mode" button, and the board does not show a "Join" button.

---

## 6. Cast and deal

The board picks the **cast**, not the seats: "5 players → Merlin · Assassin ·
Percival · Morgana · Loyal Servant". That summary is already public today
(`GameState.compositionSummary`) and is shown on the board.

The deal then:

1. deals the cast across occupied seats, in memory, once;
2. sends each seat its character to that device only;
3. **discards the map**.

Hard rules, each with a test:

| Rule | Why |
| --- | --- |
| `GameState` gains no character, seat-to-role or "who is evil" field | The engine's existing guarantee, quoted in `game_state.dart`, stays true |
| `DealService` is the only object that ever holds seat → character | One auditable place instead of a leak scattered across features |
| The board UI has no code path that renders a character | Cannot be triggered by a mistake |
| Nothing serialises a character: not history, not export, not logs | A saved match must not be a saved solution |
| Re-request allowed only with the device's own token and deal generation | Reconnect works without opening a door |
| Reveal is hold-to-show, auto-hides after 10 s | A neighbour cannot glimpse a screen that is already gone |
| `FLAG_SECURE` on the reveal screen | No screenshots, no recents thumbnail |

Honest limit: the board computed the shuffle, so a board owner who wants to cheat
can. That is the same trust as the person who shuffled the physical cards. The
README must say so, and must not claim "cheat-proof".

---

## 7. Protocol

Plain JSON over WebSocket, versioned, on the local network.

Player → host: `hello {code, name}`, `vote {verdict}`, `propose {seats}`,
`questCard {result}`, `assassinGuess {seat}`, `ping`.

Host → player: `welcome {seat, token, cast}`, `state {public}`, `role {character}`
(private, once per deal), `ask {kind}`, `presence {seat, connected}`, `error`.

The board is a projection of `GameState` plus presence — no new public state is
invented.

---

## 8. Engine changes

| Change | Reason | Blast radius |
| --- | --- | --- |
| `approveVotes` / `rejectVotes` counters → `Map<int, TeamVerdict>` | Reject double votes, survive a reconnect, show who voted | Voting, its tests |
| Quest cards held per seat until all are in | Secret submission instead of hand signals | Quest resolution |
| `TableSession`: seat ↔ device token, presence | Identity without touching `Player` | New |
| `DealService` | Characters outside the engine | New |
| Phases `lobby` and `dealing` | The board can stall waiting for phones | Router, transitions |

`Player` stays `{seat, name}`. That is the point.

---

## 9. Build notes

- One app, one entrypoint. The mode is a setting, not a build variant.
- New dependency: a QR scanner (`mobile_scanner` or equivalent) plus the camera
  permission in the Android manifest.
- A six-character code is typed by hand as well as scanned: cameras fail in dim
  rooms, and this is the fallback that saves the evening.
- **Split per ABI.** The universal APK is 66.5 MB; guests downloading it over a
  hotspot while eight phones contend for bandwidth want the ~25 MB arm64 build.
  The board serves the split that matches the phone that asked, falling back to
  the universal APK.
- `flutter analyze` and `flutter test` keep running on Windows as today. No Xcode,
  no `.ipa`, no Mac.

---

## 10. Phases

Each phase is shippable on its own and each has a stop condition.

### Phase 1 — the room (no characters)

`Tablet Mode`, `Join a Game`, QR + code, name, live seats, presence, reconnect.
No roles anywhere, so no privacy risk and no engine change.

**Done when:** eight Android phones hold the lobby for ten minutes, one drops its
Wi-Fi and rejoins *into the same seat*, and the board never shows a stale seat.

**Stop here if:** joining takes longer than ~15 seconds per player, or a phone on
the same hotspot cannot reach the board.

### Phase 2 — cast and deal

Cast picker on the board, private deal, hold-to-reveal hand.

**Done when:** a full table is dealt, every phone shows the right character, and a
test proves no character reaches the board, the history file or a log line.

### Phase 3 — the vote

Approve / reject from phones; the board shows counts only; rejections still
advance the leader token.

**Done when:** a vote passes and fails with no input on the board.

### Phase 4 — the quest and the assassin

Secret success / fail cards per quest member; the Assassin guesses from their own
phone.

**Done when:** a complete match is played with the board touched zero times
between `Start` and the result.

### Phase 5 — the board

Board skin, narration driven by the board, results and history read back at table
size.

---

## 11. Risks

| Risk | Mitigation |
| --- | --- |
| Hotspot client isolation blocks phone → board | Detect, explain, and offer the manual code path; test on the target devices |
| Eight people must install an APK before they can play | The board serves the APK itself; split per ABI; "install" code shown next to the "join" code |
| Android blocks installs from an unknown source | The install prompt itself explains it; this is a one-tap allow, not a setting hunt |
| A phone sleeps and loses the seat | Wake lock while a hand is open; reconnect by token, not by re-joining |
| Board battery dies mid-match | Match state lives on the board; document "the round is lost" rather than build host migration |
| A player has no Android phone | A seat can be marked "paper": the board shows the name, the player is dealt a physical card |
| Someone turns up with an iPhone | They cannot install the app and cannot join. Say it in the release notes, not at the table |

---

## 12. Open questions

1. Does the board also play? (Assumed no — the board is the board.)
2. If a player's phone dies mid-match, can the board deal that seat to a spare
   device, or is that player out for the round?
3. Should the cast picker warn when the chosen cast leaves the table unwinnable?
4. Lady of the Lake / Excalibur: Phase 5, or left to the physical components?
