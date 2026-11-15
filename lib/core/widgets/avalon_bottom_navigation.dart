import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.routeName,
  });

  final String label;
  final IconData icon;
  final String routeName;
}

/// Bottom navigation for the non-game shell: Home, History, Settings.
/// Never more than four destinations — `avalon-ui-system`.
class AvalonBottomNavigation extends StatelessWidget {
  const AvalonBottomNavigation({
    super.key,
    required this.currentRouteName,
    required this.onSelected,
    this.destinations = defaultDestinations,
  });

  final String currentRouteName;
  final ValueChanged<String> onSelected;
  final List<NavDestination> destinations;

  static const defaultDestinations = <NavDestination>[
    NavDestination(label: 'Home', icon: Icons.castle_outlined, routeName: 'home'),
    NavDestination(label: 'History', icon: Icons.history_edu_outlined, routeName: 'history'),
    NavDestination(label: 'Settings', icon: Icons.tune_outlined, routeName: 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final destination in destinations)
                Expanded(
                  child: _NavItem(
                    destination: destination,
                    isSelected: destination.routeName == currentRouteName,
                    onTap: () => onSelected(destination.routeName),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.gold : AppColors.mutedText;
    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkWell(
        key: Key('nav_${destination.routeName}'),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(destination.icon, size: 21, color: color),
            const SizedBox(height: Space.xxs),
            Text(
              destination.label,
              style: AppText.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
