import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either_stream.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/stripe_datasource.dart';
import '../datasources/subscription_api_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required FirebaseFirestore firestore,
    required StripeDataSource stripe,
    required SubscriptionApiDataSource api,
  }) : _firestore = firestore,
       _stripe = stripe,
       _api = api;

  final FirebaseFirestore _firestore;
  final StripeDataSource _stripe;
  final SubscriptionApiDataSource _api;

  @override
  Stream<Either<Failure, PlanId>> watchCurrentPlan(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => planIdFrom(doc.data()?['plan'] as String?))
        .toEither();
  }

  @override
  Future<Either<Failure, Unit>> subscribe({
    required PlanId plan,
    required String email,
  }) => _guard(() async {
    // 1. Stripe tokeniza la tarjeta (no pasa por nuestro servidor)
    final paymentMethodId = await _stripe.createCardPaymentMethod(email);
    // 2. El servidor cobra y actualiza el plan en Firestore
    await _api.subscribe(planId: plan.name, paymentMethodId: paymentMethodId);
  });

  @override
  Future<Either<Failure, Unit>> cancel() => _guard(_api.cancel);

  Future<Either<Failure, Unit>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return right(unit);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (_) {
      return left(const ServerFailure('No se pudo completar el pago.'));
    }
  }
}
