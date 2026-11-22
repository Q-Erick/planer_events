import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/profile_usecases.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.isUploadingPhoto = false,
    this.isSavingName = false,
    this.message,
    this.isError = false,
  });

  final bool isUploadingPhoto;
  final bool isSavingName;
  final String? message;
  final bool isError;

  ProfileState copyWith({
    bool? isUploadingPhoto,
    bool? isSavingName,
    String? message,
    bool? isError,
  }) {
    return ProfileState(
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      isSavingName: isSavingName ?? this.isSavingName,
      message: message,
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [isUploadingPhoto, isSavingName, message, isError];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required UpdateProfilePhoto updateProfilePhoto,
    required UpdateDisplayName updateDisplayName,
    required ImagePicker imagePicker,
  }) : _updateProfilePhoto = updateProfilePhoto,
       _updateDisplayName = updateDisplayName,
       _picker = imagePicker,
       super(const ProfileState());

  final UpdateProfilePhoto _updateProfilePhoto;
  final UpdateDisplayName _updateDisplayName;
  final ImagePicker _picker;

  Future<void> changePhoto(UserEntity user, ImageSource source) async {
    if (state.isUploadingPhoto) return;

    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
    } catch (_) {
      emit(
        state.copyWith(
          message: 'No se pudo abrir la cámara o la galería.',
          isError: true,
        ),
      );
      return;
    }
    if (file == null) return; // El usuario canceló

    emit(state.copyWith(isUploadingPhoto: true));
    final bytes = await file.readAsBytes();
    final result = await _updateProfilePhoto(
      UpdatePhotoParams(user: user, bytes: bytes),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isUploadingPhoto: false,
          message: failure.message,
          isError: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isUploadingPhoto: false,
          message: 'Foto actualizada.',
          isError: false,
        ),
      ),
    );
  }

  Future<void> changeName(String name) async {
    if (state.isSavingName) return;
    emit(state.copyWith(isSavingName: true));

    final result = await _updateDisplayName(name);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSavingName: false,
          message: failure.message,
          isError: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isSavingName: false,
          message: 'Nombre actualizado.',
          isError: false,
        ),
      ),
    );
  }
}
