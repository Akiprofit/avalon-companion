# Table Mode — Phase 1 implementation plan

**Status:** proposed, awaiting approval. No implementation code has been written.
**Spec:** `docs/table-mode.md` (approved design; this document only turns §10 Phase 1 into a work order).
**Target build:** 1.11.0+35.
**One line:** the tablet hosts a room, a phone joins by QR or six-character code,
seats and presence are live, and a phone that loses its Wi-Fi comes back into the
same seat. No characters, no deal, no vote.

---

## 0. Scope

### In

| Item | Source |
| --- | --- |
| `Tablet Mode` on Home: hosts one room, shows QR, code, address, live seats | spec §2, §5 |
| `Join a Game` on Home: scan the QR, or type the code | spec §2, §9 |
| Name entry, one seat per phone, seats in join order | spec §2 |
| Live presence: connected / away, pushed, never stale | spec §10 |
| Reconnect into the same seat after a Wi-Fi drop | spec §10 |
| A remembered per-device role, so a board never shows "Join a Game" | rule 3, spec §5 |

### Out, deliberately

Cast picker, deal, hand, hold-to-reveal, vote, proposal, quest card, assassin,
board skins, narration on the host, serving the APK, mDNS, host migration,
`FLAG_SECURE` (nothing secret exists yet), iOS, web.

The lobby therefore has **no "Start the match" button**: there is nothing to start
until Phase 2. The board offers "Close the room" and the phone offers "Leave the
table", and that is the whole control surface.

### Solo mode

No file under `lib/game_engine/`, no screen that solo mode uses, and no route
that solo mode visits changes. Table Mode is reached from Home and never from
inside a match. The one shared file that changes is `AppSettings`, which gains a
single value with a default that leaves every existing behaviour identical.

---

## 1. Package choices

The question is not "which packages are good" but "what is the smallest set that
still works in a dim room with no internet".

| Need | Choice | Version | Added bytes | Permissions | Why this and not something bigger |
| --- | --- | --- | --- | --- | --- |
| WebSocket **server** | `dart:io` `HttpServer` + `WebSocketTransformer.upgrade` | SDK | **0** | `INTERNET` | We serve exactly one endpoint. `shelf` + `shelf_web_socket` would add ~5 packages (`http_parser`, `stream_channel`, `stack_trace`, …) to route a single request. `WebSocketTransformer` is in the SDK and is the same code `shelf_web_socket` calls. |
| WebSocket **client** | `dart:io` `WebSocket.connect` | SDK | **0** | `INTERNET` | `web_socket_channel` exists to abstract the client across web and VM. There is no web client and no iOS client. Its one real gift — a testable channel seam — we get in ~25 lines (`TableConnection`), and we need our own seam anyway because the host side has no channel abstraction at all. |
| LAN discovery (so a typed code finds the board) | `dart:io` `RawDatagramSocket` broadcast | SDK | **0** | `INTERNET` | A six-character code cannot address a host. Either the player types an IP as well (fails the "camera failed, type the code" case) or the host announces itself. One UDP datagram per 1.5 s is ~40 lines. `multicast_dns`/`bonsoir` would add a native mDNS dependency and a multicast group that many venue routers drop. |
| Local address | `dart:io` `NetworkInterface.list` | SDK | **0** | none | No Android Wi-Fi API, therefore no `ACCESS_WIFI_STATE`, no `NEARBY_WIFI_DEVICES`, no runtime prompt. |
| QR **render** (board side) | `qr` | ^4.0.1 | ~60 KB Dart, no native code | none | `qr` is pure Dart with one transitive dependency (`meta`, already present). `qr_flutter` pins `qr` 3.x and is unmaintained since 2023 for a widget that is ~50 lines of `Canvas.drawRect`. |
| QR **scan** (phone side) | `mobile_scanner` | ^7.5.0 | **+5 to +9 MB universal, ~+2.5–3 MB per ABI split** | `CAMERA` (declared by the plugin, restated in our manifest) | The only maintained scanner with a bundled decoder. It bundles ML Kit `barcode-scanning:17.3.0` — a native model per ABI. The unbundled variant (`play-services-mlkit-barcode-scanning`, switchable via a Gradle property) saves the bytes but downloads the model from Google Play Services on first scan: that fails on a hotspot with no internet, which is the exact situation this feature exists for. `camera` + `zxing2` (pure Dart decode) avoids the ML Kit bytes but needs frame plumbing, rotation handling and our own decoder tuning; it is a worse trade for the evening it has to work. |

### Rejected on purpose

| Package | Why not |
| --- | --- |
| `permission_handler` | `mobile_scanner` requests the camera itself. A second permission plugin is native code for a prompt we already get. |
| `web_socket_channel` | See above: a cross-platform abstraction we do not need, and not a test seam for the host. |
| `shelf`, `shelf_web_socket`, `shelf_static` | One endpoint. `dart:io` covers it, and will cover the Phase 2 APK download too. |
| `multicast_dns`, `bonsoir`, `nsd` | Multicast is the first thing a venue router blocks. Unicast broadcast plus a typed code is more robust and has no dependency. |
| `nearby_connections`, Bluetooth, Wi-Fi Direct | Needs runtime permissions, pairing, and a whole second transport. Out of scope for a WebSocket room. |
| `flutter_secure_storage` | Phase 1's token lives in memory only (see §4). Nothing secret is written. |

### APK cost, measured not guessed

