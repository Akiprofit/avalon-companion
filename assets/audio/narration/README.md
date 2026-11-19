# Recorded narrator clips

The narrator of the app. Every night line plays from the MP3 in these folders;
the phone's text-to-speech engine is only the fallback for a line with no
recording, so a missing file degrades to a voice rather than silence.

`test/unit/narration_clips_test.dart` fails when a night line has no file here,
and the registry in `lib/narration_engine/services/narration_clips.dart` must
list exactly the recorded ids.

## Layout

One folder per narrator, then one per language:

```
assets/audio/narration/
  Dahlia voices/     the narrator bundled with the app
    en/              English recordings
    fil/             Filipino recordings
```

`Dahlia voices/` is the folder `NarrationClips.voice` names, so renaming it in
the file system means renaming it there, in `pubspec.yaml` and in this README.

A second folder beside it is **not** played by the app. To add another narrator,
bundle it under `assets/audio/voices/<pack>/en|fil/` — see
`assets/audio/voices/README.md` — and choose it in **Settings → Narrator voice**.

One file per instruction id, same name in both languages:

```
en/night.close_eyes.mp3
fil/night.close_eyes.mp3
```

Lowercase, dots and underscores only, so the id in the script is the file name.

## Night lines (`lib/narration_engine/scripts/night_script.dart`)

| id | heading |
| --- | --- |
| `night.close_eyes` | THE NIGHT BEGINS |
| `night.evil.wake` | MINIONS OF MORDRED |
| `night.evil.look` | MINIONS OF MORDRED |
| `night.evil.look_oberon` | MINIONS OF MORDRED |
| `night.evil.sleep` | MINIONS OF MORDRED |
| `night.merlin.wake` | MERLIN |
| `night.merlin.look` | MERLIN |
| `night.merlin.look_mordred` | MERLIN |
| `night.merlin.sleep` | MERLIN |
| `night.percival.wake` | PERCIVAL |
| `night.percival.look` | PERCIVAL |
| `night.percival.look_alone` | PERCIVAL |
| `night.percival.sleep` | PERCIVAL |
| `night.end` | DAYBREAK |

`look_oberon`, `look_mordred` and `look_alone` are conditional variants: only
one file of each pair is ever played in a match, so all six look-lines need
recording, because any composition can occur.

## Round lines (`lib/narration_engine/scripts/round_script.dart`)

| id | heading |
| --- | --- |
| `round.proposal` | THE ROUND TABLE |
| `vote.approved` | THE VOTE |
| `vote.rejected` | THE VOTE |
| `vote.rejection_warning` | FOUR REJECTIONS |
| `quest.success` | THE QUEST |
| `quest.fail` | THE QUEST |
| `assassination.begin` | THE ACCUSATION |

These seven are defined but not played anywhere in the app today, so they have
no recordings. The fallback voice never reads them either.

## Format

- MP3, 44.1 kHz, mono, 64-96 kbps keeps a full set small
- Trim leading and trailing silence; the script's own pause follows each line
- Keep the same room tone across a language so the set sounds like one narrator
