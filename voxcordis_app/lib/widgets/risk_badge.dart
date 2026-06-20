import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/analysis_result.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final String label;
  const RiskBadge({super.key, required this.level, required this.label});

  Color get _color {
    switch (level) {
      case RiskLevel.low:      return AppColors.riskLow;
      case RiskLevel.moderate: return AppColors.riskModerate;
      case RiskLevel.high:     return AppColors.riskHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _color)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: _color,
            fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

/// Badge date avec icône calendrier (style vu dans le design)
class DateBadge extends StatelessWidget {
  final String date;
  const DateBadge({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8DDD8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF8B4A4A)),
        const SizedBox(width: 5),
        Text(date, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w500, color: Color(0xFF8B4A4A))),
      ]),
    );
  }
}
