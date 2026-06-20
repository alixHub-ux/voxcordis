import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../services/audio_service.dart';
import '../services/inference_service.dart';
import '../services/backend_service.dart';
import '../database/database_helper.dart';

enum AnalysisState { idle, recording, analyzing, done, error }

class AnalysisProvider extends ChangeNotifier {
  final AudioService _audio = AudioService();
  final InferenceService _inference = InferenceService();
  final BackendService _backend = BackendService();

  AnalysisState _state = AnalysisState.idle;
  AnalysisResult? _lastResult;
  List<AnalysisResult> _history = [];
  String? _errorMsg;

  AnalysisState get state => _state;
  AnalysisResult? get lastResult => _lastResult;
  List<AnalysisResult> get history => _history;
  String? get errorMsg => _errorMsg;

  // ── Enregistrement ────────────────────────────────────────────────────────

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

  /// Arrete l'enregistrement puis lance l'inference (offline ou online).
  Future<void> stopAndAnalyze() async {
    _state = AnalysisState.analyzing;
    notifyListeners();

    try {
      final wavPath = await _audio.stopRecording();
      if (wavPath == null) throw Exception('Fichier audio introuvable.');

      // Detection auto offline/online (section 5)
      final online = await _backend.isOnline();
      AnalysisResult result;

      if (online) {
        result = await _backend.predictOnline(wavPath);
      } else {
        result = await _inference.runInference(wavPath);
      }

      // Persistance locale
      final id = await DatabaseHelper.instance.insertResult(result);
      _lastResult = AnalysisResult(
        id: id,
        date: result.date,
        predictedClass: result.predictedClass,
        confidence: result.confidence,
        riskLevel: result.riskLevel,
        isSynced: result.isSynced,
        modelVersion: result.modelVersion,
      );

      // Sync cloud en arriere-plan si online
      if (online) {
        DatabaseHelper.instance.markSynced(id);
      }

      await _audio.deleteTemp();
      _state = AnalysisState.done;
    } catch (e) {
      _errorMsg = e.toString();
      _state = AnalysisState.error;
    }
    notifyListeners();
  }

  // ── Historique ────────────────────────────────────────────────────────────

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
    _inference.close();
    super.dispose();
  }
}
