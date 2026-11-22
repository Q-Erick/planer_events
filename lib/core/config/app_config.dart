class AppConfig {
  AppConfig._();

  /// Clave PUBLICABLE de Stripe (modo prueba). Nunca la secreta.
  static const stripePublishableKey =
      'pk_test_51RJ3CICsf9ywDtAU3Ylrd5FVrrcWUaILoSe97t8YkxMS7fx79jMfYJjJzY2Yrbtx10U188aM52zniz2JtoiDSm0h00ceQHB7CT';

  /// Servidor de pagos en el droplet.
  static const apiBaseUrl = 'https://planerevents.duckdns.org';
}
