import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const _nav = <_AdminNav>[
    _AdminNav(route: '/admin/dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
    _AdminNav(route: '/admin/users', label: 'Users', icon: Icons.people_outline),
    _AdminNav(route: '/admin/papers', label: 'Papers', icon: Icons.description_outlined),
    _AdminNav(route: '/admin/moderation', label: 'Moderation', icon: Icons.shield_outlined),
  ];

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _nav.length; i++) {
      if (path.startsWith(_nav[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.amber),
            SizedBox(width: 8),
            Text('MINDORA Admin'),
          ],
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => context.go(_nav[i].route),
        destinations: _nav
            .map((n) => NavigationDestination(icon: Icon(n.icon), label: n.label))
            .toList(),
      ),
    );
  }
}

class _AdminNav {
  final String route, label;
  final IconData icon;
  const _AdminNav({required this.route, required this.label, required this.icon});
}
