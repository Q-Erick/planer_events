import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invitation_config.dart';
import '../repositories/invitation_repository.dart';

class SaveInvitationParams extends Equatable {
  const SaveInvitationParams({required this.eventId, required this.config});
  final String eventId;
  final InvitationConfig config;

  @override
  List<Object> get props => [eventId, config];
}

class UploadBackgroundParams extends Equatable {
  const UploadBackgroundParams({required this.eventId, required this.bytes});
  final String eventId;
  final Uint8List bytes;

  @override
  List<Object> get props => [eventId, bytes];
}

class WatchInvitation implements StreamUseCase<InvitationConfig, String> {
  const WatchInvitation(this._repository);
  final InvitationRepository _repository;

  @override
  Stream<Either<Failure, InvitationConfig>> call(String eventId) =>
      _repository.watchInvitation(eventId);
}

class SaveInvitation implements UseCase<Unit, SaveInvitationParams> {
  const SaveInvitation(this._repository);
  final InvitationRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveInvitationParams p) =>
      _repository.saveInvitation(p.eventId, p.config.normalized());
}

class UploadInvitationBackground
    implements UseCase<String, UploadBackgroundParams> {
  const UploadInvitationBackground(this._repository);
  final InvitationRepository _repository;

  @override
  Future<Either<Failure, String>> call(UploadBackgroundParams p) =>
      _repository.uploadBackground(p.eventId, p.bytes);
}
