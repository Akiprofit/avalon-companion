// Synthetic phones, driven against a real board over real sockets.
//
// This is the tool the Phase 1 stop condition is measured with when the board
// is a real device and there is only one phone in the room:
//
//   dart run tool/table_client_probe.dart --host=192.168.43.1 --port=8787 --code=ABC234
//   dart run tool/table_client_probe.dart --clients=8 --minutes=10 --drop=3
//
// It reports per-phone join latency against the 15 s budget, optionally drops
// one phone and checks it comes back to the same seat with the same token, and
// optionally soaks the room with pings so the board's silence watchdog has
// nothing to sweep.
//
// Exit code 0 means every phone was seated, the dropped phone returned to its
// own seat, the soak kept every seat connected, and every phone left cleanly.
// Anything else prints why and exits non-zero.

import 'dart:async';
import 'dart:io';

import 'package:avalon_companion/features/table_mode/io/websocket_table_connection.dart';
import 'package:avalon_companion/features/table_mode/player/table_client.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_connection.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_invite.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_protocol.dart';

/// One synthetic phone and the connections it has used.
class ProbePhone {
  ProbePhone(this.client);

  final TableClient client;
  final List<DroppableConnection> connections = [];

  DroppableConnection get current => connections.last;

  TableClientSeated get seated => client.state as TableClientSeated;
}

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final invite = TableInvite(
    code: options.code,
    host: options.host,
    port: options.port,
  );

  final phones = <ProbePhone>[];
  var failed = false;

  // A developer machine may carry `http_proxy` in its environment, and Dart's
  // socket would be routed through it. A room is on the LAN: go straight there.
  final direct = HttpClient()..findProxy = ((_) => 'DIRECT');

  ProbePhone makePhone(int index) {
    late final ProbePhone phone;
    final client = TableClient(
      invite: invite,
      name: 'Probe $index',
      connect: (uri) async {
        final connection = DroppableConnection(
          WebSocketTableConnection(
            await WebSocket.connect(uri.toString(), customClient: direct),
          ),
        );
        phone.connections.add(connection);
        return connection;
      },
    );
    phone = ProbePhone(client);
    return phone;
  }

  try {
    final budget = TableProtocol.connectTimeout.inMilliseconds * 3;
    final joins = <int>[];

    for (var index = 1; index <= options.clients; index++) {
      final phone = makePhone(index);
      phones.add(phone);

      final stopwatch = Stopwatch()..start();
      await phone.client.open();
      stopwatch.stop();

      if (phone.client.state is! TableClientSeated) {
        stderr.writeln(
          'phone $index was not seated: ${phone.client.state.runtimeType}',
        );
        failed = true;
        continue;
      }

      final seated = phone.seated;
      joins.add(stopwatch.elapsedMilliseconds);
      stdout.writeln(
        'phone $index seated at ${seated.seat} in '
        '${stopwatch.elapsedMilliseconds}ms '
        '(${seated.seats.length} at the table)',
      );
      if (stopwatch.elapsedMilliseconds > budget) {
        stderr.writeln('phone $index took longer than the join budget');
        failed = true;
      }
    }

    if (joins.isNotEmpty) {
      final slowest = joins.reduce((a, b) => a > b ? a : b);
      stdout.writeln(
        'slowest join ${slowest}ms, budget ${budget}ms '
        '(${budget ~/ 1000}s per player)',
      );
    }

    final seats = phones.map((phone) => phone.seated.seat).toSet();
    if (seats.length != phones.length) {
      stderr.writeln('two phones were given the same seat: $seats');
      failed = true;
    }

    if (options.drop > 0 && options.drop <= phones.length) {
      final phone = phones[options.drop - 1];
      final seat = phone.seated.seat;
      final token = phone.seated.token;

      // The Wi-Fi goes away: the phone stops hearing the board while the
      // board's socket is still open, so the seat has to be won back by token.
      phone.current.drop();
      await _waitFor(
        () => phone.client.state is TableClientLost,
        timeout: const Duration(seconds: 10),
      );

      final back = Stopwatch()..start();
      await phone.client.open();
      back.stop();

      if (phone.client.state is! TableClientSeated) {
        stderr.writeln(
          'phone ${options.drop} did not come back: '
          '${phone.client.state.runtimeType}',
        );
        failed = true;
      } else {
        final again = phone.seated;
        stdout.writeln(
          'phone ${options.drop} back at seat ${again.seat} in '
          '${back.elapsedMilliseconds}ms',
        );
        if (again.seat != seat || again.token != token) {
          stderr.writeln(
            'phone ${options.drop} moved from seat $seat to ${again.seat} '
            'or lost its token',
          );
          failed = true;
        }
      }
    }

    if (options.minutes > 0) {
      final soak = Duration(minutes: options.minutes);
      stdout.writeln(
        'soaking ${phones.length} phones for ${options.minutes} min, '
        'pinging every ${TableProtocol.pingInterval.inSeconds}s',
      );
      final ping = Timer.periodic(TableProtocol.pingInterval, (_) {
        for (final phone in phones) {
          phone.client.ping();
        }
      });
      await Future<void>.delayed(soak);
      ping.cancel();

      final stillSeated = phones
          .where((phone) => phone.client.state is TableClientSeated)
          .length;
      stdout.writeln(
        'after soak: $stillSeated of ${phones.length} still seated',
      );
      if (stillSeated != phones.length) {
        stderr.writeln('a phone lost its seat during the soak');
        failed = true;
      }
    }

    for (final phone in phones) {
      await phone.client.leave();
    }
    stdout.writeln('all ${phones.length} phones left cleanly');
  } on Object catch (error) {
    stderr.writeln('probe failed: $error');
    failed = true;
  } finally {
    for (final phone in phones) {
      await phone.client.dispose();
    }
  }

  if (failed) {
    exit(1);
  }
  stdout.writeln('client probe passed');
  // Exit explicitly: a probe holds sockets by design, and a lingering handle
  // must not keep the VM alive after every phone has left.
  exit(0);
}

