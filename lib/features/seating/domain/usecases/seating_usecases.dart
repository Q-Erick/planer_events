import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../guests/domain/entities/guest_entity.dart';
import '../../../guests/domain/usecases/guest_usecases.dart';
import '../entities/table_entity.dart';
import '../repositories/seating_repository.dart';
import '../services/seating_planner.dart';

// ---------------- Parámetros ----------------

class SeatsPerTableParams extends Equatable {
  const SeatsPerTableParams({required this.eventId, required this.seats});
  final String eventId;
  final int seats;

  @override
  List<Object> get props => [eventId, seats];
}

class AddTableParams extends Equatable {
  const AddTableParams({
    required this.eventId,
    required this.shape,
    required this.seats,
    required this.existingTables,
  });
  final String eventId;
  final TableShape shape;
  final int seats;
  final List<TableEntity> existingTables;

  @override
  List<Object> get props => [eventId, shape, seats, existingTables];
}

class MoveTableParams extends Equatable {
  const MoveTableParams({
    required this.table,
    required this.x,
    required this.y,
  });
  final TableEntity table;
  final double x;
  final double y;

  @override
  List<Object> get props => [table, x, y];
}

class ChangeSeatsParams extends Equatable {
  const ChangeSeatsParams({required this.table, required this.seats});
  final TableEntity table;
  final int seats;

  @override
  List<Object> get props => [table, seats];
}

class ChangeShapeParams extends Equatable {
  const ChangeShapeParams({required this.table, required this.shape});
  final TableEntity table;
  final TableShape shape;

  @override
  List<Object> get props => [table, shape];
}

class AssignGuestParams extends Equatable {
  const AssignGuestParams({
    required this.table,
    required this.seat,
    required this.guest,
    required this.allTables,
    required this.together,
  });

  final TableEntity table;
  final int seat;
  final GuestEntity guest;
  final List<TableEntity> allTables;

  /// true = sentar todo el grupo junto; false = solo esta silla.
  final bool together;

  @override
  List<Object> get props => [table, seat, guest, allTables, together];
}

class SeatParams extends Equatable {
  const SeatParams({required this.table, required this.seat});
  final TableEntity table;
  final int seat;

  @override
  List<Object> get props => [table, seat];
}

// ---------------- Casos de uso ----------------

class WatchTables implements StreamUseCase<List<TableEntity>, String> {
  const WatchTables(this._repository);
  final SeatingRepository _repository;

  @override
  Stream<Either<Failure, List<TableEntity>>> call(String eventId) =>
      _repository.watchTables(eventId);
}

class WatchSeatsPerTable implements StreamUseCase<int, String> {
  const WatchSeatsPerTable(this._repository);
  final SeatingRepository _repository;

  @override
  Stream<Either<Failure, int>> call(String eventId) =>
      _repository.watchSeatsPerTable(eventId);
}

class SetSeatsPerTable implements UseCase<Unit, SeatsPerTableParams> {
  const SetSeatsPerTable(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SeatsPerTableParams p) async {
    if (p.seats < 1 || p.seats > kMaxSeatsPerTable) {
      return left(
        const ServerFailure(
          'Las sillas deben estar entre 1 y $kMaxSeatsPerTable.',
        ),
      );
    }
    return _repository.setSeatsPerTable(p.eventId, p.seats);
  }
}

class AddTable implements UseCase<Unit, AddTableParams> {
  const AddTable(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AddTableParams p) {
    // Siguiente número disponible
    final nextNumber =
        p.existingTables.fold<int>(
          0,
          (max, t) => t.number > max ? t.number : max,
        ) +
        1;
    final position = SeatingPlanner.nextPosition(p.existingTables.length);

    return _repository.addTable(
      TableEntity(
        eventId: p.eventId,
        number: nextNumber,
        shape: p.shape,
        seats: p.seats,
        x: position.x,
        y: position.y,
      ),
    );
  }
}

class MoveTable implements UseCase<Unit, MoveTableParams> {
  const MoveTable(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MoveTableParams p) =>
      _repository.moveTable(
        p.table.eventId,
        p.table.id,
        p.x.clamp(0.0, 1.0),
        p.y.clamp(0.0, 1.0),
      );
}

class ChangeTableSeats implements UseCase<Unit, ChangeSeatsParams> {
  const ChangeTableSeats(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ChangeSeatsParams p) async {
    if (p.seats < 1 || p.seats > kMaxSeatsPerTable) {
      return left(
        const ServerFailure(
          'Una mesa puede tener de 1 a $kMaxSeatsPerTable sillas.',
        ),
      );
    }
    if (!SeatingPlanner.canReduceTo(p.table, p.seats)) {
      return left(
        const ServerFailure(
          'Esa silla está ocupada. Libérala antes de quitarla.',
        ),
      );
    }
    return _repository.updateTable(p.table.copyWith(seats: p.seats));
  }
}

class ChangeTableShape implements UseCase<Unit, ChangeShapeParams> {
  const ChangeTableShape(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ChangeShapeParams p) =>
      _repository.updateTable(p.table.copyWith(shape: p.shape));
}

class DeleteTable implements UseCase<Unit, TableEntity> {
  const DeleteTable(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(TableEntity table) =>
      _repository.deleteTable(table.eventId, table.id);
}

class AssignGuest implements UseCase<AssignResult, AssignGuestParams> {
  const AssignGuest(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, AssignResult>> call(AssignGuestParams p) async {
    if (p.table.isSeatTaken(p.seat)) {
      return left(const ServerFailure('Esa silla ya está ocupada.'));
    }

    final remaining = SeatingPlanner.remaining(p.guest, p.allTables);
    if (remaining == 0) {
      return left(
        ServerFailure('${p.guest.name} ya tiene todos sus lugares asignados.'),
      );
    }

    final wanted = p.together ? remaining : 1;
    final filled = SeatingPlanner.fill(
      table: p.table,
      startSeat: p.seat,
      guestId: p.guest.id,
      count: wanted,
    );

    final saved = await _repository.saveAssignments(p.table.eventId, {
      p.table.id: filled.assignments,
    });

    return saved.map(
      (_) => AssignResult(
        assigned: filled.assigned,
        pending: remaining - filled.assigned,
      ),
    );
  }
}

class ReleaseSeat implements UseCase<Unit, SeatParams> {
  const ReleaseSeat(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SeatParams p) =>
      _repository.saveAssignments(p.table.eventId, {
        p.table.id: SeatingPlanner.releaseSeat(p.table, p.seat),
      });
}

class ReleaseGuestSeats implements UseCase<Unit, GuestRef> {
  const ReleaseGuestSeats(this._repository);
  final SeatingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(GuestRef ref) =>
      _repository.releaseGuestEverywhere(ref.eventId, ref.guestId);
}
