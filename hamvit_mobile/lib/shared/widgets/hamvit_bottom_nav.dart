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
    (label: 'Hábitos', icon: Icons.checklist_rounded),
    (label: 'Alimentação', icon: Icons.restaurant_menu_outlined),
    (label: 'Evolução', icon: Icons.show_chart_rounded),
    (label: 'Perfil', icon: Icons.person_outline_rounded),
  ];

  late final List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(_items.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected());
  }

  @override
  void didUpdateWidget(covariant HamvitBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected());
    }
  }

  void _centerSelected() {
    if (!mounted || widget.currentIndex < 0 || widget.currentIndex >= _itemKeys.length) {
      return;
    }
    final targetContext = _itemKeys[widget.currentIndex].currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      alignment: 0.5,
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  for (var i = 0; i < _items.length; i++)
                    Padding(
                      key: _itemKeys[i],
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: _BottomItem(
                        label: _items[i].label,
                        icon: _items[i].icon,
                        selected: widget.currentIndex == i,
                        onTap: () => widget.onTap(i),
                      ),
                    ),
                  const SizedBox(width: 6),
                ],
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
