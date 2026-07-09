import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_app/core/errors/failures.dart';
import 'package:gym_app/src/application/use_cases/use_cases.dart';
import 'package:gym_app/src/domain/entities/entities.dart';
import 'package:gym_app/src/domain/ports/output/auth_repository_port.dart';

class _MockAuthRepository extends Mock implements AuthRepositoryPort {}

class _MockUser extends Mock implements User {}

class _FakeAuthCredentials extends Fake implements AuthCredentials {}

void main() {
  late _MockAuthRepository authRepository;
  late LoginUseCase useCase;

  setUpAll(() {
    registerFallbackValue(_FakeAuthCredentials());
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    useCase = LoginUseCase(authRepository: authRepository);
  });

  test('rechaza email inválido sin tocar el repositorio', () async {
    final result = await useCase.execute(
      const LoginCommand(email: 'no-es-email', password: '123456'),
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('debería fallar'),
    );
    verifyNever(() => authRepository.login(any()));
  });

  test('rechaza contraseña vacía', () async {
    final result = await useCase.execute(
      const LoginCommand(email: 'user@gym.com', password: ''),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => authRepository.login(any()));
  });

  test('propaga el failure del repositorio', () async {
    when(() => authRepository.login(any())).thenAnswer(
      (_) async => left(const AuthFailure(message: 'Credenciales inválidas')),
    );

    final result = await useCase.execute(
      const LoginCommand(email: 'user@gym.com', password: 'mala'),
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<AuthFailure>()),
      (_) => fail('debería fallar'),
    );
  });

  test('devuelve LoginResult con user y token en éxito', () async {
    final user = _MockUser();
    when(() => authRepository.login(any())).thenAnswer(
      (_) async => right(AuthResult(user: user, token: 'jwt-token')),
    );

    final result = await useCase.execute(
      const LoginCommand(email: 'user@gym.com', password: 'correcta'),
    );

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('debería tener éxito'),
      (loginResult) {
        expect(loginResult.user, same(user));
        expect(loginResult.token, 'jwt-token');
      },
    );
  });
}
