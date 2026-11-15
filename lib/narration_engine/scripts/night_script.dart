import '../../game_engine/models/composition.dart';
import '../../game_engine/models/phase.dart';
import '../models/narration_instruction.dart';

/// Night sequence — master plan §6.2, text from
/// `avalon-narration/references/night-script.md`.
///
/// [sequenceFor] is the only entry point: it filters by the selected composition
/// and picks the variant lines, so a character that is not in play never gets a
/// line. No line names a player, by design.
abstract final class NightScript {
  static const closeEyes = NarrationInstruction(
    id: 'night.close_eyes',
    phase: Phase.night,
    heading: 'THE NIGHT BEGINS',
    english: 'Everyone, close your eyes and place one fist on the table.',
    filipino: 'Pumikit ang lahat at ilagay ang isang kamao sa mesa.',
    pauseAfter: Duration(milliseconds: 1200),
  );

  static const evilWake = NarrationInstruction(
    id: 'night.evil.wake',
    phase: Phase.night,
    heading: 'MINIONS OF MORDRED',
    english: 'Minions of Mordred, open your eyes.',
    filipino: 'Mga alagad ni Mordred, imulat ang mga mata.',
    requiresCharacters: ['evil'],
    pauseAfter: Duration(milliseconds: 1000),
  );

  static const evilLook = NarrationInstruction(
    id: 'night.evil.look',
    phase: Phase.night,
    heading: 'MINIONS OF MORDRED',
    english: 'Look around and recognise the others who serve the darkness.',
    filipino: 'Tumingin sa paligid at kilalanin ang ibang nasa dilim.',
    requiresCharacters: ['evil'],
    pauseAfter: Duration(milliseconds: 2000),
  );

  static const evilLookOberon = NarrationInstruction(
    id: 'night.evil.look_oberon',
    phase: Phase.night,
    heading: 'MINIONS OF MORDRED',
    english:
        'Look around and recognise the others who serve the darkness — '
        'except those who keep to themselves.',
    filipino:
        'Tumingin sa paligid at kilalanin ang ibang nasa dilim — maliban sa '
        'mga nananatiling tahimik.',
    requiresCharacters: ['evil', 'Oberon'],
    pauseAfter: Duration(milliseconds: 2000),
  );

  static const evilSleep = NarrationInstruction(
    id: 'night.evil.sleep',
    phase: Phase.night,
    heading: 'MINIONS OF MORDRED',
    english: 'Minions of Mordred, close your eyes.',
    filipino: 'Mga alagad ni Mordred, pumikit.',
    requiresCharacters: ['evil'],
    pauseAfter: Duration(milliseconds: 1000),
  );

  static const merlinWake = NarrationInstruction(
    id: 'night.merlin.wake',
    phase: Phase.night,
    heading: 'MERLIN',
    english: 'Merlin, open your eyes.',
    filipino: 'Merlin, imulat ang mga mata.',
    requiresCharacters: ['Merlin'],
    pauseAfter: Duration(milliseconds: 1500),
  );

  static const merlinLook = NarrationInstruction(
    id: 'night.merlin.look',
    phase: Phase.night,
    heading: 'MERLIN',
    english:
        'Players who serve evil, raise your thumb. Merlin, look and remember '
        'them.',
    filipino:
        'Mga nasa panig ng kasamaan, itaas ang hinlalaki. Merlin, tumingin at '
        'tandaan sila.',
    requiresCharacters: ['Merlin'],
    pauseAfter: Duration(milliseconds: 2500),
  );

  static const merlinLookMordred = NarrationInstruction(
    id: 'night.merlin.look_mordred',
    phase: Phase.night,
    heading: 'MERLIN',
    english:
        'Players who serve evil, raise your thumb. Merlin, look and remember '
        'them — one among them stays hidden from you.',
    filipino:
        'Mga nasa panig ng kasamaan, itaas ang hinlalaki. Merlin, tumingin at '
        'tandaan sila — may isang nakatago sa iyo.',
    requiresCharacters: ['Merlin', 'Mordred'],
    pauseAfter: Duration(milliseconds: 2500),
  );

