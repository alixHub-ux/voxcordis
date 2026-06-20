import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/heart_logo.dart';

class AnalysisLoadingScreen extends StatefulWidget {
  const AnalysisLoadingScreen({super.key});
  @override State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();
    if (analysis.state == AnalysisState.done || analysis.state == AnalysisState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          Navigator.pushReplacementNamed(context, AppRoutes.result));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          ),
        ),
        title: const Text('Analyse vocale',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cercle avec cœur qui pulse
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final scale = 1.0 + 0.07 * _pulse.value;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEED8D8),       // cercle rose pâle
                      border: Border.all(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.4), width: 2),
                      boxShadow: [BoxShadow(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 20 + 10 * _pulse.value, // halo qui grandit
                        spreadRadius: 2,
                      )],
                    ),
                    child: const Center(
                      child: HeartLogo(
                        size: 100,
                        color: AppColors.primary,  // logo bordeaux sur fond rose
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),
            const Text('Nous vous écoutons.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                    color: AppColors.primary)),
            const SizedBox(height: 6),
            const Text('Veuillez patienter un instant.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                    color: AppColors.primary)),
            const SizedBox(height: 40),
            // Barre de progression
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFFE0D0D0),
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 1),
    );
  }
}
