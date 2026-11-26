import 'dart:math';

import 'package:avalon_companion/features/table_mode/host/table_session.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seat book: join order, one name per room, tokens that bring a phone back.
void main() {
  TableSession session({int capacity = TableProtocol.capacity}) =>
      TableSession(code: 'ABC234', capacity: capacity, random: Random(7));

  final at = DateTime(2026, 11, 26, 20);

  JoinAccepted accepted(JoinResult result) {
    expect(result, isA<JoinAccepted>());
    return result as JoinAccepted;
  }

  test('seats are handed out in join order, lowest free number first', () {
    final book = session();
    expect(accepted(book.join(connectionId: 'a', rawName: 'Ana')).seat, 1);
    expect(accepted(book.join(connectionId: 'b', rawName: 'Bo')).seat, 2);
    expect(accepted(book.join(connectionId: 'c', rawName: 'Cy')).seat, 3);

    expect(book.seats.map((s) => s.name), ['Ana', 'Bo', 'Cy']);
    expect(book.seats.every((s) => s.connected), isTrue);
  });

  test('a released seat is reused, and the room keeps its order', () {
    final book = session();
    accepted(book.join(connectionId: 'a', rawName: 'Ana'));
    accepted(book.join(connectionId: 'b', rawName: 'Bo'));

    expect(book.release(1), isTrue);
    expect(accepted(book.join(connectionId: 'c', rawName: 'Cy')).seat, 1);
    expect(book.seats.map((s) => s.name), ['Cy', 'Bo']);
  });

  test('a name already at the table is refused, whatever its case', () {
    final book = session();
    accepted(book.join(connectionId: 'a', rawName: 'Ana'));

    final result = book.join(connectionId: 'b', rawName: 'aNa');
    expect(result, isA<JoinRejected>());
    expect((result as JoinRejected).code, TableErrorCode.nameTaken);
  });

  test('a name that cannot be a name is refused, not trimmed into one', () {
    final book = session();
    expect(
      (book.join(connectionId: 'a', rawName: '   ') as JoinRejected).code,
      TableErrorCode.nameInvalid,
    );
    expect(
      (book.join(
            connectionId: 'b',
            rawName: 'a' * (TableProtocol.maxNameLength + 1),
          )
          as JoinRejected)
          .code,
      TableErrorCode.nameInvalid,
    );
    expect(
      (book.join(connectionId: 'c', rawName: 'bad\u0007name') as JoinRejected)
          .code,
      TableErrorCode.nameInvalid,
    );
    expect(book.isEmpty, isTrue);
  });

  test('the room refuses the fifteenth player but keeps the fourteen', () {
    final book = session(capacity: 2);
    accepted(book.join(connectionId: 'a', rawName: 'Ana'));
    accepted(book.join(connectionId: 'b', rawName: 'Bo'));

    final result = book.join(connectionId: 'c', rawName: 'Cy');
    expect(result, isA<JoinRejected>());
    expect((result as JoinRejected).code, TableErrorCode.roomFull);
    expect(book.seats, hasLength(2));
  });

  test('one connection cannot take two seats', () {
    final book = session();
    accepted(book.join(connectionId: 'a', rawName: 'Ana'));

    final result = book.join(connectionId: 'a', rawName: 'Bo');
    expect((result as JoinRejected).code, TableErrorCode.alreadySeated);
  });

  test('a token returns the phone to its own seat and name', () {
    final book = session();
    final first = accepted(book.join(connectionId: 'a', rawName: 'Ana'));
    expect(first.isReturn, isFalse);

    // The phone went away, then came back on a new socket.
    expect(book.disconnect('a'), 1);
    expect(book.seatAt(1)!.connected, isFalse);

    final again = accepted(
      book.join(connectionId: 'a2', rawName: 'Ignored', token: first.token),
    );
    expect(again.isReturn, isTrue);
    expect(again.seat, 1);
    expect(again.token, first.token);
    expect(book.seatAt(1)!.name, 'Ana');
    expect(book.seatAt(1)!.connected, isTrue);
    expect(book.seatNumberForConnection('a2'), 1);
  });

  test('a token always beats a taken name, so a reconnect is never refused', () {
    final book = session();
    final first = accepted(book.join(connectionId: 'a', rawName: 'Ana'));
    accepted(book.join(connectionId: 'b', rawName: 'Bo'));
    book.disconnect('a');

    final again = accepted(
      book.join(connectionId: 'a2', rawName: 'Bo', token: first.token),
    );
    expect(again.seat, 1);
    expect(book.seatAt(1)!.name, 'Ana');
  });

  test('a corrupted or unknown token is treated as no token at all', () {
    final book = session();
    accepted(book.join(connectionId: 'a', rawName: 'Ana'));

    for (final token in ['', 'zz', 'A' * 32, '0' * 31, 'x' * 40]) {
      final result = book.join(
        connectionId: 'new-$token',
        rawName: 'Bo',
        token: token,
      );
      expect(
        result,
        isA<JoinAccepted>(),
        reason: 'a bad token must never lock a player out',
      );
      expect((result as JoinAccepted).seat, 2);
      book.release(2);
    }
  });

  test('the newest connection wins a contested seat', () {
    final book = session();
    final first = accepted(book.join(connectionId: 'a', rawName: 'Ana'));

    final again = accepted(
      book.join(connectionId: 'b', rawName: 'Ana', token: first.token),
    );
    expect(again.displacedConnection, 'a');
    expect(book.seatNumberForConnection('a'), isNull);
    expect(book.seatNumberForConnection('b'), 1);

    // The displaced socket's close must not mark the seat away afterwards.
    expect(book.disconnect('a'), isNull);
    expect(book.seatAt(1)!.connected, isTrue);
  });

  test('a released token is remembered, so the phone is told why', () {
    final book = session();
    final first = accepted(book.join(connectionId: 'a', rawName: 'Ana'));
    book.release(1);

    final result = book.join(
      connectionId: 'a2',
      rawName: 'Ana',
      token: first.token,
    );
    expect((result as JoinRejected).code, TableErrorCode.seatReleased);
  });

  test('released-token memory is bounded', () {
    final book = session(capacity: 40);
    final tokens = <String>[];
    for (var i = 0; i < 40; i++) {
      final seat = accepted(book.join(connectionId: 'c$i', rawName: 'P$i'));
      tokens.add(seat.token);
      expect(book.release(seat.seat), isTrue);
    }

    // The oldest tokens have been forgotten; the newest are still remembered.
    expect(
      (book.join(
            connectionId: 'x',
            rawName: 'Late',
            token: tokens.last,
          )
          as JoinRejected)
          .code,
      TableErrorCode.seatReleased,
    );
    expect(
      book.join(connectionId: 'y', rawName: 'Later', token: tokens.first),
      isA<JoinAccepted>(),
    );
  });

  test('tokens are 32 lowercase hex characters and never repeat', () {
    final book = session(capacity: 20);
    final tokens = <String>{};
    for (var i = 0; i < 20; i++) {
      final token = accepted(book.join(connectionId: 'c$i', rawName: 'P$i')).token;
      expect(token, matches(RegExp(r'^[0-9a-f]{32}$')));
      tokens.add(token);
    }
    expect(tokens, hasLength(20));
  });

  test('silence is measured from the last touch', () {
    final book = session();
    accepted(book.join(connectionId: 'a', rawName: 'Ana', now: at));

    expect(
      book.silentConnections(at.add(const Duration(seconds: 29)), const Duration(seconds: 30)),
      isEmpty,
    );
    expect(
      book.silentConnections(at.add(const Duration(seconds: 30)), const Duration(seconds: 30)),
      ['a'],
    );

    book.touch('a', now: at.add(const Duration(seconds: 20)));
    expect(
      book.silentConnections(at.add(const Duration(seconds: 40)), const Duration(seconds: 30)),
      isEmpty,
    );
  });

  test('a seat whose phone is away is not swept as silent', () {
    final book = session();
    accepted(book.join(connectionId: 'a', rawName: 'Ana', now: at));
    book.disconnect('a');

    expect(
      book.silentConnections(at.add(const Duration(minutes: 5)), const Duration(seconds: 30)),
      isEmpty,
    );
  });

  test('the room projection carries no token and no private bookkeeping', () {
    final book = session();
    accepted(book.join(connectionId: 'a', rawName: 'Ana'));
    final room = book.roomState(address: '192.168.43.1', port: 8787);

    expect(room.code, 'ABC234');
    expect(room.address, '192.168.43.1');
    expect(room.port, 8787);
    expect(room.seatedCount, 1);
    expect(room.seats.single.toJson().keys, ['seat', 'name', 'connected']);
  });
}
