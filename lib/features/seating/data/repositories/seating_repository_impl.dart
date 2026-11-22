import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either_stream.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/repositories/seating_repository.dart';
import '../datasources/seating_remote_datasource.dart';
import '../models/table_model.dart';

class SeatingRepositoryImpl implements SeatingRepository {
  SeatingRepositoryImpl(this._remote);

  final SeatingRemoteDataSource _remote;

  @override
  Stream<Either<Failure, List<TableEntity>>> watchTables(String eventId) =>
      _remote.watchTables(eventId).toEither();

  @override
  Stream<Either<Failure, int>> watchSeatsPerTable(String eventId) =>
      _remote.watchSeatsPerTable(eventId).toEither();

  @override
  Future<Either<Failure, Unit>> setSeatsPerTable(String eventId, int seats) =>
      _guard(() => _remote.setSeatsPerTable(eventId, seats));

  @override
  Future<Either<Failure, Unit>> addTable(TableEntity table) =>
      _guard(() => _remote.addTable(TableModel.fromEntity(table)));

  @override
  Future<Either<Failure, Unit>> updateTable(TableEntity table) =>
      _guard(() => _remote.updateTable(TableModel.fromEntity(table)));

  @override
  Future<Either<Failure, Unit>> moveTable(
    String eventId,
    String tableId,
    double x,
    double y,
  ) => _guard(() => _remote.moveTable(eventId, tableId, x, y));

  @override
  Future<Either<Failure, Unit>> deleteTable(String eventId, String tableId) =>
      _guard(() => _remote.deleteTable(eventId, tableId));

  @override
  Future<Either<Failure, Unit>> saveAssignments(
    String eventId,
    Map<String, Map<int, String>> assignmentsByTable,
  ) => _guard(() => _remote.saveAssignments(eventId, assignmentsByTable));

  @override
  Future<Either<Failure, Unit>> releaseGuestEverywhere(
    String eventId,
    String guestId,
  ) => _guard(() => _remote.releaseGuestEverywhere(eventId, guestId));

  Future<Either<Failure, Unit>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return right(unit);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } catch (_) {
      return left(const ServerFailure());
    }
  }
}
