import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/narration_panel.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../narration_engine/controllers/narration_controller.dart';
import '../../narration_engine/models/narration_instruction.dart';
import '../settings/settings_controller.dart';

/// Screen 05 — immersive night narration.
///
/// The panel shows one instruction at a time and speaks it through the Android
/// text-to-speech engine. Nothing about the match is confidential here: the
/// sequence depends on the composition, never on who holds which card.
class NarrationScreen extends ConsumerStatefulWidget {
  const NarrationScreen({super.key});

  @override
  ConsumerState<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends ConsumerState<NarrationScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = ref.read(gameSessionProvider);
      final settings = ref.read(settingsProvider);
      final controller = ref.read(narrationControllerProvider.notifier);

      controller.setVolume(settings.volume);
      controller.setRate(settings.narrationRate);
      unawaited(controller.setPitch(settings.narrationPitch));
      if (game != null) {
        controller.load(game.composition);
        controller.setLanguage(settings.defaultLanguage);
      }
      unawaited(controller.prepare());
      ref.read(gameSessionProvider.notifier).startNight();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A call, the notification shade or the screen locking takes the app away:
  /// stop talking rather than narrating an empty room.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) return;
    unawaited(ref.read(narrationControllerProvider.notifier).pause());
  }

  Future<void> _finishNight() async {
    await ref.read(narrationControllerProvider.notifier).pause();
    ref.read(gameSessionProvider.notifier).endNight();
    if (mounted) context.goNamed(RouteNames.lordSelection);
  }

  Future<void> _confirmExit() async {
    final leave = await showConfirmation(
      context,
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

    if (state.isEmpty) {
      return const AvalonScreen(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final current = state.current!;
    final isLastLine = !state.canGoForward;

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.narration,
      appBar: AppBar(
        title: const Text('NIGHT NARRATION'),
        leading: IconButton(
          key: const Key('narration_exit'),
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmExit,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.md),
            child: Center(
              child: Text(
                '${state.language == NarrationLanguage.filipino ? 'FILIPINO' : 'ENGLISH'}'
                ' · ${state.rate.toStringAsFixed(2)}x',
                style: AppText.caption,
              ),
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
        onStop: () {
          unawaited(controller.pause());
          unawaited(controller.skipToEnd());
        },
        onLanguageChanged: (isFilipino) => unawaited(
          controller.setLanguage(
            isFilipino
                ? NarrationLanguage.filipino
                : NarrationLanguage.english,
          ),
        ),
        notice: state.voiceNotice,
      ),
    );
  }
}
