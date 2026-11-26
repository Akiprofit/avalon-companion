import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/room_code.dart';
import '../protocol/table_invite.dart';
import '../protocol/table_protocol.dart';
import 'io_table_transport.dart';
import 'table_client.dart';
import 'table_discovery.dart';

/// Where a phone is in the join flow.
sealed class JoinState {
  const JoinState();
}

final class JoinIdle extends JoinState {
  const JoinIdle();
}

/// Looking for the board behind a typed code.
final class JoinLocating extends JoinState {
  const JoinLocating(this.code);

  final String code;
}

/// Nothing answered. The address field is the escape hatch.
final class JoinLocateFailed extends JoinState {
  const JoinLocateFailed(this.code);

  final String code;
}

/// The board was found (or scanned); the player picks a name.
final class JoinNaming extends JoinState {
  const JoinNaming(this.invite);

  final TableInvite invite;
}

final class JoinConnecting extends JoinState {
  const JoinConnecting({
    required this.invite,
    required this.name,
    required this.attempt,
  });

  final TableInvite invite;
  final String name;
  final int attempt;
}

final class JoinSeated extends JoinState {
  const JoinSeated({required this.invite, required this.seat});

  final TableInvite invite;
  final TableClientSeated seat;
}

final class JoinRejected extends JoinState {
  const JoinRejected(this.message);

  final String message;
}

final class JoinLost extends JoinState {
  const JoinLost({required this.attempt, required this.canRetry});

  final int attempt;
  final bool canRetry;
}

final class JoinClosed extends JoinState {
  const JoinClosed();
}

/// How the phone opens a socket. Overridden in tests.
final tableConnectProvider = Provider<TableConnect>(
  (ref) => connectTableSocket,
);

/// How the phone looks for a board. Overridden in tests.
typedef TableDiscoveryFactory = TableDiscovery Function();

final tableDiscoveryFactoryProvider = Provider<TableDiscoveryFactory>(
  (ref) => TableDiscovery.new,
);

final tableClientControllerProvider =
    NotifierProvider<TableClientController, JoinState>(
      TableClientController.new,
    );

/// Drives one phone's join, seat and reconnect.
///
/// The [TableClient] below it owns no timers, so this controller is the only
/// clock: a ten-second ping while seated, and a capped backoff while the board
/// is missing. Every timer is cancelled when the seat is given up or the
/// container is disposed, which is what keeps a widget test free of pending
/// timers.
class TableClientController extends Notifier<JoinState> {
  TableClient? _client;
  TableInvite? _invite;
  String _name = '';
  TableDiscovery? _discovery;
  StreamSubscription<TableClientState>? _clientSub;
  Timer? _pingTimer;
  Timer? _retryTimer;

  @override
  JoinState build() {
    ref.onDispose(() {
      unawaited(_stopClient());
      unawaited(_discovery?.cancel());
      _discovery = null;
    });
    return const JoinIdle();
  }

  /// Looks for the board that owns [rawCode].
  Future<void> locate(String rawCode) async {
    final code = RoomCode.normalise(rawCode);
    if (code == null) return;

    await _stopClient();
    await _cancelDiscovery();

    final discovery = ref.read(tableDiscoveryFactoryProvider)();
    _discovery = discovery;
    state = JoinLocating(code);

    final invite = await discovery.find(code);
    if (!identical(_discovery, discovery)) return;
    _discovery = null;

    if (invite == null) {
      if (state is JoinLocating) state = JoinLocateFailed(code);
      return;
    }
    _invite = invite;
    state = JoinNaming(invite);
  }

  /// Stops the discovery wait, e.g. when the player backs out.
  Future<void> cancelLocate() async {
    await _cancelDiscovery();
    if (state is JoinLocating) state = const JoinIdle();
  }

  /// A QR was scanned: its payload already carries the address.
  void useInvite(TableInvite invite) {
    _invite = invite;
    state = JoinNaming(invite);
  }

  /// The escape hatch: a typed `192.168.43.1:8787` for a network that drops
  /// broadcast. Returns false when the address cannot be read.
  bool useAddress(String code, String address) {
    final normalised = RoomCode.normalise(code);
    if (normalised == null) return false;

    final parts = address.trim().split(':');
    if (parts.length != 2) return false;
    final host = parts[0].trim();
    final port = int.tryParse(parts[1].trim());
    if (host.isEmpty || port == null || port < 1 || port > 65535) {
      return false;
    }

    _invite = TableInvite(code: normalised, host: host, port: port);
    state = JoinNaming(_invite!);
    return true;
  }

  /// Takes the seat, or returns to it if this phone held one.
  Future<void> seat(String rawName) async {
    final invite = _invite;
    if (invite == null) return;

    final name = normalisePlayerName(rawName);
    if (name == null) return;

    _name = name;
    await _stopClient();

    final client = TableClient(
      invite: invite,
      name: name,
      connect: ref.read(tableConnectProvider),
    );
    _client = client;
    _clientSub = client.states.listen(_onClientState);

    state = JoinConnecting(invite: invite, name: name, attempt: 1);
    await client.open();
  }

  /// Tries the seat again after the reconnect window ran out.
  Future<void> retry() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await _client?.retry();
  }

  /// Gives the seat up: the board releases it at once.
  Future<void> leave() async {
    _stopPing();
    _retryTimer?.cancel();
    _retryTimer = null;

    final client = _client;
    final sub = _clientSub;
    _clientSub = null;
    _client = null;
    await sub?.cancel();
    await client?.leave();

    _invite = null;
    state = const JoinIdle();
  }

  /// Back to the start, with nothing open.
  Future<void> reset() async {
    await _stopClient();
    await _cancelDiscovery();
    _invite = null;
    state = const JoinIdle();
  }

  // -------------------------------------------------------------------------
  // Client state
  // -------------------------------------------------------------------------

  void _onClientState(TableClientState next) {
    final invite = _invite;
    if (invite == null) return;

    switch (next) {
      case TableClientIdle():
        break;
      case TableClientConnecting(:final attempt):
        state = JoinConnecting(invite: invite, name: _name, attempt: attempt);
      case TableClientSeated():
        _startPing();
        state = JoinSeated(invite: invite, seat: next);
      case TableClientRejected(:final message):
        _stopPing();
        state = JoinRejected(message);
      case TableClientLost(:final attempt, :final canRetry):
        _stopPing();
        state = JoinLost(attempt: attempt, canRetry: canRetry);
        if (canRetry) _scheduleRetry(attempt);
      case TableClientClosed():
        _stopPing();
        state = const JoinClosed();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      TableProtocol.pingInterval,
      (_) => _client?.ping(),
    );
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _scheduleRetry(int attempt) {
    _retryTimer?.cancel();
    _retryTimer = Timer(TableClient.retryDelay(attempt), () {
      _retryTimer = null;
      unawaited(_client?.open());
    });
  }

  Future<void> _stopClient() async {
    _stopPing();
    _retryTimer?.cancel();
    _retryTimer = null;

    final sub = _clientSub;
    _clientSub = null;
    await sub?.cancel();

    final client = _client;
    _client = null;
    await client?.dispose();
  }

  Future<void> _cancelDiscovery() async {
    final discovery = _discovery;
    _discovery = null;
    await discovery?.cancel();
  }
}
