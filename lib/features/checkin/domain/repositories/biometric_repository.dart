import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class BiometricRepository {
  /// Pide huella, rostro o el bloqueo del dispositivo.
  Future<Either<Failure, bool>> authenticate(String reason);
}
