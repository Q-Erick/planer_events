import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';

abstract class AlbumRepository {
  Stream<Either<Failure, List<PhotoEntity>>> watchPhotos(String eventId);

  Future<Either<Failure, Unit>> uploadPhoto({
    required String eventId,
    required Uint8List bytes,
    required String uploaderId,
    required String uploaderName,
  });

  Future<Either<Failure, Unit>> deletePhoto(PhotoEntity photo);
}
