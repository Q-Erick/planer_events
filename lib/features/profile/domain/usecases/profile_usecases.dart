import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class UpdatePhotoParams extends Equatable {
  const UpdatePhotoParams({required this.user, required this.bytes});
  final UserEntity user;
  final Uint8List bytes;

  @override
  List<Object> get props => [user, bytes];
}

class UpdateProfilePhoto implements UseCase<String, UpdatePhotoParams> {
  const UpdateProfilePhoto(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, String>> call(UpdatePhotoParams params) async {
    // Regla de negocio: solo cuentas registradas con correo.
    if (!params.user.canEditPhoto) {
      return left(
        const AuthFailure(
          'Solo las cuentas registradas con correo pueden cambiar su foto.',
        ),
      );
    }
    return _repository.updatePhoto(params.bytes);
  }
}

class UpdateDisplayName implements UseCase<Unit, String> {
  const UpdateDisplayName(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return left(const AuthFailure('El nombre no puede estar vacío.'));
    }
    return _repository.updateDisplayName(trimmed);
  }
}
