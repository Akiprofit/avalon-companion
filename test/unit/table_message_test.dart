import 'dart:convert';

import 'package:avalon_companion/features/table_mode/model/room_state.dart';
import 'package:avalon_companion/features/table_mode/model/seat.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_message.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wire: every frame round-trips, and every bad frame is a value, not a
/// crash the board has to survive.
void main() {
  const seats = [
    Seat(number: 1, name: 'Ana', connected: true),
    Seat(number: 2, name: 'Bo', connected: false),
  ];

  void roundTrips(TableMessage message) {
    final result = decodeTableFrame(message.encode());
    expect(result, isA<TableDecoded>());
    expect((result as TableDecoded).message.runtimeType, message.runtimeType);
  }

  test('every frame this version defines survives encode and decode', () {
    roundTrips(const HelloMessage(code: 'ABC234', name: 'Ana'));
    roundTrips(
      HelloMessage(code: 'ABC234', name: 'Ana', token: 'a' * 32),
    );
    roundTrips(const PingMessage(t: 1234));
    roundTrips(const LeaveMessage());
    roundTrips(
      WelcomeMessage(
        seat: 1,
        token: 'b' * 32,
        code: 'ABC234',
        capacity: 14,
        phase: RoomPhase.lobby,
        seats: seats,
      ),
    );
    roundTrips(
      const StateMessage(capacity: 14, phase: RoomPhase.lobby, seats: seats),
    );
    roundTrips(const PresenceMessage(seat: 2, connected: false));
    roundTrips(const PongMessage(t: 1234));
    roundTrips(ErrorMessage.of(TableErrorCode.roomFull));
  });

  test('a decoded welcome keeps its seats in join order, with presence', () {
    final decoded =
        decodeTableFrame(
              WelcomeMessage(
                seat: 1,
                token: 'b' * 32,
                code: 'ABC234',
                capacity: 14,
                phase: RoomPhase.lobby,
                seats: seats,
              ).encode(),
            )
            as TableDecoded;

    final welcome = decoded.message as WelcomeMessage;
    expect(welcome.seat, 1);
    expect(welcome.code, 'ABC234');
    expect(welcome.capacity, 14);
    expect(welcome.seats.map((s) => s.number), [1, 2]);
    expect(welcome.seats.map((s) => s.connected), [true, false]);
  });

  test('the envelope carries the version on every frame', () {
    for (final message in <TableMessage>[
      const HelloMessage(code: 'ABC234', name: 'Ana'),
      const PingMessage(t: 1),
      const LeaveMessage(),
      const PresenceMessage(seat: 1, connected: true),
    ]) {
      expect(jsonDecode(message.encode())['v'], TableProtocol.version);
    }
  });

  test('a frame from another version is refused as a version mismatch', () {
    final result = decodeTableFrame('{"v":2,"type":"hello","code":"ABC234","name":"Ana"}');
    expect(result, isA<TableDecodeFailure>());
    expect((result as TableDecodeFailure).code, TableErrorCode.version);
  });

  test('a frame with no version is refused, not assumed', () {
    final result = decodeTableFrame('{"type":"hello","code":"ABC234","name":"Ana"}');
    expect((result as TableDecodeFailure).code, TableErrorCode.badMessage);
  });

  test('an unknown type is told apart from a malformed frame', () {
    final result = decodeTableFrame('{"v":1,"type":"deal","seats":[]}');
    expect((result as TableDecodeFailure).code, TableErrorCode.unknownType);
  });

  test('anything that is not a JSON object is a bad message', () {
    for (final raw in ['', 'nonsense', '[]', '"hello"', '42', 'null']) {
      final result = decodeTableFrame(raw);
      expect(
        (result as TableDecodeFailure).code,
        TableErrorCode.badMessage,
        reason: 'raw: $raw',
      );
    }
  });

  test('a frame missing a required field is a bad message', () {
    for (final raw in [
      '{"v":1,"type":"hello","name":"Ana"}',
      '{"v":1,"type":"hello","code":"ABC234"}',
      '{"v":1,"type":"ping"}',
      '{"v":1,"type":"presence","seat":1}',
      '{"v":1,"type":"state","capacity":14,"phase":"lobby"}',
      '{"v":1,"type":"error","code":"room_full"}',
      '{"v":1,"type":"error","code":"not_a_code","message":"x"}',
    ]) {
      final result = decodeTableFrame(raw);
      expect(
        (result as TableDecodeFailure).code,
        TableErrorCode.badMessage,
        reason: 'raw: $raw',
      );
    }
  });

  test('a seat that is not an object is refused', () {
    final result = decodeTableFrame(
      '{"v":1,"type":"state","capacity":14,"phase":"lobby","seats":["Ana"]}',
    );
    expect((result as TableDecodeFailure).code, TableErrorCode.badMessage);
  });

  test('an oversized frame is refused before it is parsed', () {
    final raw = '{"v":1,"type":"hello","code":"ABC234","name":"'
        '${'a' * TableProtocol.maxFrameBytes}"}';
    final result = decodeTableFrame(raw);
    expect((result as TableDecodeFailure).code, TableErrorCode.badMessage);
    expect(result.reason, 'frame too large');
  });

  test('the largest legal room still fits in one frame', () {
    final full = [
      for (var seat = 1; seat <= TableProtocol.capacity; seat++)
        Seat(number: seat, name: 'Player $seat', connected: true),
    ];
    final frame = StateMessage(
      capacity: TableProtocol.capacity,
      phase: RoomPhase.lobby,
      seats: full,
    ).encode();

    expect(frame.length, lessThan(TableProtocol.maxFrameBytes));
    expect(decodeTableFrame(frame), isA<TableDecoded>());
  });

  test('a seat never serialises anything but number, name and presence', () {
    const seat = Seat(number: 3, name: 'Cy', connected: true);
    expect(seat.toJson(), {'seat': 3, 'name': 'Cy', 'connected': true});
    expect(jsonEncode(seat.toJson()), isNot(contains('role')));
    expect(jsonEncode(seat.toJson()), isNot(contains('character')));
    expect(jsonEncode(seat.toJson()), isNot(contains('evil')));
  });

  test('an error code keeps the sentence a player reads', () {
    final decoded =
        decodeTableFrame(ErrorMessage.of(TableErrorCode.nameTaken).encode())
            as TableDecoded;
    final error = decoded.message as ErrorMessage;
    expect(error.code, TableErrorCode.nameTaken);
    expect(error.message, 'Someone at the table already used that name.');
  });

  test('the error table marks the terminal answers', () {
    expect(TableErrorCode.roomNotFound.isTerminal, isTrue);
    expect(TableErrorCode.nameInvalid.isTerminal, isTrue);
    expect(TableErrorCode.seatReleased.isTerminal, isTrue);
    expect(
      TableErrorCode.roomFull.isTerminal,
      isFalse,
      reason: 'a seat can free up while the phone waits',
    );
    expect(TableErrorCode.nameTaken.isTerminal, isFalse);
  });
}
