import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/snackbars.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_cubit.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (prev, curr) =>
          curr.message != null && prev.message != curr.message,
      listener: (context, state) => showAppSnackBar(context, state.message!),
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();

        return Scaffold(
          appBar: AppBar(title: const Text('Notificaciones')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!state.permissionGranted)
                    Card(
                      color: theme.colorScheme.errorContainer,
                      child: const ListTile(
                        leading: Icon(Icons.notifications_off_outlined),
                        title: Text('Notificaciones desactivadas'),
                        subtitle: Text(
                          'Actívalas en los ajustes de tu celular para '
                          'recibir avisos.',
                        ),
                      ),
                    ),
                  Text('Temas de interés', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        for (final topic in kGeneralTopics)
                          SwitchListTile(
                            title: Text(topic.title),
                            subtitle: Text(topic.description),
                            value: state.isSubscribed(topic.id),
                            onChanged: (_) => cubit.toggleTopic(topic.id),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'También puedes activar los avisos de cada evento con la '
                    'campana en su pantalla de detalle.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  // Útil para enviar una notificación de prueba
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.key_outlined),
                      title: const Text('Token del dispositivo'),
                      subtitle: Text(
                        state.token ?? 'No disponible',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.copy),
                      onTap: state.token == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: state.token!),
                              );
                              if (context.mounted) {
                                showAppSnackBar(context, 'Token copiado.');
                              }
                            },
                    ),
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
