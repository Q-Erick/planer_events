import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/guest_entity.dart';

abstract class GuestRepository {
  Stream<Either<Failure, List<GuestEntity>>> watchGuests(String eventId);

  /// Crea el invitado y devuelve su id.
  Future<Either<Failure, String>> addGuest(GuestEntity guest);

  Future<Either<Failure, Unit>> updateGuest(GuestEntity guest);

  Future<Either<Failure, Unit>> deleteGuest(String eventId, String guestId);
}
