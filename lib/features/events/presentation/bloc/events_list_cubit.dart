import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/event_usecases.dart';

class EventsListState extends Equatable {
  const EventsListState({
    this.isLoading = true,
    this.events = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<EventEntity> events;
  final String? errorMessage;

  @override
  List<Object?> get props => [isLoading, events, errorMessage];
}

class EventsListCubit extends Cubit<EventsListState> {
  EventsListCubit(this._watchHostEvents) : super(const EventsListState());

  final WatchHostEvents _watchHostEvents;
  StreamSubscription<dynamic>? _subscription;

  void watch(String hostId) {
    _subscription?.cancel();
    _subscription = _watchHostEvents(hostId).listen((result) {
      result.fold(
        (failure) => emit(
          EventsListState(
            isLoading: false,
            events: state.events,
            errorMessage: failure.message,
          ),
        ),
        (events) => emit(EventsListState(isLoading: false, events: events)),
      );
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
