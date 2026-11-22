import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetAuthStateChanges getAuthStateChanges,
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
  }) : _getAuthStateChanges = getAuthStateChanges,
       _signOut = signOut,
       super(_initialState(getCurrentUser())) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthUserRefreshed>(
      (event, emit) => emit(AuthState.authenticated(event.user)),
    );
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final GetAuthStateChanges _getAuthStateChanges;
  final SignOut _signOut;

  /// Firebase ya sabe si hay sesión al abrir la app.
  static AuthState _initialState(UserEntity? user) => user == null
      ? const AuthState.unauthenticated()
      : AuthState.authenticated(user);

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) {
    return emit.onEach<UserEntity?>(
      _getAuthStateChanges(),
      onData: (user) => emit(_initialState(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _signOut(const NoParams());
  }
}
