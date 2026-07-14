import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


/// [color] permet de teinter le logo (blanc sur splash, bordeaux sur loading).

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


/// [fillRatio] 0.0 = entièrement gris, 1.0 = entièrement bordeaux.

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
      height: size,
      child: Stack(
        children: [
          // Couche 1 : logo entier en gris (fond)
          SvgPicture.asset(
            'assets/images/logo_voxcordis.svg',
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(emptyColor, BlendMode.srcIn),
          ),
          // Couche 2 : logo bordeaux clipé de gauche → droite
          ClipRect(
            clipper: _LeftFillClipper(fillRatio),
            child: SvgPicture.asset(
              'assets/images/logo_voxcordis.svg',
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(filledColor, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clippe le widget pour ne montrer que la portion gauche (fillRatio * width)
class _LeftFillClipper extends CustomClipper<Rect> {
  final double fillRatio;
  const _LeftFillClipper(this.fillRatio);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fillRatio, size.height);

  @override
  bool shouldReclip(_LeftFillClipper old) => old.fillRatio != fillRatio;
}