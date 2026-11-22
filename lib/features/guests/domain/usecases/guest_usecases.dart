import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/guest_entity.dart';
import '../repositories/guest_repository.dart';

/// Máximo de lugares por pase.
const kMaxPassesPerGuest = 30;

Failure? _validate(GuestEntity guest) {
  if (guest.name.trim().isEmpty) {
    return const ServerFailure('Escribe el nombre del invitado.');
  }
  if (guest.passes < 1 || guest.passes > kMaxPassesPerGuest) {
    return const ServerFailure(
      'El número de lugares debe estar entre 1 y $kMaxPassesPerGuest.',
    );
  }
  return null;
}

class GuestRef extends Equatable {
  const GuestRef({required this.eventId, required this.guestId});
  final String eventId;
  final String guestId;

  @override
  List<Object> get props => [eventId, guestId];
}

class WatchGuests implements StreamUseCase<List<GuestEntity>, String> {
  const WatchGuests(this._repository);
  final GuestRepository _repository;

  @override
  Stream<Either<Failure, List<GuestEntity>>> call(String eventId) =>
      _repository.watchGuests(eventId);
}

class AddGuest implements UseCase<String, GuestEntity> {
  const AddGuest(this._repository);
  final GuestRepository _repository;

  @override
  Future<Either<Failure, String>> call(GuestEntity guest) async {
    final error = _validate(guest);
    if (error != null) return left(error);
    return _repository.addGuest(guest);
  }
}

class UpdateGuest implements UseCase<Unit, GuestEntity> {
  const UpdateGuest(this._repository);
  final GuestRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(GuestEntity guest) async {
    final error = _validate(guest);
    if (error != null) return left(error);
    return _repository.updateGuest(guest);
  }
}

class DeleteGuest implements UseCase<Unit, GuestRef> {
  const DeleteGuest(this._repository);
  final GuestRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(GuestRef ref) =>
      _repository.deleteGuest(ref.eventId, ref.guestId);
}
