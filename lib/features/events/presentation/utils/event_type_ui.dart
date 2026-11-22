import 'package:material_ui/material_ui.dart';

import '../../domain/entities/event_entity.dart';

extension EventTypeUi on EventType {
  String get label => switch (this) {
    EventType.wedding => 'Boda',
    EventType.xv => 'XV años',
    EventType.graduation => 'Graduación',
    EventType.birthday => 'Cumpleaños',
    EventType.other => 'Otro',
  };

  IconData get icon => switch (this) {
    EventType.wedding => Icons.favorite_outline,
    EventType.xv => Icons.auto_awesome_outlined,
    EventType.graduation => Icons.school_outlined,
    EventType.birthday => Icons.cake_outlined,
    EventType.other => Icons.celebration_outlined,
  };
}

extension EventCountdown on DateTime {
  /// Texto corto: "Hoy", "Mañana", "En 12 días" o "Finalizado".
  String get countdownLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(year, month, this.day);
    final days = day.difference(today).inDays;

    if (days == 0) return 'Hoy';
    if (days == 1) return 'Mañana';
    if (days > 1) return 'En $days días';
    return 'Finalizado';
  }
}
