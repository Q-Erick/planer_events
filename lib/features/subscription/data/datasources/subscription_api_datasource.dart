import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';

abstract class SubscriptionApiDataSource {
  Future<void> subscribe({
    required String planId,
    required String paymentMethodId,
  });
  Future<void> cancel();
}

class SubscriptionApiDataSourceImpl implements SubscriptionApiDataSource {
  SubscriptionApiDataSourceImpl(this._client, this._auth);

  final http.Client _client;
  final FirebaseAuth _auth;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('No hay sesión activa.');
    final token = await user.getIdToken();

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const ServerException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    Map<String, dynamic> data = {};
    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // La respuesta no era JSON
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw ServerException(
      data['error'] as String? ??
          'Error del servidor (${response.statusCode}).',
    );
  }

  @override
  Future<void> subscribe({
    required String planId,
    required String paymentMethodId,
  }) => _post('/subscriptions', {
    'planId': planId,
    'paymentMethodId': paymentMethodId,
  });

  @override
  Future<void> cancel() => _post('/subscriptions/cancel', {});
}
