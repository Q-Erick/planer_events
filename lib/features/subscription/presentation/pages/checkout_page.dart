import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' show CardField;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_layout.dart';
import '../../domain/entities/subscription_plan.dart';
import '../bloc/subscription_cubit.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, required this.planId});

  final PlanId planId;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null) return const Scaffold();

    final plan = planById(planId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider(
      create: (_) => sl<SubscriptionCubit>()..watch(user.uid),
      child: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listenWhen: (prev, curr) =>
            (curr.message != null && prev.message != curr.message) ||
            prev.paidPlan != curr.paidPlan,
        listener: (context, state) {
          if (state.message != null) {
            showAppSnackBar(context, state.message!, isError: state.isError);
          }
          if (state.paidPlan != null) context.pop();
        },
        builder: (context, state) {
          final cubit = context.read<SubscriptionCubit>();

          return Scaffold(
            appBar: AppBar(title: const Text('Pago')),
            body: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Resumen
                      Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.workspace_premium,
                            color: scheme.primary,
                            size: 36,
                          ),
                          title: Text(
                            'Plan ${plan.name}',
                            style: theme.textTheme.titleLarge,
                          ),
                          subtitle: Text('\$${plan.price} MXN al mes'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Datos de la tarjeta',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      // Formulario NATIVO de Stripe: valida número,
                      // fecha y CVC sin que los datos pasen por nuestro código
                      CardField(
                        enablePostalCode: false,
                        style: TextStyle(color: scheme.onSurface),
                        cursorColor: scheme.primary,
                        onCardChanged: (details) =>
                            cubit.cardChanged(details?.complete ?? false),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escribe el número; después aparecen la fecha (MM/AA) '
                        'y el CVC.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      // Ayuda para pruebas
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Modo de prueba: usa la tarjeta 4242 4242 4242 4242, '
                          'cualquier fecha futura y cualquier CVC.',
                          style: TextStyle(color: scheme.onSecondaryContainer),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        label: 'Pagar \$${plan.price} MXN',
                        isLoading: state.isPaying,
                        onPressed: () => cubit.pay(plan.id, user.email),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: scheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pago seguro procesado por Stripe',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
