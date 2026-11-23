import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/guest_entity.dart';
import '../bloc/guests_cubit.dart';
import '../widgets/guest_form_sheet.dart';
import '../widgets/guest_qr_dialog.dart';
import '../../../../core/router/app_router.dart';

enum _GuestAction { qr, invitation, copyCode, edit, delete }

class GuestsPage extends StatelessWidget {
  const GuestsPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GuestsCubit>()..watch(eventId),
      child: BlocListener<GuestsCubit, GuestsState>(
        listenWhen: (prev, curr) =>
            curr.message != null && prev.message != curr.message,
        listener: (context, state) => showAppSnackBar(context, state.message!),
        child: Scaffold(
          appBar: AppBar(title: const Text('Invitados')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showGuestFormSheet(context, eventId: eventId),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Agregar'),
          ),
          body: BlocBuilder<GuestsCubit, GuestsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    children: [
                      _Summary(state: state),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: TextField(
                          onChanged: context.read<GuestsCubit>().search,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por nombre o teléfono',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      Expanded(
                        child: state.guests.isEmpty
                            ? const _EmptyGuests()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                                itemCount: state.filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) =>
                                    _GuestTile(guest: state.filtered[i]),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final GuestsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = state.isOverCapacity ? scheme.error : scheme.primary;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Invitaciones',
                value: '${state.guests.length}',
              ),
            ),
            Expanded(
              child: _Stat(
                label: 'Lugares',
                value: '${state.totalPasses} / ${state.maxGuests}',
                color: color,
              ),
            ),
            if (state.isOverCapacity)
              Tooltip(
                message: 'Superas el máximo de invitados del evento.',
                child: Icon(Icons.warning_amber_rounded, color: scheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({required this.guest});

  final GuestEntity guest;

  Future<void> _onAction(BuildContext context, _GuestAction action) async {
    switch (action) {
      case _GuestAction.invitation:
        await context.push(AppRoutes.guestInvitation(guest.eventId, guest.id));
      case _GuestAction.copyCode:
        await Clipboard.setData(ClipboardData(text: guest.qrData));
        if (context.mounted) {
          showAppSnackBar(
            context,
            'Código copiado. Envíalo a ${guest.name} para que abra su invitación.',
          );
        }
      case _GuestAction.qr:
        await showGuestQrDialog(context, guest);
      case _GuestAction.edit:
        await showGuestFormSheet(context, eventId: guest.eventId, guest: guest);
      case _GuestAction.delete:
        final cubit = context.read<GuestsCubit>();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('¿Eliminar invitado?'),
            content: Text('Se eliminará a ${guest.name} y su pase.'),
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
        if (confirmed == true) await cubit.delete(guest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seated = context.select(
      (GuestsCubit cubit) => cubit.state.seatedOf(guest.id),
    );
    final subtitle = [
      '$seated/${guest.passes} sentados',
      if (guest.phone.isNotEmpty) guest.phone,
    ].join(' · ');

    return ListTile(
      leading: UserAvatar(name: guest.name),
      title: Text(guest.name),
      subtitle: Text(subtitle),
      onTap: () => showGuestQrDialog(context, guest),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (guest.checkedIn)
            Icon(Icons.check_circle, color: scheme.primary, size: 20),
          PopupMenuButton<_GuestAction>(
            onSelected: (action) => _onAction(context, action),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _GuestAction.qr,
                child: ListTile(
                  leading: Icon(Icons.qr_code_2),
                  title: Text('Ver pase QR'),
                ),
              ),
              PopupMenuItem(
                value: _GuestAction.invitation,
                child: ListTile(
                  leading: Icon(Icons.mail_outline),
                  title: Text('Ver su invitación'),
                ),
              ),
              PopupMenuItem(
                value: _GuestAction.copyCode,
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copiar código'),
                ),
              ),
              PopupMenuItem(
                value: _GuestAction.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),
              PopupMenuItem(
                value: _GuestAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Eliminar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyGuests extends StatelessWidget {
  const _EmptyGuests();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Aún no hay invitados', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Agrega personas o grupos con el botón "Agregar".',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
