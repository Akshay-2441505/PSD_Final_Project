import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _profile;
  bool _loading = false;
  String? _error;

  String?             get token   => _token;
  Map<String, dynamic>? get profile => _profile;
  bool                get loading => _loading;
  String?             get error   => _error;
  bool                get isLoggedIn => _token != null;

  // Called on app start to restore session
  Future<void> restoreSession() async {
    _token = await _storage.read(key: 'jwt_token');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.loginBorrower(email, password);
      _token = res['access_token'];
      await _storage.write(key: 'jwt_token', value: _token);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _api.registerBorrower(data);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _profile = null;
    await _storage.delete(key: 'jwt_token');
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
