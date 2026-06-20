import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/risk_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // ignore: use_build_context_synchronously
    Future.microtask(() => context.read<AnalysisProvider>().loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final user     = context.watch<AuthProvider>().currentUser;
    final analysis = context.watch<AnalysisProvider>();
    final last     = analysis.lastResult ??
        (analysis.history.isNotEmpty ? analysis.history.first : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenue
              const Text('Bienvenue,',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              Text(user?.fullName ?? '—',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 28),

              // Carte dernier dépistage
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
                child: last == null
                    ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Dernier dépistage',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        SizedBox(height: 12),
                        Text('Aucun dépistage effectué.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Dernier dépistage',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        // Badge date
                        DateBadge(date: DateFormat('MMM d, yyyy', 'fr').format(last.date)),
                        const SizedBox(height: 10),
                        // Badge risque avec point coloré
                        RiskBadge(level: last.riskLevel, label: last.riskLabel),
                        const SizedBox(height: 14),
                        Text(last.userMessage,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary,
                                height: 1.5)),
                      ]),
              ),
              const SizedBox(height: 28),

              // Ce que vous devez faire
              const Text('Ce que vous devez faire',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(last?.recommendation ?? 'Effectuez votre premier dépistage.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary,
                      height: 1.5)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 0),
    );
  }
}
