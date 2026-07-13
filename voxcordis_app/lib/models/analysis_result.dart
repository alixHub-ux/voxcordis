import '../core/constants/app_constants.dart';

/// Niveaux de risque tels que definis dans le Resume Technique, section 4
enum RiskLevel { low, moderate, high }

class AnalysisResult {
  final int? id;
  final DateTime date;
  final int predictedClass; // 0=Healthy, 1=Laryngeal, 2=Cardiovascular
  final double confidence;
  final RiskLevel riskLevel;
  final bool isSynced;
  final String? modelVersion;

  AnalysisResult({
    this.id,
    required this.date,
    required this.predictedClass,
    required this.confidence,
    required this.riskLevel,
    this.isSynced = false,
    this.modelVersion,
  });

  // ---------- Helpers UI (section 4 du Resume) ----------

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Risque Bas';
      case RiskLevel.moderate:
        return 'Risque Modéré';
      case RiskLevel.high:
        return 'Risque Élevé';
    }
  }

  String get userMessage {
    switch (predictedClass) {
      case AppConstants.classHealthy:
        return 'Aucune anomalie détectée';
      case AppConstants.classLaryngeal:
        return 'Anomalie détectée';
      case AppConstants.classCardiac:
        return 'Signes associés à un risque cardiovasculaire';
      default:
        return 'Résultat inconnu';
    }
  }

  String get recommendation {
    switch (predictedClass) {
      case AppConstants.classHealthy:
        return 'Aucune action requise ! Continuez à surveiller votre santé.';
      case AppConstants.classLaryngeal:
        return 'Consultez un spécialiste ORL.';
      case AppConstants.classCardiac:
        return 'Consultez un cardiologue dans les plus brefs délais.';
      default:
        return '';
    }
  }

  // ---------- SQLite ----------

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'predictedClass': predictedClass,
        'confidence': confidence,
        'riskLevel': riskLevel.index,
        'isSynced': isSynced ? 1 : 0,
        'modelVersion': modelVersion,
      };

  factory AnalysisResult.fromMap(Map<String, dynamic> map) => AnalysisResult(
        id: map['id'],
        date: DateTime.parse(map['date']),
        predictedClass: map['predictedClass'],
        confidence: map['confidence'],
        riskLevel: RiskLevel.values[map['riskLevel']],
        isSynced: map['isSynced'] == 1,
        modelVersion: map['modelVersion'],
      );
}
