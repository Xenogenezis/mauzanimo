import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/responsive.dart';

/// A top-level navigation destination for [AdaptiveNavScaffold].
class AdaptiveNavDestination {
  final IconData icon;
  final String label;
  const AdaptiveNavDestination({required this.icon, required this.label});
}

/// Scaffold that shows a [BottomNavigationBar] on phones and a
/// [NavigationRail] on wide screens (>= [kNavigationRailBreakpoint]).
class AdaptiveNavScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveNavDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;

  const AdaptiveNavScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final wide = useNavigationRail(MediaQuery.sizeOf(context).width);
    if (!wide) {
      return Scaffold(
        drawer: drawer,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.grey,
          onTap: onDestinationSelected,
          items: [
            for (final d in destinations)
              BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }
    return Scaffold(
      drawer: drawer,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(children: [
        NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          labelType: NavigationRailLabelType.all,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
          selectedIconTheme: const IconThemeData(color: AppTheme.primary),
          unselectedIconTheme: const IconThemeData(color: Colors.grey),
          selectedLabelTextStyle: const TextStyle(
              color: AppTheme.primary, fontWeight: FontWeight.w600),
          unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
          destinations: [
            for (final d in destinations)
              NavigationRailDestination(
                  icon: Icon(d.icon), label: Text(d.label)),
          ],
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: body),
      ]),
    );
  }
}
