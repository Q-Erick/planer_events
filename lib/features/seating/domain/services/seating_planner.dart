import 'package:equatable/equatable.dart';

import '../../../guests/domain/entities/guest_entity.dart';
import '../entities/table_entity.dart';

/// Máximo de sillas por mesa.
const kMaxSeatsPerTable = 30;

/// Resultado de sentar a un invitado.
class AssignResult extends Equatable {
  const AssignResult({required this.assigned, required this.pending});

  /// Sillas que se ocuparon.
  final int assigned;

  /// Lugares del grupo que quedaron sin silla.
  final int pending;

  @override
  List<Object> get props => [assigned, pending];
}

/// Reglas del plano de mesas. Son funciones puras: reciben datos
/// y devuelven datos, sin tocar la base de datos.
class SeatingPlanner {
  SeatingPlanner._();

  /// Sillas que ocupa un invitado en todo el salón.
  static int seatedCount(List<TableEntity> tables, String guestId) =>
      tables.fold(0, (sum, t) => sum + t.seatsOf(guestId));

  /// Lugares del invitado que todavía no tienen silla.
  static int remaining(GuestEntity guest, List<TableEntity> tables) {
    final left = guest.passes - seatedCount(tables, guest.id);
    return left < 0 ? 0 : left;
  }

  /// Sienta hasta [count] lugares empezando en [startSeat] y avanzando
  /// alrededor de la mesa, saltando las sillas ocupadas.
  /// Las sillas están numeradas en orden, así el grupo queda junto.
  static ({Map<int, String> assignments, int assigned}) fill({
    required TableEntity table,
    required int startSeat,
    required String guestId,
    required int count,
  }) {
    final result = Map<int, String>.from(table.assignments);
    var assigned = 0;

    for (var k = 0; k < table.seats && assigned < count; k++) {
      final seat = (startSeat + k) % table.seats;
      if (!result.containsKey(seat)) {
        result[seat] = guestId;
        assigned++;
      }
    }
    return (assignments: result, assigned: assigned);
  }

  /// Libera una silla.
  static Map<int, String> releaseSeat(TableEntity table, int seat) =>
      Map<int, String>.from(table.assignments)..remove(seat);

  /// Solo se pueden quitar sillas si las que se eliminan están libres.
  static bool canReduceTo(TableEntity table, int newSeats) =>
      table.assignments.keys.every((seat) => seat < newSeats);

  /// Posición inicial para una mesa nueva: las va acomodando en
  /// una cuadrícula para que no queden encimadas.
  static ({double x, double y}) nextPosition(int existingTables) {
    final col = existingTables % 5;
    final row = (existingTables ~/ 5) % 4;
    return (x: 0.12 + col * 0.19, y: 0.18 + row * 0.21);
  }
}
