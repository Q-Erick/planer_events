import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../entities/photo_entity.dart';
import '../repositories/album_repository.dart';

/// Regla de negocio: el anfitrión puede subir fotos siempre;
/// los invitados solo el día del evento.
class AlbumPolicy {
  AlbumPolicy._();

  static bool canUpload({required EventEntity event, required bool isHost}) =>
      isHost || event.isToday;
}

class UploadPhotoParams extends Equatable {
  const UploadPhotoParams({
    required this.event,
    required this.bytes,
    required this.uploaderId,
    required this.uploaderName,
    required this.isHost,
  });

  final EventEntity event;
  final Uint8List bytes;
  final String uploaderId;
  final String uploaderName;
  final bool isHost;

  @override
  List<Object> get props => [event, bytes, uploaderId, uploaderName, isHost];
}

class WatchPhotos implements StreamUseCase<List<PhotoEntity>, String> {
  const WatchPhotos(this._repository);
  final AlbumRepository _repository;

  @override
  Stream<Either<Failure, List<PhotoEntity>>> call(String eventId) =>
      _repository.watchPhotos(eventId);
}

class UploadPhoto implements UseCase<Unit, UploadPhotoParams> {
  const UploadPhoto(this._repository);
  final AlbumRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UploadPhotoParams p) async {
    if (!AlbumPolicy.canUpload(event: p.event, isHost: p.isHost)) {
      return left(
        const ServerFailure('La cámara se activa el día del evento.'),
      );
    }
    return _repository.uploadPhoto(
      eventId: p.event.id,
      bytes: p.bytes,
      uploaderId: p.uploaderId,
      uploaderName: p.uploaderName,
    );
  }
}

class DeletePhoto implements UseCase<Unit, PhotoEntity> {
  const DeletePhoto(this._repository);
  final AlbumRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(PhotoEntity photo) =>
      _repository.deletePhoto(photo);
}
