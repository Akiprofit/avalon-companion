import 'package:avalon_companion/features/table_mode/protocol/table_announcement.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_invite.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the board prints and shouts: an address book entry, and the datagram
/// that saves a player from reading an IP address aloud.
void main() {
  group('the QR invite', () {
    const invite = TableInvite(
      code: '7K3QF9',
      host: '192.168.43.1',
      port: 8787,
    );

    test('round-trips through the exact string drawn in the QR', () {
      final parsed = TableInvite.parse(invite.encode());
      expect(parsed, isNotNull);
      expect(parsed!.code, '7K3QF9');
      expect(parsed.host, '192.168.43.1');
      expect(parsed.port, 8787);
    });

    test('the payload is an avalon:// link a later phase can register', () {
      expect(invite.encode(), startsWith('avalon://join?'));
      expect(invite.encode(), contains('v=1'));
    });

    test('points at the WebSocket endpoint the board serves', () {
      expect(invite.socketUri.toString(), 'ws://192.168.43.1:8787/table');
    });

    test('a QR from anywhere else is simply not ours', () {
      for (final raw in [
        '',
        'https://example.com',
        'WIFI:S:Cafe;T:WPA;P:password;;',
        'avalon://join?v=1&c=7K3QF9&h=192.168.43.1',
        'avalon://join?v=1&c=BADCODE&h=192.168.43.1&p=8787',
        'avalon://join?v=1&c=7K3QF9&h=&p=8787',
        'avalon://join?v=1&c=7K3QF9&h=192.168.43.1&p=0',
        'avalon://join?v=1&c=7K3QF9&h=192.168.43.1&p=70000',
        'avalon://join?v=2&c=7K3QF9&h=192.168.43.1&p=8787',
      ]) {
        expect(TableInvite.parse(raw), isNull, reason: 'payload: $raw');
      }
    });

    test('a scanned code is normalised on the way in', () {
      final parsed = TableInvite.parse(
        'avalon://join?v=1&c=7k3-qf9&h=192.168.43.1&p=8787',
      );
      expect(parsed?.code, '7K3QF9');
    });
  });

  group('the LAN announcement', () {
    const announcement = TableAnnouncement(
      code: '7K3QF9',
      port: 8791,
      boardName: 'Avalon board',
    );

    test('round-trips, carrying the port the board actually bound', () {
      final parsed = TableAnnouncement.parse(announcement.encode());
      expect(parsed, isNotNull);
      expect(parsed!.code, '7K3QF9');
      expect(parsed.port, 8791);
      expect(parsed.boardName, 'Avalon board');
    });

    test('a pipe in the board name cannot forge a field', () {
      final parsed = TableAnnouncement.parse(
        const TableAnnouncement(
          code: '7K3QF9',
          port: 8787,
          boardName: 'Upstairs | 9999',
        ).encode(),
      );
      expect(parsed, isNotNull);
      expect(
        parsed!.boardName,
        isNot(contains('|')),
        reason: 'the separator never survives into a field',
      );
      expect(parsed.boardName.replaceAll(' ', ''), 'Upstairs9999');
      expect(parsed.port, 8787);
    });

    test('a stray datagram is ignored rather than guessed at', () {
      for (final raw in [
        '',
        'hello',
        'AVALON2|7K3QF9|8787|Board',
        'AVALON1|SHORT|8787|Board',
        'AVALON1|7K3QF9|nope|Board',
        'AVALON1|7K3QF9|0|Board',
        'AVALON1|7K3QF9|8787',
        'AVALON1|7K3QF9|8787|Board|extra',
      ]) {
        expect(TableAnnouncement.parse(raw), isNull, reason: 'datagram: $raw');
      }
    });
  });
}
