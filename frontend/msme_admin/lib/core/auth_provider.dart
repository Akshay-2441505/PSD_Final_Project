import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _api     = AdminApiService();

  String? _token;
  String? _adminName;
  bool    _loading = false;
  String? _error;

  String? get token     => _token;
  String? get adminName => _adminName;
  bool    get loading   => _loading;
  String? get error     => _error;
  bool    get isLoggedIn => _token != null;

  Future<void> restoreSession() async {
    _token     = await _storage.read(key: 'admin_jwt');
    _adminName = await _storage.read(key: 'admin_name');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res  = await _api.loginAdmin(email, password);
      _token     = res['access_token'];
      _adminName = res['admin_name'] as String? ?? email.split('@').first;
      await _storage.write(key: 'admin_jwt',  value: _token);
      await _storage.write(key: 'admin_name', value: _adminName);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    _token     = null;
    _adminName = null;
    await _storage.delete(key: 'admin_jwt');
    await _storage.delete(key: 'admin_name');
    notifyListeners();
  }
}
