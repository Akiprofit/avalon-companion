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
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/medieval_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../host/table_host_controller.dart';
import '../host/table_host_server.dart';
import '../model/room_state.dart';
import '../model/seat.dart';
import '../protocol/table_invite.dart';
import '../widgets/join_qr.dart';
import '../widgets/room_code_card.dart';
import '../widgets/seat_row.dart';

/// Screen — the board. Opens one room and shows who is at the table.
///
/// It renders [RoomState] only: the code, the address and the seats. The object
/// that holds device tokens is the room's session, and it never reaches a
/// widget, which is why nothing on this screen can leak a seat credential.
class TableHostScreen extends ConsumerStatefulWidget {
  const TableHostScreen({super.key});

  @override
  ConsumerState<TableHostScreen> createState() => _TableHostScreenState();
}

class _TableHostScreenState extends ConsumerState<TableHostScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame: starting the room sets provider state, which must
    // not happen while the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(tableHostControllerProvider) is TableHostIdle) {
        unawaited(ref.read(tableHostControllerProvider.notifier).start());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableHostControllerProvider);

    return AvalonScreen(
      contentWidth: kBoardContentWidth,
      showBackButton: true,
      onBack: () => context.goNamed(RouteNames.home),
      child: switch (state) {
        TableHostIdle() || TableHostStarting() => const LoadingState(
          label: 'Opening the room…',
        ),
        TableHostFailed(:final failure) => _FailedView(
          failure: failure,
          onRetry: () =>
              unawaited(ref.read(tableHostControllerProvider.notifier).start()),
        ),
        TableHostRunning(:final room) => _BoardView(
          room: room,
          onClose: _closeRoom,
          onRelease: _releaseSeat,
        ),
        TableHostClosed() => _ClosedView(
          onHome: () => context.goNamed(RouteNames.home),
        ),
      },
    );
  }

  Future<void> _closeRoom() async {
    final confirmed = await showConfirmation(
      context,
      title: 'Close the room?',
      message:
          'Every phone loses its seat and the code stops working. '
          'Nothing is saved.',
      confirmLabel: 'Close the room',
    );
    if (!confirmed || !mounted) return;

    await ref.read(tableHostControllerProvider.notifier).closeRoom();
    if (!mounted) return;
    context.goNamed(RouteNames.home);
  }

  Future<void> _releaseSeat(Seat seat) async {
    final confirmed = await showConfirmation(
      context,
      title: 'Release seat ${seat.number}?',
      message:
          '${seat.name} will have to join again. Only release a phone that '
          'is not coming back.',
      confirmLabel: 'Release seat',
    );
    if (!confirmed || !mounted) return;
    ref.read(tableHostControllerProvider.notifier).releaseSeat(seat.number);
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.failure, required this.onRetry});

  final HostBindFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'The room did not open',
      message: switch (failure) {
        HostBindFailure.noNetwork =>
          'This device is not on a Wi-Fi network. Join one, or turn on the '
              'hotspot, and try again.',
        HostBindFailure.noPort =>
          'This device could not open a port for the room. Close other apps '
              'and try again.',
        HostBindFailure.refused =>
          'This device refused to open the room. Try again, or restart the app.',
      },
      onRetry: onRetry,
    );
  }
}

class _ClosedView extends StatelessWidget {
  const _ClosedView({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.meeting_room_outlined,
      title: 'The room is closed',
      message: 'The code no longer works. Open a new room when the table is ready.',
      action: PrimaryButton(
        key: const Key('table_host_home'),
        label: 'Back to Home',
        onPressed: onHome,
      ),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({
    required this.room,
    required this.onClose,
    required this.onRelease,
  });

  final RoomState room;
  final VoidCallback onClose;
  final ValueChanged<Seat> onRelease;

  @override
  Widget build(BuildContext context) {
    final invite = TableInvite(
      code: room.code,
      host: room.address,
      port: room.port,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kBoardBreakpoint;
        final left = _JoinColumn(room: room, invite: invite, wide: wide);
        final right = _SeatsCard(
          room: room,
          onClose: onClose,
          onRelease: onRelease,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.screenPadding,
            Space.lg,
            Space.screenPadding,
            Space.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kBoardContentWidth),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: left),
                        const SizedBox(width: Space.xl),
                        Expanded(flex: 4, child: right),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        left,
                        const SizedBox(height: Space.lg),
                        right,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _JoinColumn extends StatelessWidget {
  const _JoinColumn({
    required this.room,
    required this.invite,
    required this.wide,
  });

  final RoomState room;
  final TableInvite invite;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TABLET MODE',
          style: AppText.sectionTitle.copyWith(letterSpacing: 4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.md),
        RoomCodeCard(key: const Key('table_host_code'), code: room.code),
        const SizedBox(height: Space.lg),
        Center(
          child: JoinQr(
            key: const Key('table_host_qr'),
            data: invite.encode(),
            size: wide ? kJoinQrSizeLarge : kJoinQrSize,
            semanticLabel: 'Scan to join room ${room.code}',
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          '${room.address}:${room.port}',
          key: const Key('table_host_address'),
          style: AppText.caption.copyWith(
            color: AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'Everyone needs Avalon Companion on their phone and the same Wi-Fi. '
          'No internet is used.',
          style: AppText.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SeatsCard extends StatelessWidget {
  const _SeatsCard({
    required this.room,
    required this.onClose,
    required this.onRelease,
  });

  final RoomState room;
  final VoidCallback onClose;
  final ValueChanged<Seat> onRelease;

  @override
  Widget build(BuildContext context) {
    return MedievalCard(
      key: const Key('table_host_seats'),
      showTopRule: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'At the table',
                  padding: EdgeInsets.zero,
                ),
              ),
              MetaPill(
                label: '${room.seatedCount} of ${room.capacity}',
                color: room.isEmpty ? AppColors.mutedText : AppColors.gold,
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          if (room.seats.isEmpty)
            Text(
              'No one has joined yet. Scan the code to take the first seat.',
              style: AppText.caption,
            )
          else
            for (final seat in room.seats)
              SeatRow(
                key: ValueKey('seat_${seat.number}'),
                seat: seat,
                // A connected phone leaves on its own; only an away seat is the
                // MC's to release.
                onRelease: seat.connected ? null : () => onRelease(seat),
              ),
          const SizedBox(height: Space.md),
          DangerButton(
            key: const Key('table_host_close'),
            label: 'Close the room',
            icon: Icons.meeting_room_outlined,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
