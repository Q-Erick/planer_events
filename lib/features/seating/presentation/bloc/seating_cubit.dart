import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../guests/domain/entities/guest_entity.dart';
import '../../../guests/domain/usecases/guest_usecases.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/services/seating_planner.dart';
import '../../domain/usecases/seating_usecases.dart';
import '../utils/table_geometry.dart';

enum SeatingMode { assign, move }

class SeatingState extends Equatable {
  const SeatingState({
    this.isLoading = true,
    this.tables = const [],
    this.guests = const [],
    this.seatsPerTable = 10,
    this.mode = SeatingMode.assign,
    this.dragPositions = const {},
    this.draggingId,
    this.pendingGuestId,
    this.message,
    this.isError = false,
  });

  final bool isLoading;
  final List<TableEntity> tables;
  final List<GuestEntity> guests;
  final int seatsPerTable;
  final SeatingMode mode;

  /// Posición temporal de las mesas mientras se arrastran.
  final Map<String, Offset> dragPositions;
  final String? draggingId;

  /// Grupo al que le faltan lugares por asignar.
  final String? pendingGuestId;

  final String? message;
  final bool isError;

  Map<String, GuestEntity> get guestsById => {for (final g in guests) g.id: g};

  GuestEntity? get pendingGuest =>
      pendingGuestId == null ? null : guestsById[pendingGuestId];

  int remainingOf(GuestEntity guest) => SeatingPlanner.remaining(guest, tables);

  /// Invitados que todavía tienen lugares sin silla.
  List<GuestEntity> get guestsToSeat =>
      guests.where((g) => remainingOf(g) > 0).toList();

  int get totalPasses => guests.fold(0, (sum, g) => sum + g.passes);

  int get totalSeated {
    final ids = guestsById;
    return tables.fold(
      0,
      (sum, t) => sum + t.assignments.values.where(ids.containsKey).length,
    );
  }

  Offset positionOf(TableEntity table) =>
      dragPositions[table.id] ?? Offset(table.x, table.y);

  SeatingState copyWith({
    bool? isLoading,
    List<TableEntity>? tables,
    List<GuestEntity>? guests,
    int? seatsPerTable,
    SeatingMode? mode,
    Map<String, Offset>? dragPositions,
    String? draggingId,
    bool clearDragging = false,
    String? pendingGuestId,
    bool clearPending = false,
    String? message,
    bool? isError,
  }) {
    return SeatingState(
      isLoading: isLoading ?? this.isLoading,
      tables: tables ?? this.tables,
      guests: guests ?? this.guests,
      seatsPerTable: seatsPerTable ?? this.seatsPerTable,
      mode: mode ?? this.mode,
      dragPositions: dragPositions ?? this.dragPositions,
      draggingId: clearDragging ? null : (draggingId ?? this.draggingId),
      pendingGuestId: clearPending
          ? null
          : (pendingGuestId ?? this.pendingGuestId),
      message: message,
      isError: isError ?? false,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    tables,
    guests,
    seatsPerTable,
    mode,
    dragPositions,
    draggingId,
    pendingGuestId,
    message,
    isError,
  ];
}

class SeatingCubit extends Cubit<SeatingState> {
  SeatingCubit({
    required WatchTables watchTables,
    required WatchSeatsPerTable watchSeatsPerTable,
    required WatchGuests watchGuests,
    required SetSeatsPerTable setSeatsPerTable,
    required AddTable addTable,
    required MoveTable moveTable,
    required ChangeTableSeats changeTableSeats,
    required ChangeTableShape changeTableShape,
    required DeleteTable deleteTable,
    required AssignGuest assignGuest,
    required ReleaseSeat releaseSeat,
    required ReleaseGuestSeats releaseGuestSeats,
  }) : _watchTables = watchTables,
       _watchSeatsPerTable = watchSeatsPerTable,
       _watchGuests = watchGuests,
       _setSeatsPerTable = setSeatsPerTable,
       _addTable = addTable,
       _moveTable = moveTable,
       _changeTableSeats = changeTableSeats,
       _changeTableShape = changeTableShape,
       _deleteTable = deleteTable,
       _assignGuest = assignGuest,
       _releaseSeat = releaseSeat,
       _releaseGuestSeats = releaseGuestSeats,
       super(const SeatingState());

  final WatchTables _watchTables;
  final WatchSeatsPerTable _watchSeatsPerTable;
  final WatchGuests _watchGuests;
  final SetSeatsPerTable _setSeatsPerTable;
  final AddTable _addTable;
  final MoveTable _moveTable;
  final ChangeTableSeats _changeTableSeats;
  final ChangeTableShape _changeTableShape;
  final DeleteTable _deleteTable;
  final AssignGuest _assignGuest;
  final ReleaseSeat _releaseSeat;
  final ReleaseGuestSeats _releaseGuestSeats;

  /// Controla el zoom y el desplazamiento del plano.
  final TransformationController transformController =
      TransformationController();
  bool _fitted = false;

  final _subscriptions = <StreamSubscription<dynamic>>[];
  String _eventId = '';

  // ---------------- Escuchar datos ----------------

