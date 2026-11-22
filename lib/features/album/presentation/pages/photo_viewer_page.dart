import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_format.dart';
import '../../domain/entities/photo_entity.dart';

class PhotoViewerPage extends StatelessWidget {
  PhotoViewerPage({
    super.key,
    required this.photos,
    required int initialIndex,
    this.onDelete,
  }) : _controller = PageController(initialPage: initialIndex);

  final List<PhotoEntity> photos;
  final Future<void> Function(PhotoEntity photo)? onDelete;
  final PageController _controller;

  Future<void> _confirmDelete(BuildContext context) async {
    final index = _controller.page?.round() ?? 0;
    final photo = photos[index];
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar foto?'),
        content: const Text('Se quitará del álbum para todos.'),
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
      await onDelete?.call(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: photos.length,
        itemBuilder: (_, i) {
          final photo = photos[i];
          return Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: CachedNetworkImage(
                    imageUrl: photo.url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: SafeArea(
                  child: Text(
                    '${photo.uploaderName} · '
                    '${AppDateFormat.short(photo.createdAt)} '
                    '${AppDateFormat.time(photo.createdAt)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
