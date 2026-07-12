import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/analysis_result.dart';

/// Pipeline d'inference locale (mode offline).
///
/// Doit reproduire EXACTEMENT le preprocessing du backend Python :
///   rms = sqrt(mean(x^2))
///   audio = audio * (0.1 / rms)
///
/// Ordre des operations (section 3) :
///   1. Charger le fichier WAV
///   2. Normalisation RMS (identique au preprocessing d'entrainement)
///   3. Passer dans YAMNet.tflite  -> embedding 1024-dim
///   4. Appliquer le StandardScaler (depuis scaler_params.json)
///   5. Passer dans voxcordis_model.tflite -> probabilites 3 classes
///   6. Retourner un AnalysisResult
///
/// NOTE : scaler_params.json doit contenir {"mean_": [...], "scale_": [...]}
/// (export Python : voir documentation du backend).
class InferenceService {
  Interpreter? _yamnet;
  Interpreter? _classifier;
  List<double>? _scalerMean;
  List<double>? _scalerScale;

  bool _isLoaded = false;

  /// Charge les deux modeles TFLite et les params du scaler.
  Future<void> loadModels() async {
    if (_isLoaded) return;

    // Charge YAMNet
    _yamnet = await Interpreter.fromAsset(AppConstants.yamnetModelPath);

    // Charge le classificateur Voxcordis
    _classifier =
        await Interpreter.fromAsset(AppConstants.classifierModelPath);

    // Charge les parametres du StandardScaler depuis JSON
    final jsonStr = await rootBundle.loadString(AppConstants.scalerParamsPath);
    final Map<String, dynamic> params = json.decode(jsonStr);
    _scalerMean = List<double>.from(params['mean_']);
    _scalerScale = List<double>.from(params['scale_']);

    _isLoaded = true;
  }

  /// Lance l'inference complete sur un fichier WAV.
  Future<AnalysisResult> runInference(String wavPath) async {
    if (!_isLoaded) await loadModels();

    // 1. Lire les samples PCM depuis le fichier WAV
    final samples = await _readWavSamples(wavPath);

    // 2. Normalisation RMS (reproduit le preprocessing Python)
    final normalized = _rmsNormalize(samples);

    // 3. Inference YAMNet -> embedding 1024-dim
    final embedding = await _runYamnet(normalized);

    // 4. StandardScaler
    final scaled = _applyScaler(embedding);

    // 5. Classificateur -> probabilites
    final probs = await _runClassifier(scaled);

    // 6. Construction du resultat
    final classIdx =
        probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
    final confidence = probs[classIdx] * 100; // pourcentage, comme le backend
    final risk = _toRiskLevel(classIdx);

    return AnalysisResult(
      date: DateTime.now(),
      predictedClass: classIdx,
      confidence: confidence,
      riskLevel: risk,
      modelVersion: '1.1.0',
    );
  }

  // ── Helpers prive ──────────────────────────────────────────────────────────

  /// Lit les echantillons PCM 16-bit d'un WAV mono 16kHz.
  /// Format WAV minimal : 44 bytes d'entete, puis donnees PCM Little-Endian.
  Future<List<double>> _readWavSamples(String path) async {
    final bytes = await File(path).readAsBytes();
    final data = bytes.sublist(44); // on passe l'entete WAV
    final samples = <double>[];
    for (int i = 0; i + 1 < data.length; i += 2) {
      final s = (data[i + 1] << 8) | data[i];
      final signed = s > 32767 ? s - 65536 : s;
      samples.add(signed / 32768.0);
    }
    // Tronquer / padder a exactement sampleRate * durationSeconds echantillons
    const targetLen =
        AppConstants.sampleRate * AppConstants.recordingDurationSeconds;
    if (samples.length > targetLen) {
      return samples.sublist(0, targetLen);
    }
    while (samples.length < targetLen) {
      samples.add(0.0);
    }
    return samples;
  }

  static const double _rmsTarget = 0.1;

  /// Normalisation RMS : identique au step Python
  /// `audio = audio * (0.1 / (sqrt(mean(audio^2)) + 1e-9))`
  List<double> _rmsNormalize(List<double> samples) {
    final rms = _rms(samples);
    if (rms > 0) {
      return samples.map((s) => s * (_rmsTarget / (rms + 1e-9))).toList();
    }
    return samples;
  }

  double _rms(List<double> s) {
    final sum = s.fold<double>(0.0, (acc, x) => acc + x * x);
    return math.sqrt(sum / s.length);
  }

  /// Passe les samples dans YAMNet et retourne l'embedding (1024-dim).
  Future<List<double>> _runYamnet(List<double> samples) async {
    // YAMNet attend un tenseur [1, N] float32
    final input = [samples.map((e) => e.toDouble()).toList()];
    // YAMNet produit embeddings [frames, 1024] – on prend la moyenne
    final outputShape = _yamnet!.getOutputTensor(1).shape;
    final outputRaw =
        List.generate(outputShape[0], (_) => List.filled(1024, 0.0));
    final outputs = {1: outputRaw};
    _yamnet!.runForMultipleInputs([input], outputs);
    // Moyenne sur les frames
    final frames = outputRaw.length;
    final mean = List.filled(1024, 0.0);
    for (final frame in outputRaw) {
      for (int i = 0; i < 1024; i++) {
        mean[i] += frame[i] / frames;
      }
    }
    return mean;
  }

  /// Applique le StandardScaler : (x - mean) / scale
  List<double> _applyScaler(List<double> embedding) {
    return List.generate(
      embedding.length,
      (i) => (embedding[i] - _scalerMean![i]) / _scalerScale![i],
    );
  }

  /// Lance le classificateur et retourne les 3 probabilites softmax.
  Future<List<double>> _runClassifier(List<double> scaled) async {
    final input = [scaled];
    final output = [List.filled(3, 0.0)];
    _classifier!.run(input, output);
    return output[0];
  }

  RiskLevel _toRiskLevel(int classIdx) {
    switch (classIdx) {
      case AppConstants.classHealthy:
        return RiskLevel.low;
      case AppConstants.classLaryngeal:
        return RiskLevel.moderate;
      case AppConstants.classCardiac:
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }

  void close() {
    _yamnet?.close();
    _classifier?.close();
  }
}
