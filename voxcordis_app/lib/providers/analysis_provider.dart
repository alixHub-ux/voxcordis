import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../services/audio_service.dart';
import '../services/backend_service.dart';
import '../database/database_helper.dart';

enum AnalysisState { idle, recording, analyzing, done, error }

class AnalysisProvider extends ChangeNotifier {
  final AudioService _audio = AudioService();
  final BackendService backend; // partagé depuis main.dart

  AnalysisProvider({required this.backend});

  AnalysisState _state = AnalysisState.idle;
  AnalysisResult? _lastResult;
  List<AnalysisResult> _history = [];
  String? _errorMsg;

  AnalysisState get state => _state;
  AnalysisResult? get lastResult => _lastResult;
  List<AnalysisResult> get history => _history;
  String? get errorMsg => _errorMsg;

  Future<bool> startRecording() async {
    final granted = await _audio.requestPermission();
    if (!granted) {
      _errorMsg = 'Permission microphone refusée.';
      _state = AnalysisState.error;
      notifyListeners();
      return false;
    }
    await _audio.startRecording();
    _state = AnalysisState.recording;
    notifyListeners();
    return true;
  }

  Future<void> stopAndAnalyze() async {
    _state = AnalysisState.analyzing;
    _errorMsg = null;
    notifyListeners();

    try {
      final wavPath = await _audio.stopRecording();
      if (wavPath == null) throw Exception('Fichier audio introuvable.');

      final online = await backend.isOnline();
      if (!online) {
        throw Exception(
          'Connexion au serveur impossible.\n'
          'Vérifiez votre connexion internet.\n'
          'Note : le serveur peut prendre 30-60s à démarrer.'
        );
      }

      final result = await backend.predictOnline(wavPath);

      final id = await DatabaseHelper.instance.insertResult(result);
      _lastResult = AnalysisResult(
        id: id,
        date: result.date,
        predictedClass: result.predictedClass,
        confidence: result.confidence,
        riskLevel: result.riskLevel,
        isSynced: true,
        modelVersion: result.modelVersion,
      );

      await DatabaseHelper.instance.markSynced(id);
      await _audio.deleteTemp();
      _state = AnalysisState.done;

    } catch (e) {
      _errorMsg = e.toString().replaceFirst('Exception: ', '');
      _state = AnalysisState.error;
    }
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _history = await DatabaseHelper.instance.getAllResults();
    notifyListeners();
  }

  void reset() {
    _state = AnalysisState.idle;
    _errorMsg = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }
}