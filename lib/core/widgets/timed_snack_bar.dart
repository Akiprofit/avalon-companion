import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Shows [snackBar] on [messenger] and takes it down when its own clock runs
/// out.
///
/// The framework is supposed to do this by itself. It does not under a
/// `MaterialApp.router`: the messenger's snackbar clock pauses while the route
/// it was shown on is no longer current and is never restarted, so a bar such
/// as the undo offer sits on top of every screen for the rest of the match.
/// The clock lives here instead, and the bar is closed only while it is still
/// the one on screen, so a newer message is never cut short.
///
/// Pass a [messenger] captured before an `await` or a route change rather than
/// a `BuildContext` that may be gone by then.
void showTimedSnackBar(ScaffoldMessengerState messenger, SnackBar snackBar) {
  final bar = messenger.showSnackBar(snackBar);
  var closed = false;
  final timer = Timer(snackBar.duration, () {
    if (!closed && messenger.mounted) bar.close();
  });
  // Dismissed early — by Undo itself, or by the MC — so the clock is dropped
  // with the bar.
  bar.closed.whenComplete(() {
    closed = true;
    timer.cancel();
  });
}
