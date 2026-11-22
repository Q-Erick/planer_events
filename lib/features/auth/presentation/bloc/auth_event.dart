part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Empieza a escuchar los cambios de sesión de Firebase.
final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

/// Actualiza el usuario a mano (por ejemplo, al verificar el correo).
final class AuthUserRefreshed extends AuthEvent {
  const AuthUserRefreshed(this.user);
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
