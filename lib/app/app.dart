import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_info.dart';
import '../core/services/feedback.dart';
import '../core/services/host_services.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/settings_controller.dart';
import '../game_engine/controllers/game_session_controller.dart';
import 'router.dart';

/// The app shell.
///
/// Besides the router it owns the two platform behaviours that depend on the
/// whole session rather than one screen: keeping the display awake while a
/// match is live, and a short vibration when the match changes phase.
class AvalonApp extends ConsumerStatefulWidget {
  const AvalonApp({super.key});

  @override
  ConsumerState<AvalonApp> createState() => _AvalonAppState();
}

class _AvalonAppState extends ConsumerState<AvalonApp> {
  @override
  void initState() {
    super.initState();
    // The restored match is already in the provider at the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyKeepAwake();
    });
  }

  /// The screen stays on only while there is something to watch: a live match.
  void _applyKeepAwake() {
    final game = ref.read(gameSessionProvider);
    final keep = ref.read(settingsProvider).keepScreenAwake;
    final live = game != null && !game.phase.isVictory;
    unawaited(ref.read(hostServicesProvider).setKeepAwake(keep && live));
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    ref.listen(gameSessionProvider, (previous, next) {
      _applyKeepAwake();
      final before = previous?.phase;
      final after = next?.phase;
      if (before != null && after != null && before != after) {
        ref.read(feedbackProvider).phaseChange();
      }
    });
    ref.listen(
      settingsProvider.select((s) => s.keepScreenAwake),
      (_, _) => _applyKeepAwake(),
    );

    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
