import '../model/room_code.dart';
import 'table_protocol.dart';

/// What the board prints as a QR, and what a phone reads off it.
///
/// It is an address book entry, not a secret: the code, the address and the
/// port, so the phone can connect without a discovery round trip. The scheme is
/// `avalon://` so a later phase can register an intent filter without changing
/// what the board draws.
class TableInvite {
  const TableInvite({
    required this.code,
    required this.host,
    required this.port,
  });

  final String code;
  final String host;
  final int port;

  Uri toUri() => Uri(
    scheme: 'avalon',
    host: 'join',
    queryParameters: {
      'v': '${TableProtocol.version}',
      'c': code,
      'h': host,
      'p': '$port',
    },
  );

  /// The exact string drawn in the QR.
  String encode() => toUri().toString();

  /// Parses a scanned payload, or null when it is not one of ours.
  ///
  /// Null is the normal answer for the QR on a menu or a bus stop: the scanner
  /// keeps looking instead of showing an error.
  static TableInvite? parse(String raw) {
    final Uri uri;
    try {
      uri = Uri.parse(raw.trim());
    } on FormatException {
      return null;
    }
    if (uri.scheme != 'avalon' || uri.host != 'join') return null;

    final query = uri.queryParameters;
    if (query['v'] != '${TableProtocol.version}') return null;

    final code = RoomCode.normalise(query['c'] ?? '');
    if (code == null) return null;

    final host = (query['h'] ?? '').trim();
    if (host.isEmpty) return null;

    final port = int.tryParse(query['p'] ?? '');
    if (port == null || port < 1 || port > 65535) return null;

    return TableInvite(code: code, host: host, port: port);
  }

  /// `ws://192.168.43.1:8787/table`.
  Uri get socketUri => Uri(
    scheme: 'ws',
    host: host,
    port: port,
    path: TableProtocol.endpointPath,
  );
}
