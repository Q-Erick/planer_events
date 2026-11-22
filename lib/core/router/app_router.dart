import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/theme_cubit.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/';
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _TemporaryHomePage(),
      ),
    ],
  );
}

/// Página temporal para probar tema y fuentes. Se reemplaza en la Parte 3.
class _TemporaryHomePage extends StatelessWidget {
  const _TemporaryHomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planer Events'),
        actions: [
          IconButton(
            tooltip: 'Cambiar tema',
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () =>
                context.read<ThemeCubit>().toggle(theme.brightness),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tu evento, perfecto',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Invitaciones, mesas y fotos en un solo lugar.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(onPressed: () {}, child: const Text('Comenzar')),
            ],
          ),
        ),
      ),
    );
  }
}