`mobile_scanner` is the only real growth. The plan is to build once with it and
record the true number in the CHANGELOG before the release:

- before: 71.8 MB universal, ~25 MB arm64 split (1.10.1);
- expected: 76–80 MB universal, ~28 MB arm64 split;
- if the universal APK passes ~85 MB, stop and report before shipping — that is a
  size regression worth a decision, not a detail.

The `qr` painter and the four `dart:io` adapters cost nothing measurable.

### Permissions, exactly

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

Nothing else. In particular:

- **No** `ACCESS_WIFI_STATE` / `CHANGE_WIFI_STATE`: we never call the Android Wi-Fi API.
- **No** `NEARBY_WIFI_DEVICES`: we do not scan or join networks.
- **No** `ACCESS_LOCAL_NETWORK`: Android's own guidance says to add it only when
  targeting SDK 37+. This app targets 36, where local network access is granted
  implicitly by `INTERNET`. Adding it now would be a permission nothing uses.
- **No** foreground service: the board is a foreground screen with the display kept awake.

`INTERNET` is a normal permission: no prompt, granted at install. `CAMERA` is a
runtime prompt, asked the first time the scanner opens — never on Home, never in
solo mode.

---

## 2. Transport, addressing and discovery

### Host

1. Find the LAN address: `NetworkInterface.list(type: IPv4, includeLinkLocal: false)`,
   preferring `wlan0`. If there is none, **refuse to host** and say so
   ("This device is not on a Wi-Fi network"), as spec §3 requires.
2. Bind `HttpServer.bind(InternetAddress.anyIPv4, port)` trying 8787, then
   8788–8797. Report the port actually bound, so a busy port is never a dead end.
3. One route: `GET /table` with `Upgrade: websocket` → `WebSocketTransformer.upgrade`.
   Anything else gets `404`. Phase 2 will add `GET /avalon.apk` here.
4. Start the announcer: every 1.5 s, send the datagram
   `AVALON1|<code>|<tcpPort>|<boardName>` to `255.255.255.255:<udpPort>`
   (UDP 8787, then the same 8788–8797 range as TCP).

### Player

1. From a scanned QR: `avalon://join?v=1&c=7K3QF9&h=192.168.43.1&p=8787`.
2. From a typed code: listen on UDP 8787 (and 8788–8797) for up to 6 s, accept the
   first datagram whose code matches, then connect to the announced address.
3. Escape hatch: an expandable "Enter the board's address" field taking
   `192.168.43.1:8787` for a network that drops broadcast.
4. `WebSocket.connect('ws://$host:$port/table')` with a 5 s timeout.

The QR is scanned **inside the app**, so no custom URL scheme intent-filter is
needed in Phase 1. The payload is URL-shaped only so a later phase can add one
without changing what the board prints.

### Frame rules

| Rule | Value | Why |
| --- | --- | --- |
| Encoding | UTF-8 JSON, one object per frame | Readable in a probe; no binary format to version |
| Max frame | 4096 bytes | A 14-seat `welcome` is under 1 KB; anything larger is a bug or an attack |
| Version | `"v":1`, required on every frame | An old phone must be told, not silently mis-seated |
| Unknown fields | ignored | A newer phone can send more without breaking an older board |
| Unknown `type` | `error unknown_type`, connection kept | One bad frame should not drop a seat |
| Malformed JSON / missing `v` | `error bad_message`, then close 1008 | Nothing to reply to |
| Oversized frame | close 1009 | No parsing of unbounded input |

---

## 3. Messages, Phase 1

Every frame is `{"v":1,"type":"…", …}`. Seats are integers, 1-based, join order.

### Phone → board

| `type` | Fields | Notes |
| --- | --- | --- |
| `hello` | `code` string(6), `name` string(1–20), `token` string(32 hex)? | `token` present means "I am coming back". Absent means "seat me". |
| `ping` | `t` int (ms since epoch) | Keepalive every 10 s; also measures the hop |
| `leave` | — | Clean exit: the seat is released at once |

### Board → phone

| `type` | Fields | Notes |
| --- | --- | --- |
| `welcome` | `seat` int, `token` string(32 hex), `code` string, `capacity` int, `phase` `"lobby"`, `seats` array | Identity + first snapshot, in one frame |
| `state` | `phase`, `capacity`, `seats` array | Sent to everyone else when the room changes |
| `presence` | `seat` int, `connected` bool | One seat changed |
| `pong` | `t` int | Echo of `ping.t` |
| `error` | `code` string, `message` string | `message` is shown to the player as-is |

`seats` is an array of `{"seat":1,"name":"Ana","connected":true}`.

### Error codes

| `code` | When | What the phone says |
| --- | --- | --- |
| `version` | `v` is not 1 | "This phone and that board are different versions." |
| `bad_message` | Not JSON, not an object, missing `type` | (closes; the phone retries once) |
| `unknown_type` | `type` not in the table above | (logged nowhere; the frame is ignored) |
| `room_not_found` | `code` does not match this board | "That code belongs to a different board." |
| `room_full` | 14 seats taken | "The board has no free seat." |
| `name_taken` | Name in use by a seated player, no valid token | "Someone at the table already used that name." |
| `name_invalid` | Empty, >20 chars, or control characters | "Use 1 to 20 characters." |
| `already_seated` | A second `hello` on the same connection | (the phone ignores it) |
| `seat_released` | Token matched a seat the board released | "That seat was released. Join again." |

