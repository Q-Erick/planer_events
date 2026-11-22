import 'package:material_ui/material_ui.dart';

import '../../domain/entities/subscription_plan.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final bool isCurrent;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: plan.highlighted ? scheme.primary : scheme.outlineVariant,
          width: plan.highlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name, style: theme.textTheme.headlineSmall),
                const Spacer(),
                if (plan.highlighted)
                  Chip(
                    label: const Text('Recomendado'),
                    backgroundColor: scheme.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: plan.isFree ? 'Gratis' : '\$${plan.price} MXN',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  if (!plan.isFree)
                    TextSpan(text: ' / mes', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: const Text('Tu plan actual'),
                    )
                  : plan.isFree
                  ? const SizedBox.shrink()
                  : FilledButton(
                      onPressed: onSelect,
                      child: const Text('Elegir plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
