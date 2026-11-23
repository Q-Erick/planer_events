import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/invitation_config.dart';
import '../bloc/invitation_editor_cubit.dart';
import '../widgets/invitation_view.dart';

class InvitationEditorPage extends StatelessWidget {
  const InvitationEditorPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvitationEditorCubit>()..load(eventId),
      child: BlocConsumer<InvitationEditorCubit, InvitationEditorState>(
        listenWhen: (prev, curr) =>
            curr.message != null && prev.message != curr.message,
        listener: (context, state) =>
            showAppSnackBar(context, state.message!, isError: state.isError),
        buildWhen: (prev, curr) =>
            prev.isLoading != curr.isLoading ||
            prev.isSaving != curr.isSaving ||
            prev.hasChanges != curr.hasChanges,
        builder: (context, state) {
          final cubit = context.read<InvitationEditorCubit>();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Invitación'),
              actions: [
                if (!state.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: state.isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : TextButton.icon(
                            onPressed: state.hasChanges ? cubit.save : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Guardar'),
                          ),
                  ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Pantalla grande: editor y vista previa lado a lado
                      if (constraints.maxWidth >= 900) {
                        return const Row(
                          children: [
                            SizedBox(width: 460, child: _EditorForm()),
                            VerticalDivider(width: 1),
                            Expanded(child: _Preview()),
                          ],
                        );
                      }
                      // Celular: pestañas
                      return const DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              tabs: [
                                Tab(icon: Icon(Icons.tune), text: 'Diseño'),
                                Tab(
                                  icon: Icon(Icons.visibility_outlined),
                                  text: 'Vista previa',
                                ),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [_EditorForm(), _Preview()],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

// ---------------- Vista previa ----------------

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvitationEditorCubit, InvitationEditorState>(
      builder: (context, state) {
        final event = state.event;
        if (event == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: InvitationView(event: event, config: state.config),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------- Formulario ----------------

class _EditorForm extends StatelessWidget {
  const _EditorForm();

  Future<void> _pickTime(BuildContext context, ItineraryItem item) async {
    final cubit = context.read<InvitationEditorCubit>();
    final parts = item.time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 20,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      cubit.updateItineraryItem(item.id, time: '$h:$m');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<InvitationEditorCubit>();

    return BlocBuilder<InvitationEditorCubit, InvitationEditorState>(
      builder: (context, state) {
        final c = state.config;

        Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Text(text, style: theme.textTheme.titleMedium),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ---------- Contenido ----------
            sectionTitle('Contenido'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Mensaje de bienvenida'),
                    value: c.showMessage,
                    onChanged: cubit.toggleMessage,
                  ),
                  if (c.showMessage)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextFormField(
                        initialValue: c.message,
                        onChanged: cubit.messageChanged,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje para tus invitados',
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Cuenta regresiva'),
                    value: c.showCountdown,
                    onChanged: cubit.toggleCountdown,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Ubicación y mapa'),
                    value: c.showLocation,
                    onChanged: cubit.toggleLocation,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Itinerario'),
                    value: c.showItinerary,
                    onChanged: cubit.toggleItinerary,
                  ),
                  if (c.showItinerary)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                      child: Column(
                        children: [
                          for (final item in c.itinerary)
                            Padding(
                              key: ValueKey(item.id),
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(80, 48),
                                    ),
                                    onPressed: () => _pickTime(context, item),
                                    child: Text(
                                      item.time.isEmpty ? 'Hora' : item.time,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item.title,
                                      onChanged: (v) =>
                                          cubit.updateItineraryItem(
                                            item.id,
                                            title: v,
                                          ),
                                      decoration: const InputDecoration(
                                        hintText: 'Actividad',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Quitar',
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        cubit.removeItineraryItem(item.id),
                                  ),
                                ],
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: cubit.addItineraryItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar actividad'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Código de vestimenta'),
                    value: c.showDressCode,
                    onChanged: cubit.toggleDressCode,
                  ),
                  if (c.showDressCode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextFormField(
                        initialValue: c.dressCode,
                        onChanged: cubit.dressCodeChanged,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Formal, coctel, blanco y negro...',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---------- Tipografía ----------
            sectionTitle('Tipografía'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final font in kInvitationFonts)
                  ChoiceChip(
                    label: Text(
                      font,
                      style: GoogleFonts.getFont(font, fontSize: 16),
                    ),
                    selected: c.fontFamily == font,
                    onSelected: (_) => cubit.fontChanged(font),
                  ),
              ],
            ),

            // ---------- Color ----------
            sectionTitle('Color principal'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in kInvitationColors)
                  GestureDetector(
                    onTap: () => cubit.colorChanged(color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.colorValue == color
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: c.colorValue == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),

            // ---------- Fondo ----------
            sectionTitle('Imagen de fondo'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (c.hasBackground)
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: c.backgroundUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (state.isUploading) const LinearProgressIndicator(),
                  ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(
                      c.hasBackground ? 'Cambiar imagen' : 'Elegir imagen',
                    ),
                    onTap: state.isUploading ? null : cubit.pickBackground,
                  ),
                  if (c.hasBackground)
                    ListTile(
                      leading: const Icon(Icons.hide_image_outlined),
                      title: const Text('Quitar imagen'),
                      onTap: cubit.removeBackground,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
