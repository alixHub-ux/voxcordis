import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/heart_logo.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});
  @override State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  Timer? _fillTimer;
  double _fillRatio = 0.0;
  int _elapsed = 0;
  bool _isProcessing = false;

  static const _duration = 3;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fillTimer?.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isProcessing) return;

    final analysis = context.read<AnalysisProvider>();
    final isRec = analysis.state == AnalysisState.recording;

    if (!isRec) {
      _isProcessing = true;
      final ok = await analysis.startRecording();
      if (!ok && mounted) {
        _isProcessing = false;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(analysis.errorMsg ?? 'Erreur microphone')));
        return;
      }
      setState(() {
        _elapsed = 0;
        _fillRatio = 0.0;
      });
      _fillTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          _elapsed += 100;
          _fillRatio = (_elapsed / (_duration * 1000)).clamp(0.0, 1.0);
        });
        if (_elapsed >= _duration * 1000) {
          t.cancel();
          _stopAndAnalyze();
        }
      });
    } else {
      _fillTimer?.cancel();
      _stopAndAnalyze();
    }
  }

  Future<void> _stopAndAnalyze() async {
    final analysis = context.read<AnalysisProvider>();
    await analysis.stopAndAnalyze();
    _isProcessing = false;
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.analysisLoading);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();
    final isRec = analysis.state == AnalysisState.recording;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(
              context, AppRoutes.recordingGuide),
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
            HeartLogoAnimated(
            size: 160,
            filledColor: AppColors.primary,
            emptyColor: const Color(0xFFCCCCCC),
            fillRatio: _fillRatio,
          ),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final scale = isRec ? (1.0 + 0.08 * _pulseCtrl.value) : 1.0;
                return GestureDetector(
                  onTap: _onTap,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 110 * scale, height: 110 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                    ),
                    Container(
                      width: 95, height: 95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            // ignore: deprecated_member_use
                            color: AppColors.primary.withOpacity(0.5), width: 2),
                      ),
                    ),
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.primary),
                      child: const Icon(Icons.mic, color: Colors.white, size: 36),
                    ),
                  ]),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              isRec
                  ? 'Appuyez pour arrêter'
                  : "Appuyez pour commencer l'enregistrement",
              style: const TextStyle(color: AppColors.primary, fontSize: 15,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 1),
    );
  }
}