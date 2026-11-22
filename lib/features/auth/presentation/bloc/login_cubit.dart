import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.showErrors = false,
    this.status = FormStatus.initial,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool obscurePassword;
  final bool showErrors;
  final FormStatus status;
  final String? errorMessage;

  bool get isLoading => status == FormStatus.loading;

  String? get emailError => showErrors ? Validators.email(email) : null;
  String? get passwordError =>
      showErrors ? Validators.required(password, 'tu contraseña') : null;

  bool get isValid => Validators.email(email) == null && password.isNotEmpty;

  LoginState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? showErrors,
    FormStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    obscurePassword,
    showErrors,
    status,
    errorMessage,
  ];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required SignInWithEmail signInWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignInWithFacebook signInWithFacebook,
  }) : _signInWithEmail = signInWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signInWithFacebook = signInWithFacebook,
       super(const LoginState());

  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithFacebook _signInWithFacebook;

  void emailChanged(String value) => emit(state.copyWith(email: value));
  void passwordChanged(String value) => emit(state.copyWith(password: value));
  void togglePasswordVisibility() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  Future<void> submit() async {
    if (state.isLoading) return;
    if (!state.isValid) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: FormStatus.loading));
    _handle(
      await _signInWithEmail(
        SignInParams(email: state.email, password: state.password),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    if (state.isLoading) return;
    emit(state.copyWith(status: FormStatus.loading));
    _handle(await _signInWithGoogle(const NoParams()));
  }

  Future<void> signInWithFacebook() async {
    if (state.isLoading) return;
    emit(state.copyWith(status: FormStatus.loading));
    _handle(await _signInWithFacebook(const NoParams()));
  }

  void _handle(Either<Failure, UserEntity> result) {
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        failure is CancelledFailure
            ? state.copyWith(status: FormStatus.initial)
            : state.copyWith(
                status: FormStatus.failure,
                errorMessage: failure.message,
              ),
      ),
      // La navegación la hace el router al detectar la sesión.
      (_) => emit(state.copyWith(status: FormStatus.success)),
    );
  }
}
