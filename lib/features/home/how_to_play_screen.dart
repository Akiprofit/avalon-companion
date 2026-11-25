import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/rules/avalon_tables.dart';

/// The table manual: how a game of Avalon is actually played, step by step,
/// and what the MC does in the app at each point.
///
/// Static content, no game state. The rules follow the cards, not the app: the
/// app is the moderator's script and the public scoreboard, and it is never
/// told who holds which character.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _sections = <_ManualSection>[
    _ManualSection(
      title: 'Before you begin',
      intro:
          'Avalon is a hidden-role game for five to ten players. Everyone '
          'receives one secret character card. Arthur\'s loyal servants try to '
          'complete three quests; the minions of Mordred try to stop them. Most '
          'of the game is conversation — accusing, defending and deciding who '
          'to trust.',
      entries: [
        _ManualEntry(
          'You need the base game\'s physical cards: one character card per '
          'player, an approve and a reject card for each player, five success '
          'and five fail quest cards, and the leader token.',
        ),
        _ManualEntry(
          'One player is the Master of Ceremonies — the MC — and holds the '
          'phone. The MC can play too. The app never asks who holds which card, '
          'so it can never give a role away.',
        ),
        _ManualEntry(
          'The app is the moderator\'s script and the scoreboard: it narrates '
          'the night, shows team sizes, counts votes and keeps the quest score. '
          'It does not replace the cards or settle an argument at the table.',
        ),
        _ManualEntry(
          'The table plays the game. Cards stay physical, claims may be lies, '
          'and only what the whole table saw goes into the app.',
        ),
        _ManualEntry(
          'More than ten at the table? Settings → Game → Big table unlocks '
          'house sizes up to fourteen. Those sizes are ours, not the rulebook\'s: '
          'the quest teams and role counts above ten are invented, and one box '
          'may not hold enough cards for them.',
        ),
      ],
    ),
    _ManualSection(
      title: 'Set up the table',
      intro: 'Do this once, in this order, before the first night.',
      entries: [
        _ManualEntry(
          'Seat five to ten players in a circle in a fixed order — up to '
          'fourteen when Settings → Game → Big table is on. Seat 1 is the '
          'first leader; after that the leader token moves one seat clockwise.',
          number: 1,
        ),
        _ManualEntry(
          'Open New Game and enter the players in that seating order.',
          number: 2,
        ),
        _ManualEntry(
          'Choose the characters. The app suggests a roster for the player '
          'count — Merlin, Percival and loyal servants for Good; the Assassin, '
          'Morgana, Mordred and Oberon for Evil, as far as the count allows. '
          'The table may agree on a different roster; the app checks the good '
          'and evil totals.',
          number: 3,
        ),
        _ManualEntry(
          'Read the Preparation screen. It shows the starting leader, the '
          'composition and how many players each quest needs.',
          number: 4,
        ),
        _ManualEntry(
          'Shuffle the physical character cards and deal one face down to each '
          'player. Each player looks at their own card once and keeps it '
          'hidden — from the other players and from the app.',
          number: 5,
        ),
        _ManualEntry(
          'Give every player an approve and a reject card, put the success and '
          'fail quest cards in the middle, and place the leader token in front '
          'of seat 1.',
          number: 6,
        ),
        _ManualEntry(
          'Tap Begin the match, then Open Night Narration. The room is ready '
          'for the night.',
          number: 7,
        ),
      ],
    ),
    _ManualSection(
      title: 'Know the characters',
      intro:
          'The app shows the roster but never who has which card. These are '
          'the base-game roles.',
      entries: [
        _ManualEntry(
          'Knows every evil player except Mordred. Merlin must steer the table '
          'without being obvious, because the Assassin gets one shot at him.',
          term: 'Merlin',
        ),
        _ManualEntry(
          'Knows who Merlin is. If Morgana is in play, Percival sees two '
          'possible Merlins and never learns which is which.',
          term: 'Percival',
        ),
        _ManualEntry(
          'No special knowledge. Discusses, votes and goes on quests like '
          'everyone else.',
          term: 'Loyal Servant of Arthur',
        ),
        _ManualEntry(
          'A minion of Mordred with one job at the end: name Merlin. If the '
          'name is right, Evil wins even after three successful quests.',
          term: 'Assassin',
        ),
        _ManualEntry(
          'Appears to Percival as a second possible Merlin, splitting his '
          'certainty.',
          term: 'Morgana',
        ),
        _ManualEntry(
          'Invisible to Merlin: the evil player Merlin cannot see.',
          term: 'Mordred',
        ),
        _ManualEntry(
          'Unknown to the other minions, and he does not know them. He works '
          'alone.',
          term: 'Oberon',
        ),
        _ManualEntry(
          'Knows the other evil players except Oberon, and tries to fail '
          'quests without being caught.',
          term: 'Minion of Mordred',
        ),
      ],
    ),
    _ManualSection(
      title: 'The night',
      intro:
          'Everyone closes their eyes and follows the voice. The app skips any '
          'step whose character is not in play, and it never says a player\'s '
          'name.',
      entries: [
        _ManualEntry(
          'Everyone closes their eyes and places one fist on the table. No '
          'talking, pointing or peeking from here on.',
          number: 1,
        ),
        _ManualEntry(
          'Minions of Mordred, open your eyes. Every evil player except Oberon '
          'opens their eyes and looks around to recognise the others. Oberon '
          'stays out of it.',
          number: 2,
        ),
        _ManualEntry('Minions of Mordred, close your eyes.', number: 3),
        _ManualEntry(
          'Merlin, open your eyes. Every evil player except Mordred raises a '
          'thumb. Merlin looks and remembers them; Mordred stays hidden. Thumbs '
          'down, Merlin closes his eyes.',
          number: 4,
        ),
        _ManualEntry(
          'Percival, open your eyes. Merlin and Morgana raise a thumb: two '
          'candidates, and Percival never learns which is which. If Morgana is '
          'not in play, only Merlin raises a thumb. Thumbs down, Percival '
          'closes his eyes.',
          number: 5,
        ),
        _ManualEntry(
          'Everyone, open your eyes. What each player learned at night stays '
          'private; everything said from now on can be a lie.',
          number: 6,
        ),
        _ManualEntry(
          'The app then opens the wheel for the first Lord. With automatic '
          'King mode on, every later round returns to the wheel the same way.',
          number: 7,
        ),
      ],
    ),
    _ManualSection(
      title: 'Every round',
      intro:
          'Each round is one proposal, one vote and — if the vote passes — one '
          'quest.',
      entries: [
        _ManualEntry(
          'The leader chooses a team of the size the quest requires. On the '
          'dashboard, tap Choose the Quest Team and select the seats.',
          number: 1,
        ),
        _ManualEntry(
          'The table discusses the proposal. The discussion ring is a timer the '
          'MC controls; it is not a rule and can be ignored.',
          number: 2,
        ),
        _ManualEntry(
          'Everyone votes — including players on the proposed team. Each player '
          'plays approve or reject face down; the MC turns them over and taps '
          'each seat\'s vote.',
          number: 3,
        ),
        _ManualEntry(
          'The app resolves the vote. A strict majority approves; a tie counts '
          'as a rejection.',
          number: 4,
        ),
        _ManualEntry(
          'If the team is approved, it goes on the quest. If it is rejected, '
          'the leader token passes one seat clockwise and the next leader '
          'proposes a new team.',
          number: 5,
        ),
        _ManualEntry(
          'After a quest is resolved, the next leader — one seat clockwise — '
          'proposes the next team. Continue until one side wins.',
          number: 6,
        ),
        _ManualEntry(
          'By default the token passes clockwise. If Draw a new King '
          'automatically is on, the app spins for a leader each round instead '
          'and avoids repeating one while another player can lead. Draw a new '
          'King on the dashboard does the same once.',
        ),
      ],
    ),
    _ManualSection(
      title: 'Team size',
      intro:
          'The leader\'s team grows with the quest. The app shows these numbers '
          'on the Preparation screen and when a team is chosen. The Big table '
          'setting adds 11 to 14 seats, with larger teams the app shows the '
          'same way.',
      table: _QuestSizeTable(),
    ),
    _ManualSection(
      title: 'Rules that catch people out',
      entries: [
        _ManualEntry(
          'Approval needs a strict majority of every vote cast. With ten '
          'players, five approve and five reject is a rejection.',
        ),
        _ManualEntry(
          'Five rejected proposals in a row end the game for Evil. An approved '
          'team resets the count.',
        ),
        _ManualEntry(
          'A rejected proposal does not change the quest number. The same quest '
          'is proposed again by the next leader.',
        ),
        _ManualEntry(
          'Good players must play a success card on a quest. Evil players may '
          'play either, so a success can be a bluff.',
        ),
        _ManualEntry(
          'Only the number of fail cards is revealed, never the cards '
          'themselves. The MC shuffles the played cards first.',
        ),
        _ManualEntry(
          'The fourth quest needs two fail cards when seven or more players '
          'are seated. Every other quest fails on one.',
        ),
        _ManualEntry(
          'After three successful quests the game is not over: the Assassin '
          'still gets one accusation.',
        ),
        _ManualEntry(
          'No talking during the night. After daybreak, claims are fair game — '
          'and may be lies.',
        ),
        _ManualEntry(
          'A house rule can skip the approval vote in Settings. Everything else '
          'here follows the cards.',
        ),
      ],
    ),
    _ManualSection(
      title: 'The final accusation',
      intro: 'Good has completed three quests. One step remains.',
      entries: [
        _ManualEntry(
          'The Assassin — not the table, not the MC — names one player as '
          'Merlin.',
        ),
        _ManualEntry(
          'The named player reveals their character card if it is Merlin. The '
          'MC taps Merlin was named or Merlin survived on the accusation '
          'screen.',
        ),
        _ManualEntry(
          'The app stores only whether the accusation was right. It never '
          'records who was named.',
        ),
        _ManualEntry('If Merlin was named, Evil wins. If not, Good wins.'),
      ],
    ),
    _ManualSection(
      title: 'How to win',
      entries: [
        _ManualEntry(
          'Good wins by completing three quests and keeping Merlin alive '
          'through the accusation.',
        ),
        _ManualEntry(
          'Evil wins by failing three quests, by five rejected proposals in a '
          'row, or by naming Merlin.',
        ),
        _ManualEntry(
          'Three failed quests end the game immediately. There is no '
          'accusation after them.',
        ),
      ],
    ),
    _ManualSection(
      title: 'Using the app',
      entries: [
        _ManualEntry(
          'The dashboard\'s main button follows the phase: Open Night '
          'Narration, Choose the Lord, Choose the Quest Team, Open the Vote, '
          'Resolve the Quest, Begin the Accusation, See the Result.',
        ),
        _ManualEntry(
          'The night screen plays the recordings. Play, pause, next, previous '
          'and replay control the line; End night is separate and asks before '
          'it ends the night.',
        ),
        _ManualEntry(
          'Language switches between English and Filipino without restarting '
          'the match. Settings also holds the narrator voice, the fallback '
          'voice and the extra delay after each line.',
        ),
        _ManualEntry(
          'The quest board lists what the table already saw: each resolved '
          'quest and the seats that went on it. The app never stores who voted '
          'which way or who played which quest card.',
        ),
        _ManualEntry(
          'Pause the match from the dashboard. If the phone locks or the app '
          'closes, the match is saved and offered as Continue Game at home.',
        ),
        _ManualEntry(
          'Abort ends the match and keeps it in History as abandoned. History '
          'shows seats and public results only, never a role.',
        ),
        _ManualEntry(
          'An MC PIN can lock Settings and Abort between matches, so the table '
          'cannot change a rule mid-game.',
        ),
      ],
    ),
    _ManualSection(
      title: 'At the table',
      entries: [
        _ManualEntry(
          'Eyes closed means eyes closed. A single peek or tap during the '
          'night can decide the game.',
        ),
        _ManualEntry(
          'Never show a character card. Claims are the game; proof ends it.',
        ),
        _ManualEntry(
          'Merlin should be useful without being obvious. The Assassin is '
          'watching for the player who knows too much.',
        ),
        _ManualEntry(
          'Evil does not have to fail every quest. Passing one now can buy the '
          'trust to fail a later one.',
        ),
        _ManualEntry(
          'Agree house rules before dealing — the vote-skipping option, a '
          'discussion timer, everything else. The app cannot change the cards.',
        ),
        _ManualEntry(
          'When in doubt about who leads, pass the token one seat clockwise. '
          'The app and the table should agree before the proposal.',
        ),
        _ManualEntry(
          'The MC records what the table sees. If a count is wrong, recount and '
          'correct it before resolving; the app waits for every seat.',
        ),
        _ManualEntry(
          'One phone is enough. Passing it around to show a role would defeat '
          'the game, and the app never needs to see a card.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AvalonScreen(
      showBackButton: true,
      appBar: AppBar(title: const Text('HOW TO PLAY')),
      backgroundImage: Artwork.roundTable,
      padded: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.md,
          Space.screenPadding,
          Space.xxl,
        ),
        children: [
          for (final section in _sections) ...[
            SectionHeader(title: section.title),
            MedievalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.intro case final intro?) ...[
                    Text(intro, style: AppText.body),
                    if (section.entries.isNotEmpty || section.table != null)
                      const SizedBox(height: Space.sm),
                  ],
                  for (final entry in section.entries)
                    _ManualEntryView(entry: entry),
                  ?section.table,
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
          ],
        ],
      ),
    );
  }
}

