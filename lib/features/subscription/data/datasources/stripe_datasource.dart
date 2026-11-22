import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../core/errors/exceptions.dart';

abstract class StripeDataSource {
  /// Devuelve el id del método de pago (pm_...).
  Future<String> createCardPaymentMethod(String email);
}

class StripeDataSourceImpl implements StripeDataSource {
  @override
  Future<String> createCardPaymentMethod(String email) async {
    try {
      final method = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(email: email),
          ),
        ),
      );
      return method.id;
    } on StripeException catch (e) {
      throw ServerException(
        e.error.localizedMessage ?? 'Revisa los datos de la tarjeta.',
      );
    }
  }
}
