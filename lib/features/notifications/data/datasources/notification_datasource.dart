import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_notification.dart';

abstract class NotificationDataSource {
  Future<bool> requestPermission();
  Stream<AppNotification> onForegroundMessage();
  Stream<AppNotification> onMessageOpened();
  Future<AppNotification?> getInitialMessage();
  Set<String> subscribedTopics();
  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);
  Future<String?> deviceToken();
}

class NotificationDataSourceImpl implements NotificationDataSource {
  NotificationDataSourceImpl(this._messaging, this._prefs);

  final FirebaseMessaging _messaging;
  final SharedPreferences _prefs;
  static const _topicsKey = 'subscribed_topics';

  static AppNotification _fromRemote(RemoteMessage m) {
    return AppNotification(
      id: m.messageId ?? '${DateTime.now().microsecondsSinceEpoch}',
      title:
          m.notification?.title ??
          m.data['title'] as String? ??
          'Planer Events',
      body: m.notification?.body ?? m.data['body'] as String? ?? '',
      route: m.data['route'] as String?,
    );
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Stream<AppNotification> onForegroundMessage() =>
      FirebaseMessaging.onMessage.map(_fromRemote);

  @override
  Stream<AppNotification> onMessageOpened() =>
      FirebaseMessaging.onMessageOpenedApp.map(_fromRemote);

  @override
  Future<AppNotification?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _fromRemote(message);
  }

  @override
  Set<String> subscribedTopics() =>
      (_prefs.getStringList(_topicsKey) ?? const []).toSet();

  Future<void> _saveTopics(Set<String> topics) =>
      _prefs.setStringList(_topicsKey, topics.toList());

  @override
  Future<void> subscribe(String topic) async {
    await _messaging.subscribeToTopic(topic);
    await _saveTopics({...subscribedTopics(), topic});
  }

  @override
  Future<void> unsubscribe(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    await _saveTopics(subscribedTopics()..remove(topic));
  }

  @override
  Future<String?> deviceToken() => _messaging.getToken();
}
