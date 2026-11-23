import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/usecases/event_usecases.dart';
import '../../domain/entities/invitation_config.dart';
import '../../domain/usecases/invitation_usecases.dart';

class InvitationEditorState extends Equatable {
  const InvitationEditorState({
    this.isLoading = true,
    this.event,
    this.config = const InvitationConfig(),
    this.isSaving = false,
    this.isUploading = false,
    this.hasChanges = false,
    this.message,
    this.isError = false,
  });

  final bool isLoading;
  final EventEntity? event;

  /// Borrador que se está editando.
  final InvitationConfig config;
  final bool isSaving;
  final bool isUploading;
  final bool hasChanges;
  final String? message;
  final bool isError;

  InvitationEditorState copyWith({
    bool? isLoading,
    EventEntity? event,
    InvitationConfig? config,
    bool? isSaving,
    bool? isUploading,
    bool? hasChanges,
    String? message,
    bool? isError,
  }) {
    return InvitationEditorState(
      isLoading: isLoading ?? this.isLoading,
      event: event ?? this.event,
      config: config ?? this.config,
      isSaving: isSaving ?? this.isSaving,
      isUploading: isUploading ?? this.isUploading,
      hasChanges: hasChanges ?? this.hasChanges,
      message: message,
      isError: isError ?? false,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    event,
    config,
    isSaving,
    isUploading,
    hasChanges,
    message,
    isError,
  ];
}

class InvitationEditorCubit extends Cubit<InvitationEditorState> {
  InvitationEditorCubit({
    required WatchEvent watchEvent,
    required WatchInvitation watchInvitation,
    required SaveInvitation saveInvitation,
    required UploadInvitationBackground uploadBackground,
    required ImagePicker imagePicker,
  }) : _watchEvent = watchEvent,
       _watchInvitation = watchInvitation,
       _saveInvitation = saveInvitation,
       _uploadBackground = uploadBackground,
       _picker = imagePicker,
       super(const InvitationEditorState());

  final WatchEvent _watchEvent;
  final WatchInvitation _watchInvitation;
  final SaveInvitation _saveInvitation;
  final UploadInvitationBackground _uploadBackground;
  final ImagePicker _picker;

  StreamSubscription<dynamic>? _eventSub;
  String _eventId = '';

  Future<void> load(String eventId) async {
    _eventId = eventId;
    // El evento se escucha en vivo (para la vista previa)
    _eventSub = _watchEvent(eventId).listen((result) {
      result.fold((_) {}, (event) => emit(state.copyWith(event: event)));
    });

    // La invitación se carga una sola vez para no pisar el borrador
    final result = await _watchInvitation(eventId).first;
    if (isClosed) return;
    result.fold(
      (f) => emit(
        state.copyWith(isLoading: false, message: f.message, isError: true),
      ),
      (config) => emit(state.copyWith(isLoading: false, config: config)),
    );
  }

  void _update(InvitationConfig config) =>
      emit(state.copyWith(config: config, hasChanges: true));

  // ---------------- Contenido ----------------

  void messageChanged(String v) => _update(state.config.copyWith(message: v));
  void dressCodeChanged(String v) =>
      _update(state.config.copyWith(dressCode: v));

  void toggleMessage(bool v) => _update(state.config.copyWith(showMessage: v));
  void toggleCountdown(bool v) =>
      _update(state.config.copyWith(showCountdown: v));
  void toggleLocation(bool v) =>
      _update(state.config.copyWith(showLocation: v));
  void toggleItinerary(bool v) =>
      _update(state.config.copyWith(showItinerary: v));
  void toggleDressCode(bool v) =>
      _update(state.config.copyWith(showDressCode: v));

  void addItineraryItem() => _update(
    state.config.copyWith(
      itinerary: [
        ...state.config.itinerary,
        ItineraryItem(id: const Uuid().v4(), time: '20:00'),
      ],
    ),
  );

  void updateItineraryItem(String id, {String? time, String? title}) => _update(
    state.config.copyWith(
      itinerary: [
        for (final item in state.config.itinerary)
          item.id == id ? item.copyWith(time: time, title: title) : item,
      ],
    ),
  );

  void removeItineraryItem(String id) => _update(
    state.config.copyWith(
      itinerary: state.config.itinerary.where((i) => i.id != id).toList(),
    ),
  );

  // ---------------- Estilo ----------------

  void fontChanged(String font) =>
      _update(state.config.copyWith(fontFamily: font));

  void colorChanged(int color) =>
      _update(state.config.copyWith(colorValue: color));

  void removeBackground() =>
      _update(state.config.copyWith(clearBackground: true));

  Future<void> pickBackground() async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
    } catch (_) {
      emit(
        state.copyWith(message: 'No se pudo abrir la galería.', isError: true),
      );
      return;
    }
    if (file == null) return;

    emit(state.copyWith(isUploading: true));
    final bytes = await file.readAsBytes();
    final result = await _uploadBackground(
      UploadBackgroundParams(eventId: _eventId, bytes: bytes),
    );
    if (isClosed) return;

    result.fold(
      (f) => emit(
        state.copyWith(isUploading: false, message: f.message, isError: true),
      ),
      (url) => emit(
        state.copyWith(
          isUploading: false,
          config: state.config.copyWith(backgroundUrl: url),
          hasChanges: true,
        ),
      ),
    );
  }

  // ---------------- Guardar ----------------

  Future<void> save() async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true));

    final result = await _saveInvitation(
      SaveInvitationParams(eventId: _eventId, config: state.config),
    );
    if (isClosed) return;

    result.fold(
      (f) => emit(
        state.copyWith(isSaving: false, message: f.message, isError: true),
      ),
      (_) => emit(
        state.copyWith(
          isSaving: false,
          hasChanges: false,
          config: state.config.normalized(),
          message: 'Invitación guardada.',
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }
}
