import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either_stream.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/repositories/album_repository.dart';
import '../datasources/album_remote_datasource.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  AlbumRepositoryImpl(this._remote);

  final AlbumRemoteDataSource _remote;

  @override
  Stream<Either<Failure, List<PhotoEntity>>> watchPhotos(String eventId) =>
      _remote.watchPhotos(eventId).toEither();

  @override
  Future<Either<Failure, Unit>> uploadPhoto({
    required String eventId,
    required Uint8List bytes,
    required String uploaderId,
    required String uploaderName,
  }) => _guard(
    () => _remote.uploadPhoto(
      eventId: eventId,
      bytes: bytes,
      uploaderId: uploaderId,
      uploaderName: uploaderName,
    ),
  );

  @override
  Future<Either<Failure, Unit>> deletePhoto(PhotoEntity photo) =>
      _guard(() => _remote.deletePhoto(photo));

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