### What is deliberately absent

No `role`, `character`, `cast`, `deal`, `vote`, `propose`, `questCard`,
`assassinGuess`, no `GameState` projection, and no field anywhere that maps a
seat to a character. A guard test asserts that the word `Character` does not
appear in any Phase 1 Table Mode source file.

### Example exchange

```json
→ {"v":1,"type":"hello","code":"7K3QF9","name":"Ana"}
← {"v":1,"type":"welcome","seat":1,"token":"9f2c…","code":"7K3QF9","capacity":14,
   "phase":"lobby","seats":[{"seat":1,"name":"Ana","connected":true}]}
   (to the others) {"v":1,"type":"state","phase":"lobby","capacity":14,
   "seats":[{"seat":1,"name":"Ana","connected":true}]}

→ {"v":1,"type":"ping","t":1764145200000}
← {"v":1,"type":"pong","t":1764145200000}

   (socket drops, phone reconnects)
→ {"v":1,"type":"hello","code":"7K3QF9","name":"Ana","token":"9f2c…"}
← {"v":1,"type":"welcome","seat":1,"token":"9f2c…", …}
```

---

## 4. State model and identity

### The three objects

| Object | Holds | Visible to widgets | Visible to the wire |
| --- | --- | --- | --- |
| `Seat` | number, name, connected, joinedAt, lastSeenAt | yes | yes (minus timestamps) |
| `RoomState` | code, address, port, phase, capacity, `List<Seat>` | yes | yes (the public projection) |
| `TableSession` | token → seat, socket → seat, last frame time | **no** | token goes only to its own phone |

This split is the Phase 1 rehearsal of the Phase 2 rule: the board renders a
projection, and the object that holds the link never reaches a widget. `RoomState`
has no token field, so no board code path can render one.

### Rules

| Rule | Behaviour | Test |
| --- | --- | --- |
| Seat assignment | lowest free seat from 1..14, so a released seat is reused and the board has no holes | `table_session_test` |
| Name | trimmed, 1–20 characters, no control characters, unique case-insensitively | `table_session_test`, `table_message_test` |
| Capacity | 14 (the largest house table the engine already supports) | `table_session_test` |
| Reconnect | a valid token always wins: same seat, same name, presence back to connected | **the required test**, §7 |
| Unknown or corrupt token | treated as absent, never as an error and never as a match | `table_session_test` |
| Second live connection, same token | the old socket is closed, the new one keeps the seat | `table_session_test` |
| Socket closes | seat is **kept**, presence goes away, board updates | `table_host_controller_test` |
| Silent socket | no frame for 30 s → watchdog closes it and marks it away | `table_host_controller_test` |
| `leave` | seat released at once, token invalidated | `table_host_controller_test` |
| Board releases an abandoned seat | explicit action on an away seat, behind a confirmation | `table_lobby_test` |

### Why the token is not persisted

The stop condition is a Wi-Fi drop, which does not kill the process: the token
lives in memory and the socket reconnects. Persisting it would write a
long-lived seat credential to SQLite and cost a schema version for a case
(app killed while the phone sleeps) that Phase 1 does not promise. If the app is
killed, the seat stays "away" on the board with its name, and the MC can release
it. That is stated in the README rather than left to be discovered.

### Remembered device role

`AppSettings.tableRole` ∈ `solo` (default) | `board` | `player`, stored in the
`Settings` row. Home shows both entries when `solo`, only `Tablet Mode` when
`board`, only `Join a Game` when `player`. A "Switch" affordance on the table
screens and a three-way choice in Settings change it.

Cost, stated plainly: **schema v8 → v9**, one text column
`table_role` default `'solo'`, one `m.addColumn` in `onUpgrade`, one migration
test, and a `build_runner` regeneration of `app_database.g.dart`. This is the same
shape as v8's Big table switch.

---

## 5. Screens and routes

| Route | Name | Screen | Job |
| --- | --- | --- | --- |
| `/table` | `tableHost` | `TableHostScreen` | start the room, show QR + code + address, list seats, close the room |
| `/join` | `join` | `JoinScreen` | scan or type the code, then the name |
| `/join/scan` | `joinScan` | `JoinScanScreen` | camera preview, returns the payload |
| `/seat` | `playerSeat` | `PlayerSeatScreen` | the phone's resting screen: seat, presence, leave |

None of these are in the router's `needsGame` redirect: Table Mode never requires
a `GameState`.

### Board states

| State | Shows |
| --- | --- |
| `starting` | "Opening the room…" |
| `hosting` | code in large monospace, QR, `ws://192.168.43.1:8787`, "3 seated", seat rows |
| `failed` | the reason in plain words + "Try again"; `no_wifi`, `port_busy`, `permission` |
| `closed` | back to Home |

Layout: one column under 720 dp; two columns at or above it (QR and code left,
seats right). The board is read from across a table, so it gets
`kBoardContentWidth = 900` in `app_metrics.dart` rather than the 600 dp reading
measure.

### Phone states

| State | Shows |
| --- | --- |
| `idle` | "Scan the board's code" (primary), "Type the code" (secondary) |
| `locating` | "Looking for the table…" (UDP discovery, 6 s) |
| `naming` | code confirmed, name field, "Take a seat" |
| `joining` | "Taking your seat…" |
| `seated` | "SEAT 3 · Ana", "Connected to 7K3QF9", "Leave the table" |
| `reconnecting` | "Lost the board — reconnecting (2)…" with a Retry after 2 minutes |
| `rejected` | the `error.message`, and a way back |

