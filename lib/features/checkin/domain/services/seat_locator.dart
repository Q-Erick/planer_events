import 'package:equatable/equatable.dart';

import '../../../seating/domain/entities/table_entity.dart';

/// Sillas de un invitado en una mesa (numeradas desde 1).
class SeatLocation extends Equatable {
  const SeatLocation({required this.tableNumber, required this.seats});

  final int tableNumber;
  final List<int> seats;

  @override
  List<Object> get props => [tableNumber, seats];
}

class SeatLocator {
  SeatLocator._();

  /// Busca en qué mesas y sillas está sentado un invitado.
  static List<SeatLocation> locate(List<TableEntity> tables, String guestId) {
    final result = <SeatLocation>[];
    for (final table in tables) {
      final seats =
          table.assignments.entries
              .where((e) => e.value == guestId)
              .map((e) => e.key + 1)
              .toList()
            ..sort();
      if (seats.isNotEmpty) {
        result.add(SeatLocation(tableNumber: table.number, seats: seats));
      }
    }
    result.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
    return result;
  }
}
