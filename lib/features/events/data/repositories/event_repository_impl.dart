import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either_stream.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._remote);

  final EventRemoteDataSource _remote;

  @override
  Stream<Either<Failure, List<EventEntity>>> watchHostEvents(String hostId) =>
      _remote.watchHostEvents(hostId).toEither();

  @override
  Stream<Either<Failure, EventEntity>> watchEvent(String eventId) =>
      _remote.watchEvent(eventId).toEither();

  @override
  Future<Either<Failure, String>> createEvent(EventEntity event) =>
      _guard(() => _remote.createEvent(EventModel.fromEntity(event)));

  @override
  Future<Either<Failure, Unit>> updateEvent(EventEntity event) =>
      _guard(() async {
        await _remote.updateEvent(EventModel.fromEntity(event));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteEvent(String eventId) => _guard(() async {
    await _remote.deleteEvent(eventId);
    return unit;
  });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } catch (_) {
      return left(const ServerFailure());
    }
  }
}
