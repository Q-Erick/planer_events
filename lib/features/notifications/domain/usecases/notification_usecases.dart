import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class RequestNotificationPermission implements UseCase<bool, NoParams> {
  const RequestNotificationPermission(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      _repository.requestPermission();
}

class WatchForegroundNotifications {
  const WatchForegroundNotifications(this._repository);
  final NotificationRepository _repository;

  Stream<AppNotification> call() => _repository.onForegroundMessage();
}

class WatchOpenedNotifications {
  const WatchOpenedNotifications(this._repository);
  final NotificationRepository _repository;

  Stream<AppNotification> call() => _repository.onMessageOpened();
}

class GetInitialNotification {
  const GetInitialNotification(this._repository);
  final NotificationRepository _repository;

  Future<AppNotification?> call() => _repository.getInitialMessage();
}

class GetSubscribedTopics {
  const GetSubscribedTopics(this._repository);
  final NotificationRepository _repository;

  Set<String> call() => _repository.subscribedTopics();
}

class SubscribeToTopic implements UseCase<Unit, String> {
  const SubscribeToTopic(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String topic) =>
      _repository.subscribe(topic);
}

class UnsubscribeFromTopic implements UseCase<Unit, String> {
  const UnsubscribeFromTopic(this._repository);
  final NotificationRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String topic) =>
      _repository.unsubscribe(topic);
}

class GetDeviceToken {
  const GetDeviceToken(this._repository);
  final NotificationRepository _repository;

  Future<String?> call() => _repository.deviceToken();
}
