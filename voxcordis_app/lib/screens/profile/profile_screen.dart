import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          ),
        ),
        title: const Text('Profil',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Avatar
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.primary,
                child: Text(user?.initials ?? '?',
                    style: const TextStyle(fontSize: 34, color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              Text(user?.fullName ?? '—',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(user?.email ?? '',
                  style: const TextStyle(fontSize: 14, color: AppColors.primary)),
              const Spacer(),
              // Bouton Se déconnecter
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Colors.black87, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                  ),
                  child: const Text('Se déconnecter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                          color: Colors.black87)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 3),
    );
  }
}
