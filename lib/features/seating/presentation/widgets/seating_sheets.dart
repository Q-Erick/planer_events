import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../guests/domain/entities/guest_entity.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/services/seating_planner.dart';
import '../bloc/seating_cubit.dart';
import '../utils/table_shape_ui.dart';

// ---------------- Cubits pequeños ----------------

class _TextCubit extends Cubit<String> {
  _TextCubit() : super('');
  void set(String value) => emit(value);
}

class _CounterCubit extends Cubit<int> {
  _CounterCubit(super.initial);
  void increment() {
    if (state < kMaxSeatsPerTable) emit(state + 1);
  }

  void decrement() {
    if (state > 1) emit(state - 1);
  }
}

// ---------------- Elegir invitado ----------------

class PickGuestResult {
  const PickGuestResult.guest(GuestEntity this.guest) : createNew = false;
  const PickGuestResult.createNew() : guest = null, createNew = true;

  final GuestEntity? guest;
  final bool createNew;
}

Future<PickGuestResult?> showPickGuestSheet(
  BuildContext context, {
  required String title,
  required List<GuestEntity> guests,
  required int Function(GuestEntity) remainingOf,
}) {
  return showModalBottomSheet<PickGuestResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => _TextCubit(),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.75,
        child: BlocBuilder<_TextCubit, String>(
          builder: (context, query) {
            final q = query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? guests
                : guests
                      .where((g) => g.name.toLowerCase().contains(q))
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: context.read<_TextCubit>().set,
                    decoration: const InputDecoration(
                      hintText: 'Buscar invitado',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_add)),
                  title: const Text('Nuevo invitado'),
                  subtitle: const Text('Crearlo y sentarlo aquí'),
                  onTap: () =>
                      Navigator.pop(context, const PickGuestResult.createNew()),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay invitados con lugares pendientes.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final guest = filtered[i];
                            final left = remainingOf(guest);
                            return ListTile(
                              leading: UserAvatar(name: guest.name),
                              title: Text(guest.name),
                              subtitle: Text(
                                'Faltan $left de ${guest.passes} lugares',
                              ),
                              onTap: () => Navigator.pop(
                                context,
                                PickGuestResult.guest(guest),
                              ),
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

// ---------------- ¿Juntos o solo una silla? ----------------

Future<bool?> askSeatTogether(
  BuildContext context, {
  required GuestEntity guest,
  required int remaining,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(guest.name),
      content: Text(
        'Tiene $remaining lugares sin asignar. ¿Cómo quieres sentarlos?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Solo esta silla'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text('Los $remaining juntos'),
        ),
      ],
    ),
  );
}

// ---------------- Silla ocupada ----------------

enum OccupiedSeatAction { releaseSeat, releaseGroup }

Future<OccupiedSeatAction?> showOccupiedSeatSheet(
  BuildContext context, {
  required GuestEntity guest,
  required int seatsTaken,
  required int tableNumber,
  required int seat,
}) {
  return showModalBottomSheet<OccupiedSeatAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: UserAvatar(name: guest.name),
            title: Text(guest.name),
            subtitle: Text(
              'Mesa $tableNumber · silla ${seat + 1} · '
              'ocupa $seatsTaken de ${guest.passes} lugares',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.event_seat_outlined),
            title: const Text('Quitar de esta silla'),
            onTap: () =>
                Navigator.pop(sheetContext, OccupiedSeatAction.releaseSeat),
          ),
          if (seatsTaken > 1)
            ListTile(
              leading: const Icon(Icons.group_remove_outlined),
              title: const Text('Quitar a todo el grupo'),
              onTap: () =>
                  Navigator.pop(sheetContext, OccupiedSeatAction.releaseGroup),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ---------------- Nueva mesa ----------------

Future<TableShape?> showAddTableSheet(BuildContext context, int seats) {
  return showModalBottomSheet<TableShape>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nueva mesa ($seats sillas)',
            style: Theme.of(sheetContext).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final shape in TableShape.values)
            ListTile(
              leading: Icon(shape.icon),
              title: Text(shape.label),
              onTap: () => Navigator.pop(sheetContext, shape),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ---------------- Sillas por mesa (global) ----------------

Future<int?> showSeatsPerTableDialog(BuildContext context, int current) {
  return showDialog<int>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => _CounterCubit(current),
      child: Builder(
        builder: (dialogContext) {
          final counter = dialogContext.read<_CounterCubit>();
          return AlertDialog(
            title: const Text('Sillas por mesa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Número de sillas con el que se crean las mesas nuevas. '
                  'Después puedes ajustar cada mesa por separado.',
                ),
                const SizedBox(height: 20),
                BlocBuilder<_CounterCubit, int>(
                  builder: (context, value) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.outlined(
                        onPressed: counter.decrement,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '$value',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: counter.increment,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                onPressed: () => Navigator.pop(dialogContext, counter.state),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// ---------------- Opciones de una mesa ----------------

Future<void> showTableOptionsSheet(BuildContext context, String tableId) {
  final cubit = context.read<SeatingCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _TableOptions(tableId: tableId),
    ),
  );
}

class _TableOptions extends StatelessWidget {
  const _TableOptions({required this.tableId});

  final String tableId;

  Future<void> _confirmDelete(BuildContext context, TableEntity table) async {
    final cubit = context.read<SeatingCubit>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Eliminar la mesa ${table.number}?'),
        content: Text(
          table.occupiedCount == 0
              ? 'La mesa está vacía.'
              : 'Las ${table.occupiedCount} personas sentadas quedarán sin lugar.',
        ),
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

    if (confirmed == true) {
      navigator.pop();
      await cubit.deleteTable(table);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SeatingCubit, SeatingState>(
      builder: (context, state) {
        final table = state.tables.where((t) => t.id == tableId).firstOrNull;
        if (table == null) return const SizedBox(height: 120);
        final cubit = context.read<SeatingCubit>();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Mesa ${table.number}',
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  '${table.occupiedCount} de ${table.seats} sillas ocupadas',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text('Forma', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<TableShape>(
                  showSelectedIcon: false,
                  segments: [
                    for (final shape in TableShape.values)
                      ButtonSegment(
                        value: shape,
                        icon: Icon(shape.icon),
                        label: Text(shape.label),
                      ),
                  ],
                  selected: {table.shape},
                  onSelectionChanged: (value) =>
                      cubit.changeShape(table, value.first),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('Sillas', style: theme.textTheme.titleSmall),
                    ),
                    IconButton.outlined(
                      onPressed: table.seats > 1
                          ? () => cubit.changeSeats(table, table.seats - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${table.seats}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: table.seats < kMaxSeatsPerTable
                          ? () => cubit.changeSeats(table, table.seats + 1)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => _confirmDelete(context, table),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar mesa'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
