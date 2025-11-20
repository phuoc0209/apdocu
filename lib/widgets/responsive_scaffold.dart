import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final List<Widget> pages;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    // Always use BottomNavigationBar for navigation (mobile & desktop)
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: destinations
            .map((d) => BottomNavigationBarItem(icon: d.icon, label: d.label))
            .toList(),
      ),
    );
  }
}
