import '../../game_engine/models/phase.dart';
import '../models/narration_instruction.dart';

/// Round, quest and endgame lines — announced by `NarrationCues` the moment the
/// table reaches them, so the features never hardcode a spoken string.
abstract final class RoundScript {
  static const proposal = NarrationInstruction(
    id: 'round.proposal',
    phase: Phase.dayDiscussion,
    heading: 'THE ROUND TABLE',
    english: 'The leader names a team.',
    filipino: 'Pumipili ng team ang leader.',
    pauseAfter: Duration(milliseconds: 1200),
  );

  static const approved = NarrationInstruction(
    id: 'vote.approved',
    phase: Phase.teamVoting,
    heading: 'THE VOTE',
    english: 'The team is approved. The quest begins.',
    filipino: 'Aprubado ang team. Simula na ng quest.',
    pauseAfter: Duration(milliseconds: 1200),
  );

  static const rejected = NarrationInstruction(
    id: 'vote.rejected',
    phase: Phase.teamVoting,
    heading: 'THE VOTE',
    english: 'The team is rejected. The leader passes on.',
    filipino: 'Na-reject ang team. Lilipat ang leader.',
    pauseAfter: Duration(milliseconds: 1200),
  );

  static const rejectionWarning = NarrationInstruction(
    id: 'vote.rejection_warning',
    phase: Phase.teamVoting,
    heading: 'FOUR REJECTIONS',
    english: 'That is four rejections. One more and evil wins.',
    filipino: 'Apat nang rejection. Isa pa, panalo ang evil.',
    pauseAfter: Duration(milliseconds: 1200),
  );

  static const questSuccess = NarrationInstruction(
    id: 'quest.success',
    phase: Phase.questResolution,
    heading: 'THE QUEST',
    english: 'The quest succeeds.',
    filipino: 'Tagumpay ang quest.',
    pauseAfter: Duration(milliseconds: 1200),
  );

  static const questFail = NarrationInstruction(
    id: 'quest.fail',
    phase: Phase.questResolution,
    heading: 'THE QUEST',
    english: 'The quest fails.',
    filipino: 'Bagsak ang quest.',
    pauseAfter: Duration(milliseconds: 1200),
  );

  static const assassination = NarrationInstruction(
    id: 'assassination.begin',
    phase: Phase.assassination,
    heading: 'THE ACCUSATION',
    english: 'Three quests are won. Assassin, the table awaits your accusation.',
    filipino:
        'Tatlong quest ang napanalunan. Assassin, hinihintay ng mesa ang '
        'akusasyon mo.',
    pauseAfter: Duration(milliseconds: 1600),
  );

  /// Every round line, in the order a match meets them.
  static const all = [
    proposal,
    approved,
    rejected,
    rejectionWarning,
    questSuccess,
    questFail,
    assassination,
  ];
}