The seated screen shows no character and says so: "Nothing is dealt yet." That
sentence is the honest Phase 1 state and disappears in Phase 2.

### Home

New section below the primary actions, above "How to Play":

- `solo`: two rows, **Tablet Mode** ("This device becomes the board") and
  **Join a Game** ("Scan the board's code").
- `board`: one row, **Tablet Mode**, plus "This device is the board · Switch".
- `player`: one row, **Join a Game**, plus the same switch line.

`New Game` / `Continue Game` keep their exact position and behaviour.

### Copy

Short, plain, no exclamation marks. The board never says "cheat-proof"; the
phone never promises a character. The one sentence the README must carry:

> The board shuffles, so whoever holds the board could cheat — exactly like
> whoever shuffled the physical cards.

---

## 6. File-by-file change list

> **Superseded in part (2026-11-26):** the board moved to its own app,
> Virtual Avalon. The host files listed below (`table_host_server`,
> `table_announcer`, `table_room`, `table_session`, the board screen and the
> lobby widgets) were extracted into that repository and are documented there
> in `docs/board-app.md`. The protocol, model and IO files are shared verbatim.
> The companion's copies remain until the phone flow is verified on hardware,
> then they are removed so the solo app carries no board code.

### New - pure Dart, no Flutter import (so a PC probe can drive them)

| File | Lines | Contents |
| --- | --- | --- |
| `lib/features/table_mode/model/room_code.dart` | ~70 | 6 characters from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no I/O/0/1), `Random.secure`, `normalise`, `isValid` |
| `lib/features/table_mode/model/seat.dart` | ~45 | immutable `Seat` + `copyWith` |
| `lib/features/table_mode/model/room_state.dart` | ~95 | immutable room projection: code, address, port, phase, capacity, seats |
| `lib/features/table_mode/model/table_role.dart` | ~30 | `solo` / `board` / `player`, `fromStorage` tolerant of a newer value |
| `lib/features/table_mode/protocol/table_protocol.dart` | ~55 | version, frame limit, name/capacity limits, `TableErrorCode` |
| `lib/features/table_mode/protocol/table_message.dart` | ~230 | sealed `TableMessage` hierarchy, `toJson`, `fromJson` |
| `lib/features/table_mode/protocol/table_connection.dart` | ~35 | `Stream<String> incoming`, `send`, `close`, `id` |
| `lib/features/table_mode/host/table_session.dart` | ~190 | seat ↔ token ↔ connection registry, presence, watchdog decisions. **No IO.** |
| `lib/features/table_mode/host/table_room.dart` | ~260 | the protocol state machine: connections in, `RoomState` + per-peer frames out. **No IO, no Flutter.** |
| `lib/features/table_mode/host/table_host_server.dart` | ~110 | `dart:io` adapter: bind, upgrade, wrap each socket as a `TableConnection` |
| `lib/features/table_mode/host/table_announcer.dart` | ~85 | UDP broadcast loop |
| `lib/features/table_mode/player/table_client.dart` | ~250 | connect, hello, welcome, ping, reconnect-with-token, give-up. **No IO, no Flutter.** |
| `lib/features/table_mode/player/io_table_transport.dart` | ~90 | `dart:io` `WebSocket.connect` adapter |
| `lib/features/table_mode/player/table_discovery.dart` | ~115 | UDP listen-by-code, 6 s window |

### New — Flutter

| File | Lines | Contents |
| --- | --- | --- |
| `lib/features/table_mode/table_mode_providers.dart` | ~70 | overridable seams: server factory, transport factory, discovery factory |
| `lib/features/table_mode/host/table_host_controller.dart` | ~130 | Riverpod notifier over `TableRoom`, timers, keep-awake |
| `lib/features/table_mode/player/table_client_controller.dart` | ~130 | Riverpod notifier over `TableClient`, navigation on state change |
| `lib/features/table_mode/widgets/join_qr.dart` | ~75 | `CustomPainter` over `qr`'s module matrix; `background` modules on a `parchment` ground |
| `lib/features/table_mode/widgets/room_code_card.dart` | ~85 | the six characters, grouped `ABC DEF`, at table size |
| `lib/features/table_mode/widgets/seat_row.dart` | ~70 | seat number, name, `StatusIndicator` (connected / away), release action |
| `lib/features/table_mode/screens/table_host_screen.dart` | ~250 | board: states, layout, keys |
| `lib/features/table_mode/screens/join_screen.dart` | ~270 | code entry, discovery, name, connecting, errors |
| `lib/features/table_mode/screens/join_scan_screen.dart` | ~120 | `MobileScanner`, with an injectable preview builder for tests |
| `lib/features/table_mode/screens/player_seat_screen.dart` | ~140 | seat, presence, leave |

### Edited

