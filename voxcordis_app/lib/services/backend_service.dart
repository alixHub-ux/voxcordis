import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

/// Communication avec le backend FastAPI Voxcordis sur Render.
class BackendService {
  static const String _baseUrl = 'https://voxcordis-api.onrender.com';

  // Token JWT stocké après login
  String? _token;
  String? get token => _token;
  void setToken(String t) => _token = t;
  void clearToken() => _token = null;

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Vérifie si le backend est joignable (utilise /docs qui existe toujours)
  Future<bool> isOnline() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/docs'))
          .timeout(const Duration(seconds: 90));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Inscription via le backend
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 30));

    final data = json.decode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(data['detail'] ?? 'Erreur inscription');
    }
    return data;
  }

  /// Connexion via le backend — retourne le token JWT
  Future<String> login({
    required String email,
    required String password,
  }) async {
    // FastAPI OAuth2 attend du form-data pour /auth/login
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=$email&password=$password',
    ).timeout(const Duration(seconds: 30));

    final data = json.decode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['detail'] ?? 'Email ou mot de passe incorrect');
    }

    final token = data['access_token'] as String;
    _token = token;
    return token;
  }

  /// Envoie le fichier WAV et retourne le résultat d'analyse
  Future<AnalysisResult> predictOnline(String wavPath) async {
    if (_token == null) throw Exception('Non authentifié.');

    final uri = Uri.parse('$_baseUrl/analysis/predict');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_token'
      ..files.add(await http.MultipartFile.fromPath('file', wavPath));

    final streamed = await request.send()
        .timeout(const Duration(seconds: 90));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      final err = json.decode(body);
      throw Exception(err['detail'] ?? 'Erreur analyse');
    }

    final data = json.decode(body) as Map<String, dynamic>;

    return AnalysisResult(
      date: DateTime.now(),
      predictedClass: data['predicted_class'] ?? 0,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      riskLevel: RiskLevel.values[data['risk_level_index'] ?? 0],
      isSynced: true,
      modelVersion: data['model_version'],
    );
  }

  /// Récupère l'historique depuis le backend
  Future<List<Map<String, dynamic>>> fetchHistory() async {
    if (_token == null) throw Exception('Non authentifié.');

    final res = await http.get(
      Uri.parse('$_baseUrl/analysis/history'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) throw Exception('Erreur historique');
    final list = json.decode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }
}