import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_controller.dart';
import '../../game_engine/rules/avalon_tables.dart';
import '../controllers/voice_packs_controller.dart';
import '../models/narration_instruction.dart';
import '../models/voice_pack.dart';
import '../scripts/round_script.dart';
import 'clip_provider.dart';
import 'clip_service.dart';
import 'tts_provider.dart';
import 'tts_service.dart';

/// Says the round lines out loud as the table reaches them.
///
/// The night is a script the MC starts from a panel. The round lines are not:
/// a team is proposed, a vote settles, a quest is recorded, the assassin wakes.
/// Each one is announced in the chosen narrator's voice at the moment it
/// happens, so the phone speaks to the table instead of only showing text.
///
/// One line at a time: a new announcement replaces whatever was speaking.
/// Nothing here can block the table, so every failure is silent — a voice that
/// did not record the line falls back to the phone's own voice, exactly like the
/// night does, and a phone with neither simply stays quiet.
class NarrationCues {
  const NarrationCues({
    required this.clips,
    required this.tts,
    required this.settings,
    required this.pack,
  });

  final ClipService clips;
  final TtsService tts;
  final AppSettings settings;

  /// The recorded voice chosen in settings.
  final VoicePack pack;

  /// The line for a settled vote.
  ///
  /// A rejection that leaves one more before Evil wins says so, because that is
  /// the moment the table needs to hear: the next rejected team ends the match.
  static NarrationInstruction voteOutcome({
    required bool approved,
    required int rejectionCount,
  }) => approved
      ? RoundScript.approved
      : rejectionCount >= AvalonTables.rejectionsBeforeEvil - 1
      ? RoundScript.rejectionWarning
      : RoundScript.rejected;

  /// Speaks [line] once. Completes when it has finished, was replaced, or
  /// could not play — the caller does not wait for it either way.
  Future<void> play(NarrationInstruction line) async {
    final language = settings.defaultLanguage;
    final path = pack.pathFor(line.id, language);

    if (path != null) {
      await clips.initialize();
      if (clips.isAvailable) {
        // The recordings are the narrator: the phone's own voice must not
        // finish a line underneath one. Only an engine that is actually
        // running has anything to silence — asking a phone with no engine
        // would wait on a channel that is not there.
        if (tts.isAvailable) await tts.stop();
        if (await clips.play(path, volume: settings.volume)) return;
      }
    }

    // A voice with no recording for this line, or a player that could not open
    // it, falls through to the platform voice.
    await clips.stop();
    await tts.initialize();
    if (!tts.isAvailable) return;

    final locale = language.localeCode;
    if (!await tts.isLanguageAvailable(locale)) return;
    await tts.speak(
      line.textFor(language),
      locale: locale,
      rate: settings.narrationRate,
      volume: settings.volume,
      pitch: settings.narrationPitch,
      voiceId: settings.narratorVoiceId,
    );
  }
}

/// Rebuilt whenever the narrator settings change, so a voice, a language or a
/// volume picked mid-match applies to the next announcement.
final narrationCuesProvider = Provider<NarrationCues>((ref) {
  final settings = ref.watch(settingsProvider);
  final packs = ref.watch(voicePacksProvider);
  return NarrationCues(
    clips: ref.watch(clipServiceProvider),
    tts: ref.watch(ttsServiceProvider),
    settings: settings,
    pack: packs.active(settings.narratorPackId),
  );
});
