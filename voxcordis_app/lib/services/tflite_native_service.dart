import 'package:flutter/services.dart';

/// Appelle le plugin TFLite Android natif via MethodChannel.
class TfliteNativeService {
  static const _channel = MethodChannel('com.example.voxcordis_app/tflite');

  Future<bool> loadModels() async {
    final ok = await _channel.invokeMethod<bool>('loadModels');
    return ok ?? false;
  }

  Future<List<double>> runYamnet(List<double> samples) async {
    final result = await _channel.invokeMethod<List<dynamic>>('runYamnet', {
      'samples': samples,
    });
    return result?.cast<double>() ?? [];
  }

  Future<List<double>> runClassifier(List<double> embedding) async {
    final result = await _channel.invokeMethod<List<dynamic>>('runClassifier', {
      'embedding': embedding,
    });
    return result?.cast<double>() ?? [];
  }

  Future<void> close() async {
    await _channel.invokeMethod<void>('close');
  }
}
