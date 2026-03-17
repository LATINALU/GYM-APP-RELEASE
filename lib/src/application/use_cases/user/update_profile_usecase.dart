import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/auth_repository_port.dart';

class UpdateProfileUseCase {
  final AuthRepositoryPort _repository;

  UpdateProfileUseCase(this._repository);

  FutureVoidResult execute(User user) {
    return _repository.updateProfile(user);
  }
}
