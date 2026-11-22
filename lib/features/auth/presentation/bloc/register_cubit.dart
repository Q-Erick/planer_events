import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/usecases/auth_usecases.dart';

class RegisterState extends Equatable {
  const RegisterState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.showErrors = false,
    this.status = FormStatus.initial,
    this.errorMessage,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool showErrors;
  final FormStatus status;
  final String? errorMessage;

  bool get isLoading => status == FormStatus.loading;

  String? get nameError =>
      showErrors ? Validators.required(name, 'tu nombre') : null;
  String? get emailError => showErrors ? Validators.email(email) : null;
  String? get passwordError =>
      showErrors ? Validators.password(password) : null;
  String? get confirmError =>
      showErrors ? Validators.confirmPassword(confirmPassword, password) : null;

  bool get isValid =>
      Validators.required(name, '') == null &&
      Validators.email(email) == null &&
      Validators.password(password) == null &&
      Validators.confirmPassword(confirmPassword, password) == null;

  RegisterState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? showErrors,
    FormStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    confirmPassword,
    obscurePassword,
    showErrors,
    status,
    errorMessage,
  ];
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({required RegisterWithEmail registerWithEmail})
    : _registerWithEmail = registerWithEmail,
      super(const RegisterState());

  final RegisterWithEmail _registerWithEmail;

  void nameChanged(String v) => emit(state.copyWith(name: v));
  void emailChanged(String v) => emit(state.copyWith(email: v));
  void passwordChanged(String v) => emit(state.copyWith(password: v));
  void confirmPasswordChanged(String v) =>
      emit(state.copyWith(confirmPassword: v));
  void togglePasswordVisibility() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  Future<void> submit() async {
    if (state.isLoading) return;
    if (!state.isValid) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: FormStatus.loading));

    final result = await _registerWithEmail(
      RegisterParams(
        name: state.name,
        email: state.email,
        password: state.password,
      ),
    );
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
