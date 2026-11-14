import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/admin_events_repository.dart';

final _scaffoldKey = GlobalKey<ScaffoldState>();

class AdminLayout extends ConsumerStatefulWidget {
  const AdminLayout({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  static const _items = <_NavItem>[
    _NavItem(route: '/admin/dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
    _NavItem(route: '/admin/analytics', label: 'Analytics', icon: Icons.insights_outlined),
    _NavItem(route: '/admin/users', label: 'Utilisateurs', icon: Icons.people_outline),
    _NavItem(route: '/admin/papers', label: 'Épreuves', icon: Icons.description_outlined),
    _NavItem(route: '/admin/ai', label: 'AI Center', icon: Icons.smart_toy_outlined),
    _NavItem(route: '/admin/content', label: 'Contenus (CMS)', icon: Icons.edit_document),
    _NavItem(route: '/admin/broadcasts', label: 'Broadcasts', icon: Icons.campaign_outlined),
    _NavItem(route: '/admin/moderation', label: 'Modération', icon: Icons.shield_outlined),
  ];

  int _unreadCount = 0;
  bool _wsConnected = false;

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _items.length; i++) {
      if (path.startsWith(_items[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time events
    ref.listen(adminEventsStreamProvider, (prev, next) {
      next.whenData((state) {
        if (!mounted) return;
        if (state is AdminEventConnected) {
          setState(() => _wsConnected = true);
        } else if (state is AdminEventDisconnected) {
          setState(() => _wsConnected = false);
        } else if (state is AdminEventReceived) {
          setState(() => _unreadCount++);
          _showEventSnackBar(context, state.event);
        }
      });
    });

    final index = _currentIndex(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isWide ? null : _buildDrawer(context, index),
      body: Row(
        children: [
          if (isWide) _buildSidebar(context, index),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  showMenuButton: !isWide,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  screenWidth: width,
                  unreadCount: _unreadCount,
                  wsConnected: _wsConnected,
                  onBellTap: () => setState(() => _unreadCount = 0),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEventSnackBar(BuildContext context, AdminEvent event) {
    final theme = Theme.of(context);
    final (icon, color, label) = _eventVisual(event.type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: theme.colorScheme.onInverseSurface),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.inverseSurface,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static (IconData, Color, String) _eventVisual(String type) {
    switch (type) {
      case 'user.created':
        return (Icons.person_add, Colors.green, 'Nouvel utilisateur inscrit');
      case 'user.suspended':
        return (Icons.block, Colors.orange, 'Utilisateur suspendu');
      case 'document.submitted':
        return (Icons.upload_file, Colors.blue, 'Nouveau document soumis');
      case 'document.approved':
        return (Icons.check_circle, Colors.green, 'Document approuvé');
      case 'document.rejected':
        return (Icons.cancel, Colors.red, 'Document rejeté');
      case 'paper.created':
        return (Icons.picture_as_pdf, Colors.purple, 'Nouvelle épreuve uploadée');
      case 'ai.request.failed':
        return (Icons.error, Colors.red, 'Erreur requête IA');
      case 'system.error':
        return (Icons.warning, Colors.red, 'Erreur système');
      default:
        return (Icons.notifications, Colors.blue, 'Événement: $type');
    }
  }

  Widget _buildSidebar(BuildContext context, int index) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      color: const Color(0xFF151B2E),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'MINDORA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == index;
            return _NavTile(
              item: item,
              selected: selected,
              onTap: () => context.go(item.route),
            );
          }),
          const Spacer(),
          const Divider(color: Colors.white12),
          _LogoutTile(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, int index) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF151B2E)),
            child: Text(
              'MINDORA Admin',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              selected: i == index,
              onTap: () {
                Navigator.pop(context);
                context.go(item.route);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _LogoutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.white70, size: 20),
      title: const Text('Déconnexion',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) context.go('/admin/login');
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showMenuButton,
    required this.onMenuTap,
    required this.screenWidth,
    required this.unreadCount,
    required this.wsConnected,
    required this.onBellTap,
  });
  final bool showMenuButton;
  final VoidCallback onMenuTap;
  final double screenWidth;
  final int unreadCount;
  final bool wsConnected;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2E),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuTap,
            ),
          const Spacer(),
          if (screenWidth >= 600) ...[
            Container(
              width: screenWidth.clamp(200.0, 300.0) - 80,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.white54, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rechercher...',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          // WS connection indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: wsConnected ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white70),
                onPressed: onBellTap,
                visualDensity: VisualDensity.compact,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF6E8DFF),
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.route, required this.label, required this.icon});
  final String route;
  final String label;
  final IconData icon;
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? theme.colorScheme.primary : Colors.white70,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? theme.colorScheme.primary : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
