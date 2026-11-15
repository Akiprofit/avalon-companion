import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/section_header.dart';

/// A plain-language rules reference. Static content, no game state.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _sections = <({String title, List<String> points})>[
    (
      title: 'What this app does',
      points: [
        'It narrates the night, tracks the public state of the match and does '
            'the arithmetic. You still play with the physical Avalon cards.',
        'One person — the MC — holds the phone. Nobody else needs a device.',
        'The app never knows who holds which character. It never asks.',
      ],
    ),
    (
      title: 'Setup',
      points: [
        'Choose 5 to 10 players and enter their names in seating order.',
        'Choose the characters in play. The app checks that the good and evil '
            'counts match the player count.',
        'Shuffle and deal the physical character cards yourself.',
      ],
    ),
    (
      title: 'The night',
      points: [
        'Everyone closes their eyes. The app narrates each step in order.',
        'Minions of Mordred open their eyes and recognise each other. Oberon '
            'stays hidden from them.',
        'Merlin opens their eyes; evil players raise a thumb. Mordred does not.',
        'Percival opens their eyes and sees two thumbs: Merlin and Morgana, '
            'indistinguishable.',
      ],
    ),
    (
      title: 'Each round',
      points: [
        'The leader proposes a team of the size the quest requires.',
        'Everyone votes with a physical card. More than half approve means the '
            'team goes on the quest; a tie is a rejection.',
        'A rejection passes the leader token to the next player, and five '
            'rejections in a row win the game for evil.',
        'Settings can switch the approval vote off for a house-rules game: the '
            'leader\'s team then goes straight to the quest.',
      ],
    ),
    (
      title: 'Quests',
      points: [
        'Team members play a success or fail card. Counts are public; who '
            'played what is not.',
        'One fail card fails a quest — except quest 4 with seven or more '
            'players, which needs two.',
      ],
    ),
    (
      title: 'Winning',
      points: [
        'Good wins by completing three quests and surviving the accusation.',
        'Evil wins by failing three quests, by five consecutive rejections, or '
            'by identifying Merlin.',
        'After three successful quests the game does not end: the Assassin '
            'still gets one accusation.',
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
                  for (final point in section.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('·  ', style: AppText.caption),
                          Expanded(
                            child: Text(point, style: AppText.body),
                          ),
                        ],
                      ),
                    ),
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
