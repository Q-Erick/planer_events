import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/biometric_repository.dart';

class AuthenticateReception implements UseCase<bool, String> {
  const AuthenticateReception(this._repository);
  final BiometricRepository _repository;

  @override
  Future<Either<Failure, bool>> call(String reason) =>
      _repository.authenticate(reason);
}