/// One line of the manual: a numbered step, a role, or a plain rule.
class _ManualEntry {
  const _ManualEntry(this.text, {this.number, this.term});

  final String text;
  final int? number;
  final String? term;
}

class _ManualSection {
  const _ManualSection({
    required this.title,
    this.intro,
    this.entries = const [],
    this.table,
  });

  final String title;
  final String? intro;
  final List<_ManualEntry> entries;
  final Widget? table;
}

class _ManualEntryView extends StatelessWidget {
  const _ManualEntryView({required this.entry});

  final _ManualEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: entry.number == null
                ? const Text('·', style: AppText.caption)
                : Text(
                    '${entry.number}.',
                    style: AppText.bodyStrong.copyWith(
                      color: AppColors.gold,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: entry.term == null
                ? Text(entry.text, style: AppText.body)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.term!,
                        style: AppText.bodyStrong.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(entry.text, style: AppText.body),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// The base game's team sizes, every player count in one table.
class _QuestSizeTable extends StatelessWidget {
  const _QuestSizeTable();

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(1.6),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FlexColumnWidth(),
        5: FlexColumnWidth(),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColors.divider, width: 0.5),
      ),
      children: [
        TableRow(
          children: [
            _cell('Players', header: true, align: TextAlign.start),
            for (var quest = 1; quest <= AvalonTables.questCount; quest++)
              _cell('Q$quest', header: true),
          ],
        ),
        for (
          var players = AvalonTables.minPlayers;
          players <= AvalonTables.officialMaxPlayers;
          players++
        )
          TableRow(
            children: [
              _cell('$players', align: TextAlign.start),
              for (var quest = 1; quest <= AvalonTables.questCount; quest++)
                _cell('${AvalonTables.teamSize(players, quest)}'),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    String text, {
    bool header = false,
    TextAlign align = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Text(
        text,
        textAlign: align,
        style: header
            ? AppText.caption.copyWith(fontWeight: FontWeight.w600)
            : AppText.body.copyWith(fontSize: 14),
      ),
    );
  }
}
