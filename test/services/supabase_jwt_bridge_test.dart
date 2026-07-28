import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/infrastructure/services/supabase_jwt_bridge.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient client;
  final endpoint = Uri.parse('http://localhost:8000/functions/v1/firebase-token-exchange');

  setUpAll(() {
    registerFallbackValue(endpoint);
  });

  setUp(() {
    client = _MockHttpClient();
  });

  test('sin sesión de Firebase devuelve null sin llamar al endpoint', () async {
    final bridge = SupabaseJwtBridge(
      endpoint: endpoint,
      httpClient: client,
      getFirebaseIdToken: () async => null,
    );

    final token = await bridge.mintAccessToken();

    expect(token, isNull);
    verifyNever(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
  });

  test('con sesión válida, intercambia el ID token por un access_token del endpoint', () async {
    when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => http.Response(
              '{"access_token": "supabase-jwt", "expires_in": 3600}',
              200,
            ));

    final bridge = SupabaseJwtBridge(
      endpoint: endpoint,
      httpClient: client,
      getFirebaseIdToken: () async => 'firebase-id-token',
    );

    final token = await bridge.mintAccessToken();

    expect(token, 'supabase-jwt');
    final captured = verify(() => client.post(
          endpoint,
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;
    expect(captured.single, contains('firebase-id-token'));
  });

  test('cachea el token y no vuelve a llamar al endpoint antes de expirar', () async {
    when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => http.Response(
              '{"access_token": "supabase-jwt", "expires_in": 3600}',
              200,
            ));

    final bridge = SupabaseJwtBridge(
      endpoint: endpoint,
      httpClient: client,
      getFirebaseIdToken: () async => 'firebase-id-token',
    );

    await bridge.mintAccessToken();
    await bridge.mintAccessToken();

    verify(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .called(1);
  });

  test('respuesta con error del endpoint lanza excepción', () async {
    when(() => client.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => http.Response('Invalid Firebase ID token', 401));

    final bridge = SupabaseJwtBridge(
      endpoint: endpoint,
      httpClient: client,
      getFirebaseIdToken: () async => 'firebase-id-token',
    );

    expect(bridge.mintAccessToken(), throwsException);
  });
}
