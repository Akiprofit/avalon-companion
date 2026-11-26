import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';

/// The board's QR: the invite string, drawn as modules on a parchment ground.
///
/// A `CustomPainter` over `qr`'s matrix rather than a QR widget package: it is
/// about fifty lines, has one transitive dependency (`meta`), and draws in the
/// app's own colours. The quiet zone is real padding on a light surface, because
/// a scanner needs contrast around the code as much as inside it.
class JoinQr extends StatelessWidget {
  const JoinQr({
    super.key,
    required this.data,
    this.size = kJoinQrSize,
    this.semanticLabel = 'Join code',
  });

  final String data;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = QrImage(
      QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: QrErrorCorrectLevel.medium,
      ),
    );

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: CustomPaint(
          painter: _QrPainter(image: image, color: AppColors.background),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter({required this.image, required this.color});

  final QrImage image;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final modules = image.moduleCount;
    if (modules <= 0) return;

    final module = size.shortestSide / modules;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    for (var row = 0; row < modules; row++) {
      for (var col = 0; col < modules; col++) {
        if (!image.isDark(row, col)) continue;
        // The half-pixel overlap closes the hairline seams that appear when a
        // module size does not divide the box exactly.
        canvas.drawRect(
          Rect.fromLTWH(
            col * module,
            row * module,
            module + 0.5,
            module + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.color != color;
}
