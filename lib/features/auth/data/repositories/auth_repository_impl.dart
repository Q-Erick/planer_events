import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<UserEntity?> authStateChanges() => _remote.authStateChanges();

  @override
  UserEntity? get currentUser => _remote.currentUser;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() => _remote.signInWithEmail(email, password));

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _guard(() => _remote.registerWithEmail(name, email, password));

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() =>
      _guard(_remote.signInWithGoogle);

  @override
  Future<Either<Failure, UserEntity>> signInWithFacebook() =>
      _guard(_remote.signInWithFacebook);

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() =>
      _guardUnit(_remote.sendEmailVerification);

  @override
  Future<Either<Failure, UserEntity>> reloadUser() =>
      _guard(_remote.reloadUser);

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) =>
      _guardUnit(() => _remote.sendPasswordReset(email));

  @override
  Future<Either<Failure, Unit>> signOut() => _guardUnit(_remote.signOut);

  // ---------------- Helpers ----------------

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } on CancelledException {
      return left(const CancelledFailure());
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } catch (_) {
      return left(const ServerFailure());
    }
  }

  Future<Either<Failure, Unit>> _guardUnit(Future<void> Function() action) {
    return _guard(() async {
      await action();
      return unit;
    });
  }
}
