import 'package:flutter/material.dart';

/// Palette de couleurs Voxcordis (cf. Resume Technique, section 1)
class AppColors {
  AppColors._();

  // Couleur primaire : Bordeaux fonce
  static const Color primary = Color(0xFF4E0000);
  static const Color primaryLight = Color(0xFF8B0000);

  // Couleur secondaire : Beige chaud (fond d'ecran)
  static const Color background = Color(0xFFFAF6F0);

  // Blanc (cartes, texte sur fond sombre)
  static const Color surface = Color(0xFFFFFFFF);

  // Niveaux de risque (section 4)
  static const Color riskLow = Color(0xFF2E7D32);
  static const Color riskModerate = Color(0xFFF57C00);
  static const Color riskHigh = Color(0xFFC62828);

  // Texte
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
}
