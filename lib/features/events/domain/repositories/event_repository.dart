import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/event_entity.dart';

abstract class EventRepository {
  /// Eventos del anfitrión, en tiempo real.
  Stream<Either<Failure, List<EventEntity>>> watchHostEvents(String hostId);

  /// Un evento, en tiempo real.
  Stream<Either<Failure, EventEntity>> watchEvent(String eventId);

  /// Crea el evento y devuelve su id.
  Future<Either<Failure, String>> createEvent(EventEntity event);

  Future<Either<Failure, Unit>> updateEvent(EventEntity event);

  Future<Either<Failure, Unit>> deleteEvent(String eventId);
}
