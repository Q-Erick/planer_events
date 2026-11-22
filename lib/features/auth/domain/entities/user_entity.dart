import 'package:equatable/equatable.dart';

/// Con qué proveedor inició sesión el usuario.
enum AuthProviderType { email, google, facebook }

class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.provider,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final AuthProviderType provider;

  /// Regla de negocio: solo las cuentas de correo pueden cambiar su foto.
  /// Las de Google o Facebook usan la foto de su proveedor.
  bool get canEditPhoto => provider == AuthProviderType.email;

  /// Google y Facebook ya verifican el correo por su cuenta.
  bool get needsEmailVerification =>
      provider == AuthProviderType.email && !emailVerified;

  /// Nombre para mostrar; si no tiene, usa la parte inicial del correo.
  String get name => (displayName != null && displayName!.isNotEmpty)
      ? displayName!
      : email.split('@').first;

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    emailVerified,
    provider,
  ];
}
