import 'package:flutter/material.dart';

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _NavIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: Icon(icon, size: selected ? 24 : 22),
    );
  }
}

class HamvitBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const HamvitBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 72,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(icon: _NavIcon(icon: Icons.today_outlined, selected: currentIndex == 0), label: 'Hoje'),
        NavigationDestination(icon: _NavIcon(icon: Icons.checklist_rounded, selected: currentIndex == 1), label: 'Hábitos'),
        NavigationDestination(icon: _NavIcon(icon: Icons.restaurant_menu_outlined, selected: currentIndex == 2), label: 'Alimentação'),
        NavigationDestination(icon: _NavIcon(icon: Icons.show_chart_rounded, selected: currentIndex == 3), label: 'Evolução'),
        NavigationDestination(icon: _NavIcon(icon: Icons.person_outline_rounded, selected: currentIndex == 4), label: 'Perfil'),
      ],
    );
  }
}
