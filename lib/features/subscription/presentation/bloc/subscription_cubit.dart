import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/usecases/subscription_usecases.dart';

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.currentPlan = PlanId.free,
    this.isLoadingPlan = true,
    this.cardComplete = false,
    this.isPaying = false,
    this.isCancelling = false,
    this.paidPlan,
    this.message,
    this.isError = false,
  });

  final PlanId currentPlan;
  final bool isLoadingPlan;

  /// El CardField nativo indica si los datos están completos.
  final bool cardComplete;
  final bool isPaying;
  final bool isCancelling;

  /// Se llena cuando un pago termina bien.
  final PlanId? paidPlan;
  final String? message;
  final bool isError;

  SubscriptionState copyWith({
    PlanId? currentPlan,
    bool? isLoadingPlan,
    bool? cardComplete,
    bool? isPaying,
    bool? isCancelling,
    PlanId? paidPlan,
    String? message,
    bool? isError,
  }) {
    return SubscriptionState(
      currentPlan: currentPlan ?? this.currentPlan,
      isLoadingPlan: isLoadingPlan ?? this.isLoadingPlan,
      cardComplete: cardComplete ?? this.cardComplete,
      isPaying: isPaying ?? this.isPaying,
      isCancelling: isCancelling ?? this.isCancelling,
      paidPlan: paidPlan ?? this.paidPlan,
      message: message,
      isError: isError ?? false,
    );
  }

  @override
  List<Object?> get props => [
    currentPlan,
    isLoadingPlan,
    cardComplete,
    isPaying,
    isCancelling,
    paidPlan,
    message,
    isError,
  ];
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required WatchCurrentPlan watchCurrentPlan,
    required SubscribeToPlan subscribeToPlan,
    required CancelSubscription cancelSubscription,
  }) : _watchCurrentPlan = watchCurrentPlan,
       _subscribeToPlan = subscribeToPlan,
       _cancelSubscription = cancelSubscription,
       super(const SubscriptionState());

  final WatchCurrentPlan _watchCurrentPlan;
  final SubscribeToPlan _subscribeToPlan;
  final CancelSubscription _cancelSubscription;
  StreamSubscription<dynamic>? _subscription;

  void watch(String uid) {
    _subscription = _watchCurrentPlan(uid).listen((result) {
      result.fold(
        (f) => emit(state.copyWith(isLoadingPlan: false, message: f.message)),
        (plan) => emit(state.copyWith(isLoadingPlan: false, currentPlan: plan)),
      );
    });
  }

  void cardChanged(bool complete) =>
      emit(state.copyWith(cardComplete: complete));

  Future<void> pay(PlanId plan, String email) async {
    if (state.isPaying) return;
    if (!state.cardComplete) {
      emit(
        state.copyWith(
          message: 'Completa los datos de la tarjeta.',
          isError: true,
        ),
      );
      return;
    }
    emit(state.copyWith(isPaying: true));

    final result = await _subscribeToPlan(
      SubscribeParams(plan: plan, email: email),
    );
    if (isClosed) return;

    result.fold(
      (f) => emit(
        state.copyWith(isPaying: false, message: f.message, isError: true),
      ),
      (_) => emit(
        state.copyWith(
          isPaying: false,
          paidPlan: plan,
          message: '¡Listo! Ahora tienes el plan ${planById(plan).name}.',
        ),
      ),
    );
  }

  Future<void> cancel() async {
    if (state.isCancelling) return;
    emit(state.copyWith(isCancelling: true));

    final result = await _cancelSubscription(const NoParams());
    if (isClosed) return;

    result.fold(
      (f) => emit(
        state.copyWith(isCancelling: false, message: f.message, isError: true),
      ),
      (_) => emit(
        state.copyWith(
          isCancelling: false,
          message: 'Tu suscripción fue cancelada.',
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
