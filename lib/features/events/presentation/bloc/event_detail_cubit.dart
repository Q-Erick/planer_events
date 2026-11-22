import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/event_usecases.dart';

class EventDetailState extends Equatable {
  const EventDetailState({
    this.isLoading = true,
    this.event,
    this.errorMessage,
    this.isDeleting = false,
    this.deleted = false,
  });

  final bool isLoading;
  final EventEntity? event;
  final String? errorMessage;
  final bool isDeleting;
  final bool deleted;

  EventDetailState copyWith({
    bool? isLoading,
    EventEntity? event,
    String? errorMessage,
    bool? isDeleting,
    bool? deleted,
  }) {
    return EventDetailState(
      isLoading: isLoading ?? this.isLoading,
      event: event ?? this.event,
      errorMessage: errorMessage,
      isDeleting: isDeleting ?? this.isDeleting,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    event,
    errorMessage,
    isDeleting,
    deleted,
  ];
}

class EventDetailCubit extends Cubit<EventDetailState> {
  EventDetailCubit({
    required WatchEvent watchEvent,
    required DeleteEvent deleteEvent,
  }) : _watchEvent = watchEvent,
       _deleteEvent = deleteEvent,
       super(const EventDetailState());

  final WatchEvent _watchEvent;
  final DeleteEvent _deleteEvent;
  StreamSubscription<dynamic>? _subscription;
  String? _eventId;

  void watch(String eventId) {
    _eventId = eventId;
    _subscription?.cancel();
    _subscription = _watchEvent(eventId).listen((result) {
      result.fold(
        (failure) => emit(
          state.copyWith(isLoading: false, errorMessage: failure.message),
        ),
        (event) => emit(state.copyWith(isLoading: false, event: event)),
      );
    });
  }

  Future<void> delete() async {
    final id = _eventId;
    if (id == null || state.isDeleting) return;

    emit(state.copyWith(isDeleting: true));
    // Dejamos de escuchar antes de borrar para no recibir el error
    // de "el evento ya no existe".
    await _subscription?.cancel();

    final result = await _deleteEvent(id);
    if (isClosed) return;

    result.fold((failure) {
      emit(state.copyWith(isDeleting: false, errorMessage: failure.message));
      watch(id);
    }, (_) => emit(state.copyWith(isDeleting: false, deleted: true)));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
