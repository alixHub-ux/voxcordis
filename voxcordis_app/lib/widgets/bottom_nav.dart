import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import '../core/constants/app_colors.dart';

class VoxcordisBottomNav extends StatelessWidget {
  final int currentIndex;
  const VoxcordisBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    final routes = [AppRoutes.dashboard, AppRoutes.recording, AppRoutes.history, AppRoutes.profile];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, index: 0, current: currentIndex, onTap: (i) => _onTap(context, i)),
              _NavItem(icon: Icons.mic_outlined, index: 1, current: currentIndex, onTap: (i) => _onTap(context, i)),
              _NavItem(icon: Icons.format_list_bulleted, index: 2, current: currentIndex, onTap: (i) => _onTap(context, i)),
              _NavItem(icon: Icons.person_outline, index: 3, current: currentIndex, onTap: (i) => _onTap(context, i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({required this.icon, required this.index,
      required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isActive ? AppColors.primary : Colors.grey.shade500,
            size: 24),
      ),
    );
  }
}
