import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  final String _base = kBaseUrl;

  Map<String, String> _headers([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // ── AUTH ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> registerBorrower(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('$_base/auth/register'),
        headers: _headers(), body: jsonEncode(data));
    return _parse(r);
  }

  Future<Map<String, dynamic>> loginBorrower(String email, String password) async {
    final r = await http.post(Uri.parse('$_base/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}));
    return _parse(r);
  }

  // ── LOANS ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> applyLoan(Map<String, dynamic> data, String token) async {
    final r = await http.post(Uri.parse('$_base/loans/apply'),
        headers: _headers(token), body: jsonEncode(data));
    return _parse(r);
  }

  Future<List<dynamic>> getMyLoans(String token) async {
    final r = await http.get(Uri.parse('$_base/loans/my'), headers: _headers(token));
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(body['detail'] ?? 'Failed to fetch loans');
    return body as List;
  }

  Future<Map<String, dynamic>> getLoanStatus(String appId, String token) async {
    final r = await http.get(Uri.parse('$_base/loans/$appId/status'), headers: _headers(token));
    return _parse(r);
  }

  Future<Map<String, dynamic>> fetchBankStatement(String appId, String token) async {
    final r = await http.post(
        Uri.parse('$_base/loans/account-aggregator/fetch?app_id=$appId'),
        headers: _headers(token));
    return _parse(r);
  }

  // ── DASHBOARD ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardInsights(String token) async {
    final r = await http.get(Uri.parse('$_base/dashboard/insights'), headers: _headers(token));
    return _parse(r);
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _parse(http.Response r) {
    final body = jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw Exception(body['detail'] ?? 'Request failed (${r.statusCode})');
    }
    return body as Map<String, dynamic>;
  }
}
