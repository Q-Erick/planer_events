import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/usecases/event_usecases.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/usecases/album_usecases.dart';

class AlbumState extends Equatable {
  const AlbumState({
    this.isLoading = true,
    this.event,
    this.photos = const [],
    this.uploadingCount = 0,
    this.message,
    this.isError = false,
  });

  final bool isLoading;
  final EventEntity? event;
  final List<PhotoEntity> photos;

  /// Fotos que se están subiendo ahora mismo.
  final int uploadingCount;
  final String? message;
  final bool isError;

  AlbumState copyWith({
    bool? isLoading,
    EventEntity? event,
    List<PhotoEntity>? photos,
    int? uploadingCount,
    String? message,
    bool? isError,
  }) {
    return AlbumState(
      isLoading: isLoading ?? this.isLoading,
      event: event ?? this.event,
      photos: photos ?? this.photos,
      uploadingCount: uploadingCount ?? this.uploadingCount,
      message: message,
      isError: isError ?? false,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    event,
    photos,
    uploadingCount,
    message,
    isError,
  ];
}

class AlbumCubit extends Cubit<AlbumState> {
  AlbumCubit({
    required WatchPhotos watchPhotos,
    required WatchEvent watchEvent,
    required UploadPhoto uploadPhoto,
    required DeletePhoto deletePhoto,
    required ImagePicker imagePicker,
  }) : _watchPhotos = watchPhotos,
       _watchEvent = watchEvent,
       _uploadPhoto = uploadPhoto,
       _deletePhoto = deletePhoto,
       _picker = imagePicker,
       super(const AlbumState());

  final WatchPhotos _watchPhotos;
  final WatchEvent _watchEvent;
  final UploadPhoto _uploadPhoto;
  final DeletePhoto _deletePhoto;
  final ImagePicker _picker;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  void watch(String eventId) {
    _subscriptions.add(
      _watchEvent(eventId).listen((result) {
        result.fold((_) {}, (event) => emit(state.copyWith(event: event)));
      }),
    );
    _subscriptions.add(
      _watchPhotos(eventId).listen((result) {
        result.fold(
          (f) => emit(
            state.copyWith(isLoading: false, message: f.message, isError: true),
          ),
          (photos) => emit(state.copyWith(isLoading: false, photos: photos)),
        );
      }),
    );
  }

  Future<void> takePhoto(UserEntity user) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 80,
      );
    } catch (_) {
      _error('No se pudo abrir la cámara.');
      return;
    }
    if (file != null) await _uploadAll([file], user);
  }

  Future<void> pickFromGallery(UserEntity user) async {
    final List<XFile> files;
    try {
      files = await _picker.pickMultiImage(maxWidth: 1920, imageQuality: 80);
    } catch (_) {
      _error('No se pudo abrir la galería.');
      return;
    }
    if (files.isNotEmpty) await _uploadAll(files, user);
  }

  Future<void> _uploadAll(List<XFile> files, UserEntity user) async {
    final event = state.event;
    if (event == null) return;

    emit(state.copyWith(uploadingCount: state.uploadingCount + files.length));
    var uploaded = 0;

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final result = await _uploadPhoto(
        UploadPhotoParams(
          event: event,
          bytes: bytes,
          uploaderId: user.uid,
          uploaderName: user.name,
          isHost: event.hostId == user.uid,
        ),
      );
      if (isClosed) return;
      result.fold((f) => _error(f.message), (_) => uploaded++);
      emit(state.copyWith(uploadingCount: state.uploadingCount - 1));
    }

    if (uploaded > 0) {
      emit(
        state.copyWith(
          message: uploaded == 1
              ? 'Foto agregada al álbum.'
              : '$uploaded fotos agregadas al álbum.',
        ),
      );
    }
  }

  Future<void> delete(PhotoEntity photo) async {
    final result = await _deletePhoto(photo);
    if (isClosed) return;
    result.fold(
      (f) => _error(f.message),
      (_) => emit(state.copyWith(message: 'Foto eliminada.')),
    );
  }

  void _error(String message) {
    if (!isClosed) emit(state.copyWith(message: message, isError: true));
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }
}
