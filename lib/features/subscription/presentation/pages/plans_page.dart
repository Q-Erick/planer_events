import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/subscription_plan.dart';
import '../bloc/subscription_cubit.dart';
import '../widgets/plan_card.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthBloc b) => b.state.user?.uid);
    if (uid == null) return const Scaffold();

    return BlocProvider(
      create: (_) => sl<SubscriptionCubit>()..watch(uid),
      child: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listenWhen: (prev, curr) =>
            curr.message != null && prev.message != curr.message,
        listener: (context, state) =>
            showAppSnackBar(context, state.message!, isError: state.isError),
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Planes')),
            body: state.isLoadingPlan
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsivo: 1 columna en celular, 2 o 4 en pantallas grandes
                      final columns = constraints.maxWidth >= 1100
                          ? 4
                          : constraints.maxWidth >= 700
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - 32 - (columns - 1) * 12) /
                          columns;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final plan in kPlans)
                                  SizedBox(
                                    width: width,
                                    child: PlanCard(
                                      plan: plan,
                                      isCurrent: plan.id == state.currentPlan,
                                      onSelect: () => context.push(
                                        AppRoutes.checkout(plan.id.name),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (state.currentPlan != PlanId.free) ...[
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: state.isCancelling
                                    ? null
                                    : () => _confirmCancel(context),
                                child: const Text('Cancelar suscripción'),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<SubscriptionCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cancelar suscripción?'),
        content: const Text('Tu cuenta regresará al plan Gratis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.cancel();
  }
}
