import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// What the board calls itself when it announces the room.
///
/// Shown only inside the discovery datagram, so two boards on one network are
/// told apart by a human rather than by an IP address.
final tableBoardNameProvider = Provider<String>((ref) => 'Avalon board');

/// Builds the camera preview, and reports the first non-empty payload it reads.
///
/// The seam exists for one reason: a widget test must never construct a camera.
/// Override this provider with a fake that calls `onDetected` on a button press,
/// and the whole join-by-scan flow is testable in CI.
typedef TableScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onDetected);

final tableScannerBuilderProvider = Provider<TableScannerBuilder>((ref) {
  return (context, onDetected) => MobileScanner(
    onDetect: (capture) {
      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue;
        if (value == null || value.isEmpty) continue;
        onDetected(value);
        return;
      }
    },
  );
});
