import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// ---------------- Parámetros ----------------

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name;
  final String email;
  final String password;

  @override
  List<Object> get props => [name, email, password];
}

// ---------------- Casos de uso ----------------

class GetAuthStateChanges {
  const GetAuthStateChanges(this._repository);
  final AuthRepository _repository;

  Stream<UserEntity?> call() => _repository.authStateChanges();
}

class GetCurrentUser {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  UserEntity? call() => _repository.currentUser;
}

class SignInWithEmail implements UseCase<UserEntity, SignInParams> {
  const SignInWithEmail(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) => _repository
      .signInWithEmail(email: params.email.trim(), password: params.password);
}

class RegisterWithEmail implements UseCase<UserEntity, RegisterParams> {
  const RegisterWithEmail(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) =>
      _repository.registerWithEmail(
        name: params.name.trim(),
        email: params.email.trim(),
        password: params.password,
      );
}

class SignInWithGoogle implements UseCase<UserEntity, NoParams> {
  const SignInWithGoogle(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.signInWithGoogle();
}

class SignInWithFacebook implements UseCase<UserEntity, NoParams> {
  const SignInWithFacebook(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.signInWithFacebook();
}

class SendEmailVerification implements UseCase<Unit, NoParams> {
  const SendEmailVerification(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.sendEmailVerification();
}

class ReloadUser implements UseCase<UserEntity, NoParams> {
  const ReloadUser(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.reloadUser();
}

class SendPasswordReset implements UseCase<Unit, String> {
  const SendPasswordReset(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repository.sendPasswordReset(email.trim());
}

class SignOut implements UseCase<Unit, NoParams> {
  const SignOut(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.signOut();
}

class SignInAnonymously implements UseCase<UserEntity, NoParams> {
  const SignInAnonymously(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.signInAnonymously();
}
