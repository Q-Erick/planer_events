import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/album_cubit.dart';
import 'photo_viewer_page.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AlbumCubit>()..watch(eventId),
      child: const _AlbumView(),
    );
  }
}

class _AlbumView extends StatelessWidget {
  const _AlbumView();

  Future<void> _addPhotos(BuildContext context) async {
    final cubit = context.read<AlbumCubit>();
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              subtitle: const Text('Puedes seleccionar varias'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );

    if (fromCamera == true) await cubit.takePhoto(user);
    if (fromCamera == false) await cubit.pickFromGallery(user);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AlbumCubit>();
    final uid = context.select((AuthBloc b) => b.state.user?.uid);

    return BlocConsumer<AlbumCubit, AlbumState>(
      listenWhen: (prev, curr) =>
          curr.message != null && prev.message != curr.message,
      listener: (context, state) =>
          showAppSnackBar(context, state.message!, isError: state.isError),
      builder: (context, state) {
        final isHost = state.event?.hostId == uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.photos.isEmpty ? 'Álbum' : 'Álbum (${state.photos.length})',
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.event == null ? null : () => _addPhotos(context),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Agregar'),
          ),
          body: Column(
            children: [
              if (state.uploadingCount > 0) ...[
                const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    state.uploadingCount == 1
                        ? 'Subiendo 1 foto...'
                        : 'Subiendo ${state.uploadingCount} fotos...',
                  ),
                ),
              ],
              if (state.event != null && !state.event!.isToday)
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  color: theme.colorScheme.secondaryContainer,
                  child: const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text(
                      'Tus invitados podrán subir fotos el día del evento.',
                    ),
                  ),
                ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.photos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 72,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aún no hay fotos',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Las fotos que tomen tú y tus invitados '
                                'aparecerán aquí.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    // Responsivo: más columnas en pantallas grandes
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 96),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 160,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                        itemCount: state.photos.length,
                        itemBuilder: (context, i) {
                          final photo = state.photos[i];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PhotoViewerPage(
                                  photos: state.photos,
                                  initialIndex: i,
                                  onDelete: isHost ? cubit.delete : null,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: photo.url,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => ColoredBox(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined),
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
