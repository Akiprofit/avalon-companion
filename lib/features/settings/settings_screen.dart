import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/constants/routes.dart';
import '../../core/services/feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_bottom_navigation.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/gold_divider.dart';
import '../../core/widgets/mc_pin_dialog.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/settings_tile.dart';
import '../../narration_engine/models/narration_instruction.dart';
import '../../narration_engine/services/tts_provider.dart';
import '../../narration_engine/services/tts_service.dart';
import 'pin_controller.dart';
import 'settings_controller.dart';

/// Screen 15 — settings.
///
/// Every preference is live. When the MC has set a PIN, the screen opens locked
/// and asks for it once per app session before showing anything that could
/// change the table's behaviour.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinProvider);
    if (pin.locked) {
      return _LockedSettings(
        onUnlock: () => requestPin(
          context,
          ref,
          title: 'Settings are locked',
          message: 'Enter the MC PIN to change this device\'s preferences.',
        ),
      );
    }

    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return AvalonScreen(
      appBar: AppBar(title: const Text('SETTINGS')),
      backgroundImage: Artwork.settings,
      padded: false,
      capBottom: false,
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
                  description: 'Short vibration on taps and phase changes.',
                  value: settings.haptics,
                  onChanged: (value) => controller.update(
                    (s) => s.copyWith(haptics: value),
                  ),
                ),
                SettingsTile.toggle(
                  key: const Key('settings_sound_effects'),
                  label: 'Sound effects',
                  description: 'System tone on confirmed actions.',
                  value: settings.soundEffects,
                  onChanged: (value) => controller.update(
                    (s) => s.copyWith(soundEffects: value),
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
                Text(
                  'The night is read by the recorded narrator that ships with '
                  'the app. The voice settings below shape the fallback used '
                  'only when a recorded line cannot play.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.sm),
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
                  label: 'Fallback speed',
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
                const _VoiceChoice(),
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
                Text('Extra delay after each line', style: AppText.bodyStrong),
                const SizedBox(height: Space.xxs),
                Text(
                  'Additional waiting time after each narrator line finishes '
                  'speaking. Use it when the table needs longer to move the '
                  'physical cards.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xxs,
                  children: [
                    for (final seconds in _delayPresets)
                      ChoiceChip(
                        key: Key('settings_delay_$seconds'),
                        label: Text('${seconds}s'),
                        selected: !_isCustomDelay(settings.narratorExtraDelay) &&
                            settings.narratorExtraDelay.inSeconds == seconds,
                        onSelected: (_) => controller.setNarratorExtraDelay(
                          Duration(seconds: seconds),
                        ),
                      ),
                    ChoiceChip(
                      key: const Key('settings_delay_custom'),
                      label: Text(
                        _isCustomDelay(settings.narratorExtraDelay)
                            ? '${settings.narratorExtraDelay.inSeconds}s · Custom'
                            : 'Custom…',
                      ),
                      selected: _isCustomDelay(settings.narratorExtraDelay),
                      onSelected: (_) => _pickCustomDelay(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(
                  _delayPreview(settings.narratorExtraDelay),
                  key: const Key('settings_delay_preview'),
                  style: AppText.caption.copyWith(color: AppColors.mutedGold),
                ),
                const Divider(height: Space.lg),
                SettingsTile.toggle(
                  key: const Key('settings_auto_advance'),
                  label: 'Automatic narration',
                  description: 'Read the night through on its own: each line is '
                      'spoken, then the extra delay, then the next line. Manual '
                      'advance is the safer default.',
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
                Text('King selection mode', style: AppText.bodyStrong),
                const SizedBox(height: Space.xxs),
                Text(
                  'Choose how the quest leader is selected each round.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xxs,
                  children: [
                    for (final mode in KingSelectionMode.values)
                      ChoiceChip(
                        key: Key('settings_king_${mode.name}'),
                        label: Text(mode.label),
                        selected: settings.kingSelectionMode == mode,
                        onSelected: (_) =>
                            controller.setKingSelectionMode(mode),
                      ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(
                  settings.kingsDrawnAutomatically
                      ? 'The wheel spins at the start of every round, so a new '
                            'King leads each quest. The King who has just served '
                            'is left out of the draw.'
                      : 'The wheel spins when you open it, and the leadership '
                            'token keeps its own order between proposals.',
                  key: const Key('settings_king_description'),
                  style: AppText.caption.copyWith(color: AppColors.mutedGold),
                ),
                const SizedBox(height: Space.md),
                SettingsTile.toggle(
                  key: const Key('settings_team_vote'),
                  label: 'Team approval vote',
                  description: settings.teamVoteEnabled
                      ? 'Each proposed team is approved or rejected before the '
                            'cards are played.'
                      : 'The leader\'s team goes straight to the quest, and '
                            'rejections stop being counted.',
                  value: settings.teamVoteEnabled,
                  onChanged: controller.setTeamVoteEnabled,
                ),
                const SizedBox(height: Space.md),
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
                    Icon(
                      pin.enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: 18,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text('MC PIN', style: AppText.bodyStrong),
                    ),
                    Text(
                      pin.enabled ? 'Set' : 'Off',
                      style: AppText.caption.copyWith(
                        color: AppColors.mutedGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  pin.enabled
                      ? 'Settings and Abort ask for the PIN once per app '
                            'session. The app stores only a salted hash.'
                      : 'Optional. Keeps players out of settings and away from '
                            'Abort between rounds.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.md),
                if (pin.enabled) ...[
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('settings_change_pin'),
                          label: 'Change PIN',
                          onPressed: () => _changePin(context, ref),
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: SecondaryButton(
                          key: const Key('settings_remove_pin'),
                          label: 'Remove PIN',
                          onPressed: () => _removePin(context, ref),
                        ),
                      ),
                    ],
                  ),
                ] else
                  PrimaryButton(
                    key: const Key('settings_set_pin'),
                    label: 'Set a PIN',
                    onPressed: () => _changePin(context, ref),
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

  /// Sets or replaces the PIN. The dialog asks twice, so a typo cannot lock the
  /// device out of its own settings.
  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final pin = await requestNewPin(context);
    if (pin == null || !context.mounted) return;
    final saved = await ref.read(pinProvider.notifier).setPin(pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'MC PIN saved. It is asked once per app session.'
              : 'The PIN could not be saved on this device.',
        ),
      ),
    );
  }

  Future<void> _removePin(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      ref,
      title: 'Remove the MC PIN?',
      message: 'Settings and Abort will be open to anyone holding the phone.',
      confirmLabel: 'Remove PIN',
    );
    if (!confirmed || !context.mounted) return;
    final cleared = await ref.read(pinProvider.notifier).clear();
    if (!context.mounted) return;
    if (!cleared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The PIN could not be removed.')),
      );
    }
  }

  /// Any whole number of seconds between 0 and 20, for tables that need longer
  /// than the presets.
  Future<void> _pickCustomDelay(BuildContext context, WidgetRef ref) async {
    final current = ref.read(settingsProvider).narratorExtraDelay.inSeconds;
    var draft = current.clamp(0, 20);
    final choice = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Custom extra delay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _delayPreview(Duration(seconds: draft)),
                key: const Key('settings_delay_dialog_preview'),
                style: AppText.body,
              ),
              const SizedBox(height: Space.sm),
              Slider(
                key: const Key('settings_delay_slider'),
                value: draft.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                label: '${draft}s',
                onChanged: (value) =>
                    setDialogState(() => draft = value.round()),
              ),
            ],
          ),
          actions: [
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            PrimaryButton(
              key: const Key('settings_delay_save'),
              label: 'Save',
              onPressed: () => Navigator.of(dialogContext).pop(draft),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    ref
        .read(settingsProvider.notifier)
        .setNarratorExtraDelay(Duration(seconds: choice));
    ref.read(feedbackProvider).tap();
  }
}

/// The preset extra delays offered in settings, in seconds.
const List<int> _delayPresets = [0, 1, 2, 3, 5, 7, 10];

/// True when the stored delay is not one of the presets.
bool _isCustomDelay(Duration delay) =>
    delay.inSeconds > 0 && !_delayPresets.contains(delay.inSeconds);

/// The plain sentence shown under the chips, so the MC sees what the value does.
String _delayPreview(Duration delay) {
  final seconds = delay.inSeconds;
  if (seconds <= 0) {
    return 'Each narration slide continues as soon as the line finishes.';
  }
  return 'Each narration slide will wait an additional $seconds '
      '${seconds == 1 ? 'second' : 'seconds'} before continuing.';
}

/// Picks the fallback voice from what the phone actually has installed.
///
/// The recordings are the narrator; this voice covers only a line the app has
/// no recording for. The list comes from the speech engine itself; an app
/// cannot know which voices are installed, and a fixed list would be a lie on
/// most phones.
class _VoiceChoice extends ConsumerStatefulWidget {
  const _VoiceChoice();

  @override
  ConsumerState<_VoiceChoice> createState() => _VoiceChoiceState();
}

class _VoiceChoiceState extends ConsumerState<_VoiceChoice> {
  List<TtsVoice> _voices = const [];
  NarrationLanguage? _loadedFor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final language = ref.read(settingsProvider).defaultLanguage;
    if (mounted) setState(() => _loading = true);
    List<TtsVoice> voices;
    try {
      voices = await ref.read(ttsServiceProvider).voices(language.localeCode);
    } catch (_) {
      voices = const [];
    }
    if (!mounted) return;
    setState(() {
      _voices = [
        for (final voice in voices)
          if (!voice.networkRequired) voice,
      ];
      _loadedFor = language;
      _loading = false;
    });
  }

  TtsVoice? get _selected {
    final id = ref.watch(settingsProvider).narratorVoiceId;
    if (id == null) return null;
    for (final voice in _voices) {
      if (voice.id == id) return voice;
    }
    return null;
  }

  Future<void> _pick() async {
    final current = ref.read(settingsProvider).narratorVoiceId;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Fallback voice'),
          contentPadding: const EdgeInsets.symmetric(vertical: Space.md),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    key: const Key('voice_auto'),
                    leading: _Check(selected: current == null),
                    title: const Text('Automatic'),
                    subtitle: const Text(
                      'The best installed voice for the language.',
                    ),
                    onTap: () => Navigator.of(dialogContext).pop(''),
                  ),
                  for (final voice in _voices)
                    ListTile(
                      key: Key('voice_${voice.id}'),
                      leading: _Check(selected: voice.id == current),
                      title: Text(voice.name),
                      subtitle: Text(voice.locale),
                      onTap: () => Navigator.of(dialogContext).pop(voice.id),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
    if (choice == null || !mounted) return;
    ref.read(settingsProvider.notifier).update(
      (s) => choice.isEmpty
          ? s.copyWith(clearNarratorVoice: true)
          : s.copyWith(narratorVoiceId: choice),
    );
    ref.read(feedbackProvider).tap();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider.select((s) => s.defaultLanguage), (_, next) {
      if (next != _loadedFor) _load();
    });
    final selected = _selected;
    final label = _loading
        ? 'Reading…'
        : selected == null
        ? 'Automatic'
        : selected.name;

    return InkWell(
      key: const Key('settings_voice'),
      borderRadius: BorderRadius.circular(Radii.card),
      onTap: _voices.isEmpty ? null : _pick,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fallback voice', style: AppText.bodyStrong),
                  const SizedBox(height: 2),
                  Text(
                    _voices.isEmpty && !_loading
                        ? 'This phone exposes no selectable voices; the '
                              'engine picks one.'
                        : 'Used only when a recorded line cannot play, chosen '
                              'from the voices installed on this phone.',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Flexible(
              child: Text(
                label,
                style: AppText.bodyStrong.copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            if (_voices.isNotEmpty)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.mutedText,
              ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      color: selected ? AppColors.gold : AppColors.mutedText,
      size: 20,
    );
  }
}

/// What the settings screen shows before the PIN is entered.
/// Deliberately blank rather than dimmed: a locked phone on the table should not
/// preview the discussion timer or narration speed to the table.
class _LockedSettings extends StatelessWidget {
  const _LockedSettings({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return AvalonScreen(
      appBar: AppBar(title: const Text('SETTINGS')),
      backgroundImage: Artwork.settings,
      capBottom: false,
      bottom: AvalonBottomNavigation(
        currentRouteName: RouteNames.settings,
        onSelected: (name) {
          if (name != RouteNames.settings) context.goNamed(name);
        },
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.md),
          child: MedievalCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: AppColors.mutedGold,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Settings are locked',
                  style: AppText.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Enter the MC PIN to change this device. The match itself '
                  'stays playable without it.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.lg),
                PrimaryButton(
                  key: const Key('settings_unlock'),
                  label: 'Unlock settings',
                  icon: Icons.lock_open_rounded,
                  onPressed: onUnlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