  void watch(String eventId) {
    _eventId = eventId;

    _subscriptions.add(
      _watchTables(eventId).listen((result) {
        result.fold(_fail, (tables) {
          // Conserva solo la posición de la mesa que se está arrastrando
          final dragging = state.draggingId;
          final keep = <String, Offset>{
            if (dragging != null && state.dragPositions[dragging] != null)
              dragging: state.dragPositions[dragging]!,
          };
          emit(
            state.copyWith(
              isLoading: false,
              tables: tables,
              dragPositions: keep,
            ),
          );
          // Si el grupo pendiente ya quedó completo, se limpia el aviso
          final pending = state.pendingGuest;
          if (pending != null && state.remainingOf(pending) == 0) {
            emit(state.copyWith(clearPending: true));
          }
        });
      }),
    );

    _subscriptions.add(
      _watchGuests(eventId).listen((result) {
        result.fold(_fail, (guests) => emit(state.copyWith(guests: guests)));
      }),
    );

    _subscriptions.add(
      _watchSeatsPerTable(eventId).listen((result) {
        result.fold(
          (_) {},
          (seats) => emit(state.copyWith(seatsPerTable: seats)),
        );
      }),
    );
  }

  /// Ajusta el zoom inicial para que el salón quepa a lo ancho.
  void fitToWidth(double viewportWidth) {
    if (_fitted || viewportWidth <= 0) return;
    _fitted = true;
    final scale = (viewportWidth / kVenueSize.width).clamp(0.2, 1.5);
    // Se aplica después de dibujar para no modificar el árbol durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        transformController.value = Matrix4.diagonal3Values(scale, scale, 1);
      }
    });
  }

  void setMode(SeatingMode mode) => emit(state.copyWith(mode: mode));

  // ---------------- Mesas ----------------

  Future<void> addTable(TableShape shape) async {
    final result = await _addTable(
      AddTableParams(
        eventId: _eventId,
        shape: shape,
        seats: state.seatsPerTable,
        existingTables: state.tables,
      ),
    );
    result.fold(_fail, (_) {});
  }

  void dragTable(TableEntity table, Offset delta) {
    final current = state.positionOf(table);
    final next = Offset(
      (current.dx + delta.dx / kVenueSize.width).clamp(0.02, 0.98),
      (current.dy + delta.dy / kVenueSize.height).clamp(0.02, 0.98),
    );
    emit(
      state.copyWith(
        dragPositions: {...state.dragPositions, table.id: next},
        draggingId: table.id,
      ),
    );
  }

  Future<void> endDrag(TableEntity table) async {
    final position = state.dragPositions[table.id];
    emit(state.copyWith(clearDragging: true));
    if (position == null) return;

    final result = await _moveTable(
      MoveTableParams(table: table, x: position.dx, y: position.dy),
    );
    result.fold(_fail, (_) {});
  }

  Future<void> changeSeats(TableEntity table, int seats) async {
    final result = await _changeTableSeats(
      ChangeSeatsParams(table: table, seats: seats),
    );
    result.fold(_fail, (_) {});
  }

  Future<void> changeShape(TableEntity table, TableShape shape) async {
    final result = await _changeTableShape(
      ChangeShapeParams(table: table, shape: shape),
    );
    result.fold(_fail, (_) {});
  }

  Future<void> deleteTable(TableEntity table) async {
    final result = await _deleteTable(table);
    result.fold(_fail, (_) => _info('Mesa ${table.number} eliminada.'));
  }

  Future<void> setSeatsPerTable(int seats) async {
    final result = await _setSeatsPerTable(
      SeatsPerTableParams(eventId: _eventId, seats: seats),
    );
    result.fold(_fail, (_) => _info('Las mesas nuevas tendrán $seats sillas.'));
  }

  // ---------------- Asignaciones ----------------

  Future<void> assign(
    TableEntity table,
    int seat,
    GuestEntity guest, {
    required bool together,
  }) async {
    final result = await _assignGuest(
      AssignGuestParams(
        table: table,
        seat: seat,
        guest: guest,
        allTables: state.tables,
        together: together,
      ),
    );
    if (isClosed) return;

    result.fold(_fail, (res) {
      if (together && res.pending > 0) {
        emit(
          state.copyWith(
            pendingGuestId: guest.id,
            message:
                'Se sentaron ${res.assigned}. Faltan ${res.pending} '
                'de ${guest.name}: toca otra silla libre.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            clearPending: true,
            message: together
                ? '${guest.name} quedó sentado.'
                : 'Silla asignada a ${guest.name}.',
          ),
        );
      }
    });
  }

  Future<void> releaseSeat(TableEntity table, int seat) async {
    final result = await _releaseSeat(SeatParams(table: table, seat: seat));
    result.fold(_fail, (_) {});
  }

  Future<void> releaseGuest(GuestEntity guest) async {
    final result = await _releaseGuestSeats(
      GuestRef(eventId: _eventId, guestId: guest.id),
    );
    result.fold(
      _fail,
      (_) => _info('Se liberaron los lugares de ${guest.name}.'),
    );
  }

  void clearPending() => emit(state.copyWith(clearPending: true));

  // ---------------- Helpers ----------------

  void _fail(Failure failure) {
    if (!isClosed) {
      emit(state.copyWith(message: failure.message, isError: true));
    }
  }

  void _info(String message) {
    if (!isClosed) emit(state.copyWith(message: message));
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    transformController.dispose();
    return super.close();
  }
}
