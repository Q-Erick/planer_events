import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either_stream.dart';
import '../../domain/entities/invitation_config.dart';
import '../../domain/repositories/invitation_repository.dart';
import '../datasources/invitation_remote_datasource.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  InvitationRepositoryImpl(this._remote);

  final InvitationRemoteDataSource _remote;

  @override
  Stream<Either<Failure, InvitationConfig>> watchInvitation(String eventId) =>
      _remote.watchInvitation(eventId).toEither();

  @override
  Future<Either<Failure, Unit>> saveInvitation(
    String eventId,
    InvitationConfig config,
  ) => _guard(() async {
    await _remote.saveInvitation(eventId, config);
    return unit;
  });

  @override
  Future<Either<Failure, String>> uploadBackground(
    String eventId,
    Uint8List bytes,
  ) => _guard(() => _remote.uploadBackground(eventId, bytes));

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
