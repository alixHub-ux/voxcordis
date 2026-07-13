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

  /// Lance l'analyse (online si possible, sinon offline).
  /// Appelé depuis l'écran de loading.
  Future<void> startAnalysis(String wavPath) async {
    _state = AnalysisState.analyzing;
    _errorMsg = null;
    notifyListeners();

    try {
      final online = await backend.isOnline();

      late final AnalysisResult result;
      late final bool isSynced;
      if (online && backend.token != null) {
        try {
          result = await backend.predictOnline(wavPath);
          isSynced = true;
        } catch (_) {
          result = await _local.runInference(wavPath);
          isSynced = false;
        }
      } else {
        result = await _local.runInference(wavPath);
        isSynced = false;
      }
      final id = await DatabaseHelper.instance.insertResult(result);
      _lastResult = AnalysisResult(
        id: id,
        date: result.date,
        predictedClass: result.predictedClass,
        confidence: result.confidence,
        riskLevel: result.riskLevel,
        isSynced: isSynced,
        modelVersion: result.modelVersion,
      );

      if (isSynced) await DatabaseHelper.instance.markSynced(id);
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