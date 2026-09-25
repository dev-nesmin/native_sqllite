import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _destinations = <({String label, String path, IconData icon})>[
  (label: 'Home', path: '/', icon: Icons.home_outlined),
  (label: 'CRUD', path: '/crud', icon: Icons.edit_note_outlined),
  (label: 'Orders', path: '/orders', icon: Icons.receipt_long_outlined),
  (label: 'Query', path: '/query', icon: Icons.search),
  (label: 'More', path: '/advanced', icon: Icons.apps),
];

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _selectedIndex {
    final exact = _destinations.indexWhere(
      (destination) => destination.path == location,
    );
    if (exact >= 0) return exact;
    return location == '/' ? 0 : _destinations.length - 1;
  }

  void _navigate(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: child,
      ),
    );

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => _navigate(context, index),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in _destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => _navigate(context, index),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
