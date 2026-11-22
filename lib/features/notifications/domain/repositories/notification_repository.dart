import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, bool>> requestPermission();

  /// Notificaciones recibidas con la app abierta.
  Stream<AppNotification> onForegroundMessage();

  /// Notificaciones tocadas con la app en segundo plano.
  Stream<AppNotification> onMessageOpened();

  /// Notificación que abrió la app estando cerrada.
  Future<AppNotification?> getInitialMessage();

  Set<String> subscribedTopics();

  Future<Either<Failure, Unit>> subscribe(String topic);

  Future<Either<Failure, Unit>> unsubscribe(String topic);

  Future<String?> deviceToken();
}