| File | Change |
| --- | --- |
| `pubspec.yaml` | `mobile_scanner: ^7.5.0`, `qr: ^4.0.1`; version 1.11.0+35 |
| `android/app/src/main/AndroidManifest.xml` | `INTERNET`, `CAMERA`, camera `uses-feature required=false` |
| `lib/core/constants/routes.dart` | 4 names, 4 paths |
| `lib/app/router.dart` | 4 routes, outside the `needsGame` gate |
| `lib/features/home/home_screen.dart` | the Table Mode section, filtered by `tableRole` |
| `lib/core/models/app_settings.dart` | `tableRole` + `copyWith` |
| `lib/database/app_database.dart` | `tableRole` column, `schemaVersion` 9, `if (from < 9) addColumn` |
| `lib/database/app_database.g.dart` | regenerated by `build_runner` |
| `lib/database/repositories/settings_repository.dart` | encode/decode `tableRole` |
| `lib/features/settings/settings_screen.dart` | "Table Mode" three-way choice |
| `lib/core/theme/app_metrics.dart` | `kBoardContentWidth`, `kBoardBreakpoint`, `kJoinQrSize`, `kJoinQrSizeLarge` |
| `lib/core/constants/app_info.dart` | version 1.11.0 |
| `README.md`, `CHANGELOG.md`, `DEVELOPMENT_PLAN.md` | see §10 |

### New — dev tools (not in the APK)

| File | Where | Purpose |
| --- | --- | --- |
| `tool/table_board_probe.dart` | Virtual Avalon | runs a real host on the PC: N synthetic phones, join-latency report, `--soak` minutes, `--bind=lan` to serve a real Wi-Fi address, `--serve` to leave the room open for a phone |
| `tool/table_client_probe.dart` | this repo | N synthetic phones against any board: join-latency report, `--drop <n>` to lose a phone and win its seat back by token, `--minutes` soak with pings |

These exist because the stop condition is "eight phones for ten minutes" and
there is one Android device in the room. They drive the same `TableRoom` and
`TableClient` classes the app uses, over real sockets.

Measured on the development PC on 2026-11-26 (loopback, not Wi-Fi):

| Run | Result |
| --- | --- |
| 8 phones, fresh room | slowest join 358 ms against a 15 000 ms budget |
| 8 phones, 1 minute soak, pings every 10 s | 8 of 8 still connected, 8 seats held |
| 8 phones, drop phone 3 | back at seat 3 in 11–28 ms, same token |
| 1 phone, 8-client board, leave | all seats released on leave |

The loopback numbers say the room is not the slow part. The number that decides
the stop condition is a phone on the same hotspot, and that needs a second
device.

### New — tests

| File | Approx. tests |
| --- | --- |
| `test/unit/table/room_code_test.dart` | 5 |
| `test/unit/table/table_message_test.dart` | 10 |
| `test/unit/table/table_session_test.dart` | 9 |
| `test/unit/table/table_room_test.dart` | 8 |
| `test/unit/table/table_client_test.dart` | 7 |
| `test/unit/table/discovery_test.dart` | 3 |
| `test/unit/table/io_adapter_test.dart` | 1 (real loopback socket) |
| `test/unit/table/table_privacy_guard_test.dart` | 3 |
| `test/unit/table/solo_network_guard_test.dart` | 1 |
| `test/widget/table_mode_home_test.dart` | 4 |
| `test/widget/table_lobby_test.dart` | 5 |
| `test/widget/join_flow_test.dart` | 6 |
| `test/widget/table_layout_test.dart` | 3 |
| `test/support/fake_table_network.dart` | (harness) |

Expected: **~65 new cases, 393 → ~458 tests.**

---

## 7. Test list

### The required test: reconnect into the same seat

Two halves, because one proves the rule and one proves the wire.

**A. Pure rule (`table_session_test.dart` / `table_client_test.dart`)**

> Given a room with Ana in seat 1 and Ben in seat 2, when Ben's socket closes and
> Ben's client reconnects with the token it was given, then the board has exactly
> two seats, Ben is still seat 2 with the same name, and seat 3 does not exist.

Assertions: seat count unchanged, seat number unchanged, name unchanged,
presence true, and no `welcome` ever carried a different seat number.

**B. Widget (`table_lobby_test.dart`)**

> Given the board lobby showing "Ana · Seat 1 · Connected", when the fake phone's
> socket drops and reconnects with its token, then the row reads "Away" within one
> frame of the drop, and reads "Connected" again with the same seat number after
> the reconnect — and the board never shows a second Ana.

**C. Device (A36, §8)** — the real Wi-Fi drop.

### Unit

| Test | Proves |
| --- | --- |
| Room code alphabet | no `I`, `O`, `0`, `1`; 6 characters; 1000 draws are all distinct enough to be plausible; `normalise` accepts `7k3 qf9`, rejects `7K3QF` and `7K3QF0` |
| Message round-trip | every type survives `toJson` → `fromJson`; extra fields ignored; unknown type yields `unknown_type`, not an exception; missing `v` yields `bad_message`; a 5000-byte frame is rejected; a 21-character name yields `name_invalid` |
| Seat assignment | join order; lowest free seat reused after release; capacity 14 then `room_full`; duplicate name case-insensitive rejected; control characters rejected |
| Token rules | valid token reclaims its seat; corrupt token is treated as absent; unknown token with a taken name gives `name_taken`; a second live connection with the same token displaces the first |
| Room protocol | hello → welcome + broadcast; presence on connect and on drop; ping → pong; leave releases; wrong code → `room_not_found`; frames after close are ignored, not thrown |
| Watchdog | no frame for 30 s marks the seat away and closes the socket; a ping resets the clock |
| Client | connect → welcome; terminal errors do not retry; transport errors retry with capped backoff; gives up after 2 minutes and exposes Retry; dispose cancels every timer |
| Discovery packet | `AVALON1\|CODE\|PORT\|NAME` round-trips; other versions, other codes and garbage are ignored |
| Loopback adapter | a real `dart:io` server on `127.0.0.1:0` upgrades a real client, `hello` → `welcome`; both ends closed in `tearDown` |

