import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/event_usecases.dart';

class EventFormState extends Equatable {
  const EventFormState({
    required this.date,
    this.eventId,
    this.hostId,
    this.name = '',
    this.type = EventType.wedding,
    this.venueName = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.maxGuests = '100',
    this.isLoading = false,
    this.showErrors = false,
    this.status = FormStatus.initial,
    this.errorMessage,
    this.savedEventId,
  });

  final String? eventId;
  final String? hostId;
  final String name;
  final EventType type;
  final DateTime date;
  final String venueName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String maxGuests;
  final bool isLoading;
  final bool showErrors;
  final FormStatus status;
  final String? errorMessage;

  /// Id del evento guardado (para navegar al detalle).
  final String? savedEventId;

  bool get isEditing => eventId != null;
  bool get isSaving => status == FormStatus.loading;
  bool get hasLocation => latitude != null && longitude != null;
  int? get guestsNumber => int.tryParse(maxGuests.trim());

  String? get nameError =>
      showErrors ? Validators.required(name, 'el nombre del evento') : null;

  String? get guestsError {
    if (!showErrors) return null;
    final n = guestsNumber;
    return (n == null || n <= 0) ? 'Ingresa un número válido.' : null;
  }

  String? get locationError =>
      showErrors && !hasLocation ? 'Selecciona la ubicación en el mapa.' : null;

  bool get isValid =>
      name.trim().isNotEmpty && (guestsNumber ?? 0) > 0 && hasLocation;

  EventFormState copyWith({
    String? eventId,
    String? hostId,
    String? name,
    EventType? type,
    DateTime? date,
    String? venueName,
    String? address,
    double? latitude,
    double? longitude,
    String? maxGuests,
    bool? isLoading,
    bool? showErrors,
    FormStatus? status,
    String? errorMessage,
    String? savedEventId,
  }) {
    return EventFormState(
      eventId: eventId ?? this.eventId,
      hostId: hostId ?? this.hostId,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxGuests: maxGuests ?? this.maxGuests,
      isLoading: isLoading ?? this.isLoading,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorMessage: errorMessage,
      savedEventId: savedEventId ?? this.savedEventId,
    );
  }

  @override
  List<Object?> get props => [
    eventId,
    hostId,
    name,
    type,
    date,
    venueName,
    address,
    latitude,
    longitude,
    maxGuests,
    isLoading,
    showErrors,
    status,
    errorMessage,
    savedEventId,
  ];
}

class EventFormCubit extends Cubit<EventFormState> {
  EventFormCubit({
    required WatchEvent watchEvent,
    required CreateEvent createEvent,
    required UpdateEvent updateEvent,
  }) : _watchEvent = watchEvent,
       _createEvent = createEvent,
       _updateEvent = updateEvent,
       super(EventFormState(date: _defaultDate()));

  final WatchEvent _watchEvent;
  final CreateEvent _createEvent;
  final UpdateEvent _updateEvent;

  /// Por defecto: dentro de 30 días a las 6:00 p. m.
  static DateTime _defaultDate() {
    final d = DateTime.now().add(const Duration(days: 30));
    return DateTime(d.year, d.month, d.day, 18);
  }

  /// Carga un evento existente para editarlo.
  Future<void> load(String eventId) async {
    emit(state.copyWith(isLoading: true));
    final result = await _watchEvent(eventId).first;
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          status: FormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (e) => emit(
        EventFormState(
          eventId: e.id,
          hostId: e.hostId,
          name: e.name,
          type: e.type,
          date: e.date,
          venueName: e.venueName,
          address: e.address,
          latitude: e.latitude,
          longitude: e.longitude,
          maxGuests: '${e.maxGuests}',
        ),
      ),
    );
  }

  void nameChanged(String v) => emit(state.copyWith(name: v));
  void typeChanged(EventType v) => emit(state.copyWith(type: v));
  void venueNameChanged(String v) => emit(state.copyWith(venueName: v));
  void addressChanged(String v) => emit(state.copyWith(address: v));
  void maxGuestsChanged(String v) => emit(state.copyWith(maxGuests: v));

  void dateChanged(DateTime day) {
    final d = state.date;
    emit(
      state.copyWith(
        date: DateTime(day.year, day.month, day.day, d.hour, d.minute),
      ),
    );
  }

  void timeChanged(int hour, int minute) {
    final d = state.date;
    emit(state.copyWith(date: DateTime(d.year, d.month, d.day, hour, minute)));
  }

  void locationChanged(double latitude, double longitude) =>
      emit(state.copyWith(latitude: latitude, longitude: longitude));

  Future<void> save(String currentUserId) async {
    if (state.isSaving) return;
    if (!state.isValid) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: FormStatus.loading));

    final event = EventEntity(
      id: state.eventId ?? '',
      hostId: state.hostId ?? currentUserId,
      name: state.name,
      type: state.type,
      date: state.date,
      venueName: state.venueName,
      address: state.address,
      latitude: state.latitude,
      longitude: state.longitude,
      maxGuests: state.guestsNumber!,
    );

    if (state.isEditing) {
      final result = await _updateEvent(event);
      if (isClosed) return;
      result.fold(
        (f) => emit(
          state.copyWith(status: FormStatus.failure, errorMessage: f.message),
        ),
        (_) => emit(
          state.copyWith(status: FormStatus.success, savedEventId: event.id),
        ),
      );
    } else {
      final result = await _createEvent(event);
      if (isClosed) return;
      result.fold(
        (f) => emit(
          state.copyWith(status: FormStatus.failure, errorMessage: f.message),
        ),
        (id) =>
            emit(state.copyWith(status: FormStatus.success, savedEventId: id)),
      );
    }
  }
}
