class ServerException implements Exception {
  const ServerException([this.message = 'Error del servidor.']);
  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Error de autenticación.']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Error de caché.']);
  final String message;
}

class CancelledException implements Exception {
  const CancelledException();
}
