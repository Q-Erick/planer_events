import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

/// Reglas que debe cumplir un evento antes de guardarse.
Failure? _validate(EventEntity event) {
  if (event.name.trim().isEmpty) {
    return const ServerFailure('El evento necesita un nombre.');
  }
  if (event.maxGuests <= 0) {
    return const ServerFailure('El número de invitados debe ser mayor a 0.');
  }
  if (!event.hasLocation) {
    return const ServerFailure('Selecciona la ubicación en el mapa.');
  }
  return null;
}

class WatchHostEvents implements StreamUseCase<List<EventEntity>, String> {
  const WatchHostEvents(this._repository);
  final EventRepository _repository;

  @override
  Stream<Either<Failure, List<EventEntity>>> call(String hostId) =>
      _repository.watchHostEvents(hostId);
}

class WatchEvent implements StreamUseCase<EventEntity, String> {
  const WatchEvent(this._repository);
  final EventRepository _repository;

  @override
  Stream<Either<Failure, EventEntity>> call(String eventId) =>
      _repository.watchEvent(eventId);
}

class CreateEvent implements UseCase<String, EventEntity> {
  const CreateEvent(this._repository);
  final EventRepository _repository;

  @override
  Future<Either<Failure, String>> call(EventEntity event) async {
    final error = _validate(event);
    if (error != null) return left(error);
    return _repository.createEvent(event);
  }
}

class UpdateEvent implements UseCase<Unit, EventEntity> {
  const UpdateEvent(this._repository);
  final EventRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EventEntity event) async {
    final error = _validate(event);
    if (error != null) return left(error);
    return _repository.updateEvent(event);
  }
}

class DeleteEvent implements UseCase<Unit, String> {
  const DeleteEvent(this._repository);
  final EventRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String eventId) =>
      _repository.deleteEvent(eventId);
}
