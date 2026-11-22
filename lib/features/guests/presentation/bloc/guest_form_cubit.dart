import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/usecases/guest_usecases.dart';

class GuestFormState extends Equatable {
  const GuestFormState({
    this.eventId = '',
    this.original,
    this.name = '',
    this.phone = '',
    this.passes = 1,
    this.showErrors = false,
    this.status = FormStatus.initial,
    this.errorMessage,
    this.savedGuest,
  });

  final String eventId;
  final GuestEntity? original;
  final String name;
  final String phone;
  final int passes;
  final bool showErrors;
  final FormStatus status;
  final String? errorMessage;

  /// Invitado guardado (con su id).
  final GuestEntity? savedGuest;

  bool get isEditing => original != null;
  bool get isSaving => status == FormStatus.loading;

  String? get nameError =>
      showErrors ? Validators.required(name, 'el nombre') : null;

  GuestFormState copyWith({
    String? eventId,
    GuestEntity? original,
    String? name,
    String? phone,
    int? passes,
    bool? showErrors,
    FormStatus? status,
    String? errorMessage,
    GuestEntity? savedGuest,
  }) {
    return GuestFormState(
      eventId: eventId ?? this.eventId,
      original: original ?? this.original,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      passes: passes ?? this.passes,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorMessage: errorMessage,
      savedGuest: savedGuest ?? this.savedGuest,
    );
  }

  @override
  List<Object?> get props => [
    eventId,
    original,
    name,
    phone,
    passes,
    showErrors,
    status,
    errorMessage,
    savedGuest,
  ];
}

class GuestFormCubit extends Cubit<GuestFormState> {
  GuestFormCubit({required AddGuest addGuest, required UpdateGuest updateGuest})
    : _addGuest = addGuest,
      _updateGuest = updateGuest,
      super(const GuestFormState());

  final AddGuest _addGuest;
  final UpdateGuest _updateGuest;

  void start({
    required String eventId,
    GuestEntity? guest,
    String initialName = '',
  }) {
    emit(
      GuestFormState(
        eventId: eventId,
        original: guest,
        name: guest?.name ?? initialName,
        phone: guest?.phone ?? '',
        passes: guest?.passes ?? 1,
      ),
    );
  }

  void nameChanged(String v) => emit(state.copyWith(name: v));
  void phoneChanged(String v) => emit(state.copyWith(phone: v));

  void increment() {
    if (state.passes < kMaxPassesPerGuest) {
      emit(state.copyWith(passes: state.passes + 1));
    }
  }

  void decrement() {
    if (state.passes > 1) emit(state.copyWith(passes: state.passes - 1));
  }

  Future<void> save() async {
    if (state.isSaving) return;
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: FormStatus.loading));

    final base =
        state.original ?? GuestEntity(eventId: state.eventId, name: '');
    final guest = base.copyWith(
      name: state.name.trim(),
      phone: state.phone.trim(),
      passes: state.passes,
    );

    if (state.isEditing) {
      final result = await _updateGuest(guest);
      if (isClosed) return;
      result.fold(
        (f) => emit(
          state.copyWith(status: FormStatus.failure, errorMessage: f.message),
        ),
        (_) =>
            emit(state.copyWith(status: FormStatus.success, savedGuest: guest)),
      );
    } else {
      final result = await _addGuest(guest);
      if (isClosed) return;
      result.fold(
        (f) => emit(
          state.copyWith(status: FormStatus.failure, errorMessage: f.message),
        ),
        (id) => emit(
          state.copyWith(
            status: FormStatus.success,
            savedGuest: guest.copyWith(id: id),
          ),
        ),
      );
    }
  }
}
