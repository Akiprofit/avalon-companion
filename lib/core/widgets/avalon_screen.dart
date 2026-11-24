import 'package:flutter/gestures.dart'
    show Drag, DragEndDetails, DragStartDetails, DragUpdateDetails;
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
            child: _PrimaryScrollScope(
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
                  final gutter = (constraints.maxWidth - maxContentWidth) / 2;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            key: contentKey,
                            constraints: const BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: content,
                          ),
                        ),
                      ),
                      // The reading column stops at [maxContentWidth], so the
                      // glass beside it belongs to no scroll view. A finger
                      // that lands there would move nothing on a tablet, which
                      // reads as a frozen screen. Both gutters drive the
                      // page's own scroll position instead.
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: gutter,
                        child: const _GutterScroll(),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: gutter,
                        child: const _GutterScroll(),
                      ),
                    ],
                  );
                },
              ),
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

/// Gives the body one scroll controller for every vertical list that does not
/// own one, so the gutters beside the reading column have something to move.
class _PrimaryScrollScope extends StatefulWidget {
  const _PrimaryScrollScope({required this.child});

  final Widget child;

  @override
  State<_PrimaryScrollScope> createState() => _PrimaryScrollScopeState();
}

class _PrimaryScrollScopeState extends State<_PrimaryScrollScope> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PrimaryScrollController(controller: _controller, child: widget.child);
}

/// One gutter beside the reading column, wired to the page's scroll position.
///
/// It starts a real drag on that position rather than jumping it, so a finger
/// on the gutter scrolls and flings exactly like a finger on the list.
class _GutterScroll extends StatefulWidget {
  const _GutterScroll();

  @override
  State<_GutterScroll> createState() => _GutterScrollState();
}

class _GutterScrollState extends State<_GutterScroll> {
  Drag? _drag;

  /// The page's scroll position, when there is exactly one to move.
  ScrollPosition? get _position {
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return null;
    // Two attached lists would make `position` ambiguous; the gutter then does
    // nothing rather than throwing at the table.
    if (controller.positions.length != 1) return null;
    return controller.position;
  }

  void _start(DragStartDetails details) {
    final position = _position;
    if (position == null) return;
    _drag = position.drag(details, () => _drag = null);
  }

  void _update(DragUpdateDetails details) => _drag?.update(details);

  void _end(DragEndDetails details) {
    _drag?.end(details);
    _drag = null;
  }

  void _cancel() {
    _drag?.cancel();
    _drag = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _start,
      onVerticalDragUpdate: _update,
      onVerticalDragEnd: _end,
      onVerticalDragCancel: _cancel,
    );
  }
}
