import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/feedback.dart';
import '../settings/settings_controller.dart';

/// The MC's discussion clock. It is a UI convenience, not a rule: nothing in
/// the engine depends on it, and the match can continue with it stopped.
class DiscussionTimerState {
  const DiscussionTimerState({
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.isRunning,
  });

  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

  bool get isFinished => remainingSeconds == 0;

  String get label {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  DiscussionTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
  }) {
    return DiscussionTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class DiscussionTimerController extends Notifier<DiscussionTimerState> {
  Timer? _ticker;

  @override
  DiscussionTimerState build() {
    ref.onDispose(_stopTicker);
    final seconds = ref.read(settingsProvider).discussionSeconds;
    return DiscussionTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: false,
    );
  }

  void start() {
    if (state.isRunning || state.remainingSeconds == 0) return;
    state = state.copyWith(isRunning: true);
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (!state.isRunning) return;
    _stopTicker();
    state = state.copyWith(isRunning: false);
  }

  void toggle() => state.isRunning ? pause() : start();

  void reset([int? seconds]) {
    _stopTicker();
    final total = seconds ?? state.totalSeconds;
    state = DiscussionTimerState(
      totalSeconds: total,
      remainingSeconds: total,
      isRunning: false,
    );
  }

  void _tick() {
    final remaining = state.remainingSeconds - 1;
    if (remaining <= 0) {
      _stopTicker();
      state = state.copyWith(remainingSeconds: 0, isRunning: false);
      // The table can see the ring, but a phone lying flat needs to say this
      // out loud: two heavy taps mean the discussion is over.
      ref.read(feedbackProvider).alarm();
      return;
    }
    state = state.copyWith(remainingSeconds: remaining);
    // One quiet tick with ten seconds left, so the MC can start closing the
    // discussion without watching the screen.
    if (remaining == 10) ref.read(feedbackProvider).tap();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}

final discussionTimerProvider =
    NotifierProvider<DiscussionTimerController, DiscussionTimerState>(
      DiscussionTimerController.new,
    );
