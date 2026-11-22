import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

class VerifyEmailState extends Equatable {
  const VerifyEmailState({
    this.cooldown = 0,
    this.isChecking = false,
    this.isSending = false,
    this.verifiedUser,
    this.message,
    this.isError = false,
  });

  /// Segundos que faltan para poder reenviar el correo.
  final int cooldown;
  final bool isChecking;
  final bool isSending;

  /// Se llena cuando el correo ya fue verificado.
  final UserEntity? verifiedUser;

  final String? message;
  final bool isError;

  VerifyEmailState copyWith({
    int? cooldown,
    bool? isChecking,
    bool? isSending,
    UserEntity? verifiedUser,
    String? message,
    bool? isError,
  }) {
    return VerifyEmailState(
      cooldown: cooldown ?? this.cooldown,
      isChecking: isChecking ?? this.isChecking,
      isSending: isSending ?? this.isSending,
      verifiedUser: verifiedUser ?? this.verifiedUser,
      message: message,
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [
    cooldown,
    isChecking,
    isSending,
    verifiedUser,
    message,
    isError,
  ];
}

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit({
    required ReloadUser reloadUser,
    required SendEmailVerification sendEmailVerification,
  }) : _reloadUser = reloadUser,
       _sendEmailVerification = sendEmailVerification,
       super(const VerifyEmailState()) {
    _autoCheck = Timer.periodic(
      const Duration(seconds: 5),
      (_) => check(silent: true),
    );
  }

  final ReloadUser _reloadUser;
  final SendEmailVerification _sendEmailVerification;

  Timer? _autoCheck;
  Timer? _cooldownTimer;

  /// Revisa si el correo ya fue verificado.
  /// [silent] = true cuando lo hace el temporizador (no muestra mensajes).
  Future<void> check({bool silent = false}) async {
    if (state.isChecking || isClosed) return;
    if (!silent) emit(state.copyWith(isChecking: true));

    final result = await _reloadUser(const NoParams());
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isChecking: false,
          message: silent ? null : failure.message,
          isError: true,
        ),
      ),
      (user) {
        if (user.emailVerified) {
          _autoCheck?.cancel();
          emit(state.copyWith(isChecking: false, verifiedUser: user));
        } else if (!silent) {
          emit(
            state.copyWith(
              isChecking: false,
              message: 'Tu correo aún no está verificado.',
              isError: true,
            ),
          );
        }
      },
    );
  }

  Future<void> resend() async {
    if (state.cooldown > 0 || state.isSending) return;
    emit(state.copyWith(isSending: true));

    final result = await _sendEmailVerification(const NoParams());
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSending: false,
          message: failure.message,
          isError: true,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            isSending: false,
            cooldown: 60,
            message: 'Te enviamos un nuevo correo de verificación.',
            isError: false,
          ),
        );
        _startCooldown();
      },
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) return timer.cancel();
      if (state.cooldown <= 1) {
        timer.cancel();
        emit(state.copyWith(cooldown: 0));
      } else {
        emit(state.copyWith(cooldown: state.cooldown - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _autoCheck?.cancel();
    _cooldownTimer?.cancel();
    return super.close();
  }
}
