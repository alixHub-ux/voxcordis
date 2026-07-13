import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../models/analysis_result.dart';
import 'tflite_native_service.dart';

/// Pipeline d'inference locale via le plugin Android TFLite natif.
class InferenceService {
  final TfliteNativeService _native = TfliteNativeService();
  List<double>? _scalerMean;
  List<double>? _scalerScale;
  bool _isLoaded = false;

  Future<void> loadModels() async {
    if (_isLoaded) return;

    try {
      final ok = await _native.loadModels();
      if (!ok) throw Exception('Failed to load TFLite models');

      final jsonStr = await rootBundle.loadString(AppConstants.scalerParamsPath);
      final Map<String, dynamic> params = json.decode(jsonStr);
      _scalerMean = List<double>.from(params['mean_']);
      _scalerScale = List<double>.from(params['scale_']);

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      rethrow;
    }
  }

  Future<AnalysisResult> runInference(String wavPath) async {
    if (!_isLoaded) await loadModels();

    final samples = await _readWavSamples(wavPath);
    final normalized = _rmsNormalize(samples);
    final embedding = await _native.runYamnet(normalized);
    final scaled = _applyScaler(embedding);
    final probs = await _native.runClassifier(scaled);

    final classIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
    final confidence = probs[classIdx] * 100;
    final risk = _toRiskLevel(classIdx);

    return AnalysisResult(
      date: DateTime.now(),
      predictedClass: classIdx,
      confidence: confidence,
      riskLevel: risk,
      modelVersion: '1.1.0',
    );
  }

  Future<List<double>> _readWavSamples(String path) async {
    final bytes = await File(path).readAsBytes();
    final data = bytes.sublist(44);
    final samples = <double>[];
    for (int i = 0; i + 1 < data.length; i += 2) {
      final s = (data[i + 1] << 8) | data[i];
      final signed = s > 32767 ? s - 65536 : s;
      samples.add(signed / 32768.0);
    }
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

  List<double> _applyScaler(List<double> embedding) {
    return List.generate(
      embedding.length,
      (i) => (embedding[i] - _scalerMean![i]) / _scalerScale![i],
    );
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
    _native.close();
  }
}
