import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../services/audio_service.dart';
import '../services/backend_service.dart';
import '../services/inference_service.dart';
import '../services/pdf_export_service.dart';
import '../database/database_helper.dart';

enum AnalysisState { idle, recording, analyzing, done, error }

class AnalysisProvider extends ChangeNotifier {
  final AudioService _audio = AudioService();
  final BackendService backend;
  final InferenceService _local = InferenceService();

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

  /// Arrête l'enregistrement et retourne le chemin du fichier WAV.
  Future<String?> stopRecording() async {
    final wavPath = await _audio.stopRecording();
    return wavPath;
  }

  /// Lance l'analyse toujours via TFLite, puis synchronise si connecté.
  /// Appelé depuis l'écran de loading.
  Future<void> startAnalysis(String wavPath) async {
    _state = AnalysisState.analyzing;
    _errorMsg = null;
    notifyListeners();

    try {
      // 1. Toujours TFLite — pas de branchement online/offline
      final result = await _local.runInference(wavPath);

      // 2. Sauvegarde locale immédiate
      final id = await DatabaseHelper.instance.insertResult(result);
      _lastResult = AnalysisResult(
        id: id,
        date: result.date,
        predictedClass: result.predictedClass,
        confidence: result.confidence,
        riskLevel: result.riskLevel,
        isSynced: false,
        modelVersion: result.modelVersion,
      );

      // 3. Navigation immédiate vers le résultat
      _state = AnalysisState.done;
      notifyListeners();

      // 4. Sync arrière-plan si connecté (non-bloquant pour l'utilisateur)
      if (backend.token != null) {
        _syncAfterAnalysis(result, id);
      }

      // 5. Nettoyage fichier temporaire
      await _audio.deleteTemp();

    } catch (e) {
      _errorMsg = e.toString().replaceFirst('Exception: ', '');
      _state = AnalysisState.error;
      notifyListeners();
    }
  }

  /// Synchronise le résultat en arrière-plan après navigation
  Future<void> _syncAfterAnalysis(AnalysisResult result, int dbId) async {
    try {
      final online = await backend.isOnline();
      if (online) {
        await backend.syncResult(result);
        await DatabaseHelper.instance.markSynced(dbId);
        _lastResult = _lastResult?.copyWith(isSynced: true);
        notifyListeners();
      }
    } catch (_) {
      // sync échoué → reste local, pas de blocage
    }
  }

  Future<void> loadHistory() async {
    _history = await DatabaseHelper.instance.getAllResults();
    notifyListeners();
  }

  Future<void> deleteResult(int id) async {
    await DatabaseHelper.instance.deleteResult(id);
    _history.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> deleteAllResults() async {
    await DatabaseHelper.instance.deleteAllResults();
    _history.clear();
    notifyListeners();
  }

  Future<void> exportPdf(AnalysisResult result) async {
    await PdfExportService.export(result);
  }

  void reset() {
    _state = AnalysisState.idle;
    _errorMsg = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audio.dispose();
    _local.close();
    super.dispose();
  }
}