/// A connection whose incoming stream can be cut while the socket stays open.
///
/// This is the phone's view of a Wi-Fi drop: the board is still there, the
/// phone simply cannot hear it any more.
class DroppableConnection implements TableConnection {
  DroppableConnection(this._inner) {
    _subscription = _inner.incoming.listen(
      _frames.add,
      onDone: _frames.close,
      onError: (Object _) => _frames.close(),
    );
  }

  final TableConnection _inner;
  final StreamController<String> _frames = StreamController<String>();
  StreamSubscription<String>? _subscription;
  bool _dropped = false;

  @override
  String get id => _inner.id;

  @override
  Stream<String> get incoming => _frames.stream;

  @override
  int? get closeCode => _inner.closeCode;

  @override
  void send(String frame) => _inner.send(frame);

  @override
  Future<void> close({int? code, String? reason}) async {
    await _subscription?.cancel();
    _subscription = null;
    if (!_frames.isClosed) await _frames.close();
    await _inner.close(code: code, reason: reason);
  }

  /// Stops hearing the board without telling it anything.
  void drop() {
    if (_dropped) return;
    _dropped = true;
    _subscription?.cancel();
    _subscription = null;
    if (!_frames.isClosed) _frames.close();
  }
}

Future<void> _waitFor(
  bool Function() condition, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition never became true', timeout);
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _Options {
  const _Options({
    required this.host,
    required this.port,
    required this.code,
    required this.clients,
    required this.minutes,
    required this.drop,
  });

  final String host;
  final int port;
  final String code;
  final int clients;
  final int minutes;
  final int drop;

  static _Options parse(List<String> args) {
    var host = '127.0.0.1';
    var port = 8787;
    var code = 'ABC234';
    var clients = 8;
    var minutes = 0;
    var drop = 0;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      String? value;
      var name = arg;
      if (arg.contains('=')) {
        name = arg.substring(0, arg.indexOf('='));
        value = arg.substring(arg.indexOf('=') + 1);
      } else if (i + 1 < args.length) {
        value = args[i + 1];
        i++;
      } else {
        throw ArgumentError('$arg needs a value');
      }

      switch (name) {
        case '--host':
          host = value;
        case '--port':
          port = int.tryParse(value) ?? port;
        case '--code':
          code = value.toUpperCase();
        case '--clients':
          clients = int.tryParse(value) ?? clients;
        case '--minutes':
          minutes = int.tryParse(value) ?? minutes;
        case '--drop':
          drop = int.tryParse(value) ?? drop;
        default:
          throw ArgumentError('unknown argument: $name');
      }
    }

    if (clients < 1 || clients > TableProtocol.capacity) {
      throw ArgumentError('clients must be 1..${TableProtocol.capacity}');
    }
    if (drop < 0 || drop > clients) {
      throw ArgumentError('drop must be 0..$clients');
    }
    return _Options(
      host: host,
      port: port,
      code: code,
      clients: clients,
      minutes: minutes,
      drop: drop,
    );
  }
}
