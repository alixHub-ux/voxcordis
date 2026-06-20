import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';

/// Gestion du micro : capture, sauvegarde WAV temporaire, permissions.
/// Pipeline : 16kHz, mono, 3 secondes (identique a l'entrainement – section 8).
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _tempFilePath;

  /// Verifie et demande la permission micro (Android / iOS).
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Demarre l'enregistrement vers un fichier WAV temporaire.
  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _tempFilePath =
        '${dir.path}/voxcordis_record_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: AppConstants.sampleRate, // 16000 Hz
        numChannels: 1,                      // mono
      ),
      path: _tempFilePath!,
    );
  }

  /// Arrete l'enregistrement et retourne le chemin du fichier WAV.
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path ?? _tempFilePath;
  }

  /// Libere les ressources. A appeler apres chaque analyse (section 8, point 1).
  Future<void> dispose() async {
    await _recorder.dispose();
  }

  /// Supprime le fichier temporaire apres inference.
  Future<void> deleteTemp() async {
    if (_tempFilePath != null) {
      final f = File(_tempFilePath!);
      if (await f.exists()) await f.delete();
    }
  }

  bool get isRecording => false; // wrapper, utilise _recorder.isRecording() en vrai
  Future<bool> get isRecordingAsync => _recorder.isRecording();
}
