import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_detail_cubit.dart';
import '../utils/event_type_ui.dart';
import '../widgets/event_location_map.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EventDetailCubit>()..watch(eventId),
      child: BlocConsumer<EventDetailCubit, EventDetailState>(
        listener: (context, state) {
          if (state.deleted) {
            showAppSnackBar(context, 'Evento eliminado.');
            context.pop();
          } else if (state.errorMessage != null && state.event != null) {
            showAppSnackBar(context, state.errorMessage!, isError: true);
          }
        },
        builder: (context, state) {
          final event = state.event;

          return Scaffold(
            appBar: AppBar(
              title: Text(event?.name ?? 'Evento'),
              actions: [
                if (event != null) ...[
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push(AppRoutes.eventEdit(event.id)),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: state.isDeleting
                        ? null
                        : () => _confirmDelete(context),
                  ),
                ],
              ],
            ),
            body: () {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (event == null) {
                return Center(
                  child: Text(state.errorMessage ?? 'Evento no encontrado.'),
                );
              }
              return _EventDetailBody(event: event);
            }(),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<EventDetailCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.delete();
  }
}

class _EventDetailBody extends StatelessWidget {
  const _EventDetailBody({required this.event});

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- Encabezado ----------
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(event.type.icon, color: scheme.onPrimary),
                        const SizedBox(width: 8),
                        Text(
                          event.type.label,
                          style: TextStyle(color: scheme.onPrimary),
                        ),
                        const Spacer(),
                        Text(
                          event.date.countdownLabel,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppDateFormat.long(event.date)}\n'
                      '${AppDateFormat.time(event.date)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---------- Datos ----------
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(
                        event.venueName.isEmpty ? 'Lugar' : event.venueName,
                      ),
                      subtitle: event.address.isEmpty
                          ? null
                          : Text(event.address),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: const Text('Invitados máximos'),
                      trailing: Text(
                        '${event.maxGuests}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---------- Mapa ----------
              if (event.hasLocation)
                EventLocationMap(
                  latitude: event.latitude!,
                  longitude: event.longitude!,
                  title: event.venueName.isEmpty ? event.name : event.venueName,
                ),
              const SizedBox(height: 24),

              // ---------- Módulos ----------
              Text('Organiza tu evento', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 500 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      const _ModuleTile(
                        icon: Icons.mail_outline,
                        label: 'Invitación',
                      ),
                      _ModuleTile(
                        icon: Icons.people_outline,
                        label: 'Invitados',
                        onTap: () => context.push(AppRoutes.guests(event.id)),
                      ),
                      const _ModuleTile(
                        icon: Icons.table_restaurant_outlined,
                        label: 'Plano de mesas',
                      ),
                      const _ModuleTile(
                        icon: Icons.qr_code_scanner,
                        label: 'Recepción',
                      ),
                      const _ModuleTile(
                        icon: Icons.photo_library_outlined,
                        label: 'Álbum',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => showAppSnackBar(context, 'Próximamente.'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: scheme.primary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
