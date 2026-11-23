import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../album/domain/usecases/album_usecases.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../../checkin/domain/services/seat_locator.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/usecases/event_usecases.dart';
import '../../../guests/domain/entities/guest_entity.dart';
import '../../../guests/domain/usecases/guest_usecases.dart';
import '../../../seating/domain/entities/table_entity.dart';
import '../../../seating/domain/usecases/seating_usecases.dart';
import '../../domain/entities/invitation_config.dart';
import '../../domain/usecases/invitation_usecases.dart';

class GuestViewState extends Equatable {
  const GuestViewState({
    this.event,
    this.config,
    this.guest,
    this.tables = const [],
    this.isUploading = false,
    this.error,
    this.message,
    this.isError = false,
  });

  final EventEntity? event;
  final InvitationConfig? config;
  final GuestEntity? guest;
  final List<TableEntity> tables;
  final bool isUploading;

  /// Error que impide mostrar la invitación.
  final String? error;
  final String? message;
  final bool isError;

  bool get isReady => event != null && config != null && guest != null;
  bool get isLoading => error == null && !isReady;

  List<SeatLocation> get seats =>
      guest == null ? const [] : SeatLocator.locate(tables, guest!.id);

  GuestViewState copyWith({
    EventEntity? event,
    InvitationConfig? config,
    GuestEntity? guest,
    List<TableEntity>? tables,
    bool? isUploading,
    String? error,
    String? message,
    bool? isError,
  }) {
    return GuestViewState(
      event: event ?? this.event,
      config: config ?? this.config,
      guest: guest ?? this.guest,
      tables: tables ?? this.tables,
      isUploading: isUploading ?? this.isUploading,
      error: error ?? this.error,
      message: message,
      isError: isError ?? false,
    );
  }

  @override
  List<Object?> get props => [
    event,
    config,
    guest,
    tables,
    isUploading,
    error,
    message,
    isError,
  ];
}

class GuestViewCubit extends Cubit<GuestViewState> {
  GuestViewCubit({
    required GetCurrentUser getCurrentUser,
    required SignInAnonymously signInAnonymously,
    required WatchEvent watchEvent,
    required WatchInvitation watchInvitation,
    required WatchGuest watchGuest,
    required WatchTables watchTables,
    required UploadPhoto uploadPhoto,
    required ImagePicker imagePicker,
  }) : _getCurrentUser = getCurrentUser,
       _signInAnonymously = signInAnonymously,
       _watchEvent = watchEvent,
       _watchInvitation = watchInvitation,
       _watchGuest = watchGuest,
       _watchTables = watchTables,
       _uploadPhoto = uploadPhoto,
       _picker = imagePicker,
       super(const GuestViewState());

  final GetCurrentUser _getCurrentUser;
  final SignInAnonymously _signInAnonymously;
  final WatchEvent _watchEvent;
  final WatchInvitation _watchInvitation;
  final WatchGuest _watchGuest;
  final WatchTables _watchTables;
  final UploadPhoto _uploadPhoto;
  final ImagePicker _picker;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  Future<void> start(String eventId, String guestId) async {
    // Si no hay sesión, entra como invitado anónimo (sin cuenta)
    if (_getCurrentUser() == null) {
      final result = await _signInAnonymously(const NoParams());
      if (isClosed) return;
      if (result.isLeft()) {
        emit(
          state.copyWith(
            error: 'No se pudo abrir la invitación. Revisa tu conexión.',
          ),
        );
        return;
      }
    }

    const notFound = 'Esta invitación no existe o fue cancelada.';

    _subscriptions.add(
      _watchEvent(eventId).listen((r) {
        r.fold(
          (_) => emit(state.copyWith(error: notFound)),
          (event) => emit(state.copyWith(event: event)),
        );
      }),
    );
    _subscriptions.add(
      _watchInvitation(eventId).listen((r) {
        r.fold((_) {}, (config) => emit(state.copyWith(config: config)));
      }),
    );
    _subscriptions.add(
      _watchGuest(GuestRef(eventId: eventId, guestId: guestId)).listen((r) {
        r.fold(
          (_) => emit(state.copyWith(error: notFound)),
          (guest) => emit(state.copyWith(guest: guest)),
        );
      }),
    );
    _subscriptions.add(
      _watchTables(eventId).listen((r) {
        r.fold((_) {}, (tables) => emit(state.copyWith(tables: tables)));
      }),
    );
  }

  Future<void> addPhoto(ImageSource source) async {
    final event = state.event;
    final guest = state.guest;
    final user = _getCurrentUser();
    if (event == null || guest == null || user == null) return;

    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 80,
      );
    } catch (_) {
      emit(
        state.copyWith(message: 'No se pudo abrir la cámara.', isError: true),
      );
      return;
    }
    if (file == null) return;

    emit(state.copyWith(isUploading: true));
    final bytes = await file.readAsBytes();
    final result = await _uploadPhoto(
      UploadPhotoParams(
        event: event,
        bytes: bytes,
        uploaderId: user.uid,
        uploaderName: guest.name,
        isHost: event.hostId == user.uid,
      ),
    );
    if (isClosed) return;

    result.fold(
      (f) => emit(
        state.copyWith(isUploading: false, message: f.message, isError: true),
      ),
      (_) => emit(
        state.copyWith(
          isUploading: false,
          message: '¡Gracias! Tu foto ya está en el álbum.',
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }
}
