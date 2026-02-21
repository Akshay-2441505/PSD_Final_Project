import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class AdminApiService {
  final String _base = kBaseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _parse(http.Response r) {
    final body = jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw Exception((body is Map ? body['detail'] : body).toString());
    }
    return body is Map<String, dynamic> ? body : {'data': body};
  }

  List<dynamic> _parseList(http.Response r) {
    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      throw Exception((body is Map ? body['detail'] : body).toString());
    }
    return jsonDecode(r.body) as List<dynamic>;
  }

  // ── AUTH ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> loginAdmin(String email, String password) async {
    final r = await http.post(
      Uri.parse('$_base/auth/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parse(r);
  }

  // ── APPLICATIONS ──────────────────────────────────────────────────────
  Future<List<dynamic>> getApplications(String token, {String? status}) async {
    final uri = Uri.parse('$_base/admin/applications')
        .replace(queryParameters: status != null ? {'status': status} : null);
    final r = await http.get(uri, headers: _headers(token));
    return _parseList(r);
  }

  Future<Map<String, dynamic>> getApplicationDetail(String token, String appId) async {
    final r = await http.get(
      Uri.parse('$_base/admin/applications/$appId'),
      headers: _headers(token),
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> submitDecision(
      String token, String appId, String decision, String? remarks) async {
    final r = await http.patch(
      Uri.parse('$_base/admin/applications/$appId/decision'),
      headers: _headers(token),
      body: jsonEncode({'decision': decision, 'remarks': remarks ?? ''}),
    );
    return _parse(r);
  }

  // ── CHARTS ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getExpenseChart(String token, String appId) async {
    final r = await http.get(
      Uri.parse('$_base/admin/charts/expenses?app_id=$appId'),
      headers: _headers(token),
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> getRevenueChart(String token, String appId) async {
    final r = await http.get(
      Uri.parse('$_base/admin/charts/revenue?app_id=$appId'),
      headers: _headers(token),
    );
    return _parse(r);
  }
}
