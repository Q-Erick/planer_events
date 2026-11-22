import 'package:local_auth/local_auth.dart';

import '../../../../core/errors/exceptions.dart';

abstract class BiometricDataSource {
  Future<bool> authenticate(String reason);
}

class BiometricDataSourceImpl implements BiometricDataSource {
  BiometricDataSourceImpl(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate(String reason) async {
    // Si el celular no tiene ningún bloqueo configurado,
    // no hay forma de verificar: se permite el acceso.
    final supported = await _auth.isDeviceSupported();
    if (!supported) return true;

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // false = acepta huella, rostro o PIN/patrón del celular
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      throw AuthException(
        'No se pudo verificar tu identidad (${e.code.name}).',
      );
    }
  }
}
