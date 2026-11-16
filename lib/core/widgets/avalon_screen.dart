import 'package:material_ui/material_ui.dart';

import '../theme/app_metrics.dart';
import 'cinematic_background.dart';

/// Internal screen shell: background, safe area and the screen padding rules
/// from `flutter-ui-design`. Not a master-plan component, just the thing every
/// screen is wrapped in.
///
/// Passing both [appBar] and `showBackButton` keeps the supplied title and
/// actions but inserts the back control, so no screen is left without a way out.
///
/// Screens opt into cinematic artwork by passing [backgroundImage]; without it
/// the shell keeps the plain token gradient.
class AvalonScreen extends StatelessWidget {
  const AvalonScreen({
    super.key,
    required this.child,
    this.appBar,
    this.bottom,
    this.padded = true,
    this.showBackButton = false,
    this.onBack,
    this.backgroundDecoration = true,
    this.backgroundImage,
    this.capBottom = true,
  });

  /// The reading measure on a wide screen, from `app_metrics.dart`.
  static const double maxContentWidth = kMaxContentWidth;

  /// The bounded body, so a layout test can prove the column never grows past
  /// [maxContentWidth] no matter how wide the window is.
  static const Key contentKey = ValueKey('screen_content');

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottom;
  final bool padded;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool backgroundDecoration;

  /// Bundled artwork plate drawn behind the screen. See `Artwork`.
  final String? backgroundImage;

  /// Whether the bottom bar keeps the content width. Action bars do, so a gold
  /// button stops being a full-width band; the navigation bar does not, because
  /// it is a band edge to edge and only its items are centred.
  final bool capBottom;

  PreferredSizeWidget? _resolveAppBar(BuildContext context) {
    final Widget? back = showBackButton
        ? IconButton(
            key: const Key('screen_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          )
        : null;

    final supplied = appBar;
    if (supplied == null) {
      return back == null ? null : AppBar(leading: back);
    }
    if (supplied is! AppBar) return supplied;

    return AppBar(
      title: supplied.title,
      actions: supplied.actions,
      leading: back ?? supplied.leading,
      centerTitle: supplied.centerTitle,
      automaticallyImplyLeading: supplied.automaticallyImplyLeading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (backgroundDecoration)
          Positioned.fill(
            child: CinematicBackground(imageAsset: backgroundImage),
          ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _resolveAppBar(context),
          body: SafeArea(
            bottom: bottom == null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = padded
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.screenPadding,
                        ),
                        child: child,
                      )
                    : child;
                if (constraints.maxWidth <= maxContentWidth) {
                  return KeyedSubtree(key: contentKey, child: content);
                }
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    key: contentKey,
                    constraints: const BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: content,
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: bottom == null
              ? null
              : SafeArea(
                  top: false,
                  child: !capBottom
                      ? bottom!
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth <= maxContentWidth) {
                              return bottom!;
                            }
                            // The action bar keeps the same width as the
                            // content, so a gold button stops being a
                            // full-width band on a tablet.
                            return Align(
                              alignment: Alignment.topCenter,
                              // Height follows the bar, not the Scaffold's
                              // loose maximum; see `avalon_bottom_navigation`.
                              heightFactor: 1,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: maxContentWidth,
                                ),
                                child: bottom!,
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
