import 'package:flutter/material.dart';

class _NavIcon extends StatelessWidget {
  final String path;
  final bool selected;
  const _NavIcon({required this.path, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: selected ? 26 : 24,
      height: selected ? 26 : 24,
      child: Image.asset(path, fit: BoxFit.contain),
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
        NavigationDestination(icon: _NavIcon(path: 'assets/icons/inicio.png', selected: currentIndex == 0), label: 'Hoje'),
        NavigationDestination(icon: _NavIcon(path: 'assets/icons/habitos.png', selected: currentIndex == 1), label: 'Hábitos'),
        NavigationDestination(icon: _NavIcon(path: 'assets/icons/alimentacao.png', selected: currentIndex == 2), label: 'Alimentação'),
        NavigationDestination(icon: _NavIcon(path: 'assets/icons/progresso.png', selected: currentIndex == 3), label: 'Evolução'),
        NavigationDestination(icon: _NavIcon(path: 'assets/icons/bem_estar.png', selected: currentIndex == 4), label: 'Perfil'),
      ],
    );
  }
}


