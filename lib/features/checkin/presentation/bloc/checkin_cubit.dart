import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../guests/domain/entities/guest_entity.dart';
import '../../../guests/domain/usecases/guest_usecases.dart';
import '../../../seating/domain/entities/table_entity.dart';
import '../../../seating/domain/usecases/seating_usecases.dart';
import '../../domain/entities/qr_pass.dart';
import '../../domain/services/seat_locator.dart';
import '../../domain/usecases/checkin_usecases.dart';

class CheckInState extends Equatable {
  const CheckInState({
    this.isUnlocked = false,
    this.isAuthenticating = false,
    this.authError,
    this.guests = const [],
    this.tables = const [],
    this.selectedGuestId,
    this.isSaving = false,
    this.message,
    this.isError = false,
  });

  final bool isUnlocked;
  final bool isAuthenticating;
  final String? authError;
  final List<GuestEntity> guests;
  final List<TableEntity> tables;

  /// Invitado escaneado o buscado.
  final String? selectedGuestId;
  final bool isSaving;
  final String? message;
  final bool isError;

  Map<String, GuestEntity> get guestsById => {for (final g in guests) g.id: g};

  GuestEntity? get selectedGuest =>
      selectedGuestId == null ? null : guestsById[selectedGuestId];

  List<SeatLocation> get selectedSeats => selectedGuestId == null
      ? const []
      : SeatLocator.locate(tables, selectedGuestId!);

  int get totalPasses => guests.fold(0, (sum, g) => sum + g.passes);

  int get arrivedPasses =>
      guests.where((g) => g.checkedIn).fold(0, (sum, g) => sum + g.passes);

  CheckInState copyWith({
    bool? isUnlocked,
    bool? isAuthenticating,
    String? authError,
    List<GuestEntity>? guests,
    List<TableEntity>? tables,
    String? selectedGuestId,
    bool clearSelected = false,
    bool? isSaving,
    String? message,
    bool? isError,
  }) {
    return CheckInState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      authError: authError,
      guests: guests ?? this.guests,
      tables: tables ?? this.tables,
      selectedGuestId: clearSelected
          ? null
          : (selectedGuestId ?? this.selectedGuestId),
      isSaving: isSaving ?? this.isSaving,
      message: message,
      isError: isError ?? false,
    );
  }

  @override
  List<Object?> get props => [
    isUnlocked,
    isAuthenticating,
    authError,
    guests,
    tables,
    selectedGuestId,
    isSaving,
    message,
    isError,
  ];
}

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit({
    required AuthenticateReception authenticateReception,
    required WatchGuests watchGuests,
    required WatchTables watchTables,
    required CheckInGuest checkInGuest,
  }) : _authenticate = authenticateReception,
       _watchGuests = watchGuests,
       _watchTables = watchTables,
       _checkInGuest = checkInGuest,
       super(const CheckInState());

  final AuthenticateReception _authenticate;
  final WatchGuests _watchGuests;
  final WatchTables _watchTables;
  final CheckInGuest _checkInGuest;

  final MobileScannerController scannerController = MobileScannerController();

  final _subscriptions = <StreamSubscription<dynamic>>[];
  String _eventId = '';

  /// Evita volver a leer el mismo QR justo después de cerrarlo.
  String? _lastRaw;
  DateTime _ignoreUntil = DateTime.fromMillisecondsSinceEpoch(0);

  // ---------------- Sensor biométrico ----------------

  Future<void> unlock() async {
    if (state.isAuthenticating || state.isUnlocked) return;
    emit(state.copyWith(isAuthenticating: true));

    final result = await _authenticate(
      'Confirma tu identidad para abrir la recepción',
    );
    if (isClosed) return;

    result.fold(
      (f) =>
          emit(state.copyWith(isAuthenticating: false, authError: f.message)),
      (ok) => emit(
        state.copyWith(
          isAuthenticating: false,
          isUnlocked: ok,
          authError: ok ? null : 'No se verificó tu identidad.',
        ),
      ),
    );
  }

  // ---------------- Datos ----------------

  void watch(String eventId) {
    _eventId = eventId;
    _subscriptions.add(
      _watchGuests(eventId).listen((result) {
        result.fold(
          (f) => emit(state.copyWith(message: f.message, isError: true)),
          (guests) => emit(state.copyWith(guests: guests)),
        );
      }),
    );
    _subscriptions.add(
      _watchTables(eventId).listen((result) {
        result.fold((_) {}, (tables) => emit(state.copyWith(tables: tables)));
      }),
    );
  }

  // ---------------- Escaneo ----------------

  void onDetect(String? raw) {
    if (!state.isUnlocked || state.selectedGuestId != null) return;
    if (raw == null) return;
    if (raw == _lastRaw && DateTime.now().isBefore(_ignoreUntil)) return;
    _lastRaw = raw;

    final pass = QrPass.parse(raw);
    if (pass == null) {
      _error('Este código no es un pase de Planer Events.');
      return;
    }
    if (pass.eventId != _eventId) {
      _error('Este pase es de otro evento.');
      return;
    }
    final guest = state.guestsById[pass.guestId];
    if (guest == null) {
      _error('Pase no encontrado. Puede que lo hayan eliminado de la lista.');
      return;
    }
    emit(state.copyWith(selectedGuestId: guest.id));
  }

  void selectGuest(GuestEntity guest) =>
      emit(state.copyWith(selectedGuestId: guest.id));

  Future<void> confirmCheckIn() async {
    final guest = state.selectedGuest;
    if (guest == null || state.isSaving) return;
    emit(state.copyWith(isSaving: true));

    final result = await _checkInGuest(
      GuestRef(eventId: _eventId, guestId: guest.id),
    );
    if (isClosed) return;

    result.fold(
      (f) => emit(
        state.copyWith(isSaving: false, message: f.message, isError: true),
      ),
      (_) {
        _pauseSameCode();
        emit(
          state.copyWith(
            isSaving: false,
            clearSelected: true,
            message: '¡Bienvenidos, ${guest.name}!',
          ),
        );
      },
    );
  }

  void dismiss() {
    _pauseSameCode();
    emit(state.copyWith(clearSelected: true));
  }

  void _pauseSameCode() =>
      _ignoreUntil = DateTime.now().add(const Duration(seconds: 3));

  void _error(String message) {
    _pauseSameCode();
    emit(state.copyWith(message: message, isError: true));
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    scannerController.dispose();
    return super.close();
  }
}
