import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../../guests/domain/entities/guest_entity.dart';
import '../../../guests/presentation/widgets/guest_form_sheet.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/services/seating_planner.dart';
import '../bloc/seating_cubit.dart';
import '../utils/table_geometry.dart';
import '../widgets/seating_sheets.dart';
import '../widgets/table_view.dart';

class SeatingPage extends StatelessWidget {
  const SeatingPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SeatingCubit>()..watch(eventId),
      child: _SeatingView(eventId: eventId),
    );
  }
}

class _SeatingView extends StatelessWidget {
  const _SeatingView({required this.eventId});

  final String eventId;

  // ---------------- Acciones ----------------

  Future<void> _addTable(BuildContext context) async {
    final cubit = context.read<SeatingCubit>();
    final shape = await showAddTableSheet(context, cubit.state.seatsPerTable);
    if (shape != null) await cubit.addTable(shape);
  }

  Future<void> _editSeatsPerTable(BuildContext context) async {
    final cubit = context.read<SeatingCubit>();
    final seats = await showSeatsPerTableDialog(
      context,
      cubit.state.seatsPerTable,
    );
    if (seats != null) await cubit.setSeatsPerTable(seats);
  }

  Future<void> _onSeatTap(
    BuildContext context,
    TableEntity table,
    int seat,
  ) async {
    final cubit = context.read<SeatingCubit>();
    final state = cubit.state;

    // 1. Silla ocupada: opciones para liberarla
    if (table.isSeatTaken(seat)) {
      final guest = state.guestsById[table.assignments[seat]];
      if (guest == null) {
        // El invitado ya no existe: liberamos la silla
        await cubit.releaseSeat(table, seat);
        return;
      }
      final action = await showOccupiedSeatSheet(
        context,
        guest: guest,
        seatsTaken: SeatingPlanner.seatedCount(state.tables, guest.id),
        tableNumber: table.number,
        seat: seat,
      );
      if (action == OccupiedSeatAction.releaseSeat) {
        await cubit.releaseSeat(table, seat);
      } else if (action == OccupiedSeatAction.releaseGroup) {
        await cubit.releaseGuest(guest);
      }
      return;
    }

    // 2. Hay un grupo pendiente: se sienta directamente aquí
    final pending = state.pendingGuest;
    if (pending != null && state.remainingOf(pending) > 0) {
      await cubit.assign(table, seat, pending, together: true);
      return;
    }

    // 3. Elegir invitado (o crear uno nuevo)
    final pick = await showPickGuestSheet(
      context,
      title: 'Mesa ${table.number} · silla ${seat + 1}',
      guests: state.guestsToSeat,
      remainingOf: state.remainingOf,
    );
    if (pick == null || !context.mounted) return;

    GuestEntity? guest = pick.guest;
    if (pick.createNew) {
      guest = await showGuestFormSheet(context, eventId: eventId);
      if (guest == null || !context.mounted) return;
    }
    if (guest == null) return;

    final remaining = pick.createNew
        ? guest.passes
        : cubit.state.remainingOf(guest);

    // 4. Si es grupo, preguntar si se sientan juntos
    var together = true;
    if (remaining > 1) {
      final choice = await askSeatTogether(
        context,
        guest: guest,
        remaining: remaining,
      );
      if (choice == null) return;
      together = choice;
    }

    await cubit.assign(table, seat, guest, together: together);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SeatingCubit>();

    return BlocConsumer<SeatingCubit, SeatingState>(
      listenWhen: (prev, curr) =>
          curr.message != null && prev.message != curr.message,
      listener: (context, state) =>
          showAppSnackBar(context, state.message!, isError: state.isError),
      builder: (context, state) {
        final isMoveMode = state.mode == SeatingMode.move;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Plano de mesas'),
            actions: [
              IconButton(
                tooltip: 'Sillas por mesa',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _editSeatsPerTable(context),
              ),
            ],
          ),
          floatingActionButton: isMoveMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addTable(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Mesa'),
                ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: SegmentedButton<SeatingMode>(
                        segments: const [
                          ButtonSegment(
                            value: SeatingMode.assign,
                            icon: Icon(Icons.touch_app_outlined),
                            label: Text('Asignar'),
                          ),
                          ButtonSegment(
                            value: SeatingMode.move,
                            icon: Icon(Icons.open_with),
                            label: Text('Mover mesas'),
                          ),
                        ],
                        selected: {state.mode},
                        onSelectionChanged: (v) => cubit.setMode(v.first),
                      ),
                    ),
                    _SummaryBar(state: state),
                    if (state.pendingGuest != null)
                      _PendingBanner(
                        guest: state.pendingGuest!,
                        remaining: state.remainingOf(state.pendingGuest!),
                        onDone: cubit.clearPending,
                      ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          cubit.fitToWidth(constraints.maxWidth);
                          return ClipRect(
                            child: InteractiveViewer(
                              transformationController:
                                  cubit.transformController,
                              constrained: false,
                              boundaryMargin: const EdgeInsets.all(300),
                              minScale: 0.2,
                              maxScale: 4,
                              // En modo mover, el plano queda fijo para
                              // que el arrastre sea de las mesas
                              panEnabled: !isMoveMode,
                              scaleEnabled: !isMoveMode,
                              child: _Venue(
                                state: state,
                                onSeatTap: (table, seat) =>
                                    _onSeatTap(context, table, seat),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Venue extends StatelessWidget {
  const _Venue({required this.state, required this.onSeatTap});

  final SeatingState state;
  final void Function(TableEntity table, int seat) onSeatTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<SeatingCubit>();
    final isMoveMode = state.mode == SeatingMode.move;

    return SizedBox.fromSize(
      size: kVenueSize,
      child: Stack(
        children: [
          // Salón
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border.all(color: scheme.outline, width: 2),
              ),
            ),
          ),
          if (state.tables.isEmpty)
            Center(
              child: Text(
                'Agrega tu primera mesa con el botón "Mesa".',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          // Mesas
          for (final table in state.tables)
            _positioned(
              table: table,
              child: isMoveMode
                  ? GestureDetector(
                      onPanUpdate: (d) => cubit.dragTable(table, d.delta),
                      onPanEnd: (_) => cubit.endDrag(table),
                      child: TableView(
                        table: table,
                        isDragging: state.draggingId == table.id,
                      ),
                    )
                  : TableView(
                      table: table,
                      highlightGuestId: state.pendingGuestId,
                      onTableTap: () =>
                          showTableOptionsSheet(context, table.id),
                      onSeatTap: (seat) => onSeatTap(table, seat),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _positioned({required TableEntity table, required Widget child}) {
    final geometry = TableGeometry.of(table.shape, table.seats);
    final position = state.positionOf(table);
    return Positioned(
      left: position.dx * kVenueSize.width - geometry.boxSize.width / 2,
      top: position.dy * kVenueSize.height - geometry.boxSize.height / 2,
      child: child,
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.state});

  final SeatingState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text('${state.tables.length} mesas'),
          const Spacer(),
          Icon(Icons.event_seat, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('Sentados ${state.totalSeated} / ${state.totalPasses}'),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.guest,
    required this.remaining,
    required this.onDone,
  });

  final GuestEntity guest;
  final int remaining;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Faltan $remaining de ${guest.name}. '
                'Toca una silla libre para sentarlos.',
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            TextButton(onPressed: onDone, child: const Text('Listo')),
          ],
        ),
      ),
    );
  }
}
