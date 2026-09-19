import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/spacing_tokens.dart';

/// The persistent app frame: bottom nav on mobile, nav rail on wide
/// (desktop/Windows) layouts — same five destinations, per section 71
/// (do not overcrowd navigation) and section 9 (responsive layouts).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _Dest('Home', Icons.home_rounded),
    _Dest('AI', Icons.auto_awesome_rounded),
    _Dest('Planner', Icons.calendar_month_rounded),
    _Dest('Learn', Icons.menu_book_rounded),
    _Dest('Profile', Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(i),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i),
        height: 64,
        destinations: _destinations
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}

class _Dest {
  const _Dest(this.label, this.icon);
  final String label;
  final IconData icon;
}
