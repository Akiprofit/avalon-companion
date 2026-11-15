import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Single entry point: initialise bindings, install the provider scope, run.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AvalonApp()));
}
