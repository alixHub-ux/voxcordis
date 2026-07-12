import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/heart_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  bool _checkedSession = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.autoLogin();
    if (!mounted) return;
    _checkedSession = true;
    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
    setState(() {});
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo cœur lignes blanches
                HeartLogo(size: 160, color: Colors.white),
                const SizedBox(height: 32),

                // Wordmark image (VOXCORDIS)
                Image.asset(
                  'assets/images/wordmark.png',
                  height: 48,
                ),
                const SizedBox(height: 10),

                Text(
                  'La Voix Du Coeur',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                ),

                const Spacer(flex: 4),

                if (_checkedSession)
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                      ),
                      child: const Text('Commencer →',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  const SizedBox(
                    width: double.infinity, height: 56,
                    child: Center(
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}