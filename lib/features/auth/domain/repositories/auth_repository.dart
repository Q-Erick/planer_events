import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Emite el usuario cada vez que inicia o cierra sesión.
  Stream<UserEntity?> authStateChanges();

  /// Usuario actual (null si no hay sesión).
  UserEntity? get currentUser;

  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signInWithGoogle();

  Future<Either<Failure, UserEntity>> signInWithFacebook();

  /// Envía (o reenvía) el correo de verificación.
  Future<Either<Failure, Unit>> sendEmailVerification();

  /// Recarga el usuario para saber si ya verificó su correo.
  Future<Either<Failure, UserEntity>> reloadUser();

  Future<Either<Failure, Unit>> sendPasswordReset(String email);

  Future<Either<Failure, Unit>> signOut();
}
