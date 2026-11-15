import 'package:avalon_companion/database/repositories/pin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 10 gate: the optional MC PIN is stored as a salted digest and can only
/// ever answer "is this the same PIN?".
void main() {
  test('a stored PIN is a rounds, salt and digest triple', () {
    final stored = PinRepository.encode('1234');
    final parts = stored.split(r'$');
    expect(parts, hasLength(3));
    expect(parts[0], '${PinRepository.rounds}');
    expect(parts[1], hasLength(32), reason: '16-byte salt as hex');
    expect(parts[2], hasLength(64), reason: 'SHA-256 digest as hex');
    expect(stored.contains('1234'), isFalse);
  });

  test('the same PIN encodes differently every time', () {
    final first = PinRepository.encode('2468');
    final second = PinRepository.encode('2468');
    expect(first, isNot(second));
    expect(PinRepository.matches('2468', first), isTrue);
    expect(PinRepository.matches('2468', second), isTrue);
  });

  test('only the right PIN matches', () {
    final stored = PinRepository.encode('1379');
    expect(PinRepository.matches('1379', stored), isTrue);
    expect(PinRepository.matches('1378', stored), isFalse);
    expect(PinRepository.matches('', stored), isFalse);
    expect(PinRepository.matches('01379', stored), isFalse);
  });

  test('a damaged row locks rather than opens', () {
    expect(PinRepository.matches('1234', ''), isFalse);
    expect(PinRepository.matches('1234', 'nonsense'), isFalse);
    expect(PinRepository.matches('1234', r'0$abcd$abcd'), isFalse);
    expect(PinRepository.matches('1234', r'20000$abcd'), isFalse);
  });
}