### Privacy and solo guards

| Test | Proves |
| --- | --- |
| `GameState` unchanged | no character, seat-to-role, or allegiance field; `toString` still leaks nothing |
| Table Mode names no character | no file under `lib/features/table_mode/` contains `Character`, `roleOf`, `characterOf` or `seatTo`, comments excluded (the same comment-stripping helper `privacy_test.dart` already uses) |
| No board render path | `RoomState` has no token and no character field; the host widgets import only `RoomState` |
| Nothing serialises a seat | Table Mode performs no database write except the role preference; the protocol has no history/export message |
| Solo opens no socket | pump the app, play New Game → setup → preparation → dashboard with a network factory that records every call; assert zero calls, and that no route outside Table Mode imports `dart:io` |

### Widget

| Test | Proves |
| --- | --- |
| Home, solo install | both table entries, `New Game` still the primary action |
| Home, board role | no "Join a Game" text anywhere |
| Home, player role | no "Tablet Mode" text anywhere |
| Lobby | code visible, QR present, "No one has joined yet", then "Ana · Seat 1 · Connected", then "Away" |
| Lobby, release | an away seat can be released behind a confirmation; a connected seat cannot |
| Join flow | code → name → seated; wrong code shows the error and stays; duplicate name shows the error; empty name keeps the button disabled |
| Join flow, scan seam | a fake preview returns a payload and the code field fills in; the camera is never constructed in CI |
| Layout | board at 2560×1600 and 1080×2340 with 14 seats: no overflow, no clipped row; phone join screen at 1080×2340 |

### Hygiene rules for the new tests

- Every fake connection is a `StreamController` that the harness closes; no test
  binds a port except `io_adapter_test`, which binds loopback port 0 and closes
  the server in `tearDown`.
- Every controller test disposes its container; every widget test unmounts
  (`pumpWidget(SizedBox())`) so Riverpod runs `onDispose` and the watchdog timer
  is cancelled. `flutter_test` fails on a pending timer, which is the check.
- No `debugPrint`, no `print`, and no frame logging in any new file.

---

## 8. Device checklist — Galaxy A36 (SM-A366B, `RFCY30E0LRT`)

