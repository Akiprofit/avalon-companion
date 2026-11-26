import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/host_services.dart';
import '../model/room_code.dart';
import '../model/room_state.dart';
import '../protocol/table_announcement.dart';
import '../protocol/table_connection.dart';
import '../table_mode_providers.dart';
import 'table_announcer.dart';
import 'table_announcer_control.dart';
import 'table_host_server.dart';
import 'table_host_transport.dart';
import 'table_room.dart';

/// What the board is doing.
sealed class TableHostState {
  const TableHostState();
}

/// Nothing has been started yet. The screen starts the room on first build.
final class TableHostIdle extends TableHostState {
  const TableHostIdle();
}

final class TableHostStarting extends TableHostState {
  const TableHostStarting();
}

/// The room is open. [room] is the public projection: code, address, seats.
/// It has no token and no private bookkeeping, so the screen cannot render one.
final class TableHostRunning extends TableHostState {
  const TableHostRunning(this.room);

  final RoomState room;
}

final class TableHostFailed extends TableHostState {
  const TableHostFailed(this.failure);

  final HostBindFailure failure;
}

final class TableHostClosed extends TableHostState {
  const TableHostClosed();
}

/// How the board's sockets are made. Overridden in widget tests.
typedef TableHostTransportFactory = TableHostTransport Function();

/// How the LAN announcement is made. Overridden in widget tests.
typedef TableAnnouncerFactory =
    TableAnnouncerControl Function(TableAnnouncement announcement, int port);

final tableHostTransportFactoryProvider = Provider<TableHostTransportFactory>(
  (ref) => IoTableHostServer.new,
);

final tableAnnouncerFactoryProvider = Provider<TableAnnouncerFactory>(
  (ref) => (announcement, port) =>
      TableAnnouncer(announcement: announcement, port: port),
);

final tableHostControllerProvider =
    NotifierProvider<TableHostController, TableHostState>(
      TableHostController.new,
    );

/// Opens the room, keeps it alive, and tears it down.
///
/// It owns the timers the pure room deliberately does not: a five-second sweep
/// for silent phones, and nothing else. Everything it talks to is behind an
/// interface, so a widget test drives the whole lobby with in-memory
/// connections and never binds a port.
class TableHostController extends Notifier<TableHostState> {
  TableHostTransport? _transport;
  TableAnnouncerControl? _announcer;
  TableRoom? _room;
  HostServices? _hostServices;
  StreamSubscription<TableConnection>? _connectionSub;
  StreamSubscription<RoomState>? _stateSub;
  Timer? _sweepTimer;

  @override
  TableHostState build() {
    ref.onDispose(() {
      // The container is going away; timers must not outlive it.
      unawaited(_teardown());
    });
    return const TableHostIdle();
  }

  /// Opens the room. A second call while starting or running does nothing.
  Future<void> start() async {
    final current = state;
    if (current is TableHostStarting || current is TableHostRunning) return;

    state = const TableHostStarting();

    final transport = ref.read(tableHostTransportFactoryProvider)();
    _transport = transport;

    final (binding, failure) = await transport.bind();
    if (binding == null) {
      await transport.close();
      _transport = null;
      state = TableHostFailed(failure ?? HostBindFailure.refused);
      return;
    }

    final code = RoomCode.generate();
    final boardName = ref.read(tableBoardNameProvider);
    final room = TableRoom(
      code: code,
      address: binding.address,
      port: binding.port,
      boardName: boardName,
    );
    _room = room;

    _connectionSub = transport.connections.listen(room.attach);
    _stateSub = room.states.listen((roomState) {
      if (state is TableHostRunning) state = TableHostRunning(roomState);
    });
    _sweepTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => room.sweep(),
    );

    final announcer = ref.read(tableAnnouncerFactoryProvider)(
      TableAnnouncement(
        code: code,
        port: binding.port,
        boardName: boardName,
      ),
      binding.port,
    );
    _announcer = announcer;
    unawaited(announcer.start());

    // The board is watched from across the table; letting the screen sleep
    // would end the room.
    final hostServices = ref.read(hostServicesProvider);
    _hostServices = hostServices;
    unawaited(hostServices.setKeepAwake(true));

    state = TableHostRunning(room.state);
  }

  /// Releases a seat from the board, e.g. a phone that is not coming back.
  void releaseSeat(int seat) {
    final room = _room;
    if (room == null) return;
    if (room.releaseSeat(seat)) state = TableHostRunning(room.state);
  }

  /// Closes the room for everyone and leaves the screen in a closed state.
  Future<void> closeRoom() async {
    await _teardown();
    state = const TableHostClosed();
  }

  Future<void> _teardown() async {
    _sweepTimer?.cancel();
    _sweepTimer = null;

    // Cancelling takes effect immediately; the returned future only reports
    // when the stream has finished tidying up. Nothing below depends on that
    // report, and waiting for it would stall the screen if a socket's stream
    // never completes, so the cancels are fire-and-forget.
    final connectionSub = _connectionSub;
    _connectionSub = null;
    if (connectionSub != null) unawaited(connectionSub.cancel());

    final stateSub = _stateSub;
    _stateSub = null;
    if (stateSub != null) unawaited(stateSub.cancel());

    final announcer = _announcer;
    _announcer = null;
    await announcer?.stop();

    final room = _room;
    _room = null;
    await room?.close();

    final transport = _transport;
    _transport = null;
    await transport?.close();

    final hostServices = _hostServices;
    _hostServices = null;
    await hostServices?.setKeepAwake(false);
  }
}
