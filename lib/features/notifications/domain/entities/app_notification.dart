import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.route,
  });

  final String id;
  final String title;
  final String body;

  /// Pantalla a abrir al tocarla (dato personalizado "route").
  final String? route;

  @override
  List<Object?> get props => [id, title, body, route];
}

/// Tema (topic) de FCM al que el usuario se puede suscribir.
class NotificationTopic {
  const NotificationTopic(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;
}

const kGeneralTopics = [
  NotificationTopic(
    'novedades',
    'Novedades',
    'Nuevas funciones y promociones de Planer Events.',
  ),
  NotificationTopic(
    'consejos',
    'Consejos',
    'Ideas y recordatorios para organizar tu evento.',
  ),
  NotificationTopic('planes', 'Planes y pagos', 'Avisos sobre tu suscripción.'),
];

/// Tema de un evento específico.
String eventTopic(String eventId) => 'evento_$eventId';
