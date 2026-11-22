import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dataSource);

  final NotificationDataSource _dataSource;

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      return right(await _dataSource.requestPermission());
    } catch (_) {
      return left(const ServerFailure('No se pudo pedir el permiso.'));
    }
  }

  @override
  Stream<AppNotification> onForegroundMessage() =>
      _dataSource.onForegroundMessage();

  @override
  Stream<AppNotification> onMessageOpened() => _dataSource.onMessageOpened();

  @override
  Future<AppNotification?> getInitialMessage() async {
    try {
      return await _dataSource.getInitialMessage();
    } catch (_) {
      return null;
    }
  }

  @override
  Set<String> subscribedTopics() => _dataSource.subscribedTopics();

  @override
  Future<Either<Failure, Unit>> subscribe(String topic) async {
    try {
      await _dataSource.subscribe(topic);
      return right(unit);
    } catch (_) {
      return left(
        const NetworkFailure('No se pudo activar. Revisa tu conexión.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> unsubscribe(String topic) async {
    try {
      await _dataSource.unsubscribe(topic);
      return right(unit);
    } catch (_) {
      return left(
        const NetworkFailure('No se pudo desactivar. Revisa tu conexión.'),
      );
    }
  }

  @override
  Future<String?> deviceToken() async {
    try {
      return await _dataSource.deviceToken();
    } catch (_) {
      return null;
    }
  }
}
