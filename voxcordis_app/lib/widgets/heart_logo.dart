import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo Voxcordis depuis le fichier SVG officiel.
/// [color] permet de teinter le logo (blanc sur splash, bordeaux ailleurs).
class HeartLogo extends StatelessWidget {
  final double size;
  final Color? color; // null = couleurs originales du SVG

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