import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/widgets/auth_layout.dart';
import '../../domain/entities/guest_entity.dart';
import '../bloc/guest_form_cubit.dart';

/// Abre el formulario. Devuelve el id del invitado guardado.
Future<String?> showGuestFormSheet(
  BuildContext context, {
  required String eventId,
  GuestEntity? guest,
  String initialName = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          sl<GuestFormCubit>()
            ..start(eventId: eventId, guest: guest, initialName: initialName),
      child: const _GuestFormSheet(),
    ),
  );
}

class _GuestFormSheet extends StatelessWidget {
  const _GuestFormSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<GuestFormCubit, GuestFormState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          Navigator.of(context).pop(state.savedGuestId);
        } else if (state.status == FormStatus.failure) {
          showAppSnackBar(
            context,
            state.errorMessage ?? 'Ocurrió un error.',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<GuestFormCubit>();

        return Padding(
          // Sube el formulario cuando aparece el teclado
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.isEditing ? 'Editar invitado' : 'Nuevo invitado',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: state.name,
                    onChanged: cubit.nameChanged,
                    autofocus: !state.isEditing,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre o grupo',
                      hintText: 'Ej. Juan López o Familia Pérez',
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: state.nameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.phone,
                    onChanged: cubit.phoneChanged,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Contador de lugares
                  Row(
                    children: [
                      const Icon(Icons.event_seat_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lugares',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: state.passes > 1 ? cubit.decrement : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${state.passes}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: cubit.increment,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    label: state.isEditing ? 'Guardar cambios' : 'Agregar',
                    isLoading: state.isSaving,
                    onPressed: cubit.save,
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
