import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../bloc/notifications_cubit.dart';

/// Llave global para mostrar avisos desde cualquier pantalla.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class GlobalNotificationListener extends StatelessWidget {
  const GlobalNotificationListener({super.key, required this.child});

  final Widget child;

  void _openRoute(String? route) {
    if (route == null || route.isEmpty) return;
    AppRouter.router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Primer plano: aviso dentro de la app
        BlocListener<NotificationsCubit, NotificationsState>(
          listenWhen: (prev, curr) =>
              curr.foreground != null && prev.foreground != curr.foreground,
          listener: (context, state) {
            final n = state.foreground!;
            rootMessengerKey.currentState
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 6),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (n.body.isNotEmpty) Text(n.body),
                    ],
                  ),
                  action: n.route == null
                      ? null
                      : SnackBarAction(
                          label: 'Ver',
                          onPressed: () => _openRoute(n.route),
                        ),
                ),
              );
          },
        ),
        // Segundo plano o app cerrada: el usuario tocó la notificación
        BlocListener<NotificationsCubit, NotificationsState>(
          listenWhen: (prev, curr) =>
              curr.opened != null && prev.opened != curr.opened,
          listener: (context, state) => _openRoute(state.opened!.route),
        ),
      ],
      child: child,
    );
  }
}
