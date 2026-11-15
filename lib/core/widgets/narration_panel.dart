import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'avalon_icon_button.dart';

/// Full-screen narration surface — Screen 05 of the master plan.
///
/// Purely presentational: the screen owns the controller, this widget owns the
/// layout and the controls.
class NarrationPanel extends StatelessWidget {
  const NarrationPanel({
    super.key,
    required this.heading,
    required this.text,
    required this.nextLine,
    required this.englishLabel,
    required this.filipinoLabel,
    required this.languageIsFilipino,
    required this.position,
    required this.total,
    required this.isAutoPlaying,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onReplay,
    required this.onToggleAutoPlay,
    required this.onStop,
    required this.onLanguageChanged,
    this.notice,
  });

  final String heading;
  final String text;
  final String? nextLine;
  final String englishLabel;
  final String filipinoLabel;
  final bool languageIsFilipino;
  final int position;
  final int total;
  final bool isAutoPlaying;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onToggleAutoPlay;
  final VoidCallback onStop;
  final ValueChanged<bool> onLanguageChanged;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.lg,
              Space.lg,
              Space.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        heading.toUpperCase(),
                        style: AppText.sectionTitle.copyWith(
                          letterSpacing: 2,
                          color: AppColors.mutedGold,
                        ),
                      ),
                    ),
                    Text(
                      '$position / $total',
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: total == 0 ? 0 : position / total,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.xxl),
                Text(text, style: AppText.narration),
                if (nextLine != null) ...[
                  const SizedBox(height: Space.xl),
                  Text(
                    nextLine!,
                    style: AppText.body.copyWith(
                      color: AppColors.mutedText.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (notice != null) ...[
                  const SizedBox(height: Space.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 15,
                        color: AppColors.mutedGold,
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(notice!, style: AppText.caption),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: Space.xs),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AvalonIconButton(
                    key: const Key('narration_previous'),
                    icon: Icons.skip_previous_rounded,
                    semanticLabel: 'Previous instruction',
                    onPressed: canGoBack ? onPrevious : null,
                  ),
                  AvalonIconButton(
                    key: const Key('narration_replay'),
                    icon: Icons.replay_rounded,
                    semanticLabel: 'Replay instruction',
                    onPressed: onReplay,
                  ),
                  AvalonIconButton(
                    key: const Key('narration_play_pause'),
                    icon: isAutoPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    semanticLabel: isAutoPlaying
                        ? 'Pause narration'
                        : 'Play narration',
                    isActive: true,
                    size: 64,
                    onPressed: onToggleAutoPlay,
                  ),
                  AvalonIconButton(
                    key: const Key('narration_next'),
                    icon: Icons.skip_next_rounded,
                    semanticLabel: 'Next instruction',
                    onPressed: canGoForward ? onNext : null,
                  ),
                  AvalonIconButton(
                    key: const Key('narration_stop'),
                    icon: Icons.stop_circle_outlined,
                    semanticLabel: 'Emergency stop',
                    onPressed: onStop,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, Space.md),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          side: const WidgetStatePropertyAll(
                            BorderSide(color: AppColors.divider),
                          ),
                          textStyle: WidgetStatePropertyAll(AppText.caption),
                        ),
                        segments: [
                          ButtonSegment(value: false, label: Text(englishLabel)),
                          ButtonSegment(
                            value: true,
                            label: Text(filipinoLabel),
                          ),
                        ],
                        selected: {languageIsFilipino},
                        onSelectionChanged: (selection) =>
                            onLanguageChanged(selection.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
