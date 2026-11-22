import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_layout.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_form_cubit.dart';
import '../utils/event_type_ui.dart';

class EventFormPage extends StatelessWidget {
  const EventFormPage({super.key, this.eventId});

  final String? eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<EventFormCubit>();
        if (eventId != null) cubit.load(eventId!);
        return cubit;
      },
      child: BlocListener<EventFormCubit, EventFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == FormStatus.failure) {
            showAppSnackBar(
              context,
              state.errorMessage ?? 'Ocurrió un error.',
              isError: true,
            );
          }
          if (state.status == FormStatus.success) {
            if (state.isEditing) {
              context.pop();
            } else {
              context.pushReplacement(
                AppRoutes.eventDetail(state.savedEventId!),
              );
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(eventId == null ? 'Nuevo evento' : 'Editar evento'),
          ),
          body: BlocBuilder<EventFormCubit, EventFormState>(
            buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return const _EventForm();
            },
          ),
        ),
      ),
    );
  }
}

class _EventForm extends StatelessWidget {
  const _EventForm();

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final cubit = context.read<EventFormCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) cubit.dateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context, DateTime current) async {
    final cubit = context.read<EventFormCubit>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked != null) cubit.timeChanged(picked.hour, picked.minute);
  }

  Future<void> _pickLocation(BuildContext context, EventFormState s) async {
    final cubit = context.read<EventFormCubit>();
    final result = await context.push<LatLng>(
      AppRoutes.locationPicker,
      extra: s.hasLocation ? LatLng(s.latitude!, s.longitude!) : null,
    );
    if (result != null) {
      cubit.locationChanged(result.latitude, result.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();
    final theme = Theme.of(context);

    return BlocBuilder<EventFormCubit, EventFormState>(
      builder: (context, state) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- Tipo ----------
                  Text('Tipo de evento', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventType.values.map((type) {
                      return ChoiceChip(
                        avatar: Icon(type.icon, size: 18),
                        label: Text(type.label),
                        selected: state.type == type,
                        onSelected: (_) => cubit.typeChanged(type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ---------- Datos generales ----------
                  TextFormField(
                    initialValue: state.name,
                    onChanged: cubit.nameChanged,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Nombre del evento',
                      hintText: 'Ej. Boda de Ana y Luis',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      errorText: state.nameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.maxGuests,
                    onChanged: cubit.maxGuestsChanged,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Número máximo de invitados',
                      prefixIcon: const Icon(Icons.groups_outlined),
                      errorText: state.guestsError,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------- Fecha y hora ----------
                  Text('Fecha y hora', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(context, state.date),
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(AppDateFormat.short(state.date)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(context, state.date),
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(AppDateFormat.time(state.date)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---------- Lugar ----------
                  Text('Lugar', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: state.venueName,
                    onChanged: cubit.venueNameChanged,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del salón o lugar',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.address,
                    onChanged: cubit.addressChanged,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        state.hasLocation
                            ? Icons.check_circle
                            : Icons.map_outlined,
                        color: state.hasLocation
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        state.hasLocation
                            ? 'Ubicación seleccionada'
                            : 'Elegir ubicación en el mapa',
                      ),
                      subtitle: state.locationError != null
                          ? Text(
                              state.locationError!,
                              style: TextStyle(color: theme.colorScheme.error),
                            )
                          : state.hasLocation
                          ? Text(
                              '${state.latitude!.toStringAsFixed(5)}, '
                              '${state.longitude!.toStringAsFixed(5)}',
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickLocation(context, state),
                    ),
                  ),
                  const SizedBox(height: 28),

                  LoadingButton(
                    label: state.isEditing ? 'Guardar cambios' : 'Crear evento',
                    isLoading: state.isSaving,
                    onPressed: () =>
                        cubit.save(context.read<AuthBloc>().state.user!.uid),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
