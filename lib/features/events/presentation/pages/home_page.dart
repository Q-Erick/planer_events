import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/events_list_cubit.dart';
import '../widgets/event_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    if (user == null) return const Scaffold();

    return BlocProvider(
      create: (_) => sl<EventsListCubit>()..watch(user.uid),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis eventos'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push(AppRoutes.profile),
                child: UserAvatar(
                  name: user.name,
                  photoUrl: user.photoUrl,
                  radius: 18,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.newEvent),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo evento'),
        ),
        body: BlocBuilder<EventsListCubit, EventsListState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage != null && state.events.isEmpty) {
              return _Message(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudieron cargar tus eventos',
                subtitle: state.errorMessage!,
              );
            }
            if (state.events.isEmpty) {
              return _Message(
                icon: Icons.celebration_outlined,
                title: 'Aún no tienes eventos',
                subtitle: 'Crea tu primer evento con el botón "Nuevo evento".',
              );
            }

            // Responsivo: 1 columna en celular, hasta 3 en pantallas grandes
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 380).floor().clamp(
                  1,
                  3,
                );
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 112,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.events.length,
                  itemBuilder: (_, i) => EventCard(event: state.events[i]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
