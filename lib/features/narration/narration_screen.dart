import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/services/host_services.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/narration_panel.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../narration_engine/controllers/narration_controller.dart';
import '../../narration_engine/models/narration_instruction.dart';
import '../settings/settings_controller.dart';

/// Screen 05 — immersive night narration.
///
/// The panel shows one instruction at a time and plays it from the recordings
/// bundled with the app, falling back to the Android text-to-speech engine for
/// a line no recording covers. Nothing about the match is confidential here:
/// the sequence depends on the composition, never on who holds which card.
class NarrationScreen extends ConsumerStatefulWidget {
  const NarrationScreen({super.key});

  @override
  ConsumerState<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends ConsumerState<NarrationScreen>
    with WidgetsBindingObserver {
  late final HostServices _host;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _host = ref.read(hostServicesProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = ref.read(gameSessionProvider);
      final settings = ref.read(settingsProvider);
      final controller = ref.read(narrationControllerProvider.notifier);

      controller.setVolume(settings.volume);
      controller.setRate(settings.narrationRate);
      controller.setExtraDelay(settings.narratorExtraDelay);
      unawaited(controller.setPitch(settings.narrationPitch));
      unawaited(controller.setVoice(settings.narratorVoiceId));
      unawaited(controller.setVoicePack(settings.narratorPackId));
      if (game != null) {
        controller.load(game.composition);
        controller.setLanguage(settings.defaultLanguage);
      }
      unawaited(
        controller.prepare().then((_) async {
          if (!mounted) return;
          // "Automatic narration": the night starts reading by itself, so every
          // line gets its own beat plus the extra delay the MC configured.
          if (settings.autoAdvance) await controller.toggleAutoPlay();
        }),
      );
      ref.read(gameSessionProvider.notifier).startNight();
      unawaited(_host.setAmbient(settings.ambientAudio));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_host.setAmbient(false));
    super.dispose();
  }

  /// A call, the notification shade or the screen locking takes the app away:
  /// stop talking — and stop the bed under it — rather than narrating an empty
  /// room. The ambience returns with the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      if (ref.read(settingsProvider).ambientAudio) {
        unawaited(_host.setAmbient(true));
      }
      return;
    }
    unawaited(ref.read(narrationControllerProvider.notifier).pause());
    unawaited(_host.setAmbient(false));
  }

  Future<void> _finishNight() async {
    await ref.read(narrationControllerProvider.notifier).pause();
    ref.read(gameSessionProvider.notifier).endNight();
    if (mounted) context.goNamed(RouteNames.lordSelection);
  }

  /// The one control that ends the night early. It is deliberately away from
  /// **Next**, in the app bar, and always asks first: a stray thumb between
  /// lines must not skip the rest of the script.
  Future<void> _confirmEndNight() async {
    final end = await confirmAction(
      context,
      ref,
      title: 'End the night?',
      message:
          'The narration stops here and the match moves on to drawing the '
          'first King. Lines you have not reached will not be read.',
      confirmLabel: 'End the night',
      isDestructive: false,
    );
    if (!end || !mounted) return;
    await _finishNight();
  }

  Future<void> _confirmExit() async {
    final leave = await confirmAction(
      context,
      ref,
      title: 'Leave the narration?',
      message:
          'The match keeps its state. You can reopen the night narration from '
          'the dashboard.',
      confirmLabel: 'Leave narration',
      isDestructive: false,
    );
    if (!leave || !mounted) return;
    await ref.read(narrationControllerProvider.notifier).pause();
    if (mounted) context.goNamed(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(narrationControllerProvider);
    final controller = ref.read(narrationControllerProvider.notifier);

    // A change in settings applies from the next line, never mid-sentence.
    ref.listen(
      settingsProvider.select((s) => s.narratorExtraDelay),
      (_, next) => controller.setExtraDelay(next),
    );

    if (state.isEmpty) {
      return AvalonScreen(child: LoadingState(label: 'Preparing the night…'));
    }

    final current = state.current!;
    final isLastLine = !state.canGoForward;

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.narration,
      appBar: AppBar(
        title: const Text('THE NIGHT'),
        leading: IconButton(
          key: const Key('narration_exit'),
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmExit,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.xs),
            child: TextButton.icon(
              key: const Key('narration_end'),
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
              label: const Text('End night'),
              onPressed: _confirmEndNight,
            ),
          ),
        ],
      ),
      child: NarrationPanel(
        heading: current.heading,
        text: current.textFor(state.language),
        nextLine: state.nextLine?.textFor(state.language),
        englishLabel: 'English',
        filipinoLabel: 'Filipino',
        languageIsFilipino: state.language == NarrationLanguage.filipino,
        position: state.position,
        total: state.total,
        isAutoPlaying: state.isAutoPlaying,
        canGoBack: state.canGoBack,
        canGoForward: true,
        onPrevious: () => unawaited(controller.previous()),
        onNext: isLastLine
            ? () => unawaited(_finishNight())
            : () => unawaited(controller.next()),
        onReplay: () => unawaited(controller.replay()),
        onToggleAutoPlay: () => unawaited(controller.toggleAutoPlay()),
        onLanguageChanged: (isFilipino) => unawaited(
          controller.setLanguage(
            isFilipino ? NarrationLanguage.filipino : NarrationLanguage.english,
          ),
        ),
        notice: state.voiceNotice,
      ),
    );
  }
}
