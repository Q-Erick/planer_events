import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../guests/domain/entities/guest_entity.dart';
import '../../domain/services/seat_locator.dart';

// ---------------- Pantalla bloqueada ----------------

class LockedView extends StatelessWidget {
  const LockedView({
    super.key,
    required this.isAuthenticating,
    required this.error,
    required this.onUnlock,
  });

  final bool isAuthenticating;
  final String? error;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text('Modo recepción', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Verifica tu identidad con tu huella o el bloqueo de tu celular.',
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isAuthenticating ? null : onUnlock,
                icon: const Icon(Icons.lock_open),
                label: const Text('Desbloquear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Resultado del escaneo ----------------

class CheckInResultCard extends StatelessWidget {
  const CheckInResultCard({
    super.key,
    required this.guest,
    required this.seats,
    required this.isSaving,
    required this.onConfirm,
    required this.onCancel,
  });

  final GuestEntity guest;
  final List<SeatLocation> seats;
  final bool isSaving;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UserAvatar(name: guest.name, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guest.name, style: theme.textTheme.titleLarge),
                      Text(
                        guest.passes == 1
                            ? '1 lugar'
                            : '${guest.passes} lugares',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mesa y sillas
            if (seats.isEmpty)
              Text(
                'Sin lugar asignado en el plano.',
                style: TextStyle(color: scheme.error),
              )
            else
              for (final s in seats)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Mesa ${s.tableNumber} · '
                    '${s.seats.length == 1 ? 'silla' : 'sillas'} '
                    '${s.seats.join(', ')}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
            // Aviso si el pase ya se usó
            if (guest.checkedIn) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  guest.checkedInAt != null
                      ? 'Este pase ya se registró a las '
                            '${AppDateFormat.time(guest.checkedInAt!)}.'
                      : 'Este pase ya se registró.',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: guest.checkedIn || isSaving ? null : onConfirm,
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Registrar llegada'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Buscar por nombre ----------------

class _QueryCubit extends Cubit<String> {
  _QueryCubit() : super('');
  void set(String v) => emit(v);
}

Future<GuestEntity?> showGuestSearchSheet(
  BuildContext context,
  List<GuestEntity> guests,
) {
  return showModalBottomSheet<GuestEntity>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => _QueryCubit(),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.75,
        child: BlocBuilder<_QueryCubit, String>(
          builder: (context, query) {
            final q = query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? guests
                : guests
                      .where((g) => g.name.toLowerCase().contains(q))
                      .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    autofocus: true,
                    onChanged: context.read<_QueryCubit>().set,
                    decoration: const InputDecoration(
                      hintText: 'Buscar invitado',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final guest = filtered[i];
                      return ListTile(
                        leading: UserAvatar(name: guest.name),
                        title: Text(guest.name),
                        subtitle: Text(
                          guest.checkedIn ? 'Ya llegó' : 'Pendiente',
                        ),
                        trailing: guest.checkedIn
                            ? const Icon(Icons.check_circle)
                            : null,
                        onTap: () => Navigator.pop(context, guest),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