  static const merlinSleep = NarrationInstruction(
    id: 'night.merlin.sleep',
    phase: Phase.night,
    heading: 'MERLIN',
    english: 'Thumbs down. Merlin, close your eyes.',
    filipino: 'Ibaba ang hinlalaki. Merlin, pumikit.',
    requiresCharacters: ['Merlin'],
    pauseAfter: Duration(milliseconds: 1000),
  );

  static const percivalWake = NarrationInstruction(
    id: 'night.percival.wake',
    phase: Phase.night,
    heading: 'PERCIVAL',
    english: 'Percival, open your eyes.',
    filipino: 'Percival, imulat ang mga mata.',
    requiresCharacters: ['Percival'],
    pauseAfter: Duration(milliseconds: 1000),
  );

  static const percivalLook = NarrationInstruction(
    id: 'night.percival.look',
    phase: Phase.night,
    heading: 'PERCIVAL',
    english:
        'Two thumbs are raised. One is Merlin, one is Morgana. You do not know '
        'which.',
    filipino:
        'Dalawang hinlalaki ang nakataas. Isa si Merlin, isa si Morgana. Hindi '
        'mo alam kung alin.',
    requiresCharacters: ['Percival', 'Morgana'],
    pauseAfter: Duration(milliseconds: 2000),
  );

  static const percivalLookAlone = NarrationInstruction(
    id: 'night.percival.look_alone',
    phase: Phase.night,
    heading: 'PERCIVAL',
    english: 'One thumb is raised. That is Merlin.',
    filipino: 'Isang hinlalaki ang nakataas. Iyon si Merlin.',
    requiresCharacters: ['Percival'],
    pauseAfter: Duration(milliseconds: 2000),
  );

  static const percivalSleep = NarrationInstruction(
    id: 'night.percival.sleep',
    phase: Phase.night,
    heading: 'PERCIVAL',
    english: 'Thumbs down. Percival, close your eyes.',
    filipino: 'Ibaba ang hinlalaki. Percival, pumikit.',
    requiresCharacters: ['Percival'],
    pauseAfter: Duration(milliseconds: 1000),
  );

  static const end = NarrationInstruction(
    id: 'night.end',
    phase: Phase.night,
    heading: 'DAYBREAK',
    english: 'Everyone, open your eyes. The game begins.',
    filipino: 'Imulat ng lahat ang mga mata. Magsisimula na ang laro.',
    pauseAfter: Duration(milliseconds: 800),
  );

  /// Every line in declaration order — used by tests and the preview screen.
  static const all = [
    closeEyes,
    evilWake,
    evilLook,
    evilLookOberon,
    evilSleep,
    merlinWake,
    merlinLook,
    merlinLookMordred,
    merlinSleep,
    percivalWake,
    percivalLook,
    percivalLookAlone,
    percivalSleep,
    end,
  ];

  /// Builds the actual night for a composition: absent characters are skipped,
  /// and variant lines are chosen rather than played twice.
  static List<NarrationInstruction> sequenceFor(Composition composition) {
    final sequence = <NarrationInstruction>[closeEyes];

    if (composition.evilTotal > 0) {
      sequence.add(evilWake);
      sequence.add(composition.hasOberon ? evilLookOberon : evilLook);
      sequence.add(evilSleep);
    }

    if (composition.hasMerlin) {
      sequence.add(merlinWake);
      sequence.add(
        composition.hasMordred ? merlinLookMordred : merlinLook,
      );
      sequence.add(merlinSleep);
    }

    if (composition.hasPercival) {
      sequence.add(percivalWake);
      sequence.add(
        composition.hasMorgana ? percivalLook : percivalLookAlone,
      );
      sequence.add(percivalSleep);
    }

    sequence.add(end);
    return sequence;
  }
}
