import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/table_entity.dart';

abstract class SeatingRepository {
  Stream<Either<Failure, List<TableEntity>>> watchTables(String eventId);

  /// Número de sillas global (para mesas nuevas).
  Stream<Either<Failure, int>> watchSeatsPerTable(String eventId);

  Future<Either<Failure, Unit>> setSeatsPerTable(String eventId, int seats);

  Future<Either<Failure, Unit>> addTable(TableEntity table);

  /// Actualiza forma y número de sillas.
  Future<Either<Failure, Unit>> updateTable(TableEntity table);

  Future<Either<Failure, Unit>> moveTable(
    String eventId,
    String tableId,
    double x,
    double y,
  );

  Future<Either<Failure, Unit>> deleteTable(String eventId, String tableId);

  /// Guarda las asignaciones de una o varias mesas a la vez.
  Future<Either<Failure, Unit>> saveAssignments(
    String eventId,
    Map<String, Map<int, String>> assignmentsByTable,
  );

  /// Quita a un invitado de todas las mesas.
  Future<Either<Failure, Unit>> releaseGuestEverywhere(
    String eventId,
    String guestId,
  );
}
