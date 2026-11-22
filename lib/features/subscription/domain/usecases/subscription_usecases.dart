import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/subscription_plan.dart';
import '../repositories/subscription_repository.dart';

class SubscribeParams extends Equatable {
  const SubscribeParams({required this.plan, required this.email});
  final PlanId plan;
  final String email;

  @override
  List<Object> get props => [plan, email];
}

class WatchCurrentPlan implements StreamUseCase<PlanId, String> {
  const WatchCurrentPlan(this._repository);
  final SubscriptionRepository _repository;

  @override
  Stream<Either<Failure, PlanId>> call(String uid) =>
      _repository.watchCurrentPlan(uid);
}

class SubscribeToPlan implements UseCase<Unit, SubscribeParams> {
  const SubscribeToPlan(this._repository);
  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SubscribeParams p) async {
    if (p.plan == PlanId.free) {
      return left(const ServerFailure('El plan gratis no requiere pago.'));
    }
    return _repository.subscribe(plan: p.plan, email: p.email);
  }
}

class CancelSubscription implements UseCase<Unit, NoParams> {
  const CancelSubscription(this._repository);
  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.cancel();
}
