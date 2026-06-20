import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/analysis_result.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/risk_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  RiskLevel? _filter;

  @override
  void initState() {
    super.initState();
    // ignore: use_build_context_synchronously
    Future.microtask(() => context.read<AnalysisProvider>().loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final all      = context.watch<AnalysisProvider>().history;
    final filtered = _filter == null ? all : all.where((r) => r.riskLevel == _filter).toList();
    int cnt(RiskLevel l) => all.where((r) => r.riskLevel == l).length;

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
        title: const Text('Historique',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              _CounterBadge('${cnt(RiskLevel.low).toString().padLeft(2,'0')} Bas', AppColors.riskLow),
              const SizedBox(width: 10),
              _CounterBadge('${cnt(RiskLevel.moderate).toString().padLeft(2,'0')} Modéré', AppColors.riskModerate),
              const SizedBox(width: 10),
              _CounterBadge('${cnt(RiskLevel.high).toString().padLeft(2,'0')} Elevé', AppColors.riskHigh),
            ]),
          ),
          const SizedBox(height: 12),
          // Filtres pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _FilterPill('Tout', null, _filter, (v) => setState(() => _filter = v)),
              const SizedBox(width: 8),
              _FilterPill('Bas', RiskLevel.low, _filter, (v) => setState(() => _filter = v)),
              const SizedBox(width: 8),
              _FilterPill('Modéré', RiskLevel.moderate, _filter, (v) => setState(() => _filter = v)),
              const SizedBox(width: 8),
              _FilterPill('Elevé', RiskLevel.high, _filter, (v) => setState(() => _filter = v)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Aucune analyse.',
                    style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          // ignore: deprecated_member_use
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                              blurRadius: 10, offset: const Offset(0, 2))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            RiskBadge(level: r.riskLevel, label: r.riskLabel),
                            const SizedBox(width: 10),
                            DateBadge(date: DateFormat('MMM d, yyyy', 'fr').format(r.date)),
                          ]),
                          const SizedBox(height: 10),
                          Text(r.userMessage,
                              style: const TextStyle(fontSize: 15,
                                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 2),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  final String label; final Color color;
  const _CounterBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    // ignore: deprecated_member_use
    decoration: BoxDecoration(color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

class _FilterPill extends StatelessWidget {
  final String label; final RiskLevel? value; final RiskLevel? current;
  final void Function(RiskLevel?) onTap;
  const _FilterPill(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.primary,
              width: isActive ? 0 : 1.5),
        ),
        child: Text(label, style: TextStyle(
          color: isActive ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w600, fontSize: 14,
        )),
      ),
    );
  }
}
