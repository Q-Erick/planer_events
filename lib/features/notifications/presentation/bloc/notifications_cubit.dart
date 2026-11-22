import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.permissionGranted = false,
    this.topics = const {},
    this.foreground,
    this.opened,
    this.token,
    this.message,
  });

  final bool permissionGranted;
  final Set<String> topics;

  /// Última notificación recibida con la app abierta.
  final AppNotification? foreground;

  /// Última notificación tocada por el usuario.
  final AppNotification? opened;

  final String? token;
  final String? message;

  bool isSubscribed(String topic) => topics.contains(topic);

  NotificationsState copyWith({
    bool? permissionGranted,
    Set<String>? topics,
    AppNotification? foreground,
    AppNotification? opened,
    String? token,
    String? message,
  }) {
    return NotificationsState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      topics: topics ?? this.topics,
      foreground: foreground ?? this.foreground,
      opened: opened ?? this.opened,
      token: token ?? this.token,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    permissionGranted,
    topics,
    foreground,
    opened,
    token,
    message,
  ];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required RequestNotificationPermission requestPermission,
    required WatchForegroundNotifications watchForeground,
    required WatchOpenedNotifications watchOpened,
    required GetInitialNotification getInitial,
    required GetSubscribedTopics getTopics,
    required SubscribeToTopic subscribe,
    required UnsubscribeFromTopic unsubscribe,
    required GetDeviceToken getToken,
  }) : _requestPermission = requestPermission,
       _watchForeground = watchForeground,
       _watchOpened = watchOpened,
       _getInitial = getInitial,
       _getTopics = getTopics,
       _subscribe = subscribe,
       _unsubscribe = unsubscribe,
       _getToken = getToken,
       super(const NotificationsState());

  final RequestNotificationPermission _requestPermission;
  final WatchForegroundNotifications _watchForeground;
  final WatchOpenedNotifications _watchOpened;
  final GetInitialNotification _getInitial;
  final GetSubscribedTopics _getTopics;
  final SubscribeToTopic _subscribe;
  final UnsubscribeFromTopic _unsubscribe;
  final GetDeviceToken _getToken;

  final _subscriptions = <StreamSubscription<dynamic>>[];
  AppNotification? _initialMessage;

  /// Se llama una vez al arrancar la app (en main.dart).
  Future<void> initialize() async {
    final permission = await _requestPermission(const NoParams());
    emit(
      state.copyWith(
        permissionGranted: permission.getOrElse((_) => false),
        topics: _getTopics(),
      ),
    );

    // Listener global: primer plano y segundo plano
    _subscriptions.add(
      _watchForeground().listen((n) => emit(state.copyWith(foreground: n))),
    );
    _subscriptions.add(
      _watchOpened().listen((n) => emit(state.copyWith(opened: n))),
    );

    // App cerrada: se guarda y se procesa cuando la UI ya existe
    _initialMessage = await _getInitial();

    final token = await _getToken();
    if (token != null) emit(state.copyWith(token: token));
  }

  /// Se llama después del primer frame para abrir la notificación
  /// que despertó a la app estando cerrada.
  void handleInitialMessage() {
    final initial = _initialMessage;
    if (initial == null) return;
    _initialMessage = null;
    emit(state.copyWith(opened: initial));
  }

  Future<void> toggleTopic(String topic) async {
    final subscribed = state.isSubscribed(topic);
    final result = subscribed
        ? await _unsubscribe(topic)
        : await _subscribe(topic);

    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (_) => emit(
        state.copyWith(
          topics: subscribed
              ? (Set.of(state.topics)..remove(topic))
              : {...state.topics, topic},
          message: subscribed
              ? 'Ya no recibirás estos avisos.'
              : 'Recibirás estos avisos.',
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }
}
