# Avalon Companion — Design System

Cinematic dark Arthurian fantasy. This document is the working contract for
every visual decision in the app. `MASTER_PLAN.md.txt` §3.2–§3.4a remains the
authority; where this file and the master plan disagree, the master plan wins
and both get fixed in the same change.

## 1. Identity

- Dark, mysterious, dramatic, noble, medieval, cinematic.
- Reference points: Arthurian legend, Camelot, Merlin, Avalon, Excalibur, the
  Round Table, medieval royal architecture.
- Premium fantasy companion, not a toy. Restraint over decoration: one strong
  focal element per screen, soft gold accents, generous space.
- Offline, single-device, Game Master facing. The phone is a prop on the table;
  it must never imply which player holds which character.

## 2. Colour tokens

All values live in `lib/core/theme/app_colors.dart` and nowhere else. Derived
tints via `withValues(alpha:)` are allowed; new opaque colours become tokens
first.

| Token | Hex | Use |
|---|---|---|
| `background` | `#0B0E14` | Screen base. Never pure black. |
| `backgroundSecondary` | `#121A28` | Bands, headers, navigation bar. |
| `surface` | `#202B3B` | Cards, panels, inputs. |
| `surfaceRaised` | `#2A3749` | Nested panels, snackbars, switches off. |
| `gold` | `#C5A15B` | Primary action, selection, ornament. |
| `lightGold` | `#E2C98D` | Highlight on gold, quiet emphasis. |
| `mutedGold` | `#8E7440` | Supporting ornament, secondary CTA. |
| `parchment` | `#F1F0EB` | Primary text. |
| `textSecondary` | `#BBC3CE` | Supporting copy. |
| `mutedText` | `#8492A6` | Captions, hints, disabled labels. |
| `neutral` | `#8492A6` | Inactive indicators, lesser dividers. |
| `success` | `#3D9B72` | Quest success, good state. |
| `danger` | `#B84B4B` | Failure, rejection, destructive action. |
| `divider` | `#2C3748` | Hairlines and card borders. |
| `onGold` | `#0B0E14` | Text/icons on gold fills. |
| `goldOverlay` | `#22C5A15B` | Slider halo, passive glow. |
| `veilTop` / `veilMiddle` / `veilBottom` | `#8C` / `#CC` / `#F7` over `#0B0E14` | Legibility veil over artwork. |

Rules:

- Green only for success, red only for failure/rejection.
- Gold marks what the MC should act on; everything else is quiet.
- No colour carries meaning alone — pair it with an icon or a word.

## 3. Typography

- **Cinzel** — display only: app title, screen titles, victory text, numerals
  in ceremonial contexts.
- **Inter** — every other piece of text, including all body copy and controls.
- Both ship as variable fonts with explicit `FontVariation` weights so Android
  renders identically across devices.

Hierarchy (see `app_text.dart`): `display`, `screenTitle`, `sectionTitle`,
`body`, `bodyStrong`, `caption`, `button`, `numeric`.

## 4. Spacing, radius, motion

`app_metrics.dart` is the only source: `Space` (4 → 48, screen padding 20),
`Radii` (chip 8, input 12, card 16, sheet 24), `Motion` (micro 130 ms,
transition 280 ms, dramatic 520 ms), `kMinTapTarget = 48`.

Motion is restrained: fade, gentle scale, slow atmospheric drift, smooth phase
changes. Nothing bounces, nothing loops for attention.

### Reduced motion

`lib/core/theme/app_motion.dart`:

- `prefersReducedMotion(context)` reads `MediaQuery.disableAnimations`.
- `motionDuration(context, d)` returns zero when reduced motion is on.

`CinematicBackground` stops its drift, keeps a static plate, and the veil stays.
Route transitions collapse. No feature may ignore this.

## 5. Components

Canonical project names are the master plan names. The design brief used other
labels for the same concepts; this table is the mapping. Never add a second
widget for a concept that already exists.

| Brief name | This project | File |
|---|---|---|
| `GoldPrimaryButton` | `PrimaryButton` | `primary_button.dart` |
| `GoldOutlinedButton` | `SecondaryButton` | `secondary_button.dart` |
| `DarkPanel` | `MedievalCard` | `medieval_card.dart` |
| `MedievalSectionHeader` | `SectionHeader` | `section_header.dart` |
| `QuestProgressIndicator` | `QuestTracker` | `quest_tracker.dart` |
| `NarrationPlayer` | `NarrationPanel` | `narration_panel.dart` |
| `GameStatusIndicator` | `StatusIndicator` | `status_indicator.dart` |
| `OrnamentalDivider` | `GoldDivider` | `gold_divider.dart` |
| `CinematicBackground` | `CinematicBackground` | `cinematic_background.dart` |
| `SettingsTile` | `SettingsTile` | `settings_tile.dart` |

Supporting widgets: `AvalonScreen` (shell), `AvalonBottomNavigation`,
`AvalonIconButton`, `PlayerTile`, `GameProgressHeader`, `ConfirmationDialog`,
`EmptyState`, `ErrorState`, `LoadingState`.

