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
        return 'Anomalie vocale détectée';
      case AppConstants.classCardiac:
        return 'Signes associés à un risque cardiovasculaire';
      default:
        return 'Résultat inconnu';
    }
  }

  String get recommendation {
    switch (predictedClass) {
      case AppConstants.classHealthy:
        return 'Votre analyse vocale ne montre aucun signe inquiétant. '
            'Aucune action particulière n\'est requise. Nous vous conseillons '
            'de continuer à surveiller votre santé et à réaliser une analyse '
            'régulièrement pour un suivi optimal.';
      case AppConstants.classLaryngeal:
        return 'Votre analyse a détecté des anomalies pouvant être liées à '
            'une affection des cordes vocales ou du larynx (voix voilée, '
            'enrouement persistant). Nous vous recommandons de consulter un '
            'médecin ORL (Oto-Rhino-Laryngologiste) pour un examen approfondi. '
            'Ce professionnel pourra réaliser les examens nécessaires et vous '
            'proposer un traitement adapté si besoin.';
      case AppConstants.classCardiac:
        return 'Votre analyse vocale a identifié des signes pouvant évoquer '
            'un risque cardiovasculaire. Sans attendre, prenez rendez-vous '
            'avec un cardiologue pour un bilan complet. Les maladies '
            'cardiovasculaires détectées tôt se soignent mieux. En attendant '
            'votre consultation, évitez les efforts intenses et notez tout '
            'symptôme inhabituel (essoufflement, douleur thoracique, '
            'palpitations) pour les partager avec votre médecin.';
      default:
        return '';
    }
  }

  // ---------- CopyWith ----------

  AnalysisResult copyWith({
    int? id,
    DateTime? date,
    int? predictedClass,
    double? confidence,
    RiskLevel? riskLevel,
    bool? isSynced,
    String? modelVersion,
  }) =>
      AnalysisResult(
        id: id ?? this.id,
        date: date ?? this.date,
        predictedClass: predictedClass ?? this.predictedClass,
        confidence: confidence ?? this.confidence,
        riskLevel: riskLevel ?? this.riskLevel,
        isSynced: isSynced ?? this.isSynced,
        modelVersion: modelVersion ?? this.modelVersion,
      );

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
