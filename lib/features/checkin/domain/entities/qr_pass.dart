import 'package:equatable/equatable.dart';

/// Pase leído de un código QR con el formato `planer:{eventId}:{guestId}`.
class QrPass extends Equatable {
  const QrPass({required this.eventId, required this.guestId});

  final String eventId;
  final String guestId;

  /// Devuelve null si el texto no es un pase válido.
  static QrPass? parse(String? raw) {
    if (raw == null) return null;
    final parts = raw.trim().split(':');
    if (parts.length != 3 || parts[0] != 'planer') return null;
    if (parts[1].isEmpty || parts[2].isEmpty) return null;
    return QrPass(eventId: parts[1], guestId: parts[2]);
  }

  @override
  List<Object> get props => [eventId, guestId];
}
