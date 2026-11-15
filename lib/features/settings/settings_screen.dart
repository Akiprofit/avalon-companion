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
import '../../core/widgets/section_header.dart';
import '../../core/widgets/settings_tile.dart';
import '../../narration_engine/models/narration_instruction.dart';
import 'settings_controller.dart';

/// Screen 15 — settings.
///
/// General, narration and game preferences are live in this build. Security
/// (the optional MC PIN) is deliberately shown as unavailable rather than
/// pretending to protect anything.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return AvalonScreen(
      appBar: AppBar(title: const Text('SETTINGS')),
      backgroundImage: Artwork.settings,
      padded: false,
      bottom: AvalonBottomNavigation(
        currentRouteName: RouteNames.settings,
        onSelected: (name) {
          if (name != RouteNames.settings) context.goNamed(name);
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.md,
          Space.screenPadding,
          Space.xxl,
        ),
        children: [
          const SectionHeader(title: 'General'),
          MedievalCard(
            child: Column(
              children: [
                SettingsTile.toggle(
                  key: const Key('settings_keep_awake'),
                  label: 'Keep screen awake',
                  description: 'Prevents the display from sleeping during a '
                      'match.',
                  value: settings.keepScreenAwake,
                  onChanged: (value) => controller.update(
                    (s) => s.copyWith(keepScreenAwake: value),
                  ),
                ),
                SettingsTile.toggle(
                  key: const Key('settings_confirmations'),
                  label: 'Confirmation dialogs',
                  description: 'Ask before leaving a live match or aborting it.',
                  value: settings.confirmations,
                  onChanged: (value) => controller.update(
                    (s) => s.copyWith(confirmations: value),
                  ),
                ),
                SettingsTile.toggle(
                  key: const Key('settings_haptics'),
                  label: 'Haptic feedback',
                  description: 'Short vibration on phase changes.',
                  value: settings.haptics,
                  onChanged: (value) => controller.update(
                    (s) => s.copyWith(haptics: value),
                  ),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Narration'),
          MedievalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Language', style: AppText.bodyStrong),
                const SizedBox(height: Space.xs),
                SegmentedButton<NarrationLanguage>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: NarrationLanguage.english,
                      label: Text('English'),
                    ),
                    ButtonSegment(
                      value: NarrationLanguage.filipino,
                      label: Text('Filipino'),
                    ),
                  ],
                  selected: {settings.defaultLanguage},
                  onSelectionChanged: (selection) =>
                      controller.setLanguage(selection.first),
                ),
                const SizedBox(height: Space.md),
                SettingsTile.slider(
                  key: const Key('settings_rate'),
                  label: 'Speech speed',
                  valueLabel: '${settings.narrationRate.toStringAsFixed(2)}x',
                  value: settings.narrationRate,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  onChanged: controller.setRate,
                ),
                SettingsTile.slider(
                  key: const Key('settings_pitch'),
                  label: 'Voice depth',
                  valueLabel: settings.narrationPitch.toStringAsFixed(2),
                  value: settings.narrationPitch,
                  min: 0.7,
                  max: 1.2,
                  // 0.02 steps keep the 0.92 default on a division boundary.
                  divisions: 25,
                  onChanged: controller.setPitch,
                ),
                SettingsTile.slider(
                  key: const Key('settings_volume'),
                  label: 'Volume',
                  valueLabel: '${(settings.volume * 100).round()}%',
                  value: settings.volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  onChanged: controller.setVolume,
                ),
                const Divider(height: Space.lg),
                SettingsTile.toggle(
                  key: const Key('settings_auto_advance'),
                  label: 'Automatic narration',
                  description: 'Advance to the next line when the current one '
                      'ends. Manual advance is the safer default.',
                  value: settings.autoAdvance,
                  onChanged: (value) => controller.update(
                    (s) => s.copyWith(autoAdvance: value),
                  ),
                ),
                SettingsTile.toggle(
                  key: const Key('settings_ambient'),
                  label: 'Ambient audio',
                  description: 'Low background sound during the night phase.',
                  value: settings.ambientAudio,
                  onChanged: (value) => controller.update(
                    (s) => s.copyWith(ambientAudio: value),
                  ),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Game'),
          MedievalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Default player count', style: AppText.bodyStrong),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.xs,
                  children: [
                    for (var count = 5; count <= 10; count++)
                      ChoiceChip(
                        key: Key('settings_default_count_$count'),
                        label: Text('$count'),
                        selected: settings.defaultPlayerCount == count,
                        onSelected: (_) => controller.setDefaultPlayerCount(count),
                      ),
                  ],
                ),
                const SizedBox(height: Space.md),
                SettingsTile.slider(
                  key: const Key('settings_discussion'),
                  label: 'Discussion timer',
                  valueLabel: '${settings.discussionSeconds ~/ 60} min',
                  value: settings.discussionSeconds.toDouble(),
                  min: 60,
                  max: 900,
                  divisions: 14,
                  onChanged: (value) =>
                      controller.setDiscussionSeconds(value.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Security'),
          MedievalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text('MC PIN', style: AppText.bodyStrong),
                    ),
                    Text(
                      'Not available yet',
                      style: AppText.caption.copyWith(
                        color: AppColors.mutedGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Settings and match management are open in this build. '
                  'PIN protection ships with the security update.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const GoldDivider(),
          const SectionHeader(title: 'About'),
          MedievalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Version', style: AppText.caption),
                    ),
                    Text(
                      '${AppInfo.version} · ${AppInfo.buildPhase}',
                      style: AppText.bodyStrong.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                Text('Privacy', style: AppText.bodyStrong),
                const SizedBox(height: Space.xxs),
                Text(AppInfo.privacy, style: AppText.caption),
                const SizedBox(height: Space.md),
                Text('Credits', style: AppText.bodyStrong),
                const SizedBox(height: Space.xxs),
                Text(AppInfo.credits, style: AppText.caption),
                const SizedBox(height: Space.md),
                Text(AppInfo.disclaimer, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

