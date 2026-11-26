import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/avalon_screen.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/danger_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/medieval_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_indicator.dart';
import '../model/seat.dart';
import '../player/table_client_controller.dart';
import '../protocol/table_invite.dart';

/// Screen — the phone's resting place at the table.
///
/// It shows the seat, the name and whether the board can still see this phone.
/// It shows no character, because none has been dealt: that sentence is the
/// honest Phase 1 state and disappears when the deal exists.
class PlayerSeatScreen extends ConsumerWidget {
  const PlayerSeatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tableClientControllerProvider);

    return AvalonScreen(
      showBackButton: true,
      onBack: () => context.goNamed(RouteNames.home),
      child: switch (state) {
        JoinSeated(:final invite, :final seat) => _SeatedView(
          invite: invite,
          seatNumber: seat.seat,
          name: _nameAt(seat.seats, seat.seat) ?? 'You',
          onLeave: () => _leave(context, ref),
        ),
        JoinLost(:final attempt, :final canRetry) => _LostView(
          attempt: attempt,
          canRetry: canRetry,
          onRetry: () => unawaited(
            ref.read(tableClientControllerProvider.notifier).retry(),
          ),
          onLeave: () => _leave(context, ref),
        ),
        JoinConnecting() => const LoadingState(label: 'Reconnecting…'),
        JoinClosed() => EmptyState(
          icon: Icons.meeting_room_outlined,
          title: 'The board closed the room',
          message: 'Your seat is gone. Join again when a board is open.',
          action: PrimaryButton(
            key: const Key('seat_home'),
            label: 'Back to Home',
            onPressed: () => context.goNamed(RouteNames.home),
          ),
        ),
        _ => EmptyState(
          icon: Icons.event_seat_outlined,
          title: 'No seat',
          message: 'You are not at a table. Join one from Home.',
          action: PrimaryButton(
            key: const Key('seat_join'),
            label: 'Join a table',
            onPressed: () => context.goNamed(RouteNames.join),
          ),
        ),
      },
    );
  }

  static String? _nameAt(List<Seat> seats, int number) {
    for (final seat in seats) {
      if (seat.number == number) return seat.name;
    }
    return null;
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmation(
      context,
      title: 'Leave the table?',
      message: 'Your seat is released at once, and the board shows you gone.',
      confirmLabel: 'Leave the table',
    );
    if (!confirmed) return;

    await ref.read(tableClientControllerProvider.notifier).leave();
    if (!context.mounted) return;
    context.goNamed(RouteNames.home);
  }
}

class _SeatedView extends StatelessWidget {
  const _SeatedView({
    required this.invite,
    required this.seatNumber,
    required this.name,
    required this.onLeave,
  });

  final TableInvite invite;
  final int seatNumber;
  final String name;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      children: [
        const SectionHeader(title: 'Your seat'),
        MedievalCard(
          showTopRule: true,
          borderColor: AppColors.gold.withValues(alpha: 0.35),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceRaised,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  '$seatNumber',
                  key: const Key('seat_number'),
                  style: AppText.display.copyWith(fontSize: 38),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                name,
                key: const Key('seat_name'),
                style: AppText.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xs),
              const StatusIndicator(
                label: 'Connected',
                tone: StatusTone.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Room ', style: AppText.caption),
            Text(
              invite.code,
              style: AppText.bodyStrong.copyWith(letterSpacing: 2),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        MedievalCard(
          child: Column(
            children: [
              Text(
                'Nothing is dealt yet.',
                style: AppText.bodyStrong,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xxs),
              Text(
                'Characters arrive in a later version. For now the board knows '
                'your name and your seat, and nothing else.',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        DangerButton(
          key: const Key('seat_leave'),
          label: 'Leave the table',
          icon: Icons.logout,
          onPressed: onLeave,
        ),
      ],
    );
  }
}

class _LostView extends StatelessWidget {
  const _LostView({
    required this.attempt,
    required this.canRetry,
    required this.onRetry,
    required this.onLeave,
  });

  final int attempt;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingState(
          label: canRetry
              ? 'Lost the board — reconnecting ($attempt)…'
              : 'Lost the board. Your seat is still there.',
        ),
        const SizedBox(height: Space.lg),
        if (!canRetry)
          PrimaryButton(
            key: const Key('seat_retry'),
            label: 'Try again',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        const SizedBox(height: Space.sm),
        SecondaryButton(
          key: const Key('seat_leave'),
          label: 'Leave the table',
          onPressed: onLeave,
        ),
      ],
    );
  }
}
