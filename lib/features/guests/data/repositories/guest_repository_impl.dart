import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either_stream.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/repositories/guest_repository.dart';
import '../datasources/guest_remote_datasource.dart';
import '../models/guest_model.dart';

class GuestRepositoryImpl implements GuestRepository {
  GuestRepositoryImpl(this._remote);

  final GuestRemoteDataSource _remote;

  @override
  Stream<Either<Failure, List<GuestEntity>>> watchGuests(String eventId) =>
      _remote.watchGuests(eventId).toEither();

  @override
  Future<Either<Failure, String>> addGuest(GuestEntity guest) =>
      _guard(() => _remote.addGuest(GuestModel.fromEntity(guest)));

  @override
  Future<Either<Failure, Unit>> updateGuest(GuestEntity guest) =>
      _guard(() async {
        await _remote.updateGuest(GuestModel.fromEntity(guest));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteGuest(String eventId, String guestId) =>
      _guard(() async {
        await _remote.deleteGuest(eventId, guestId);
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
