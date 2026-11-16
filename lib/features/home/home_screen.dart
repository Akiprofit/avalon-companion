import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_bottom_navigation.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/gold_divider.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/models/phase.dart';
import '../setup/setup_controller.dart';

/// Screen 02 — entry point. New Game is the dominant action.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameSessionProvider);

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.home,
      capBottom: false,
      bottom: AvalonBottomNavigation(
        currentRouteName: RouteNames.home,
        onSelected: (name) {
          if (name != RouteNames.home) context.goNamed(name);
        },
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.xl,
          Space.screenPadding,
          Space.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Space.lg),
            const _HomeEmblem(),
            const SizedBox(height: Space.md),
            Text(
              'AVALON',
              style: AppText.display.copyWith(fontSize: 34, letterSpacing: 9),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xxs),
            Text(
              'COMPANION',
              style: AppText.sectionTitle.copyWith(letterSpacing: 6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Game Master for the physical game',
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            const GoldDivider(),
            PrimaryButton(
              key: const Key('home_new_game'),
              label: 'New Game',
              icon: Icons.add_circle_outline,
              onPressed: () {
                ref.read(setupProvider.notifier).reset();
                context.goNamed(RouteNames.setup);
              },
            ),
            const SizedBox(height: Space.sm),
            SecondaryButton(
              key: const Key('home_continue_game'),
              label: game != null && game.isFinished
                  ? 'Review the Last Match'
                  : 'Continue Game',
              icon: game != null && game.isFinished
                  ? Icons.emoji_events_outlined
                  : Icons.play_arrow_rounded,
              onPressed: game == null
                  ? null
                  : () => context.goNamed(RouteNames.dashboard),
            ),
            if (game == null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs, left: Space.xxs),
                child: Text('No match in progress.', style: AppText.caption),
              )
            else if (game.isFinished)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs, left: Space.xxs),
                child: Text(
                  'Last match ended in '
                  '${game.phase == Phase.goodVictory ? 'a Good' : 'an Evil'} '
                  'victory.',
                  style: AppText.caption,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: Space.xs, left: Space.xxs),
                child: Text(
                  'In progress: ${game.playerCount} players, quest '
                  '${game.questNumber} of 5.',
                  style: AppText.caption,
                ),
              ),
            const SizedBox(height: Space.md),
            _HomeAction(
              key: const Key('home_history'),
              icon: Icons.history_edu_outlined,
              title: 'Game History',
              subtitle: 'Past matches and their outcomes',
              onTap: () => context.goNamed(RouteNames.history),
            ),
            const SizedBox(height: Space.xs),
            _HomeAction(
              key: const Key('home_how_to_play'),
              icon: Icons.menu_book_outlined,
              title: 'How to Play',
              subtitle: 'Roles, quests, voting and victory',
              onTap: () => context.pushNamed(RouteNames.howToPlay),
            ),
            const SizedBox(height: Space.xs),
            _HomeAction(
              key: const Key('home_settings'),
              icon: Icons.tune_outlined,
              title: 'Settings',
              subtitle: 'Narration, timing and app preferences',
              onTap: () => context.goNamed(RouteNames.settings),
            ),
            const SizedBox(height: Space.xxl),
            Text(
              AppInfo.disclaimer,
              style: AppText.caption.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEmblem extends StatelessWidget {
  const _HomeEmblem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft gold aura — the only glow on the screen.
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.16),
                  AppColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.55),
              ),
            ),
            child: const Icon(
              Icons.shield_moon_outlined,
              size: 44,
              color: AppColors.lightGold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MedievalCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyStrong),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }
}
