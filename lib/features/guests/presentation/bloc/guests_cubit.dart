import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../events/domain/usecases/event_usecases.dart';
import '../../../seating/domain/entities/table_entity.dart';
import '../../../seating/domain/services/seating_planner.dart';
import '../../../seating/domain/usecases/seating_usecases.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/usecases/guest_usecases.dart';

class GuestsState extends Equatable {
  const GuestsState({
    this.isLoading = true,
    this.guests = const [],
    this.tables = const [],
    this.maxGuests = 0,
    this.query = '',
    this.message,
  });

  final bool isLoading;
  final List<GuestEntity> guests;
  final List<TableEntity> tables;
  final int maxGuests;
  final String query;
  final String? message;

  List<GuestEntity> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return guests;
    return guests
        .where((g) => g.name.toLowerCase().contains(q) || g.phone.contains(q))
        .toList();
  }

  int get totalPasses => guests.fold(0, (sum, g) => sum + g.passes);

  bool get isOverCapacity => maxGuests > 0 && totalPasses > maxGuests;

  /// Sillas asignadas a un invitado en todo el salón.
  int seatedOf(String guestId) => SeatingPlanner.seatedCount(tables, guestId);

  GuestsState copyWith({
    bool? isLoading,
    List<GuestEntity>? guests,
    List<TableEntity>? tables,
    int? maxGuests,
    String? query,
    String? message,
  }) {
    return GuestsState(
      isLoading: isLoading ?? this.isLoading,
      guests: guests ?? this.guests,
      tables: tables ?? this.tables,
      maxGuests: maxGuests ?? this.maxGuests,
      query: query ?? this.query,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    guests,
    tables,
    maxGuests,
    query,
    message,
  ];
}

class GuestsCubit extends Cubit<GuestsState> {
  GuestsCubit({
    required WatchGuests watchGuests,
    required WatchEvent watchEvent,
    required WatchTables watchTables,
    required DeleteGuest deleteGuest,
    required ReleaseGuestSeats releaseGuestSeats,
  }) : _watchGuests = watchGuests,
       _watchEvent = watchEvent,
       _watchTables = watchTables,
       _deleteGuest = deleteGuest,
       _releaseGuestSeats = releaseGuestSeats,
       super(const GuestsState());

  final WatchGuests _watchGuests;
  final WatchEvent _watchEvent;
  final WatchTables _watchTables;
  final DeleteGuest _deleteGuest;
  final ReleaseGuestSeats _releaseGuestSeats;

  final _subscriptions = <StreamSubscription<dynamic>>[];

  void watch(String eventId) {
    _subscriptions.add(
      _watchGuests(eventId).listen((result) {
        result.fold(
          (f) => emit(state.copyWith(isLoading: false, message: f.message)),
          (guests) => emit(state.copyWith(isLoading: false, guests: guests)),
        );
      }),
    );
    _subscriptions.add(
      _watchEvent(eventId).listen((result) {
        result.fold(
          (_) {},
          (event) => emit(state.copyWith(maxGuests: event.maxGuests)),
        );
      }),
    );
    _subscriptions.add(
      _watchTables(eventId).listen((result) {
        result.fold((_) {}, (tables) => emit(state.copyWith(tables: tables)));
      }),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  Future<void> delete(GuestEntity guest) async {
    final ref = GuestRef(eventId: guest.eventId, guestId: guest.id);

    // Primero libera sus sillas, luego elimina el pase
    final released = await _releaseGuestSeats(ref);
    if (isClosed) return;
    if (released.isLeft()) {
      emit(state.copyWith(message: 'No se pudieron liberar sus sillas.'));
      return;
    }

    final result = await _deleteGuest(ref);
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (_) => emit(state.copyWith(message: '${guest.name} eliminado.')),
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
