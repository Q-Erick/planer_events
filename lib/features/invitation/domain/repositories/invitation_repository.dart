import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/invitation_config.dart';

abstract class InvitationRepository {
  Stream<Either<Failure, InvitationConfig>> watchInvitation(String eventId);

  Future<Either<Failure, Unit>> saveInvitation(
    String eventId,
    InvitationConfig config,
  );

  /// Sube la imagen de fondo y devuelve su URL.
  Future<Either<Failure, String>> uploadBackground(
    String eventId,
    Uint8List bytes,
  );
}
