import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../events/domain/usecases/event_usecases.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/usecases/guest_usecases.dart';

class GuestsState extends Equatable {
  const GuestsState({
    this.isLoading = true,
    this.guests = const [],
    this.maxGuests = 0,
    this.query = '',
    this.message,
  });

  final bool isLoading;
  final List<GuestEntity> guests;
  final int maxGuests;
  final String query;
  final String? message;

  /// Invitados filtrados por el buscador.
  List<GuestEntity> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return guests;
    return guests
        .where((g) => g.name.toLowerCase().contains(q) || g.phone.contains(q))
        .toList();
  }

  /// Suma de lugares de todos los pases.
  int get totalPasses => guests.fold(0, (sum, g) => sum + g.passes);

  bool get isOverCapacity => maxGuests > 0 && totalPasses > maxGuests;

  GuestsState copyWith({
    bool? isLoading,
    List<GuestEntity>? guests,
    int? maxGuests,
    String? query,
    String? message,
  }) {
    return GuestsState(
      isLoading: isLoading ?? this.isLoading,
      guests: guests ?? this.guests,
      maxGuests: maxGuests ?? this.maxGuests,
      query: query ?? this.query,
      message: message,
    );
  }

  @override
  List<Object?> get props => [isLoading, guests, maxGuests, query, message];
}

class GuestsCubit extends Cubit<GuestsState> {
  GuestsCubit({
    required WatchGuests watchGuests,
    required WatchEvent watchEvent,
    required DeleteGuest deleteGuest,
  }) : _watchGuests = watchGuests,
       _watchEvent = watchEvent,
       _deleteGuest = deleteGuest,
       super(const GuestsState());

  final WatchGuests _watchGuests;
  final WatchEvent _watchEvent;
  final DeleteGuest _deleteGuest;

  StreamSubscription<dynamic>? _guestsSub;
  StreamSubscription<dynamic>? _eventSub;

  void watch(String eventId) {
    _guestsSub = _watchGuests(eventId).listen((result) {
      result.fold(
        (f) => emit(state.copyWith(isLoading: false, message: f.message)),
        (guests) => emit(state.copyWith(isLoading: false, guests: guests)),
      );
    });
    _eventSub = _watchEvent(eventId).listen((result) {
      result.fold(
        (_) {},
        (event) => emit(state.copyWith(maxGuests: event.maxGuests)),
      );
    });
  }

  void search(String query) => emit(state.copyWith(query: query));

  Future<void> delete(GuestEntity guest) async {
    final result = await _deleteGuest(
      GuestRef(eventId: guest.eventId, guestId: guest.id),
    );
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (_) => emit(state.copyWith(message: '${guest.name} eliminado.')),
    );
  }

  @override
  Future<void> close() {
    _guestsSub?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
