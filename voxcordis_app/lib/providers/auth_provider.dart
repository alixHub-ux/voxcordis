import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../database/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Veuillez remplir tous les champs.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await DatabaseHelper.instance.getUserByEmail(email);

      if (user == null) {
        _error = 'Aucun compte trouvé avec cet email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (user.password != password) {
        _error = 'Mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = 'Erreur de connexion : ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'Veuillez remplir tous les champs.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = await DatabaseHelper.instance.getUserByEmail(email);
      if (existing != null) {
        _error = 'Un compte existe déjà avec cet email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

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
      _error = 'Erreur lors de l\'inscription : ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}