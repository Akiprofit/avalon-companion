import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_bottom_navigation.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';

/// Screen 13 — saved matches. Persistence arrives in Phase 9; until then the
/// list is genuinely empty rather than a fake placeholder.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AvalonScreen(
      appBar: AppBar(title: const Text('GAME HISTORY')),
      backgroundImage: Artwork.history,
      padded: false,
      bottom: AvalonBottomNavigation(
        currentRouteName: RouteNames.history,
        onSelected: (name) {
          if (name != RouteNames.history) context.goNamed(name);
        },
      ),
      child: EmptyState(
        title: 'No matches yet',
        message:
            'Finished and abandoned matches will be listed here with their '
            'outcome and quest record. Nothing is stored until a match ends.',
        action: PrimaryButton(
          label: 'New Game',
          onPressed: () => context.goNamed(RouteNames.setup),
        ),
      ),
    );
  }
}
