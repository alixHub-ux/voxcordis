import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../database/database_helper.dart';
import '../services/backend_service.dart';

class AuthProvider extends ChangeNotifier {
  final BackendService backend; // partagé depuis main.dart

  AuthProvider({required this.backend});

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _autoClearError() {
    Future.delayed(const Duration(seconds: 4), () {
      if (_error != null) {
        _error = null;
        notifyListeners();
      }
    });
  }

  /// Traduit les messages d'erreur anglais du serveur en français
  String _translateError(String msg) {
    const map = {
      'Incorrect email or password': 'Email ou mot de passe incorrect.',
      'Email already registered': 'Un compte existe déjà avec cet email.',
      'Email already exists': 'Un compte existe déjà avec cet email.',
      'User not found': 'Utilisateur introuvable.',
      'Not authenticated': 'Non authentifié.',
      'Could not validate credentials': 'Impossible de valider vos identifiants.',
    };
    for (final entry in map.entries) {
      if (msg.contains(entry.key)) return entry.value;
    }
    return msg; // garder le message original si pas de traduction
  }

  /// Restaure la session au démarrage de l'app.
  /// Cherche un utilisateur en SQLite, tente un re-login online
  /// pour obtenir un token frais, ou reste en offline.
  Future<bool> autoLogin() async {
    final user = await DatabaseHelper.instance.getLatestUser();
    if (user == null) return false;

    _currentUser = user;

    // Tente un re-login online pour obtenir un token
    try {
      final online = await backend.isOnline();
      if (online) {
        await backend.login(email: user.email, password: user.password);
      }
    } catch (_) {
      // Échec du re-login → on reste en offline
    }

    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Veuillez remplir tous les champs.';
      notifyListeners();
      _autoClearError();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // ── Mode online : backend ──────────────────────────────────────────
    try {
      final online = await backend.isOnline();
      if (online) {
        await backend.login(email: email, password: password);

        UserModel? user = await DatabaseHelper.instance.getUserByEmail(email);
        if (user == null) {
          final id = await DatabaseHelper.instance.insertUser(UserModel(
            firstName: email.split('@').first,
            lastName: '',
            email: email,
            password: password,
          ));
          user = UserModel(
            id: id,
            firstName: email.split('@').first,
            lastName: '',
            email: email,
            password: password,
          );
        }

        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      final msg = _translateError(
          e.toString().replaceFirst('Exception: ', ''));
      // Erreur d'authentification réelle (pas offline) → bloquer
      if (!msg.contains('SocketException') &&
          !msg.contains('TimeoutException') &&
          !msg.contains('Connection')) {
        _error = msg;
        _isLoading = false;
        notifyListeners();
        _autoClearError();
        return false;
      }
    }

    // ── Mode offline : SQLite ──────────────────────────────────────────
    try {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user == null) {
        _error = 'Aucun compte trouvé. Vérifiez votre connexion internet.';
        _isLoading = false;
        notifyListeners();
        _autoClearError();
        return false;
      }
      if (user.password != password) {
        _error = 'Mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        _autoClearError();
        return false;
      }
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur : ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      _autoClearError();
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty ||
        email.isEmpty || password.isEmpty) {
      _error = 'Veuillez remplir tous les champs.';
      notifyListeners();
      _autoClearError();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final existing = await DatabaseHelper.instance.getUserByEmail(email);
    if (existing != null) {
      _error = 'Un compte existe déjà avec cet email.';
      _isLoading = false;
      notifyListeners();
      _autoClearError();
      return false;
    }

    // ── Mode online : backend ──────────────────────────────────────────
    try {
      final online = await backend.isOnline();
      if (online) {
        await backend.register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        );
        await backend.login(email: email, password: password);
      }
    } catch (e) {
      final msg = _translateError(
          e.toString().replaceFirst('Exception: ', ''));
      if (!msg.contains('SocketException') &&
          !msg.contains('TimeoutException') &&
          !msg.contains('Connection')) {
        _error = msg;
        _isLoading = false;
        notifyListeners();
        _autoClearError();
        return false;
      }
    }

    // ── SQLite (toujours) ─────────────────────────────────────────────
    try {
      final user = UserModel(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      final id = await DatabaseHelper.instance.insertUser(user);
      _currentUser = UserModel(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur inscription : ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      _autoClearError();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _error = null;
    backend.clearToken();
    notifyListeners();
  }
}