Component rules:

- Interactive targets are at least 48 dp.
- Every disabled control shows why it is disabled in nearby copy.
- Gold fill means "the next thing to press" — at most one per screen region.
- A panel is `surface` with a `divider` border; a nested panel is
  `surfaceRaised`. No drop shadows.

## 6. Screens

1. Home
2. Game setup (players + character configuration)
3. Preparation
4. Game dashboard
5. Narration
6. Team proposal
7. Voting
8. Mission results
9. Assassination
10. Game results
11. Settings

Each screen: one `AvalonScreen` shell, an optional artwork plate, a Cinzel
heading, content in `MedievalCard` panels, one primary action.

## 7. Artwork

Seven environment plates, bundled offline in `assets/images/`, all public domain
(the artists died more than 70 years ago) and sourced from Wikimedia Commons.
Each file is 1080×1920, JPEG quality 68, and the set totals under 2 MB.

| Constant | File | Work | Artist |
|---|---|---|---|
| `Artwork.camelot` | `camelot.jpg` | Tintagel Castle above the sea | Thomas Murphy (after) |
| `Artwork.forest` | `forest.jpg` | *A Mossy Glen* | John Atkinson Grimshaw (1836–1893) |
| `Artwork.roundTable` | `round_table.jpg` | *The Boy's King Arthur*, p. 102 | N. C. Wyeth (1882–1945) |
| `Artwork.merlinChamber` | `merlin_chamber.jpg` | *The Beguiling of Merlin* | Edward Burne-Jones (1833–1898) |
| `Artwork.stoneCastle` | `stone_castle.jpg` | *Abbey in the Oakwood* | Caspar David Friedrich (1774–1840) |
| `Artwork.avalon` | `avalon.jpg` | *The Lady of Shalott* | John William Waterhouse (1849–1917) |
| `Artwork.excalibur` | `excalibur.jpg` | *The Magic Circle* | John William Waterhouse (1849–1917) |

Commons file pages, for provenance:

- `File:King-Arthur's-Castle-q75-1759x1228.jpg`
- `File:John Atkinson Grimshaw (1836-1893) - A Mossy Glen - 1974.535 - Calderdale Metropolitan Borough Council.jpg`
- `File:Boys King Arthur - N. C. Wyeth - p102.jpg`
- `File:Edward Burne-Jones - The Beguiling of Merlin.jpg`
- `File:Caspar David Friedrich - Abtei im Eichwald - Google Art Project.jpg`
- `File:John William Waterhouse - The Lady of Shalott - Google Art Project.jpg`
- `File:The Magic Circle - John William Waterhouse.jpg`

Constraints kept: public domain only, no third-party game artwork, no
identifiable living people, portrait composition with calm dark space behind
text, compressed to keep the whole set under 2 MB, listed in `pubspec.yaml`.
`test/unit/artwork_test.dart` proves the files, the manifest and the `Artwork`
map agree.

Plates are decoration only: `CinematicBackground` veils them so body text stays
above 4.5:1 contrast, and they are `excludeFromSemantics: true`.

### App icon

The launcher icon comes from `assets/branding/app_icon.png`, the supplied
1254×1254 artwork. That file is the master, not a bundled asset: it is absent
from the `assets:` list in `pubspec.yaml`, so it never ships in the APK.

Only the artwork inside the file's cream frame is used — the frame itself is
dropped, because Android supplies its own mask and the frame plus a mask reads
as a double border. Every density is generated from that region at 92 % of the
tile on the palette navy `#04101D`, corners rounded at 23.5 % of the art width.
They are regenerated by `make_icons.ps1` in the session temp folder; nothing at
runtime draws them.

| Resource | Purpose |
|---|---|
| `mipmap-anydpi-v26/avalon_launcher.xml` | adaptive icon, API 26+ (background colour + foreground) |
| `mipmap-anydpi-v26/avalon_launcher_round.xml` | adaptive icon for round-mask launchers |
| `mipmap-*/avalon_launcher.png` | legacy icon, 48–192 px |
| `mipmap-*/avalon_launcher_round.png` | legacy round icon, 48–192 px |
| `mipmap-*/avalon_launcher_foreground.png` | adaptive foreground, 108–432 px |
| `values/avalon_launcher_background.xml` | `#04101D` |

`AndroidManifest.xml` points `android:icon` and `android:roundIcon` at those
resources. The names are project-specific rather than the template's
`ic_launcher*` so a stale system icon cache cannot shadow a new icon by name.

## 8. Audio

Three separate channels: narration (existing TTS MethodChannel), music, SFX.
Music and SFX need their own native channel and must duck to 20–30 % while
narration speaks, never the other way round. English and Filipino narration
both supported; changing language never restarts a match.

## 9. Verification

- `flutter analyze` clean, full test suite green.
- Layouts checked at 360, 411 and 480 dp width, plus the Galaxy A36.
- Reduced motion on: no drift, no scale, transitions instant.
- APK builds and installs on device.
