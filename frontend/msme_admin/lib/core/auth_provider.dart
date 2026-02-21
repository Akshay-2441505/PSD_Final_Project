import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _api     = AdminApiService();

  String? _token;
  bool    _loading = false;
  String? _error;

  String? get token    => _token;
  bool    get loading  => _loading;
  String? get error    => _error;
  bool    get isLoggedIn => _token != null;

  Future<void> restoreSession() async {
    _token = await _storage.read(key: 'admin_jwt');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await _api.loginAdmin(email, password);
      _token = res['access_token'];
      await _storage.write(key: 'admin_jwt', value: _token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'admin_jwt');
    notifyListeners();
  }
}
