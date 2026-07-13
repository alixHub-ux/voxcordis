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
  bool _analysisStarted = false;
  DateTime? _analysisStartTime;
  static const _minDisplayMs = 1500;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analysisStarted) {
      _analysisStarted = true;
      _analysisStartTime = DateTime.now();
      final wavPath = ModalRoute.of(context)?.settings.arguments as String?;
      if (wavPath != null) {
        context.read<AnalysisProvider>().startAnalysis(wavPath);
      }
    }
  }

  Future<void> _navigateAfterMinDelay(String routeName) async {
    final elapsed = DateTime.now().difference(_analysisStartTime!).inMilliseconds;
    if (elapsed < _minDisplayMs) {
      await Future.delayed(Duration(milliseconds: _minDisplayMs - elapsed));
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();

    // Navigation selon l'état (avec délai minimum)
    if (analysis.state == AnalysisState.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          _navigateAfterMinDelay(AppRoutes.result));
    } else if (analysis.state == AnalysisState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(analysis.errorMsg ?? 'Erreur inconnue'),
            backgroundColor: AppColors.riskHigh,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.recording);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(
              context, AppRoutes.recording),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          ),
        ),
        title: const Text('Analyse vocale',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
                      color: const Color(0xFFEED8D8),
                      border: Border.all(
                          // ignore: deprecated_member_use
                          color: AppColors.primary.withOpacity(0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 20 + 10 * _pulse.value,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Center(
                      child: HeartLogo(size: 100, color: AppColors.primary)
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