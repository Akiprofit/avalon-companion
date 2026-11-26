import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/avalon_screen.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/medieval_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../model/room_code.dart';
import '../player/table_client_controller.dart';
import '../protocol/table_invite.dart';
import '../protocol/table_protocol.dart';
import '../widgets/room_code_card.dart';

/// Screen — the phone side: find the board, take a seat.
///
/// Scan and type are peers, not a primary and a fallback: a dim room and a
/// cracked camera are ordinary, and the six characters are printed on the board
/// for exactly that evening.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _showAddress = false;
  bool _addressInvalid = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  TableClientController get _controller =>
      ref.read(tableClientControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableClientControllerProvider);

    ref.listen<JoinState>(tableClientControllerProvider, (previous, next) {
      if (next is JoinSeated && previous is! JoinSeated) {
        context.goNamed(RouteNames.playerSeat);
      }
    });

    return AvalonScreen(
      showBackButton: true,
      onBack: _leaveScreen,
      child: switch (state) {
        JoinIdle() => _idle(context),
        JoinLocating(:final code) => _locating(context, code),
        JoinLocateFailed(:final code) => _locateFailed(context, code),
        JoinNaming(:final invite) => _naming(context, invite),
        JoinConnecting() => const LoadingState(label: 'Taking your seat…'),
        JoinSeated() => const LoadingState(label: 'Taking your seat…'),
        JoinRejected(:final message) => _rejected(context, message),
        JoinLost(:final attempt, :final canRetry) => _lost(
          context,
          attempt,
          canRetry,
        ),
        JoinClosed() => _closed(context),
      },
    );
  }

  void _leaveScreen() {
    unawaited(_controller.reset());
    context.goNamed(RouteNames.home);
  }

  // -------------------------------------------------------------------------
  // Stages
  // -------------------------------------------------------------------------

  Widget _idle(BuildContext context) {
    final code = RoomCode.normalise(_codeController.text);
    final canFind = code != null;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      children: [
        const SectionHeader(title: 'Join a table'),
        Text(
          'The board shows a six-character code. Scan it, or type it here.',
          style: AppText.body,
        ),
        const SizedBox(height: Space.lg),
        PrimaryButton(
          key: const Key('join_scan'),
          label: "Scan the board's code",
          icon: Icons.qr_code_scanner,
          onPressed: _scan,
        ),
        const SizedBox(height: Space.xl),
        MedievalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Or type the code', style: AppText.bodyStrong),
              const SizedBox(height: Space.xs),
              TextField(
                key: const Key('join_code'),
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: AppText.display.copyWith(
                  fontSize: 28,
                  letterSpacing: 6,
                ),
                maxLength: 7,
                decoration: const InputDecoration(
                  hintText: 'ABC 123',
                  counterText: '',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _find(),
              ),
              const SizedBox(height: Space.sm),
              PrimaryButton(
                key: const Key('join_find'),
                label: 'Find the table',
                icon: Icons.wifi_find,
                onPressed: canFind ? _find : null,
              ),
              const SizedBox(height: Space.xs),
              Text(
                'Both devices must be on the same Wi-Fi. No internet is used.',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              if (_showAddress) ...[
                const SizedBox(height: Space.md),
                Text('The board\'s address', style: AppText.bodyStrong),
                const SizedBox(height: Space.xs),
                TextField(
                  key: const Key('join_address'),
                  controller: _addressController,
                  keyboardType: TextInputType.url,
                  style: AppText.body,
                  decoration: const InputDecoration(
                    hintText: '192.168.43.1:8787',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: Space.xs),
                SecondaryButton(
                  key: const Key('join_address_connect'),
                  label: 'Connect to this address',
                  onPressed: () => _connectByAddress(canFind),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  _addressInvalid
                      ? 'Use the address the board shows, like 192.168.43.1:8787.'
                      : 'Only needed when the network blocks the code search. '
                            'The board shows its address.',
                  style: AppText.caption.copyWith(
                    color: _addressInvalid
                        ? AppColors.danger
                        : AppColors.mutedText,
                  ),
                ),
              ] else
                TextButton(
                  key: const Key('join_show_address'),
                  onPressed: () => setState(() => _showAddress = true),
                  child: Text(
                    'Enter the board\'s address instead',
                    style: AppText.caption.copyWith(color: AppColors.mutedGold),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locating(BuildContext context, String code) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LoadingState(label: 'Looking for the table…'),
        const SizedBox(height: Space.lg),
        RoomCodeCard(code: code),
        const SizedBox(height: Space.lg),
        SecondaryButton(
          key: const Key('join_cancel'),
          label: 'Cancel',
          onPressed: () => unawaited(_controller.cancelLocate()),
        ),
      ],
    );
  }

  Widget _locateFailed(BuildContext context, String code) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      children: [
        ErrorState(
          title: 'No board answered',
          message:
              'Nothing on this Wi-Fi answered for $code. Check that the board '
              'is open and that both devices are on the same network.',
          onRetry: () => unawaited(_controller.locate(code)),
        ),
        const SizedBox(height: Space.lg),
        MedievalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('The board\'s address', style: AppText.bodyStrong),
              const SizedBox(height: Space.xs),
              TextField(
                key: const Key('join_address'),
                controller: _addressController,
                keyboardType: TextInputType.url,
                style: AppText.body,
                decoration: const InputDecoration(
                  hintText: '192.168.43.1:8787',
                  isDense: true,
                ),
              ),
              const SizedBox(height: Space.sm),
              SecondaryButton(
                key: const Key('join_address_connect'),
                label: 'Connect to this address',
                onPressed: () => _connectByAddress(true),
              ),
              if (_addressInvalid) ...[
                const SizedBox(height: Space.xxs),
                Text(
                  'Use the address the board shows, like 192.168.43.1:8787.',
                  style: AppText.caption.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        SecondaryButton(
          key: const Key('join_back'),
          label: 'Start again',
          onPressed: () => unawaited(_controller.reset()),
        ),
      ],
    );
  }

  Widget _naming(BuildContext context, TableInvite invite) {
    final name = normalisePlayerName(_nameController.text);
    final canSeat = name != null;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      children: [
        RoomCodeCard(code: invite.code, caption: 'Found the board'),
        const SizedBox(height: Space.lg),
        const SectionHeader(title: 'Your name'),
        TextField(
          key: const Key('join_name'),
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          maxLength: 20,
          style: AppText.body,
          decoration: const InputDecoration(
            hintText: 'The name the table knows you by',
            counterText: '',
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _seat(),
        ),
        const SizedBox(height: Space.lg),
        PrimaryButton(
          key: const Key('join_seat'),
          label: 'Take a seat',
          icon: Icons.event_seat_outlined,
          onPressed: canSeat ? _seat : null,
        ),
        const SizedBox(height: Space.sm),
        SecondaryButton(
          key: const Key('join_other'),
          label: 'Use a different code',
          onPressed: () => unawaited(_controller.reset()),
        ),
      ],
    );
  }

  Widget _rejected(BuildContext context, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ErrorState(
          title: 'The board said no',
          message: message,
          onRetry: _seat,
          retryLabel: 'Try again',
        ),
        const SizedBox(height: Space.md),
        SecondaryButton(
          key: const Key('join_other'),
          label: 'Use a different code',
          onPressed: () => unawaited(_controller.reset()),
        ),
      ],
    );
  }

  Widget _lost(BuildContext context, int attempt, bool canRetry) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingState(
          label: canRetry
              ? 'Lost the board — reconnecting ($attempt)…'
              : 'Lost the board.',
        ),
        const SizedBox(height: Space.lg),
        if (!canRetry)
          PrimaryButton(
            key: const Key('join_retry'),
            label: 'Try again',
            icon: Icons.refresh,
            onPressed: () => unawaited(_controller.retry()),
          ),
        const SizedBox(height: Space.sm),
        SecondaryButton(
          key: const Key('join_back'),
          label: 'Back to Home',
          onPressed: _leaveScreen,
        ),
      ],
    );
  }

  Widget _closed(BuildContext context) {
    return EmptyState(
      icon: Icons.meeting_room_outlined,
      title: 'The board closed the room',
      message: 'Your seat is gone. Join again when a board is open.',
      action: PrimaryButton(
        key: const Key('join_back'),
        label: 'Back to Home',
        onPressed: _leaveScreen,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _scan() async {
    final payload = await context.pushNamed<String>(RouteNames.joinScan);
    if (!mounted || payload == null) return;
    final invite = TableInvite.parse(payload);
    if (invite == null) return;
    _controller.useInvite(invite);
  }

  void _find() {
    final code = RoomCode.normalise(_codeController.text);
    if (code == null) return;
    unawaited(_controller.locate(code));
  }

  void _connectByAddress(bool codeKnown) {
    if (!codeKnown) return;
    final code = RoomCode.normalise(_codeController.text);
    if (code == null) return;
    final ok = _controller.useAddress(code, _addressController.text);
    setState(() => _addressInvalid = !ok);
  }

  void _seat() {
    final name = normalisePlayerName(_nameController.text);
    if (name == null) return;
    unawaited(_controller.seat(name));
  }
}