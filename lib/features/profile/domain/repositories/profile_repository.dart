import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class ProfileRepository {
  /// Sube la foto y devuelve su URL.
  Future<Either<Failure, String>> updatePhoto(Uint8List bytes);

  Future<Either<Failure, Unit>> updateDisplayName(String name);
}
