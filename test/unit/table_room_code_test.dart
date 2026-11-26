import 'dart:math';

import 'package:avalon_companion/features/table_mode/model/room_code.dart';
import 'package:flutter_test/flutter_test.dart';

/// The six characters read across a table: no I, O, 0 or 1, and a typed code
/// that is forgiven for case, spaces and hyphens but never guessed at.
void main() {
  test('a generated code is six characters from the unambiguous alphabet', () {
    for (var i = 0; i < 200; i++) {
      final code = RoomCode.generate(Random(i));
      expect(code, hasLength(kRoomCodeLength));
      for (final character in code.split('')) {
        expect(kRoomCodeAlphabet, contains(character));
      }
    }
  });

  test('the alphabet leaves out the four characters people confuse', () {
    for (final character in ['I', 'O', '0', '1']) {
      expect(kRoomCodeAlphabet, isNot(contains(character)));
    }
    expect(
      kRoomCodeAlphabet.split('').toSet(),
      hasLength(kRoomCodeAlphabet.length),
      reason: 'no character is offered twice',
    );
  });

  test('typing is forgiven case, spaces and hyphens', () {
    expect(RoomCode.normalise('7k3 qf9'), '7K3QF9');
    expect(RoomCode.normalise(' 7K3-QF9 '), '7K3QF9');
    expect(RoomCode.normalise('7K3QF9'), '7K3QF9');
  });

  test('a code that cannot be one is refused, not repaired', () {
    for (final input in [
      '',
      '7K3QF',
      '7K3QF99',
      '7K3QF0',
      '7K3QFI',
      '7K3QF1',
      '7K3QFO',
      '7K3QF!',
    ]) {
      expect(RoomCode.normalise(input), isNull, reason: 'input: $input');
      expect(RoomCode.isValid(input), isFalse);
    }
  });

  test('a code is printed in two halves so it can be read aloud', () {
    expect(RoomCode.grouped('7K3QF9'), '7K3 QF9');
    expect(
      RoomCode.grouped('SHORT'),
      'SHORT',
      reason: 'an invalid code is never silently reshaped',
    );
  });

  test('every generated code normalises back to itself', () {
    for (var i = 0; i < 50; i++) {
      final code = RoomCode.generate(Random(i));
      expect(RoomCode.normalise(code), code);
    }
  });
}
