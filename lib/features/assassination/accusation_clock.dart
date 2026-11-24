import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avalon_icon_button.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/section_header.dart';

/// The two minutes the table gives the assassin.
///
/// It is a nudge, not a rule: nothing is blocked when it reaches zero, and the
/// accusation is recorded exactly as it was before this clock existed. It
/// starts as soon as the screen opens, because the MC should not have to touch
/// the phone during an accusation, but the ring pauses and resumes it and the
/// restart button gives the table another two minutes if it needs them.
class AccusationClock extends ConsumerStatefulWidget {
  const AccusationClock({super.key, this.seconds = defaultSeconds});

  /// Two minutes — the usual Avalon accusation window.
  static const defaultSeconds = 120;

  /// Ten seconds left turns the numerals red and taps once, so the MC can
  /// start closing the accusation without watching the screen.
  static const urgentSeconds = 10;

  final int seconds;

  @override
  ConsumerState<AccusationClock> createState() => _AccusationClockState();
}

class _AccusationClockState extends ConsumerState<AccusationClock> {
  /// Not null exactly while the clock is running, so it doubles as the flag.
  Timer? _ticker;
  late int _remaining = widget.seconds;

  bool get _finished => _remaining == 0;
  bool get _urgent => _remaining <= AccusationClock.urgentSeconds;
  bool get _running => _ticker != null;

  String get _label =>
      '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    // Runs from the first frame: the accusation has already begun when this
    // card appears.
    _ticker = _newTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Timer _newTicker() =>
      Timer.periodic(const Duration(seconds: 1), (_) => _tick());

  void _tick() {
    final remaining = _remaining - 1;

    if (remaining <= 0) {
      _ticker?.cancel();
      setState(() {
        _ticker = null;
        _remaining = 0;
      });
      ref.read(feedbackProvider).alarm();
      return;
    }

    setState(() => _remaining = remaining);
    if (remaining == AccusationClock.urgentSeconds) {
      ref.read(feedbackProvider).tap();
    }
  }

  void _start() {
    if (_running || _finished) return;
    setState(() => _ticker = _newTicker());
  }

  void _pause() {
    if (!_running) return;
    setState(() {
      _ticker?.cancel();
      _ticker = null;
    });
  }

  void _restart() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.seconds;
      _ticker = _newTicker();
    });
  }

  void _toggle() => _finished
      ? _restart()
      : _running
      ? _pause()
      : _start();

  @override
  Widget build(BuildContext context) {
    final status = _finished
        ? "Time's up"
        : _running
        ? 'Running'
        : 'Paused';
    final title = _finished
        ? "Time's up"
        : _running
        ? 'Two minutes to accuse'
        : 'Clock paused';
    final caption = _finished
        ? 'The clock is only a nudge — record what the table decided.'
        : _running
        ? 'Name one player. The app never asks who.'
        : 'Tap the ring to give the table the rest of the two minutes.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'The accusation clock',
          trailing: MetaPill(label: status),
        ),
        MedievalCard(
          child: Row(
            children: [
              Semantics(
                button: true,
                label: _finished
                    ? 'The accusation clock is over. Tap to start two more '
                          'minutes.'
                    : _running
                    ? 'Pause the accusation clock'
                    : 'Start the accusation clock',
                child: InkResponse(
                  key: const Key('accusation_ring'),
                  onTap: _toggle,
                  containedInkWell: true,
                  highlightShape: BoxShape.circle,
                  radius: 40,
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: CircularProgressIndicator(
                            value: widget.seconds == 0
                                ? 0
                                : _remaining / widget.seconds,
                            strokeWidth: 6,
                            backgroundColor: AppColors.surfaceRaised,
                            color: _urgent ? AppColors.danger : AppColors.gold,
                          ),
                        ),
                        Text(
                          _label,
                          key: const Key('accusation_time'),
                          style: AppText.numeral.copyWith(
                            fontSize: 20,
                            color: _urgent ? AppColors.danger : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodyStrong),
                    const SizedBox(height: Space.xxs),
                    Text(caption, style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              AvalonIconButton(
                key: const Key('accusation_restart'),
                icon: Icons.restart_alt_rounded,
                semanticLabel: 'Restart the two minutes',
                onPressed: _restart,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
