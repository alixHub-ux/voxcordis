import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

/// Communication avec le backend FastAPI (mode online – section 5).
/// URL configurable : pointe vers le deployment Hugging Face Spaces.
class BackendService {
  static const String _baseUrl =
      'https://voxcordis-api.onrender.com';

  /// Verifie si le backend est joignable.
  Future<bool> isOnline() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 60));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envoie le fichier WAV au backend et retourne un AnalysisResult.
  Future<AnalysisResult> predictOnline(String wavPath) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files
          .add(await http.MultipartFile.fromPath('file', wavPath));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final data = json.decode(body) as Map<String, dynamic>;

    return AnalysisResult(
      date: DateTime.now(),
      predictedClass: data['predicted_class'],
      confidence: (data['confidence'] as num).toDouble(),
      riskLevel: RiskLevel.values[data['risk_level_index'] ?? 0],
      isSynced: true,
      modelVersion: data['model_version'],
    );
  }

  /// Synchronise les resultats non encore synces vers le cloud.
  Future<void> syncResult(AnalysisResult result) async {
    await http.post(
      Uri.parse('$_baseUrl/sync'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(result.toMap()),
    );
  }
}
