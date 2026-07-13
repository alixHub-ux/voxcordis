import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/analysis_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/risk_badge.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<AnalysisProvider>().lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Résultat')),
        body: const Center(child: Text('Aucun résultat.')),
        bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 1),
      );
    }

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
        title: const Text('Résultat',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte résultat
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  // ignore: deprecated_member_use
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RiskBadge(level: result.riskLevel, label: result.riskLabel),
                  const SizedBox(height: 12),
                  Text(result.userMessage,
                      style: const TextStyle(fontSize: 15,
                          color: AppColors.textSecondary, height: 1.5)),
                  if (result.riskLevel.index == 2) ...[
                    const SizedBox(height: 4),
                    const Text("Ce n'est pas un diagnostic, c'est une alerte.",
                        style: TextStyle(fontSize: 14,
                            color: AppColors.textSecondary, height: 1.5)),
                  ],
                ]),
              ),
              const SizedBox(height: 28),

              // Ce que vous devez faire
              const Text('Ce que vous devez faire',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(result.recommendation,
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 32),

              // Boutons côte à côte
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final r = context.read<AnalysisProvider>().lastResult;
                      if (r != null) PdfExportService.export(r);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32)),
                    ),
                    child: const Text('Exportez en PDF',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AnalysisProvider>().reset();
                      Navigator.pushReplacementNamed(context, AppRoutes.recordingGuide);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 52),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32)),
                    ),
                    child: const Text('Reprendre',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
              const SizedBox(height: 32),

              // Avertissement médical
              const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_outlined,
                    color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Voxcordis est un outil de dépistage uniquement il ne constitue pas '
                    'un diagnostic médical.\nVeuillez consultez un professionnel de la santé '
                    'qualifié pour toute décision médicale.',
                    style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.6),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 1),
    );
  }
}
