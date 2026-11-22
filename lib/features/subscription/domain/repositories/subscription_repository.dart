import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/subscription_plan.dart';

abstract class SubscriptionRepository {
  /// Plan actual del usuario, en tiempo real.
  Stream<Either<Failure, PlanId>> watchCurrentPlan(String uid);

  /// Tokeniza la tarjeta capturada y contrata el plan en el servidor.
  Future<Either<Failure, Unit>> subscribe({
    required PlanId plan,
    required String email,
  });

  Future<Either<Failure, Unit>> cancel();
}