`adb` at `C:\Users\Marc\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
**As of this writing `adb devices` lists nothing**, so the device steps are
pending a cable.

### Setup

Two APKs, two apps: the board is Virtual Avalon, the phone is Avalon Companion.

```powershell
$ADB = "C:\Users\Marc\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $ADB devices
& $ADB install -r "C:\Virtual Avalon\build\app\outputs\flutter-apk\app-release.apk"
& $ADB install -r build\app\outputs\flutter-apk\app-release.apk
```

### A. The A36 is the board (real host, eight synthetic phones)

**Run on 2026-11-26, home router `192.168.1.0/24`, A36 at `192.168.1.3`, PC at
`192.168.1.7`.** The board opened on launch with code `ALY5DJ` and printed
`192.168.1.3:8787`; eight synthetic phones joined over Wi-Fi in a slowest
**513 ms**, a dropped phone 3 returned to seat 3 in **83 ms** with its token, a
one-minute soak left **8 of 8 seated**, and every seat was released on leave.
Steps 6 and 7 (ten minutes, battery, temperature, screenshot pair) were not
done in that run and are still to do.

1. Put the PC on the same Wi-Fi as the A36 (the A36's hotspot, or one router).
2. On the A36: open **Virtual Avalon**. It opens a room by itself; record the
   code, the address and the port.
3. On the PC: `dart run tool\table_client_probe.dart --host <ADDRESS> --port <PORT> --code <CODE> --clients=8 --minutes=10`.
4. Check on the board: 8 rows, seats 1–8 in join order, all "Connected".
   Check the probe: per-phone join latency (target well under 15 s; expect < 1 s).
5. Drop phone 3 (`--drop=3`), watch the board show "Away", then watch the probe
   reconnect with its token. The board must still show 8 rows and seat 3 must
   keep its name.
6. Ten minutes: no crash, `adb logcat` clean of the app, address unchanged,
   battery and temperature recorded.
7. Screenshot: `adb shell screencap -p /sdcard/board.png` then `adb pull`.
   `adb shell uiautomator dump /sdcard/ui.xml`, pull it, and read it in PowerShell
   with `Get-Content -Encoding Unicode` — the file is UTF-16.

### B. The A36 is a phone (real client, real camera)

**Run on 2026-11-26, real Wi-Fi.** The board ran on the PC as
`tool/table_board_probe.dart --bind=lan --address=192.168.1.7 --serve=1500` (code
`ABC234`), and the A36 ran Avalon Companion 1.11.0+35. What happened:

- **Typed code did not find the board.** "Nothing on this Wi-Fi answered for
  ABC234" — the UDP announcement is dropped by Windows Firewall on the PC. The
  address fallback ("Enter the board's address instead") connected at once, so
  the run used `192.168.1.7:8787`.
- **Join:** seat **1**, name **MARC**, CONNECTED, on the first attempt.
- **Wi-Fi drop:** `adb shell cmd wifi set-wifi-enabled disabled`; the phone showed
  "Lost the board — reconnecting (3)…" while the PC still held a half-dead socket.
- **Reconnect:** `enabled`; the same seat 1 with the same name came back on a
  **new** TCP socket (`:43518` → `:53688`), which is the reconnect path, not a
  reused connection.
- **Leave:** confirmation dialog → Home; `netstat` showed no established socket,
  so the leave frame arrived and the seat was released.
- **Not done in this run:** the camera scan (a phone cannot scan its own screen),
  and phone-to-phone discovery.

### B2. Two phones, 2026-11-27

The board ran in **Virtual Avalon** on the Galaxy A36 (`192.168.1.3`, wired for
`adb`; the room itself is on Wi-Fi) and this app, 1.11.0+35, on a **Galaxy A32**
(`192.168.1.4`), on the same home Wi-Fi. No PC was involved in the connection.

- **Discovery:** typed `QMSSQQ` on the A32 and tapped **Find the table** → the
  join screen showed **"FOUND THE BOARD"** on the first attempt. Phone-to-phone
  UDP discovery works; the "Nothing on this Wi-Fi answered" failure recorded
  above was the PC's firewall, not the protocol.
- **Join:** seat **1**, **MARC**, CONNECTED; the A36's board read **"1 of 14"**.
- **Leave:** confirmation dialog → board back to **"0 of 14"**; the seat was
  released over the wire.
- **Camera scan:** with the board restarted (new code **WAZ V6S**), tapping
  **Scan the board's code** and holding the A32 at the A36's QR moved the app to
  **"FOUND THE BOARD WAZ V6S"** with nothing typed. A negative control came
  first: with the board stopped and its QR out of view, the scanner stayed open
  on a live camera preview and decoded nothing, so the later pop can only be the
  camera reading the new code — a cached code would have shown `QMSSQQ`.
- **Wi-Fi drop, phone-hosted board:** `cmd wifi set-wifi-enabled disabled` on the
  A32 (kept on USB so `adb` survived) → "Lost the board — reconnecting (5)…";
  `enabled` → the phone returned to **seat 1, MARC, CONNECTED** in the same room
  with nothing retyped.
- **What the run exposed:** while the room was open the host's Wi-Fi address
  moved from `192.168.1.3` to `192.168.1.10`. The board keeps the address it
  captured at open, so its screen, QR and announcement still said `192.168.1.3`,
  and the seat went **AWAY** once that socket died. The board was right; the
  address it published was not. Reopening the room is the only way to pick up a
  new address — see `docs/board-app.md` in the board repo.
- **Still not done:** a real tablet.

1. On the PC: `dart run tool\table_board_probe.dart --bind=lan --serve=300` in
   the Virtual Avalon repo — it prints the code and the Wi-Fi address, and keeps
   the room open. There is no QR on the console; use the typed code here.
   Add `--address=<ip>` if the machine advertises the wrong adapter (a VirtualBox
   or VPN interface), and expect the typed code to need the address fallback when
   the PC's firewall drops the UDP announcement.
2. On the A36: open **Avalon Companion** → **Join a Game** → type the code →
   name → **Take a seat**.
3. For the camera path, the board must be the other app on a device with a
   screen: scan the QR from the A36's lobby with a second phone, or run the
   board on the A36 and scan it with the companion on a second device.
4. Wi-Fi drop, three ways, in order, until one works:
   - `adb shell cmd wifi set-wifi-enabled disabled` … `enabled`
   - `adb shell svc wifi disable` … `enable`
   - `adb shell cmd connectivity airplane-mode enable` … `disable`
   - if all three are refused: turn Wi-Fi off by hand, and say so in the report.
5. After the drop: the phone returns to **seat 1**, not seat 2, and the board
   still reports one seat. Screenshot the reconnecting state and the recovered one.

### C. Tablet proportions without a tablet

`adb shell wm size 2560x1600` then `adb shell wm density 320` to inspect the
two-column board on the A36; `adb shell wm size reset` and
`adb shell wm density reset` afterwards. This checks the layout at tablet
proportions, and the report will say exactly that — it is not a tablet.

### D. If no second Android device exists

**A second phone did exist on 2026-11-27**, so this section no longer describes the
state of the world; it is kept as the fallback wording. The run is in **B2** above.

Say it plainly, in the CHANGELOG and in the chat:

- **Verified on hardware:** two real Android phones. A Galaxy A36 hosting the
  board and a Galaxy A32 running this app as client, over real Wi-Fi: typed-code
  discovery found the board first try, seat 1, a clean leave that freed the seat,
  and a camera scan of the QR that filled in the new code with nothing typed.
  Separately, the A36 ran the companion as client against a board on the PC
  (typed address, real Wi-Fi drop, same-seat return) and as host against eight
  synthetic clients over Wi-Fi.
- **Verified without a second phone:** eight concurrent clients, the one-minute
  soak, presence and reconnect, driven by `tool/table_client_probe.dart` over the
  same network against the real board.
- **Not verified:** eight physical phones, two phones scanning at once, a client
  phone losing Wi-Fi while a phone (rather than the PC) hosts, and a real tablet.
  Those lines are written as "not tested" — never implied.
- The stop condition is still measured on what exists: if a single real phone
  cannot reach the board, or takes more than 15 s to join, Phase 1 stops there.

### Stop conditions, and what "stop" means

Per spec §10: stop and report if joining takes longer than ~15 s per player, or a
phone on the same hotspot cannot reach the board.

Concretely: stop building, capture `adb logcat -d` for the app, the phone's IP
(`adb shell ip addr show wlan0`), the board's announced address, and whether UDP
discovery answered and whether a direct `ws://` connect succeeded. Then report
which of the two failed, with the numbers, and do not continue to Phase 2.

