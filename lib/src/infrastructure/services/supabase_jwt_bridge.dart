import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;

/// Puente de identidad Firebase Auth -> Supabase/PostgREST para el piloto
/// del módulo Mediciones.
///
/// A diferencia de la primera versión de este piloto, ya NO firma el JWT en
/// el cliente (eso exigía embeber el secreto de firma en el APK/build web,
/// forjeable por cualquiera que decompile la app). En su lugar, envía el ID
/// token real de Firebase a una función server-side (`[endpoint]`, pensada
/// como Supabase Edge Function corriendo en el mismo stack self-hosted) que
/// valida la firma del token contra las claves públicas de Firebase antes de
/// emitir el JWT puente firmado con el secreto de Supabase — ese secreto
/// nunca sale del servidor.
///
/// El token intercambiado se cachea en memoria hasta ~1 minuto antes de su
/// expiración para no pegarle al endpoint en cada request de PostgREST.
class SupabaseJwtBridge {
  final Uri _endpoint;
  final http.Client _httpClient;
  final Future<String?> Function() _getFirebaseIdToken;

  String? _cachedToken;
  DateTime? _cachedTokenExpiry;

  SupabaseJwtBridge({
    required Uri endpoint,
    http.Client? httpClient,
    Future<String?> Function()? getFirebaseIdToken,
  }) : _endpoint = endpoint,
       _httpClient = httpClient ?? http.Client(),
       _getFirebaseIdToken = getFirebaseIdToken ?? _defaultGetFirebaseIdToken;

  static Future<String?> _defaultGetFirebaseIdToken() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Devuelve un JWT válido para Supabase, o null si no hay sesión de
  /// Firebase (SupabaseClient.accessToken debe devolver null en ese caso
  /// para que las llamadas queden como rol `anon`).
  Future<String?> mintAccessToken() async {
    final cached = _cachedToken;
    final expiry = _cachedTokenExpiry;
    if (cached != null && expiry != null && DateTime.now().isBefore(expiry)) {
      return cached;
    }

    final idToken = await _getFirebaseIdToken();
    if (idToken == null || idToken.isEmpty) {
      _cachedToken = null;
      _cachedTokenExpiry = null;
      return null;
    }

    final response = await _httpClient.post(
      _endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Intercambio de token Supabase falló (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = decoded['access_token']?.toString();
    final expiresIn = decoded['expires_in'] is num
        ? (decoded['expires_in'] as num).toInt()
        : 3600;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Respuesta de intercambio de token sin access_token');
    }

    _cachedToken = accessToken;
    // Refrescar 60s antes de la expiración real para evitar carreras.
    _cachedTokenExpiry = DateTime.now().add(
      Duration(seconds: expiresIn - 60),
    );
    return accessToken;
  }
}
