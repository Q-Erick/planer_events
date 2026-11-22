import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/usecases/auth_usecases.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.email = '',
    this.showErrors = false,
    this.status = FormStatus.initial,
    this.errorMessage,
  });

  final String email;
  final bool showErrors;
  final FormStatus status;
  final String? errorMessage;

  bool get isLoading => status == FormStatus.loading;
  String? get emailError => showErrors ? Validators.email(email) : null;

  ForgotPasswordState copyWith({
    String? email,
    bool? showErrors,
    FormStatus? status,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, showErrors, status, errorMessage];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({required SendPasswordReset sendPasswordReset})
    : _sendPasswordReset = sendPasswordReset,
      super(const ForgotPasswordState());

  final SendPasswordReset _sendPasswordReset;

  void emailChanged(String v) => emit(state.copyWith(email: v));

  Future<void> submit() async {
    if (state.isLoading) return;
    if (Validators.email(state.email) != null) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: FormStatus.loading));

    final result = await _sendPasswordReset(state.email);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: FormStatus.success)),
    );
  }
}
