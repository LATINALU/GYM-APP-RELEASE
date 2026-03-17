import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// InsForge HTTP Client
/// Handles all communication with the InsForge backend (PostgREST + custom auth endpoints)
/// Manages JWT tokens, refresh, and request headers
class InsForgeClient {
  final String baseUrl;
  final String postgrestUrl;
  final http.Client _httpClient;

  String? _accessToken;
  String? _refreshToken;
  String? _currentUserId;

  static InsForgeClient? _instance;

  InsForgeClient._({
    required this.baseUrl,
    required this.postgrestUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Singleton factory
  static InsForgeClient get instance {
    if (_instance == null) {
      throw StateError('InsForgeClient not initialized. Call InsForgeClient.initialize() first.');
    }
    return _instance!;
  }

  /// Initialize the client with server URLs
  static InsForgeClient initialize({
    required String baseUrl,
    required String postgrestUrl,
    http.Client? httpClient,
  }) {
    _instance = InsForgeClient._(
      baseUrl: baseUrl,
      postgrestUrl: postgrestUrl,
      httpClient: httpClient,
    );
    return _instance!;
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  String? get accessToken => _accessToken;
  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _accessToken != null;

  void setTokens({required String accessToken, String? refreshToken, String? userId}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _currentUserId = userId;
    _persistTokens();
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _currentUserId = null;
    _clearPersistedTokens();
  }

  Future<void> restoreTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('insforge_access_token');
      _refreshToken = prefs.getString('insforge_refresh_token');
      _currentUserId = prefs.getString('insforge_user_id');
      debugPrint('[InsForge] Tokens restored: ${_accessToken != null ? "yes" : "no"}');
    } catch (e) {
      debugPrint('[InsForge] Error restoring tokens: $e');
    }
  }

  Future<void> _persistTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString('insforge_access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString('insforge_refresh_token', _refreshToken!);
      }
      if (_currentUserId != null) {
        await prefs.setString('insforge_user_id', _currentUserId!);
      }
    } catch (e) {
      debugPrint('[InsForge] Error persisting tokens: $e');
    }
  }

  Future<void> _clearPersistedTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('insforge_access_token');
      await prefs.remove('insforge_refresh_token');
      await prefs.remove('insforge_user_id');
    } catch (e) {
      debugPrint('[InsForge] Error clearing tokens: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HTTP HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Map<String, String> get _postgrestHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Prefer': 'return=representation',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // ═══════════════════════════════════════════════════════════════════
  // AUTH ENDPOINTS (InsForge backend, not PostgREST)
  // ═══════════════════════════════════════════════════════════════════

  /// Login with email/password → POST /api/auth/sessions?client_type=mobile
  /// Returns {accessToken, refreshToken, user}
  Future<InsForgeResponse> authLogin(String email, String password) async {
    return _post('$baseUrl/api/auth/sessions?client_type=mobile', {
      'email': email,
      'password': password,
    });
  }

  /// Register new user → POST /api/auth/users?client_type=mobile
  /// Returns {accessToken, refreshToken, user}
  Future<InsForgeResponse> authRegister(Map<String, dynamic> userData) async {
    return _post('$baseUrl/api/auth/users?client_type=mobile', userData);
  }

  /// Refresh JWT token → POST /api/auth/refresh?client_type=mobile
  Future<InsForgeResponse> authRefresh() async {
    return _post('$baseUrl/api/auth/refresh?client_type=mobile', {
      'refresh_token': _refreshToken,
    });
  }

  /// Get current session/user → GET /api/auth/sessions/current
  Future<InsForgeResponse> authMe() async {
    return _get('$baseUrl/api/auth/sessions/current');
  }

  /// Logout → POST /api/auth/logout?client_type=mobile
  Future<InsForgeResponse> authLogout() async {
    final response = await _post('$baseUrl/api/auth/logout?client_type=mobile', {});
    clearTokens();
    return response;
  }

  /// Change password → POST /api/auth/email/reset-password
  Future<InsForgeResponse> authChangePassword(String currentPassword, String newPassword) async {
    return _post('$baseUrl/api/auth/email/reset-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  /// Send password reset email → POST /api/auth/email/send-reset-password
  Future<InsForgeResponse> authResetPassword(String email) async {
    return _post('$baseUrl/api/auth/email/send-reset-password', {
      'email': email,
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // POSTGREST CRUD (Database operations via PostgREST)
  // ═══════════════════════════════════════════════════════════════════

  /// SELECT: Get records from a table
  /// [table] - table name
  /// [query] - PostgREST query params (e.g., 'id=eq.xxx', 'select=*')
  Future<InsForgeResponse> from(String table, {String? query}) async {
    final url = query != null ? '$postgrestUrl/$table?$query' : '$postgrestUrl/$table';
    return _get(url, usePostgrest: true);
  }

  /// INSERT: Create a new record
  Future<InsForgeResponse> insert(String table, Map<String, dynamic> data) async {
    return _post('$postgrestUrl/$table', data, usePostgrest: true);
  }

  /// INSERT MANY: Create multiple records
  Future<InsForgeResponse> insertMany(String table, List<Map<String, dynamic>> data) async {
    return _postList('$postgrestUrl/$table', data);
  }

  /// UPDATE: Update records matching filter
  /// [filter] - PostgREST filter (e.g., 'id=eq.xxx')
  Future<InsForgeResponse> update(String table, Map<String, dynamic> data, String filter) async {
    return _patch('$postgrestUrl/$table?$filter', data);
  }

  /// DELETE: Delete records matching filter
  Future<InsForgeResponse> delete(String table, String filter) async {
    return _delete('$postgrestUrl/$table?$filter');
  }

  /// RPC: Call a Postgres function
  Future<InsForgeResponse> rpc(String functionName, Map<String, dynamic> params) async {
    return _post('$postgrestUrl/rpc/$functionName', params, usePostgrest: true);
  }

  // ═══════════════════════════════════════════════════════════════════
  // STORAGE ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════

  /// Upload a file
  Future<InsForgeResponse> uploadFile(String bucket, String path, List<int> bytes, String contentType) async {
    final uri = Uri.parse('$baseUrl/api/storage/$bucket/$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: path));

    try {
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return InsForgeResponse.fromHttpResponse(response);
    } catch (e) {
      return InsForgeResponse(statusCode: 0, body: {}, error: e.toString());
    }
  }

  /// Get file URL
  String getFileUrl(String bucket, String path) {
    return '$baseUrl/api/storage/$bucket/$path';
  }

  /// Delete a file
  Future<InsForgeResponse> deleteFile(String bucket, String path) async {
    return _delete('$baseUrl/api/storage/$bucket/$path');
  }

  // ═══════════════════════════════════════════════════════════════════
  // INTERNAL HTTP METHODS
  // ═══════════════════════════════════════════════════════════════════

  Future<InsForgeResponse> _get(String url, {bool usePostgrest = false}) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: usePostgrest ? _postgrestHeaders : _authHeaders,
      );
      return InsForgeResponse.fromHttpResponse(response);
    } catch (e) {
      debugPrint('[InsForge] GET $url failed: $e');
      return InsForgeResponse(statusCode: 0, body: {}, error: e.toString());
    }
  }

  Future<InsForgeResponse> _post(String url, Map<String, dynamic> data, {bool usePostgrest = false}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: usePostgrest ? _postgrestHeaders : _authHeaders,
        body: jsonEncode(data),
      );
      return InsForgeResponse.fromHttpResponse(response);
    } catch (e) {
      debugPrint('[InsForge] POST $url failed: $e');
      return InsForgeResponse(statusCode: 0, body: {}, error: e.toString());
    }
  }

  Future<InsForgeResponse> _postList(String url, List<Map<String, dynamic>> data) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: _postgrestHeaders,
        body: jsonEncode(data),
      );
      return InsForgeResponse.fromHttpResponse(response);
    } catch (e) {
      debugPrint('[InsForge] POST[] $url failed: $e');
      return InsForgeResponse(statusCode: 0, body: {}, error: e.toString());
    }
  }

  Future<InsForgeResponse> _patch(String url, Map<String, dynamic> data) async {
    try {
      final response = await _httpClient.patch(
        Uri.parse(url),
        headers: _postgrestHeaders,
        body: jsonEncode(data),
      );
      return InsForgeResponse.fromHttpResponse(response);
    } catch (e) {
      debugPrint('[InsForge] PATCH $url failed: $e');
      return InsForgeResponse(statusCode: 0, body: {}, error: e.toString());
    }
  }

  Future<InsForgeResponse> _delete(String url) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse(url),
        headers: _postgrestHeaders,
      );
      return InsForgeResponse.fromHttpResponse(response);
    } catch (e) {
      debugPrint('[InsForge] DELETE $url failed: $e');
      return InsForgeResponse(statusCode: 0, body: {}, error: e.toString());
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Unified response wrapper for InsForge API calls
class InsForgeResponse {
  final int statusCode;
  final dynamic body;
  final String? error;

  const InsForgeResponse({
    required this.statusCode,
    required this.body,
    this.error,
  });

  factory InsForgeResponse.fromHttpResponse(http.Response response) {
    dynamic parsedBody;
    try {
      parsedBody = jsonDecode(response.body);
    } catch (_) {
      parsedBody = response.body;
    }

    return InsForgeResponse(
      statusCode: response.statusCode,
      body: parsedBody,
      error: response.statusCode >= 400 ? _extractError(parsedBody) : null,
    );
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  /// Get body as a Map
  Map<String, dynamic> get dataMap => body is Map<String, dynamic> ? body : {};

  /// Get body as a List
  List<dynamic> get dataList => body is List ? body : [];

  /// Get first item from list response
  Map<String, dynamic>? get firstItem {
    if (body is List && (body as List).isNotEmpty) {
      return body[0] as Map<String, dynamic>;
    }
    return body is Map<String, dynamic> ? body : null;
  }

  static String? _extractError(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['message'] ?? body['error'] ?? body['details'] ?? 'Unknown error';
    }
    return body?.toString();
  }

  @override
  String toString() => 'InsForgeResponse($statusCode, error: $error)';
}
