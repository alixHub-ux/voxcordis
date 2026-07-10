/// Constantes globales de l'application
class AppConstants {
  AppConstants._();

  // Pretraitement audio : doit etre IDENTIQUE au pipeline d'entrainement
  // (cf. Resume Technique, section 8, point 2)
  static const int sampleRate = 16000; // 16kHz
  static const int recordingDurationSeconds = 3;
  static const bool monoChannel = true;

  // Modeles embarques (mode offline)
  static const String yamnetModelPath = 'assets/models/yamnet_quantized.tflite';
  static const String classifierModelPath =
      'assets/models/voxcordis_model.tflite';
  // NOTE : scaler.pkl (sklearn) n'est pas utilisable directement en Dart.
  // Exporter mean_ / scale_ du StandardScaler en JSON pour ce fichier.
  static const String scalerParamsPath = 'assets/models/scaler_params.json';

  // Base de donnees locale
  static const String dbName = 'voxcordis.db';
  static const int dbVersion = 2;

  // Classes du modele (section 4)
  static const int classHealthy = 0;
  static const int classLaryngeal = 1;
  static const int classCardiac = 2;
}
