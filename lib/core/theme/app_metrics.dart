/// Spacing, radius and motion tokens — master plan §3.4 and `flutter-ui-design`.
abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Horizontal screen padding.
  static const screenPadding = 20.0;
}

abstract final class Radii {
  static const chip = 8.0;
  static const input = 12.0;
  static const card = 16.0;
  static const sheet = 24.0;
}

abstract final class Motion {
  static const micro = Duration(milliseconds: 130);
  static const transition = Duration(milliseconds: 280);
  static const dramatic = Duration(milliseconds: 520);
}

/// Minimum touch target required by `avalon-ui-system`.
const double kMinTapTarget = 48;

/// The reading measure on a wide screen.
///
/// The layout is the phone layout, unchanged: a tablet simply centres it in a
/// column this wide instead of stretching every card and every line of text
/// across the glass. 600 dp leaves 560 dp of text after the screen padding —
/// roughly 70 characters, which is still comfortable to read aloud from.
const double kMaxContentWidth = 600;
