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
    _isLoading = true;
    _error = null;
    notifyListeners();


    // Simulation pour la demo
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = UserModel(
      id: 1,
      firstName: 'Alix',
      lastName: 'VEBAMBA',
      email: email,
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final user = UserModel(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    await DatabaseHelper.instance.insertUser(user);

    _currentUser = UserModel(
        id: 1, firstName: firstName, lastName: lastName, email: email);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
