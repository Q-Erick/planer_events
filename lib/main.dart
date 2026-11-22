import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/config/app_config.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_cubit.dart';
import 'features/notifications/presentation/widgets/global_notification_listener.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;

/// Se ejecuta cuando llega una notificación con la app en segundo
/// plano o cerrada. Debe ser una función de nivel superior.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Notificación en segundo plano: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('es');
  if (!kIsWeb) {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }
  await di.init();
  await di.sl<NotificationsCubit>().initialize();

  runApp(const PlanerEventsApp());

  // Si la app se abrió desde una notificación (estando cerrada)
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => di.sl<NotificationsCubit>().handleInitialMessage(),
  );
}

class PlanerEventsApp extends StatelessWidget {
  const PlanerEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: di.sl<ThemeCubit>()),
        BlocProvider<AuthBloc>.value(value: di.sl<AuthBloc>()),
        BlocProvider<NotificationsCubit>.value(
          value: di.sl<NotificationsCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Planer Events',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
            scaffoldMessengerKey: rootMessengerKey,
            // Listener global: activo en todas las pantallas
            builder: (context, child) =>
                GlobalNotificationListener(child: child!),
          );
        },
      ),
    );
  }
}
