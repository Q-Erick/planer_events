import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class OnboardingRepository {
  /// Indica si el usuario ya vio la introducción.
  bool isCompleted();

  /// Marca la introducción como vista.
  Future<Either<Failure, Unit>> complete();
}
