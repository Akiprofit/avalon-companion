import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/routes.dart';
import '../features/assassination/assassination_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/how_to_play_screen.dart';
import '../features/lord_selection/lord_selection_screen.dart';
import '../features/mission_results/quest_resolution_screen.dart';
import '../features/narration/narration_screen.dart';
import '../features/preparation/preparation_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/setup/setup_screen.dart';
import '../features/table_mode/screens/join_scan_screen.dart';
import '../features/table_mode/screens/join_screen.dart';
import '../features/table_mode/screens/player_seat_screen.dart';
import '../features/table_mode/screens/table_host_screen.dart';
import '../features/team_selection/team_selection_screen.dart';
import '../features/victory/victory_screen.dart';
import '../features/voting/voting_screen.dart';
import '../game_engine/controllers/game_session_controller.dart';
import 'splash_screen.dart';

/// The router is the only place that constructs routes or knows their paths.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final needsGame =
          location == RoutePaths.dashboard ||
          location == RoutePaths.narration ||
          location == RoutePaths.lordSelection ||
          location == RoutePaths.teamSelection ||
          location == RoutePaths.voting ||
          location == RoutePaths.questResolution ||
          location == RoutePaths.assassination ||
          location == RoutePaths.results;
      if (needsGame && ref.read(gameSessionProvider) == null) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.setup,
        name: RouteNames.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.preparation,
        name: RouteNames.preparation,
        builder: (context, state) => const PreparationScreen(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.narration,
        name: RouteNames.narration,
        builder: (context, state) => const NarrationScreen(),
      ),
      GoRoute(
        path: RoutePaths.lordSelection,
        name: RouteNames.lordSelection,
        builder: (context, state) => const LordSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.teamSelection,
        name: RouteNames.teamSelection,
        builder: (context, state) => const TeamSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.voting,
        name: RouteNames.voting,
        builder: (context, state) => const VotingScreen(),
      ),
      GoRoute(
        path: RoutePaths.questResolution,
        name: RouteNames.questResolution,
        builder: (context, state) => const QuestResolutionScreen(),
      ),
      GoRoute(
        path: RoutePaths.assassination,
        name: RouteNames.assassination,
        builder: (context, state) => const AssassinationScreen(),
      ),
      GoRoute(
        path: RoutePaths.results,
        name: RouteNames.results,
        builder: (context, state) => const VictoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.howToPlay,
        name: RouteNames.howToPlay,
        builder: (context, state) => const HowToPlayScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      // Table Mode sits outside the `needsGame` gate: a board hosts and a phone
      // joins without a game in progress.
      GoRoute(
        path: RoutePaths.tableHost,
        name: RouteNames.tableHost,
        builder: (context, state) => const TableHostScreen(),
      ),
      GoRoute(
        path: RoutePaths.join,
        name: RouteNames.join,
        builder: (context, state) => const JoinScreen(),
      ),
      GoRoute(
        path: RoutePaths.joinScan,
        name: RouteNames.joinScan,
        builder: (context, state) => const JoinScanScreen(),
      ),
      GoRoute(
        path: RoutePaths.playerSeat,
        name: RouteNames.playerSeat,
        builder: (context, state) => const PlayerSeatScreen(),
      ),
    ],
  );
});
