import 'package:equatable/equatable.dart';

/// Error que viaja de la capa de datos hacia la UI.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

/// Error del servidor o de Firebase.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Ocurrió un error en el servidor.']);
}

/// Error de autenticación (credenciales, correo no verificado, etc.).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Error de autenticación.']);
}

/// Error al leer o guardar datos locales.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error al acceder a los datos locales.']);
}

/// Sin conexión a internet.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Revisa tu conexión a internet.']);
}

/// El usuario canceló la acción (por ejemplo, cerró el login de Google).
class CancelledFailure extends Failure {
  const CancelledFailure([super.message = 'Operación cancelada.']);
}
