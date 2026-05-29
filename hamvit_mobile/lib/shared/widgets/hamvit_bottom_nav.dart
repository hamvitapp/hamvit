import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/hamvit_colors.dart';

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _NavIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.22 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Icon(icon, size: selected ? 26 : 20),
    );
  }
}

class HamvitBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const HamvitBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  State<HamvitBottomNav> createState() => _HamvitBottomNavState();
}

class _HamvitBottomNavState extends State<HamvitBottomNav> {
  final _items = const [
    (label: 'Hoje', icon: Icons.today_outlined),
    (label: 'Dashboard', icon: Icons.dashboard_outlined),
    (label: 'Perfil', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: HamvitColors.darkCard.withValues(alpha: 0.34),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: _BottomItem(
                        label: _items[i].label,
                        icon: _items[i].icon,
                        selected: widget.currentIndex == i,
                        onTap: () => widget.onTap(i),
                      ),
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

class _BottomItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? HamvitColors.accentCyan.withValues(alpha: 0.18)
        : Colors.transparent;
    final fg = selected ? HamvitColors.darkText : HamvitColors.darkTextMuted;

    return AnimatedScale(
      scale: selected ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavIcon(icon: icon, selected: selected),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