---

## 9. Risks specific to Phase 1

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Hotspot client isolation blocks phone → board | Medium on venue routers, low on a phone hotspot | Detect a failed connect, say "this network is blocking phone-to-board traffic", offer the typed address; tested on the A36 |
| Broadcast is dropped but unicast works | Medium | The address escape hatch; discovery is an optimisation, not the only path |
| Port 8787 already in use | Low | Try 8788–8797 and report the real port; the QR carries it |
| Android 17 will require `ACCESS_LOCAL_NETWORK` | Certain, later | Targets 36 today, where `INTERNET` is enough. Noted in the README as the next Android task, not silently ignored |
| ML Kit adds ~2.5–3 MB per ABI | Certain | Measured before release; if the universal APK passes ~85 MB, stop and report |
| The board's app is killed by Android | Low while the screen is on | Keep-awake while hosting; the room is memory-only by design, and the README says the round is lost rather than pretending otherwise |
| A phone sleeps and its socket dies | Certain | 30 s watchdog, presence away, token reconnect, 2-minute retry window |
| A stale seat blocks the lobby | Certain eventually | Seats are released by `leave`, or explicitly by the board, with a confirmation |
| Dim room, camera fails | Certain | The six-character code and discovery are a first-class path, not a fallback buried in a menu |
| Two boards on one network | Low | The code is checked in `hello`; the wrong board answers `room_not_found` |
| `dart:io` breaks a web build | Certain, irrelevant | Android only, as the spec states; the README already says so |

---

## 10. Release protocol for Phase 1

Only after §7 and §8 pass:

1. `flutter analyze` — quote the real output.
2. `flutter test` — quote the real output and the new count.
3. `flutter build apk --release` — record size and SHA-256.
4. Version **1.11.0+35** in `pubspec.yaml` and `AppInfo.version`
   (`app_info_test.dart` enforces the match).
5. `CHANGELOG.md` — a 1.11.0 entry with the verified table, the real APK size and
   SHA-256, and the honest device line from §8D.
6. `DEVELOPMENT_PLAN.md` — replace the uncommitted "Optional — Table Mode (not
   scheduled)" chapter with a Phase 1 chapter **only when the build is real**,
   as the working rule requires.
7. `README.md` — a Table Mode section, and the corrections the feature forces:
   "No network calls" becomes "solo mode opens no socket; Table Mode uses only
   your local network"; the permissions list gains `INTERNET` and `CAMERA`; the
   shuffle-trust sentence from §5 is added; "no accounts" stays true.
8. GitHub release with `Avalon-Companion-1.11.0.apk`, its SHA-256 and size.
9. All text files UTF-8 without BOM, written with
   `[System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))`.

---

## 11. Decisions (answered 2026-11-26)

| # | Question | Answer | Effect on this plan |
| --- | --- | --- | --- |
| 1 | Add `mobile_scanner` + `qr`? | **Yes**, both, with the APK growth accepted | §1 stands. The real APK delta is measured before release and reported; stop if the universal APK passes ~85 MB. |
| 2 | Does the board also play? | **No.** The host device is purely the board and takes no seat | The 14 seats are all for phones. No host seat, no reveal-on-board rule, no privacy exception in Phase 2. |
| 3 | Hotspot or venue router? | **Either; the venue router preferred, the tablet hotspot as the fallback** | §2 stands: bind `anyIPv4`, report the served address. The device checklist covers a router first, then the hotspot. |
| 4 | How many phones must Phase 1 hold? | **Cap 14, verified with 8** | `kTableCapacity = 14`; the stop condition is measured with 8 clients, and the release notes claim only the tested number. |
| 5 | Commit the docs now? | **Commit `docs/table-mode.md` and this plan; hold the DEVELOPMENT_PLAN chapter until the build is real** | One `docs:` commit. `DEVELOPMENT_PLAN.md` stays modified and uncommitted until the Phase 1 build exists. |
| 6 | One app with a device role, or two apps? | **Two apps** (answered after the plan was written): the board is Virtual Avalon, its own project and repository | The board screens, the host controller and the lobby move to the new app; the companion keeps the player side. The protocol, room rules, seat projection and tests are shared unchanged. See the decision update at the top of `docs/table-mode.md`. |

Nothing in these answers moves a file, a route, a message or a test in §6 and §7
of the companion. Answer 6 is the exception by design: it moves the board out of
this repository, so §6's board files and §7's board widget tests now live in
`C:\Virtual Avalon` (documented in that repo's `docs/board-app.md`), and the
companion's Phase 1 scope is the phone: join by code or QR, take a seat,
reconnect.

---

## 12. Order of work once approved

1. `pubspec.yaml` + manifest + `flutter pub get`; confirm `flutter analyze` still clean.
2. Pure Dart layer with its tests: room code, messages, session, room, client.
3. `dart:io` adapters + the loopback test.
4. Riverpod controllers, providers, and the two probes.
5. Board screen, then join flow, then the phone seat screen.
6. Home, routes, settings, schema v9 + migration.
7. Widget tests, layout tests, guards.
8. Device checklist, then docs, version, release.

Steps 2–3 are where the stop conditions would show up first, and they need no
Android device — so a failure there costs an hour, not an evening.
