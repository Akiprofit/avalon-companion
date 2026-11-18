# Add a narrator voice

A voice is a folder of recordings, not a single file. The app plays a recording
when it has one for a line and falls back to the phone's text-to-speech for the
lines it does not, so a partial set is allowed — it just sounds like two
narrators taking turns.

There are two ways to add one. **Importing a zip is the one to use**: no
rebuild, and the voice can be deleted again from Settings.

## Import a zip (no rebuild)

1. Put the recordings in folders called `en/` and/or `fil/`:

   ```
   Voice of Dahlia/
     en/night.close_eyes.mp3
     en/night.end.mp3
     fil/night.close_eyes.mp3
   ```

   A zip with the MP3s at the top level is read as English.

2. Zip the folder and move the `.zip` to the phone.
3. In the app: **Settings → Narrator voice → Add a voice**, then pick the zip.
4. Name it — "Voice of Dahlia" — and it appears in the voice list with a count
   of the lines it can play.

Imported voices live in the app's own files, so the zip can be deleted from the
phone afterwards. **Remove** in the voice list deletes the files as well.

## Bundle a voice with the app (rebuild)

Drop the same folder under `assets/audio/voices/<pack>/`, then list **each
language folder** in `pubspec.yaml` — Flutter asset folders are not recursive:

```yaml
    - assets/audio/voices/voice-of-dahlia/en/
    - assets/audio/voices/voice-of-dahlia/fil/
```

The folder name becomes the voice name (`voice-of-dahlia` → "Voice of Dahlia").
To choose a different one, add a `voice.json` next to the language folders:

```json
{ "name": "Voice of Dahlia" }
```

A bundled voice can be hidden from the picker, and renamed, but not deleted —
the recordings are inside the app package. Bundled voices are listed in the
manifest only if their folders are in `pubspec.yaml`; a folder that is not
listed is invisible to the app.

## Files

One MP3 per instruction id. The ids are listed in
`assets/audio/narration/README.md`; the fourteen night lines are the ones that
play today. Lowercase, dots and underscores only — the id in the script is the
file name:

```
en/night.close_eyes.mp3
fil/night.close_eyes.mp3
```

Anything that is not `.mp3` inside `en/` or `fil/` is ignored, as are other
language folders. MP3, 44.1 kHz, mono, 64–96 kbps keeps a full set small.

The shipped narrator (`assets/audio/narration/`) cannot be removed. If a voice
is missing a line, that line is spoken by the phone instead of going silent.
