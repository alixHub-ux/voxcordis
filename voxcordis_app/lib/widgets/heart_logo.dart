import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo Voxcordis SVG statique.
/// [color] permet de teinter le logo (blanc sur splash, bordeaux sur loading).
/// Si color est null, les couleurs originales du SVG sont utilisées.
class HeartLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const HeartLogo({
    super.key,
    this.size = 140,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_voxcordis.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// Logo Voxcordis animé avec CustomPainter.
/// [fillRatio] 0.0 → 1.0 : proportion des lignes colorées (gauche → droite).
/// Utilisé uniquement sur l'écran d'enregistrement.
class HeartLogoAnimated extends StatelessWidget {
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final double fillRatio;

  const HeartLogoAnimated({
    super.key,
    this.size = 140,
    required this.filledColor,
    this.emptyColor = const Color(0xFFCCCCCC),
    this.fillRatio = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.88,
      child: CustomPaint(
        painter: _HeartLinePainter(
          filledColor: filledColor,
          emptyColor: emptyColor,
          fillRatio: fillRatio,
        ),
      ),
    );
  }
}

class _HeartLinePainter extends CustomPainter {
  final Color filledColor;
  final Color emptyColor;
  final double fillRatio;

  const _HeartLinePainter({
    required this.filledColor,
    required this.emptyColor,
    required this.fillRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const lineCount = 18;
    final spacing = size.width / (lineCount + 1);

    for (int i = 0; i < lineCount; i++) {
      final x = spacing * (i + 1);
      final t = i / (lineCount - 1);
      final isFilled = (i / lineCount) < fillRatio;

      final paint = Paint()
        ..color = isFilled ? filledColor : emptyColor
        ..strokeWidth = size.width * 0.028
        ..strokeCap = StrokeCap.round;

      final h = _heartProfile(t) * size.height * 0.80;
      final yOffset = _heartDip(t) * size.height * 0.16;
      final cy = size.height * 0.44 + yOffset;

      canvas.drawLine(Offset(x, cy - h / 2), Offset(x, cy + h / 2), paint);
    }
  }

  double _heartProfile(double t) {
    final l1 = math.exp(-math.pow(t - 0.27, 2) / 0.030);
    final l2 = math.exp(-math.pow(t - 0.73, 2) / 0.030);
    return (l1 + l2).clamp(0.12, 1.0);
  }

  double _heartDip(double t) => 4 * t * (1 - t);

  @override
  bool shouldRepaint(_HeartLinePainter old) =>
      old.fillRatio != fillRatio ||
      old.filledColor != filledColor ||
      old.emptyColor != emptyColor;
}